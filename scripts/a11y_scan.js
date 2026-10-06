#!/usr/bin/env node
/**
 * NGF 无障碍静态检查器
 *
 * 覆盖 5 类**绑定错误**（每一类都在本项目真实发生过）：
 *
 * | # | 检查 | 规则 |
 * |---|---|---|
 * | 1 | 图标/图片未标注 | 无 `accessibilityText` 且未标 `accessibilityLevel('no')` |
 * | 2 | 可点击容器无文本 | 无 `Text` 子节点也无 `accessibilityText` |
 * | 3 | `Toggle` 无标签 | 读屏只念「开关，关闭」，不知控制什么 |
 * | 4 | `@Builder` 用位置参数渲染文本 | 不会随状态刷新（PR-016） |
 * | 5 | `accessibilityText` 传 `ResourceStr` 联合类型 | 编译失败，必须先解析成 string |
 *
 * ## 它能证明什么、不能证明什么（必读）
 *
 * **能**：给出**下界** —— 报出来的基本是真问题。
 * **不能**：给出**上界** —— **没报不等于没问题**。
 *
 * 三样东西**静态查不到，只能靠读屏实测**：
 * 1. `accessibilityText` 是否真的被播报 —— `dumpLayout` 里 `text`/`originalText`/`description` 都是空的；
 * 2. `accessibilityGroup(true)` 是否生效 —— `dumpLayout` dump 的是**渲染树**，
 *    分组作用于**无障碍树**，分组后 dump 里**仍然**能看到子 Text 节点；
 * 3. 焦点顺序、朗读停顿等运行时行为。
 *
 * ## 已知误报（不要试图在代码里"修"）
 *
 * - 滚动条：极窄的 `Button`
 * - HDS 浮动底栏背景容器：`Tabs > Stack`，clickable 但无子节点，属 HDS 内部行为
 * - 系统状态栏节点
 * - 用了 `NGFAccessibilityAttributeModifier` 的容器**内部**的图标（语义由修饰器下发）
 *
 * 用法：`node scripts/a11y_scan.js`
 */

const fs = require('node:fs');
const path = require('node:path');

const ROOT = path.resolve(__dirname, '..');
const ROOTS = [
  path.join(ROOT, 'entry', 'src', 'main', 'ets'),
  path.join(ROOT, 'ngf_framework', 'src', 'main', 'ets', 'uiShell')
];

function walk(dir, out) {
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { walk(p, out); }
    else if (e.name.endsWith('.ets')) { out.push(p); }
  }
}

function leading(line) {
  const m = /^(\s*)/.exec(line);
  return m ? m[1].length : 0;
}

/**
 * 取组件从 start 行起的完整属性链。
 *
 * 不能用「下一行是否以 . 开头」判断 —— 多行属性参数
 * （如 .fontColor([a / ? x : y])）的续行不以 . 开头，
 * 会漏掉链尾的 .accessibilityLevel('no')，产生**误报**。
 * 改用**缩进深度**：比起始行更深的一律属于本链。
 */
function chainOf(lines, start) {
  const ind = leading(lines[start]);
  let out = lines[start];
  for (let j = start + 1; j < lines.length; j++) {
    const l = lines[j];
    if (l.trim() === '') { continue; }
    if (leading(l) <= ind) { break; }
    out += '\n' + l;
  }
  return out;
}

/**
 * 花括号配对取块，并取**块之后**的属性链。
 *
 * ⚠️ 容器形态（`Button({...}) { ... }`）的属性链写在**块结束的 `}` 之后**，
 * 而且缩进与组件行**相同**。所以不能直接对 `}` 行调 `chainOf`
 * （它会因为"不比 `}` 更深"而立刻中断），必须从**组件行的缩进**重新收集。
 */
function blockOf(lines, start) {
  const ind = leading(lines[start]);
  let depth = 0, j = start, body = '';
  for (; j < lines.length && j < start + 160; j++) {
    body += lines[j] + '\n';
    for (const ch of lines[j]) {
      if (ch === '{') { depth++; } else if (ch === '}') { depth--; }
    }
    if (depth <= 0 && j > start) { break; }
  }
  // 块结束的 } 之后的同级属性链
  let chain = lines[j] || '';
  for (let k = j + 1; k < lines.length; k++) {
    const l = lines[k];
    if (l.trim() === '') { continue; }
    if (leading(l) !== ind || !/^\s*\./.test(l)) { break; }
    chain += '\n' + l;
  }
  return { body, chain, end: j };
}

