/**
 * NGF 适老属性修饰器框架
 *
 * ## ✅ 交付路径：`AttributeModifier` 一行下发（**真机已验证可用**）
 *
 * 2026-10-06 在 MatePad Mini（API 26）实测确认：
 * `Text('语言设置').attributeModifier(this.a11yMods.text(18))` 渲染高度
 * **56px = 23.4vp = 18 × 1.3**，即 `fontSize` 与 `lineHeight` **都正确下发** ✓
 * （同一次测量中页面文本总数 21 条，渲染正常）
 *
 * ## ⚠️ 唯一的关键约束：`@State` 持有，**禁止在 build 路径里构造**
 *
 * 修饰器集**必须**作为 `@State` 字段持有，在策略变化时**整体替换**：
 *
 * ```ts
 * @State private a11yMods: NGFA11yModifierSet =
 *   new NGFA11yModifierSet(resolveA11yTextScaleForCurrent());
 *
 * private attachA11yBinding(): void {
 *   const listener: NGFAccessibilityBindingListener = {
 *     onInclusiveDesignChanged: (_r: NGFInclusiveDesignResolved): void => {
 *       // 必须**新建实例**：AttributeModifier 是命令式下发属性的，
 *       // 只改实例内部字段不会重新下发。
 *       this.a11yMods = new NGFA11yModifierSet(resolveA11yTextScaleForCurrent());
 *     }
 *   };
 *   this.a11yBinding = new NGFAccessibilityLifecycleBinding(listener);
 *   this.a11yBinding.attach();
 * }
 *
 * build() {
 *   Text('标题').attributeModifier(this.a11yMods.text(16))
 *   Button('确定').attributeModifier(this.a11yMods.button(16, 40))
 * }
 * ```
 *
 * **为什么不能写成 `private get a11y() { return new NGFA11yModifierSet(...); }`**：
 * 2026-10-06 实测，在 `MainMenuPage` 用 getter 形式后，
 * **设置页整页渲染异常** —— 文本从 21 条掉到 7 条、大片空白；
 * 移除该 getter 后**立即恢复**。**在 build 路径里现场构造对象会破坏渲染。**
 * （当时我据此误判「`AttributeModifier` 不生效」—— 那个结论**是错的**，
 * 量到的是坏页面。用 `@State` 字段重做实验后确认可用。）
 *
 * ## 为什么用 `AttributeModifier` 而不是 `@Extend` / `@Styles`
 *
 * `@Extend(Text)` 和 `@Styles` **不能跨文件导入**（ArkTS 限制），
 * 只能在声明文件里用，**无法成为可复用的框架能力**。
 * `AttributeModifier<T>`（**@since 11/12**）是**类**，可以正常导出导入。
 */

import { NGFA11yTextScale, a11yTouchTarget } from './NGFA11yTextScale';

/** 文本：字号 + 行高（附件2 §1.1 + §1.2） */
export class NGFA11yTextModifier implements AttributeModifier<TextAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly fontSizeVp: number;
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly lineHeightVp: number;

  constructor(fontSizeVp: number, lineHeightVp: number) {
    this.fontSizeVp = fontSizeVp;
    this.lineHeightVp = lineHeightVp;
  }

  /** 适老档字号（vp/fp） */
  get fontSize(): number {
    return this.fontSizeVp;
  }

  /** 适老档行高；普通档为 0 = 随字号自适应（默认行为） */
  get lineHeight(): number {
    return this.lineHeightVp;
  }

  applyNormalAttribute(instance: TextAttribute): void {
    instance.fontSize(this.fontSizeVp);
    // lineHeight 为 0 时 ArkUI 语义是「随字号自适应」，即默认行为 —— 普通档正好用它保持零回归。
    instance.lineHeight(this.lineHeightVp);
  }
}

/** 行内文本（Span）：只改字号，行高由外层 Text 控制 */
export class NGFA11ySpanModifier implements AttributeModifier<SpanAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly fontSizeVp: number;

  constructor(fontSizeVp: number) {
    this.fontSizeVp = fontSizeVp;
  }

  /** 适老档字号（vp/fp） */
  get fontSize(): number {
    return this.fontSizeVp;
  }

  applyNormalAttribute(instance: SpanAttribute): void {
    instance.fontSize(this.fontSizeVp);
  }
}

/** 符号图标：只改字号（SymbolGlyph 的尺寸由 fontSize 决定） */
export class NGFA11ySymbolModifier implements AttributeModifier<SymbolGlyphAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly fontSizeVp: number;

  constructor(fontSizeVp: number) {
    this.fontSizeVp = fontSizeVp;
  }

  /** 适老档字号（vp/fp） */
  get fontSize(): number {
    return this.fontSizeVp;
  }

  applyNormalAttribute(instance: SymbolGlyphAttribute): void {
    instance.fontSize(this.fontSizeVp);
  }
}

/** 按钮：字号 + 点击区（附件2 §1.1 + §2.1） */
export class NGFA11yButtonModifier implements AttributeModifier<ButtonAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly fontSizeVp: number;
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly touchTargetVp: number;

  constructor(fontSizeVp: number, touchTargetVp: number) {
    this.fontSizeVp = fontSizeVp;
    this.touchTargetVp = touchTargetVp;
  }

  /** 适老档字号（vp/fp） */
  get fontSize(): number {
    return this.fontSizeVp;
  }

  /** 适老档点击区下限（vp） */
  get target(): number {
    return this.touchTargetVp;
  }

  applyNormalAttribute(instance: ButtonAttribute): void {
    instance.fontSize(this.fontSizeVp);
    instance.constraintSize({ minHeight: this.touchTargetVp });
  }
}

