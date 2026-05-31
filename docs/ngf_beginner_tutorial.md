# 从零开始使用 NGF 框架开发 HarmonyOS APP：小白入门教程

欢迎来到 NGF 开发的世界！本教程将带你从零开始，使用鸿蒙最新的 DevEco Studio，在 NGF 框架下完成你的第一次开发实践。

> [!IMPORTANT]
> **认识 NGF 框架**
> 本项目并非一个独立的业务 App，而是一个 **HarmonyOS Next 核心运行框架** 与 **框架验证工程**。你的开发应当以“沉淀可复用模式、展示官方组件接入方式”为目标，保持代码的高内聚低耦合。

---

## 第一阶段：DevEco Studio 环境与认知准备

在动手写代码前，我们要确保编译环境与工程配置一致。

1. **检查 SDK 路径与版本**
   当前工程要求 `targetSdkVersion` 和 `compatibleSdkVersion` 均为 `6.1.0(23)`。
   - 打开 DevEco Studio，点击顶部菜单 `File -> Settings -> SDK`（macOS 为 `DevEco Studio -> Settings -> SDK`）。
   - 确认 **API 12 (SDK 23)** 已安装。
   - 默认安装路径一般为 `F:\DevEco Studio\sdk\default\openharmony` 或 `F:\HarmonyOS\SDK\23`。
2. **正确打开工程**
   在 DevEco Studio 中选择 `File -> Open`，一定要直接选中仓库的**根目录**（`F:\DevEcoStudioProject\NGF`），不要打开里面的子目录（如 entry），否则 hvigor 构建工具将无法正确工作。
3. **认识项目骨架**
   - `pages/ngf/`：框架的所有演示页、入口页和功能验证页都在这里。
   - `Framework/NGF/core/`：核心架构，包括生命周期管理、事件总线、服务容器。
   - `Framework/NGF/uiShell/`：UI 壳层能力，负责全局的导航封装（HdsNavigation）与顶栏组件沉浸式底板配置。
   - `Framework/NGF/utils/Logger.ets`：全局日志门面，开发过程中所有日志必须从此入口输出。

---

## 第二阶段：动手编写你的第一个页面

下面我们通过实际操作，在 `pages/ngf/` 目录下创建一个全新页面，并接入系统的 HDS 导航体系。

### 步骤 1：新建页面文件

在项目目录 `entry/src/main/ets/pages/ngf/` 右键，选择 `New -> ArkTS File`，命名为 `NGFDemoHelloPage.ets`。

将以下代码贴入文件中。这份代码严格遵守了 NGF 的沉浸式顶栏规范和无 `any` 强类型要求：

```typescript
import { HdsNavDestination } from '@kit.UIDesignKit';
import { NGFHdsTitleBarOptionsFactory } from '../../Framework/NGF/uiShell/components/HdsNavigationSupport';
import { NGFImmersiveTopChromeUnderlay } from '../../Framework/NGF/uiShell/components/NGFImmersiveTopChrome';
import { ngfStarterKernel } from '../../Framework/NGF/core/starter/index';

const TAG: string = 'NGFDemoHelloPage';

@Component
export struct NGFDemoHelloPage {
  @Consume('pageInfo') pageInfo: NavPathStack;

  aboutToAppear(): void {
    // 规范要求：必须使用 NGF 的 Logger 工具，严禁使用 console.log
    ngfStarterKernel.logger.info(TAG, 'Hello Page initialized.');
  }

  build() {
    // 规范要求：NGF 页面默认采用 HdsNavDestination 作为路由根节点
    HdsNavDestination({
      titleBar: NGFHdsTitleBarOptionsFactory.build(
        '新手演示页面', // 实际项目中建议使用 $r('app.string.xxx') 进行国际化
        () => this.pageInfo.pop()
      )
    }) {
      Stack({ alignContent: Alignment.Top }) {
        // 规范要求：提供顶部沉浸式毛玻璃底板
        NGFImmersiveTopChromeUnderlay()

        Column({ space: 24 }) {
          Text('欢迎来到 NGF 框架开发指南！')
            .fontSize(20)
            .fontWeight(FontWeight.Medium)
            .fontColor($r('sys.color.ohos_id_color_text_primary'))
          
          Button('在控制台打印日志')
            .onClick(() => {
              ngfStarterKernel.logger.debug(TAG, 'User clicked the button.');
            })
            .width('80%')
        }
        .width('100%')
        // 规范要求：为正文留出安全区避让空间 (通常为 112 或通过避让区域动态计算)
        .padding({ top: 112, left: 16, right: 16 }) 
      }
      .width('100%')
      .height('100%')
    }
    .hideTitleBar(true) // 必须隐藏默认的系统 TitleBar，由我们刚才配置的 HDS TitleBar 接管
  }
}

// 供动态路由分发使用的 Builder
@Builder
export function NGFDemoHelloPageBuilder(name: string, param: Object) {
  NGFDemoHelloPage()
}
```