/** 图标是否被「已用 NGFAccessibilityAttributeModifier 下发语义」的外层容器包住 */
function enclosedBySemanticsContainer(lines, from) {
  const ind = leading(lines[from]);
  let container = -1;
  for (let j = from - 1; j >= 0 && j > from - 40; j--) {
    const l = lines[j];
    if (l.trim() === '') { continue; }
    if (leading(l) >= ind) { continue; }
    if (/^\s*(Button|Column|Row|Stack)\s*\(/.test(l)) { container = j; }
    break;
  }
  if (container < 0) { return false; }
  return /attributeModifier\(\s*new\s+NGFAccessibility/.test(blockOf(lines, container).chain);
}

function main() {
  const files = [];
  for (const r of ROOTS) { walk(r, files); }
  const findings = [];

  for (const f of files) {
    const raw = fs.readFileSync(f, 'utf8');
    const lines = raw.split(/\r?\n/);
    const rel = path.relative(ROOT, f).replace(/\\/g, '/');

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];

      // 检查 3：Toggle 无标签
      if (/^\s*Toggle\s*\(/.test(line)) {
        const c = chainOf(lines, i);
        if (!/\.accessibilityText\(/.test(c)) {
          findings.push({ rel, line: i + 1, code: 'TOGGLE_WITHOUT_LABEL',
            msg: 'Toggle 缺 accessibilityText：读屏只念「开关，关闭」，不知控制什么' });
        }
      }

      // 检查 1：图标/图片未标注
      const im = /^\s*(SymbolGlyph|Image)\s*\(/.exec(line);
      if (im) {
        const c = chainOf(lines, i);
        const hasA11y = /\.accessibility(Text|Description)\(/.test(c);
        const decorative = /\.accessibilityLevel\('no'\)/.test(c);
        if (!hasA11y && !decorative && !enclosedBySemanticsContainer(lines, i)) {
          findings.push({ rel, line: i + 1, code: 'ICON_WITHOUT_LABEL',
            msg: im[1] + " 既无 accessibilityText 也未标 accessibilityLevel('no')" });
        }
      }

      // 检查 2：可点击容器无文本
      if (/^\s*(Row|Column|Stack)\s*\(.*\)\s*\{\s*$/.test(line)) {
        const { body, chain } = blockOf(lines, i);
        const interactive = /\.onClick\(|\.onTouch\(|\.gesture\(/.test(chain);
        if (interactive && !/\b(Button|Toggle|Slider|TextInput)\s*\(/.test(body)) {
          if (!/\bText\s*\(/.test(body) && !/\.accessibility(Text|Description)\(/.test(chain)) {
            findings.push({ rel, line: i + 1, code: 'CONTAINER_WITHOUT_LABEL',
              msg: '可点击容器既无 Text 子节点也无 accessibilityText：读屏无法理解' });
          }
        }
      }

      // 检查 4：@Builder 用位置参数渲染文本（PR-016）
      const bm = /@Builder\s+private\s+(\w+)\s*\(([^)]*)\)\s*:\s*void\s*\{/.exec(line);
      if (bm) {
        const name = bm[1], sig = bm[2].trim();
        if (sig.length > 0 && !sig.includes('@BuilderParam')) {
          const positional = sig.split(',').map(s => s.trim())
            .filter(s => s.length > 0 && !s.includes(':'));
          if (positional.length > 0) {
            const { body } = blockOf(lines, i);
            const hit = positional.some(p => new RegExp('Text\\(\\s*' + p + '\\s*\\)').test(body));
            if (hit) {
              findings.push({ rel, line: i + 1, code: 'BUILDER_POSITIONAL_PARAM',
                msg: name + '(…) 用位置参数渲染文本：不会随状态刷新（PR-016），应改传对象' });
            }
          }
        }
      }

      // 检查 5：accessibilityText 传 ResourceStr 联合类型
      // ArkUI 是 (value: string) 与 (text: Resource) 两个独立重载，不接受联合类型。
      // 只对**本文件内能查到声明且返回类型为 ResourceStr** 的方法报警 ——
      // 返回 string 的方法合法（走 string 重载），不能误报。
      const am = /\.accessibility(Text|Description)\(([^)]*)/.exec(line);
      if (am) {
        const arg = am[2].trim();
        const mm = /^this\.(\w+)\(/.exec(arg);
        if (mm) {
          const fn = mm[1];
          const decl = new RegExp('(private|public|protected)?\\s*' + fn + '\\s*\\([^)]*\\)\\s*:\\s*ResourceStr');
          if (decl.test(raw)) {
            findings.push({ rel, line: i + 1, code: 'A11Y_TEXT_RESOURCESTR',
              msg: fn + '() 声明返回 ResourceStr —— ArkUI 的 accessibilityText/Description 是 (string) 与 (Resource) 两个**独立重载**，不接受联合类型，会**编译失败**；需先 resolveResourceString() 解析成 string' });
          }
        }
      }
    }
  }

  if (findings.length === 0) {
    console.log('✓ 静态检查未发现问题');
    console.log('  （注意：这只代表**下界**。accessibilityText 是否真被播报、');
    console.log('   accessibilityGroup 是否生效，都必须用读屏服务实测。）');
    return 0;
  }

  console.log('发现 ' + findings.length + ' 处待确认：\n');
  const byFile = new Map();
  for (const x of findings) {
    const a = byFile.get(x.rel) || [];
    a.push(x);
    byFile.set(x.rel, a);
  }
  for (const [rel, arr] of [...byFile.entries()].sort((a, b) => b[1].length - a[1].length)) {
    console.log('  ' + rel + '  (' + arr.length + ')');
    for (const x of arr) {
      console.log('      L' + x.line + '  [' + x.code + '] ' + x.msg);
    }
  }
  console.log('\n判据见 .rules/skill-accessibility.md；能证明的是下界，不能证明"都没问题"。');
  return 1;
}

process.exit(main());