/** 开关：只改点击区（附件2 §2.1）—— Toggle 没有字号属性 */
export class NGFA11yToggleModifier implements AttributeModifier<ToggleAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly touchTargetVp: number;

  constructor(touchTargetVp: number) {
    this.touchTargetVp = touchTargetVp;
  }

  /** 适老档点击区下限（vp） */
  get target(): number {
    return this.touchTargetVp;
  }

  applyNormalAttribute(instance: ToggleAttribute): void {
    instance.constraintSize({ minWidth: this.touchTargetVp, minHeight: this.touchTargetVp });
  }
}

/** 图片：宽高同比放大 */
export class NGFA11yImageModifier implements AttributeModifier<ImageAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly sizeVp: number;

  constructor(sizeVp: number) {
    this.sizeVp = sizeVp;
  }

  /** 适老档尺寸（vp） */
  get size(): number {
    return this.sizeVp;
  }

  applyNormalAttribute(instance: ImageAttribute): void {
    instance.width(this.sizeVp);
    instance.height(this.sizeVp);
  }
}

/** 输入框：字号 + 高度（附件2 §1.1 + §2.1） */
export class NGFA11yTextInputModifier implements AttributeModifier<TextInputAttribute> {
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly fontSizeVp: number;
  /** 已算好的值；公开只读，便于单测直接断言（无需伪造 Attribute 实例） */
  readonly heightVp: number;

  constructor(fontSizeVp: number, heightVp: number) {
    this.fontSizeVp = fontSizeVp;
    this.heightVp = heightVp;
  }

  /** 适老档字号（vp/fp） */
  get fontSize(): number {
    return this.fontSizeVp;
  }

  /** 适老档高度（vp） */
  get height(): number {
    return this.heightVp;
  }

  applyNormalAttribute(instance: TextInputAttribute): void {
    instance.fontSize(this.fontSizeVp);
    instance.height(this.heightVp);
  }
}

/**
 * ⚠️ **间距（`space`）无法用 `AttributeModifier` 处理**。
 *
 * `List({ space })` / `Column({ space })` / `Row({ space })` 里的 `space` 是
 * **构造函数参数**，不是属性方法 —— `ListAttribute` / `FlexAttribute` 上
 * **没有** `space()`（实测编译报错 `Property 'space' does not exist`）。
 *
 * 所以间距必须留在构造处，用缩放器直接算：
 *
 * ```ts
 * Column({ space: this.a11yScale.groupSpacing(8) })     // 组内间距
 * Column({ space: this.a11yScale.paragraphSpacing(12, 18) })  // 段落间距
 * List({ space: this.a11yScale.groupSpacing(8) })
 * ```
 *
 * 本模块**不提供** List / Flex 修饰器 —— 提供了也做不到，只会误导。
 */

/**
 * 适老修饰器工厂：绑定一个缩放器，按组件类型产出正确的修饰器。
 *
 * **开发者只需要记住一件事**：`.attributeModifier(this.a11y.<组件类型>(原值))`。
 * 具体要改几个属性、适老档要改成多少，全部由框架决定。
 */
export class NGFA11yModifierSet {
  private readonly scale: NGFA11yTextScale;

  constructor(scale: NGFA11yTextScale) {
    this.scale = scale;
  }

  /** 本次构造所用的缩放器；页面只需持有修饰器集即可拿到全部数值 */
  get textScale(): NGFA11yTextScale {
    return this.scale;
  }

  /** 文本：字号自动抬到 §1.1 的 18 dp，行高自动按 §1.2 的 1.3 倍 */
  text(normalFontSize: number): NGFA11yTextModifier {
    const size: number = this.scale.font(normalFontSize);
    return new NGFA11yTextModifier(size, this.scale.lineHeight(size));
  }

  /** 文本（原本已有显式行高） */
  textWithLineHeight(normalFontSize: number, normalLineHeight: number): NGFA11yTextModifier {
    const size: number = this.scale.font(normalFontSize);
    return new NGFA11yTextModifier(size, this.scale.explicitLineHeight(size, normalLineHeight));
  }

  span(normalFontSize: number): NGFA11ySpanModifier {
    return new NGFA11ySpanModifier(this.scale.font(normalFontSize));
  }

  /** 符号图标：适老档按 1.3 倍放大（图标不适用 §1.1 的字号下限） */
  icon(normalSize: number): NGFA11ySymbolModifier {
    return new NGFA11ySymbolModifier(this.scale.isElderly ? Math.round(normalSize * 1.3) : normalSize);
  }

  /** 按钮：字号 + 点击区（适老档 ≥60，普通档保持原值） */
  button(normalFontSize: number, normalTouchTarget: number): NGFA11yButtonModifier {
    return new NGFA11yButtonModifier(
      this.scale.font(normalFontSize),
      a11yTouchTarget(this.scale.isElderly, normalTouchTarget)
    );
  }

  /** 开关：只改点击区 */
  toggle(normalTouchTarget: number): NGFA11yToggleModifier {
    return new NGFA11yToggleModifier(a11yTouchTarget(this.scale.isElderly, normalTouchTarget));
  }

  image(normalSize: number): NGFA11yImageModifier {
    return new NGFA11yImageModifier(this.scale.isElderly ? Math.round(normalSize * 1.3) : normalSize);
  }

  /** 输入框：字号 + 高度（高度按点击区下限走） */
  textInput(normalFontSize: number, normalHeight: number): NGFA11yTextInputModifier {
    return new NGFA11yTextInputModifier(
      this.scale.font(normalFontSize),
      a11yTouchTarget(this.scale.isElderly, normalHeight)
    );
  }

  // 间距没有修饰器：space 是构造参数，见文件顶部说明。
  // 需要时直接用 this.scale.groupSpacing(n) / paragraphSpacing(n, bodyFontSize)。
}