### 步骤 2：注册路由名称

打开 `entry/src/main/ets/pages/ngf/HdsDemoRoutes.ets`，在常量类中注册你的新路由名称：

```typescript
export class NGFHdsDemoRouteName {
  // ... 其他常量 ...
  static readonly DEMO_HELLO: string = 'ngf.demo.hello';
}
```

### 步骤 3：将路由映射到主导航

NGF 中大部分验证页面的主路由入口都在 `MainMenuPage.ets` 的 `pathStack` 或某个特定的路由分发表中。
我们需要将刚刚写好的 `NGFDemoHelloPageBuilder` 关联到路由名称上。如果是统一路由分发（如使用 `Navigation` 的 `navDestination` 属性），需要导入你的 builder 并在 map 中增加条件分支。由于目前代码结构可能在 `MainMenuPage.ets` 中已经有一套页面分发机制，你需要找到渲染 `NavDestination` 的 Builder 函数，添加判断：

```typescript
// 伪代码示例：在路由总线上注册
if (name === NGFHdsDemoRouteName.DEMO_HELLO) {
  NGFDemoHelloPageBuilder(name, param)
}
```

### 步骤 4：在主菜单添加点击入口

打开 `entry/src/main/ets/pages/ngf/MainMenuPage.ets`，在 UI 合适的位置（比如 `HdsTabs` 中的 `TabContent`）新增一个入口按钮及其点击事件：

```typescript
// 添加在结构体内的处理函数
private handleOpenHelloDemoTap(): void {
  try {
    // 规范要求：路由跳转必须沿用现有的 pathStack 机制
    this.pathStack.pushPathByName(NGFHdsDemoRouteName.DEMO_HELLO, null);
    this.appendLog('成功打开 Hello Demo 页面');
  } catch (error) {
    const msg = error instanceof Error ? error.message : String(error);
    this.starter.logger.error(TAG, `Failed to open hello demo: ${msg}`);
  }
}

// 在 build() 函数的卡片 Column 中增加按钮
Button('新手演示页面')
  .onClick(() => this.handleOpenHelloDemoTap())
```

---

## 第三阶段：编译、运行与排错

1. **预览与运行**
   点击 DevEco Studio 右侧栏的 `Previewer` 面板，或者连接真机/模拟器后点击顶部绿色的 `Run 'entry'` 按钮。
2. **遇到报错怎么办？**
   - **绝不无差别清理 `.cxx`**：遇到 `Ninja does not match...` 等 C++ 编译缓存冲突时，仅清理报错指向的对应路径（如 `entry\.cxx\default\default\debug\arm64-v8a`）。
   - **先查官方文档**：如果涉及某些 API 标红报黄，一定要先查看对应的 ArkTS `6.1.0` 官方文档，判断是否接口废弃或改名。
   - **严格排查 Any/Unknown**：框架配置了严格的类型检查，如果你的对象未标注类型或使用了未知的解构赋值，会直接报错，请老老实实补充 `interface` 或 `class` 定义。

> [!TIP]
> **NGF 核心红线规则总结：**
> 1. 禁用 `any` 与 `unknown`，必须有明确类型。
> 2. 必须使用 `Logger.ets` 中的工具打印日志，禁绝 `console.log`。
> 3. 不写死单一业务名称、保持模块复用性。
> 4. 使用 `$r()` 统一拉取资源。
> 5. 使用 `as` 断言，严禁将对象字面量进行危险赋值。
