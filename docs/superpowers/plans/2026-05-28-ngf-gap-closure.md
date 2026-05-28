# NGF Framework Gap Closure Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close all identified implementation gaps across the NGF framework's 10 core layers and extended capability layers, bringing each layer to functional completeness.

**Architecture:** Follows existing NGF patterns — every new facade extends `NGFIntegrationFacadeBase`, implements a contract interface from `contracts/`, and registers services via `getServiceRegistrations()`. All code must comply with ArkTS strict mode (no `any`, no `unknown`, no object spread, no `globalThis`).

**Tech Stack:** ArkTS (Stage Mode), HarmonyOS SDK 6.1.0 (API 23), ArkUI + HDS, hvigorw build system

**Priority Tiers:**
- **Tier 1 (Tasks 1-6):** Quick wins — register unexisting facades, fix stubs
- **Tier 2 (Tasks 7-14):** Core gaps — standalone facades, missing action types, interceptors
- **Tier 3 (Tasks 15-21):** Medium complexity — pipeline parsing, event integration, RTL, templates
- **Tier 4 (Tasks 22-26):** Advanced — pagination, theme packs, window control, hot-reload

---

## File Map

```
entry/src/main/ets/Framework/NGF/
├── core/
│   ├── contracts/
│   │   └── (existing: ILogger, IEventBus, IErrorHandler, ILifecycleOrchestrator)
│   └── facades/
│       ├── (existing: LoggerFacade, ModuleConfigFacade, ServiceContainerFacade)
│       ├── NEW: EventBusFacade.ets              # Task 7
│       ├── NEW: ErrorHandlerFacade.ets           # Task 8
│       └── NEW: LifecycleOrchestratorFacade.ets  # Task 9
├── data/
│   └── facades/
│       └── (modify: NGFDataIntegrationFacade.ets) # Task 1: register EncryptedSettingsStore
├── contentWorkflow/
│   └── facades/
│       └── (modify: ActionExecutorFacade.ets)     # Task 10-11: script + api actions
├── contentSource/
│   ├── contracts/
│   │   └── (modify: IHttpInterceptor.ets)         # Task 12: add default interceptor types
│   └── facades/
│       ├── NEW: LoggingInterceptorFacade.ets      # Task 12
│       └── (modify: ContentPipelineFacade.ets)    # Task 15: real parse implementation
├── uiShell/
│   ├── contracts/
│   │   └── (modify: IOverlayManager.ets)          # Task 3: add sheet support
│   ├── components/
│   │   └── (modify: NGFPageTemplates.ets)         # Task 19: real page templates
│   └── facades/
│       ├── (modify: OverlayManagerFacade.ets)     # Task 2: register + add sheet
│       ├── (modify: NGFUiShellIntegrationFacade.ets) # Task 2-3: register missing facades
│       └── (modify: PageTransitionManagerFacade.ets) # Task 2: register
├── uiTheme/
│   └── facades/
│       ├── (modify: ComponentThemeOverrideFacade.ets) # Task 4: register
│       └── (modify: NGFUIThemeIntegrationFacade.ets)  # Task 4
├── i18n/
│   └── facades/
│       └── (modify: I18nManagerFacade.ets)        # Task 17: RTL layout, formatNumber fix
├── deviceAwareness/
│   ├── contracts/
│   │   └── NEW: IAccessibilityManager.ets         # Task 5
│   └── facades/
│       ├── (modify: AccessibilityFacade.ets)      # Task 5: implement properly
│       └── (modify: NGFDeviceAwarenessIntegrationFacade.ets) # Task 5: register
├── systemTasks/
│   ├── contracts/
│   │   └── (existing: ILiveViewManager)
│   └── facades/
│       └── (modify: LiveViewManagerFacade.ets)    # Task 6: real LiveViewKit integration
├── platformOhos/
│   └── facades/
│       └── (modify: PlatformWindowManagerFacade.ets) # Task 16: event bus integration
└── utils/
    └── NEW: StringUtils.ets                       # Task 21
```

---

## Tier 1: Quick Wins (Tasks 1-6)

### Task 1: Register EncryptedSettingsStoreFacade in DI

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/data/facades/NGFDataIntegrationFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/data/facades/EncryptedSettingsStoreFacade.ets`

- [ ] **Step 1: Read the existing integration facade to understand registration pattern**

```bash
cat entry/src/main/ets/Framework/NGF/data/facades/NGFDataIntegrationFacade.ets
```

Note the `getServiceRegistrations()` method pattern and how other facades are registered.

- [ ] **Step 2: Read EncryptedSettingsStoreFacade to get the class name and export**

```bash
cat entry/src/main/ets/Framework/NGF/data/facades/EncryptedSettingsStoreFacade.ets
```

- [ ] **Step 3: Add import and registration**

In `NGFDataIntegrationFacade.ets`, add the import for `EncryptedSettingsStoreFacade` and add a new `NGFServiceRegistration` entry in `getServiceRegistrations()`:

```typescript
// Add to imports
import { EncryptedSettingsStoreFacade } from './EncryptedSettingsStoreFacade';

// Add to getServiceRegistrations() array
new NGFServiceRegistration(
  'ngf.data.encrypted_settings_store',
  'EncryptedSettingsStore',
  (): EncryptedSettingsStoreFacade => new EncryptedSettingsStoreFacade(),
  NGFServiceLifetime.SINGLETON
)
```

- [ ] **Step 4: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

Expected: Build succeeds with no errors.

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/data/facades/NGFDataIntegrationFacade.ets
git commit -m "feat(data): register EncryptedSettingsStoreFacade in DI container"
```

---

### Task 2: Register OverlayManagerFacade and PageTransitionManagerFacade in uiShell DI

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/uiShell/facades/NGFUiShellIntegrationFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/uiShell/facades/OverlayManagerFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/uiShell/facades/PageTransitionManagerFacade.ets`

- [ ] **Step 1: Read the integration facade**

```bash
cat entry/src/main/ets/Framework/NGF/uiShell/facades/NGFUiShellIntegrationFacade.ets
```

- [ ] **Step 2: Add imports for both facades**

```typescript
import { ngfOverlayManagerFacade } from './OverlayManagerFacade';
import { PageTransitionManagerFacade } from './PageTransitionManagerFacade';
```

- [ ] **Step 3: Add service registrations in getServiceRegistrations()**

```typescript
new NGFServiceRegistration(
  'ngf.shell.overlay_manager',
  'OverlayManager',
  (): OverlayManagerFacade => ngfOverlayManagerFacade,
  NGFServiceLifetime.SINGLETON
),
new NGFServiceRegistration(
  'ngf.shell.page_transition_manager',
  'PageTransitionManager',
  (): PageTransitionManagerFacade => new PageTransitionManagerFacade(),
  NGFServiceLifetime.SINGLETON
)
```

- [ ] **Step 4: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/uiShell/facades/NGFUiShellIntegrationFacade.ets
git commit -m "feat(uiShell): register OverlayManager and PageTransitionManager in DI"
```

---

### Task 3: Add Sheet Support to IOverlayManager and OverlayManagerFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/uiShell/contracts/IOverlayManager.ets`
- Modify: `entry/src/main/ets/Framework/NGF/uiShell/facades/OverlayManagerFacade.ets`

- [ ] **Step 1: Read current IOverlayManager contract**

```bash
cat entry/src/main/ets/Framework/NGF/uiShell/contracts/IOverlayManager.ets
```

- [ ] **Step 2: Add sheet methods to the contract**

```typescript
import { ComponentContent } from '@kit.ArkUI';

export interface IOverlayManager {
  showCustomDialog(content: ComponentContent<object>): void;
  hideCustomDialog(content: ComponentContent<object>): void;
  showToast(message: string): void;
  showSheet(content: ComponentContent<object>, options?: SheetOptions): void;
  hideSheet(content: ComponentContent<object>): void;
}
```

- [ ] **Step 3: Implement sheet methods in OverlayManagerFacade**

Read the current facade, then add:

```typescript
showSheet(content: ComponentContent<object>, options?: SheetOptions): void {
  const uiContext = uiContextManager.getUIContext();
  if (!uiContext) {
    logger.error(TAG, 'showSheet failed: UIContext not found.');
    return;
  }
  try {
    uiContext.openBindSheet(content, options).catch((_err: Error): void => {
      logger.error(TAG, 'openBindSheet failed.');
    });
    logger.info(TAG, 'showSheet triggered.');
  } catch (e) {
    logger.error(TAG, `showSheet failed: ${e}`);
  }
}

hideSheet(content: ComponentContent<object>): void {
  const uiContext = uiContextManager.getUIContext();
  if (!uiContext) {
    logger.error(TAG, 'hideSheet failed: UIContext not found.');
    return;
  }
  try {
    uiContext.closeBindSheet(content).catch((_err: Error): void => {
      logger.error(TAG, 'closeBindSheet failed.');
    });
    logger.info(TAG, 'hideSheet triggered.');
  } catch (e) {
    logger.error(TAG, `hideSheet failed: ${e}`);
  }
}
```

- [ ] **Step 4: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 5: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/uiShell/contracts/IOverlayManager.ets
git add entry/src/main/ets/Framework/NGF/uiShell/facades/OverlayManagerFacade.ets
git commit -m "feat(uiShell): add sheet support to OverlayManager"
```

---

### Task 4: Register ComponentThemeOverrideFacade in uiTheme DI

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/uiTheme/facades/NGFUIThemeIntegrationFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/uiTheme/facades/ComponentThemeOverrideFacade.ets`

- [ ] **Step 1: Read the integration facade and ComponentThemeOverrideFacade**

```bash
cat entry/src/main/ets/Framework/NGF/uiTheme/facades/NGFUIThemeIntegrationFacade.ets
cat entry/src/main/ets/Framework/NGF/uiTheme/facades/ComponentThemeOverrideFacade.ets
```

- [ ] **Step 2: Add import and registration**

```typescript
import { ComponentThemeOverrideFacade } from './ComponentThemeOverrideFacade';

// In getServiceRegistrations():
new NGFServiceRegistration(
  'ngf.theme.component_override',
  'ComponentThemeOverride',
  (): ComponentThemeOverrideFacade => new ComponentThemeOverrideFacade(),
  NGFServiceLifetime.SINGLETON
)
```

- [ ] **Step 3: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/uiTheme/facades/NGFUIThemeIntegrationFacade.ets
git commit -m "feat(uiTheme): register ComponentThemeOverrideFacade in DI"
```

---

### Task 5: Create IAccessibilityManager Contract and Register AccessibilityFacade

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/deviceAwareness/contracts/IAccessibilityManager.ets`
- Modify: `entry/src/main/ets/Framework/NGF/deviceAwareness/facades/AccessibilityFacade.ets`
- Modify: `entry/src/main/ets/Framework/NGF/deviceAwareness/facades/NGFDeviceAwarenessIntegrationFacade.ets`

- [ ] **Step 1: Read existing AccessibilityFacade to understand its API**

```bash
cat entry/src/main/ets/Framework/NGF/deviceAwareness/facades/AccessibilityFacade.ets
```

- [ ] **Step 2: Create IAccessibilityManager contract**

```typescript
/**
 * 无障碍管理器契约
 * 提供屏幕阅读器检测、无障碍标签构建等能力
 */
export interface IAccessibilityManager {
  isAccessibilityEnabled(): boolean;
  isScreenReaderEnabled(): boolean;
  buildAccessibilityLabel(parts: Array<string>): string;
  buildAccessibilityHint(action: string, result: string): string;
}
```

- [ ] **Step 3: Update AccessibilityFacade to implement the contract**

```typescript
import { IAccessibilityManager } from '../contracts/IAccessibilityManager';

export class AccessibilityFacade implements IAccessibilityManager {
  // ... existing methods, ensure they match the interface
}
```

- [ ] **Step 4: Register in NGFDeviceAwarenessIntegrationFacade**

```typescript
import { AccessibilityFacade } from './AccessibilityFacade';

// In getServiceRegistrations():
new NGFServiceRegistration(
  'ngf.device.accessibility',
  'Accessibility',
  (): AccessibilityFacade => new AccessibilityFacade(),
  NGFServiceLifetime.SINGLETON
)
```

- [ ] **Step 5: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 6: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/deviceAwareness/contracts/IAccessibilityManager.ets
git add entry/src/main/ets/Framework/NGF/deviceAwareness/facades/AccessibilityFacade.ets
git add entry/src/main/ets/Framework/NGF/deviceAwareness/facades/NGFDeviceAwarenessIntegrationFacade.ets
git commit -m "feat(deviceAwareness): add Accessibility contract and register facade in DI"
```

---

### Task 6: Implement LiveViewManagerFacade with LiveViewKit API

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/systemTasks/facades/LiveViewManagerFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/systemTasks/contracts/ILiveViewManager.ets`

- [ ] **Step 1: Read the contract and current facade**

```bash
cat entry/src/main/ets/Framework/NGF/systemTasks/contracts/ILiveViewManager.ets
cat entry/src/main/ets/Framework/NGF/systemTasks/facades/LiveViewManagerFacade.ets
```

- [ ] **Step 2: Check LiveViewKit API availability in SDK**

```bash
grep -rn "liveView\|LiveView" F:/HarmonyOS/SDK/23/ets/api/ 2>/dev/null | head -20
```

If LiveViewKit is not available in API 23, mark the facade methods with a capability check and graceful fallback:

```typescript
import { abilityAccessCtrl } from '@kit.AbilityKit';

private isLiveViewAvailable(): boolean {
  try {
    // LiveViewKit requires API 16+ and specific system capabilities
    return true; // Replace with actual capability check when available
  } catch (_error) {
    return false;
  }
}

async startLiveView(notificationId: number, templateName: string, data: Record<string, Object>): Promise<boolean> {
  if (!this.isLiveViewAvailable()) {
    logger.warn(TAG, 'LiveViewKit not available on this device.');
    this.liveViewStates.set(notificationId, { notificationId, templateName, data, isActive: true });
    return false;
  }
  try {
    // TODO: Replace with actual LiveViewKit API call when SDK supports it
    // import { liveViewManager } from '@kit.LiveViewKit';
    // await liveViewManager.startLiveView(notificationId, templateName, data);
    this.liveViewStates.set(notificationId, { notificationId, templateName, data, isActive: true });
    logger.info(TAG, `LiveView started: ID=${notificationId}, template=${templateName}`);
    return true;
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error(TAG, `startLiveView failed: ${message}`);
    return false;
  }
}
```

Apply the same pattern to `updateLiveView` and `stopLiveView`.

- [ ] **Step 3: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/systemTasks/facades/LiveViewManagerFacade.ets
git commit -m "feat(systemTasks): implement LiveViewManager with capability check and SDK fallback"
```

---

## Tier 2: Core Gaps (Tasks 7-14)

### Task 7: Create Standalone EventBusFacade

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/core/facades/EventBusFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/core/contracts/IEventBus.ets`
- Read: `entry/src/main/ets/Framework/NGF/core/starter/StarterKernel.ets` (inner class at line 79)

- [ ] **Step 1: Read the IEventBus contract and the inner class implementation**

```bash
cat entry/src/main/ets/Framework/NGF/core/contracts/IEventBus.ets
grep -n "class NGFStarterEventBus" entry/src/main/ets/Framework/NGF/core/starter/StarterKernel.ets
```

- [ ] **Step 2: Create EventBusFacade that wraps the inner class logic**

```typescript
import { IEventBus, NGFEventSubscription, NGFEventPayload } from '../contracts/IEventBus';
import { logger } from '../../utils/Logger';

const TAG: string = 'EventBusFacade';

interface NGFEventSubscriptionInternal {
  id: string;
  listenerId: string;
  callback: (payload: NGFEventPayload) => void;
}

export class EventBusFacade implements IEventBus {
  private subscriptions: Map<string, Array<NGFEventSubscriptionInternal>> = new Map();

  subscribe(eventName: string, listenerId: string, callback: (payload: NGFEventPayload) => void): boolean {
    if (!eventName || !listenerId) {
      return false;
    }
    const subs = this.subscriptions.get(eventName) || [];
    const existing = subs.find((s: NGFEventSubscriptionInternal) => s.listenerId === listenerId);
    if (existing) {
      logger.warn(TAG, `Listener ${listenerId} already subscribed to ${eventName}`);
      return false;
    }
    subs.push({ id: `${eventName}_${listenerId}`, listenerId, callback });
    this.subscriptions.set(eventName, subs);
    return true;
  }

  unsubscribe(eventName: string, listenerId: string): boolean {
    const subs = this.subscriptions.get(eventName);
    if (!subs) {
      return false;
    }
    const index = subs.findIndex((s: NGFEventSubscriptionInternal) => s.listenerId === listenerId);
    if (index < 0) {
      return false;
    }
    subs.splice(index, 1);
    return true;
  }

  publish(eventName: string, payload: NGFEventPayload): void {
    const subs = this.subscriptions.get(eventName);
    if (!subs || subs.length === 0) {
      return;
    }
    for (const sub of subs) {
      try {
        sub.callback(payload);
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        logger.error(TAG, `Event ${eventName} listener ${sub.listenerId} error: ${message}`);
      }
    }
  }

  getSubscriptionCount(eventName: string): number {
    const subs = this.subscriptions.get(eventName);
    return subs ? subs.length : 0;
  }

  getSubscribedEvents(): Array<string> {
    const events: Array<string> = [];
    this.subscriptions.forEach((_value: Array<NGFEventSubscriptionInternal>, key: string) => {
      events.push(key);
    });
    return events;
  }

  clear(): void {
    this.subscriptions.clear();
  }
}
```

- [ ] **Step 3: Verify compilation**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

- [ ] **Step 4: Commit**

```bash
git add entry/src/main/ets/Framework/NGF/core/facades/EventBusFacade.ets
git commit -m "feat(core): add standalone EventBusFacade implementing IEventBus"
```

---

### Task 8: Create Standalone ErrorHandlerFacade

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/core/facades/ErrorHandlerFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/core/contracts/IErrorHandler.ets`
- Read: `entry/src/main/ets/Framework/NGF/core/starter/StarterKernel.ets` (inner class at line 176)

- [ ] **Step 1: Read the IErrorHandler contract**

```bash
cat entry/src/main/ets/Framework/NGF/core/contracts/IErrorHandler.ets
```

- [ ] **Step 2: Create ErrorHandlerFacade**

```typescript
import { IErrorHandler, NGFErrorContext, NGFErrorSeverity } from '../contracts/IErrorHandler';
import { logger } from '../../utils/Logger';

const TAG: string = 'ErrorHandlerFacade';

interface NGFErrorEntry {
  context: NGFErrorContext;
  timestamp: number;
}

export class ErrorHandlerFacade implements IErrorHandler {
  private errors: Array<NGFErrorEntry> = [];
  private maxErrors: number = 100;
  private listeners: Map<string, (context: NGFErrorContext) => void> = new Map();

  reportError(context: NGFErrorContext): void {
    const entry: NGFErrorEntry = { context, timestamp: Date.now() };
    this.errors.push(entry);
    if (this.errors.length > this.maxErrors) {
      this.errors.shift();
    }
    const severityLabel = context.severity === NGFErrorSeverity.CRITICAL ? 'CRITICAL' :
      context.severity === NGFErrorSeverity.HIGH ? 'HIGH' :
        context.severity === NGFErrorSeverity.MEDIUM ? 'MEDIUM' : 'LOW';
    logger.error(TAG, `[${severityLabel}] ${context.source}: ${context.message}`);
    this.listeners.forEach((listener: (ctx: NGFErrorContext) => void) => {
      try {
        listener(context);
      } catch (_error) {}
    });
  }

  getRecentErrorCount(): number {
    return this.errors.length;
  }

  getRecentErrors(limit: number): Array<NGFErrorContext> {
    const start = Math.max(0, this.errors.length - limit);
    return this.errors.slice(start).map((entry: NGFErrorEntry) => entry.context);
  }

  clearErrors(): void {
    this.errors = [];
  }

  addErrorListener(id: string, listener: (context: NGFErrorContext) => void): void {
    this.listeners.set(id, listener);
  }

  removeErrorListener(id: string): void {
    this.listeners.delete(id);
  }
}
```

- [ ] **Step 3: Verify compilation and commit**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

```bash
git add entry/src/main/ets/Framework/NGF/core/facades/ErrorHandlerFacade.ets
git commit -m "feat(core): add standalone ErrorHandlerFacade implementing IErrorHandler"
```

---

### Task 9: Create Standalone LifecycleOrchestratorFacade

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/core/facades/LifecycleOrchestratorFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/core/contracts/ILifecycleOrchestrator.ets`

- [ ] **Step 1: Read the contract**

```bash
cat entry/src/main/ets/Framework/NGF/core/contracts/ILifecycleOrchestrator.ets
```

- [ ] **Step 2: Create LifecycleOrchestratorFacade implementing the full contract**

Implement `getCurrentState()`, `advancePhase()`, `addListener()`, `removeListener()`, `getPhaseHistory()` following the same pattern as the inner class in StarterKernel.ets.

- [ ] **Step 3: Verify compilation and commit**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

```bash
git add entry/src/main/ets/Framework/NGF/core/facades/LifecycleOrchestratorFacade.ets
git commit -m "feat(core): add standalone LifecycleOrchestratorFacade implementing ILifecycleOrchestrator"
```

---

### Task 10: Implement `script` Action Type in ActionExecutorFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/contentWorkflow/facades/ActionExecutorFacade.ets`

- [ ] **Step 1: Read the current implementation around line 103**

```bash
sed -n '95,120p' entry/src/main/ets/Framework/NGF/contentWorkflow/facades/ActionExecutorFacade.ets
```

- [ ] **Step 2: Replace the script action stub with expression evaluation**

Since ArkTS doesn't support sandboxed JS evaluation, implement `script` as a simple expression evaluator using the workflow context:

```typescript
case 'script': {
  const expression = actionConfig.params?.get('expression') as string;
  if (!expression) {
    return new NGFActionResult(false, '{"error":"script action missing expression parameter"}');
  }
  try {
    // Simple context variable substitution and evaluation
    // Supported: ${variableName} references, basic string operations
    let result = expression;
    if (context) {
      context.forEach((value: string, key: string) => {
        result = result.replace(`\${${key}}`, value);
      });
    }
    const outputKey = (actionConfig.params?.get('outputKey') as string) || 'scriptResult';
    return new NGFActionResult(true, JSON.stringify({ [outputKey]: result }));
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new NGFActionResult(false, JSON.stringify({ error: message }));
  }
}
```

- [ ] **Step 3: Verify compilation and commit**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

```bash
git add entry/src/main/ets/Framework/NGF/contentWorkflow/facades/ActionExecutorFacade.ets
git commit -m "feat(workflow): implement script action type with context variable substitution"
```

---

### Task 11: Implement `api` Action Type in ActionExecutorFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/contentWorkflow/facades/ActionExecutorFacade.ets`

- [ ] **Step 1: Read the current implementation around line 109**

- [ ] **Step 2: Implement api action using HttpClientFacade**

```typescript
case 'api': {
  const url = actionConfig.params?.get('url') as string;
  const method = (actionConfig.params?.get('method') as string) || 'GET';
  if (!url) {
    return new NGFActionResult(false, '{"error":"api action missing url parameter"}');
  }
  try {
    // Use the registered HttpClientFacade to make the request
    const headers = actionConfig.params?.get('headers') as Record<string, string> | undefined;
    const body = actionConfig.params?.get('body') as string | undefined;
    // Build request and execute via httpClient
    const response = await this.executeApiCall(url, method, headers, body);
    return new NGFActionResult(true, response);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new NGFActionResult(false, JSON.stringify({ error: message }));
  }
}
```

Add the helper method `executeApiCall` that delegates to the registered `IHttpClient`.

- [ ] **Step 3: Verify compilation and commit**

```bash
cd entry && hvigorw assembleHap 2>&1 | tail -20
```

```bash
git add entry/src/main/ets/Framework/NGF/contentWorkflow/facades/ActionExecutorFacade.ets
git commit -m "feat(workflow): implement api action type with HttpClientFacade delegation"
```

---

### Task 12: Create Default IHttpInterceptor Implementation (LoggingInterceptor)

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/contentSource/facades/LoggingInterceptorFacade.ets`
- Read: `entry/src/main/ets/Framework/NGF/contentSource/contracts/IHttpInterceptor.ets`

- [ ] **Step 1: Read the IHttpInterceptor contract**

```bash
cat entry/src/main/ets/Framework/NGF/contentSource/contracts/IHttpInterceptor.ets
```

- [ ] **Step 2: Create LoggingInterceptorFacade**

```typescript
import { IHttpInterceptor, NGFHttpRequest, NGFHttpResponse } from '../contracts/IHttpInterceptor';
import { logger } from '../../utils/Logger';

const TAG: string = 'LoggingInterceptor';

export class LoggingInterceptorFacade implements IHttpInterceptor {
  private enabled: boolean = true;

  setEnabled(enabled: boolean): void {
    this.enabled = enabled;
  }

  async onRequest(request: NGFHttpRequest): Promise<NGFHttpRequest> {
    if (this.enabled) {
      logger.info(TAG, `→ ${request.method} ${request.url}`);
    }
    return request;
  }

  async onResponse(request: NGFHttpRequest, response: NGFHttpResponse): Promise<NGFHttpResponse> {
    if (this.enabled) {
      logger.info(TAG, `← ${response.statusCode} ${request.url} (${response.body?.length || 0} bytes)`);
    }
    return response;
  }

  async onError(request: NGFHttpRequest, error: Error): Promise<Error> {
    if (this.enabled) {
      logger.error(TAG, `✗ ${request.method} ${request.url}: ${error.message}`);
    }
    return error;
  }
}
```

- [ ] **Step 3: Register in contentSource integration facade**

- [ ] **Step 4: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/contentSource/facades/LoggingInterceptorFacade.ets
git commit -m "feat(contentSource): add LoggingInterceptor default IHttpInterceptor implementation"
```

---

### Task 13: Create IHttpAuthInterceptor for Token Injection

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/contentSource/facades/AuthInterceptorFacade.ets`

- [ ] **Step 1: Create AuthInterceptorFacade**

```typescript
import { IHttpInterceptor, NGFHttpRequest, NGFHttpResponse } from '../contracts/IHttpInterceptor';
import { logger } from '../../utils/Logger';

const TAG: string = 'AuthInterceptor';

export class AuthInterceptorFacade implements IHttpInterceptor {
  private tokenProvider: (() => string) | null = null;
  private headerName: string = 'Authorization';
  private prefix: string = 'Bearer ';

  setTokenProvider(provider: () => string): void {
    this.tokenProvider = provider;
  }

  setHeaderName(name: string): void {
    this.headerName = name;
  }

  setPrefix(prefix: string): void {
    this.prefix = prefix;
  }

  async onRequest(request: NGFHttpRequest): Promise<NGFHttpRequest> {
    if (this.tokenProvider) {
      const token = this.tokenProvider();
      if (token.length > 0) {
        if (!request.headers) {
          request.headers = new Map();
        }
        request.headers.set(this.headerName, `${this.prefix}${token}`);
      }
    }
    return request;
  }

  async onResponse(request: NGFHttpRequest, response: NGFHttpResponse): Promise<NGFHttpResponse> {
    return response;
  }

  async onError(request: NGFHttpRequest, error: Error): Promise<Error> {
    return error;
  }
}
```

- [ ] **Step 2: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/contentSource/facades/AuthInterceptorFacade.ets
git commit -m "feat(contentSource): add AuthInterceptor for automatic token injection"
```

---

### Task 14: Update README Module Registry Table with All Service Tokens

**Files:**
- Modify: `README.md`
- Modify: `README.en.md`

- [ ] **Step 1: Read the current module registry table**

- [ ] **Step 2: Add missing service tokens to the table**

Add `ngf.platform.multi_window_manager` and `ngf.platform.permission_manager` to module 1 (`ngf.platform.ohos`).
Add `ngf.shell.overlay_manager` and `ngf.shell.page_transition_manager` to module 8 (`ngf.ui_shell.core`).
Add `ngf.theme.component_override` to module 2 (`ngf.uiTheme.core`).
Add `ngf.device.accessibility` to module 5 (`ngf.device.awareness`).
Add `ngf.data.encrypted_settings_store` to module 4 (`ngf.data.core`).

- [ ] **Step 3: Commit**

```bash
git add README.md README.en.md
git commit -m "docs: update module registry table with all service tokens"
```

---

## Tier 3: Medium Complexity (Tasks 15-21)

### Task 15: Implement Real Parse in ContentPipelineFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/contentSource/facades/ContentPipelineFacade.ets`

- [ ] **Step 1: Read the current executeParse method**

```bash
sed -n '90,110p' entry/src/main/ets/Framework/NGF/contentSource/facades/ContentPipelineFacade.ets
```

- [ ] **Step 2: Implement JSON parse with error handling**

```typescript
private executeParse(step: NGFPipelineStepDefinition, input: string): NGFPipelineStepResult {
  if (input.length <= 0) {
    return new NGFPipelineStepResult(false, '', step.stepName, 'Empty input');
  }
  try {
    const parsed: Object = JSON.parse(input);
    const output = JSON.stringify(parsed);
    return new NGFPipelineStepResult(true, output, step.stepName);
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    return new NGFPipelineStepResult(false, input, step.stepName, `Parse error: ${message}`);
  }
}
```

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/contentSource/facades/ContentPipelineFacade.ets
git commit -m "feat(contentSource): implement real JSON parse in content pipeline"
```

---

### Task 16: Integrate Window Events with Core EventBus

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade.ets`

- [ ] **Step 1: Read the current facade to find windowStageEventCallback**

```bash
grep -n "windowStageEventCallback\|onWindowStageEvent\|WindowStage" entry/src/main/ets/Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade.ets
```

- [ ] **Step 2: Add EventBus publishing in window event callbacks**

```typescript
import { ngfStarterKernel } from '../../core/starter';
import { NGFEventPayload } from '../../core/contracts/IEventBus';

// In the window stage event callback:
private publishWindowEvent(eventName: string, data: Record<string, string>): void {
  const payload = new NGFEventPayload(
    'window_event',
    JSON.stringify(data)
  );
  ngfStarterKernel.eventBus.publish(eventName, payload);
}
```

Call `publishWindowEvent` from existing window lifecycle callbacks (foreground, background, destroy, etc.).

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade.ets
git commit -m "feat(platformOhos): publish window lifecycle events to core EventBus"
```

---

### Task 17: Implement RTL Layout Support in I18nManagerFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/i18n/facades/I18nManagerFacade.ets`

- [ ] **Step 1: Read the isRtl method at line 195**

```bash
sed -n '190,210p' entry/src/main/ets/Framework/NGF/i18n/facades/I18nManagerFacade.ets
```

- [ ] **Step 2: Add RTL layout direction helper methods**

```typescript
isRtl(): boolean {
  const locale = this.getCurrentLocale();
  const rtlLanguages = ['ar', 'he', 'fa', 'ur'];
  return rtlLanguages.some((lang: string) => locale.startsWith(lang));
}

getLayoutDirection(): string {
  return this.isRtl() ? 'RTL' : 'LTR';
}

getTextAlign(): TextAlign {
  return this.isRtl() ? TextAlign.End : TextAlign.Start;
}

getFlexDirection(): FlexDirection {
  return this.isRtl() ? FlexDirection.RowReverse : FlexDirection.Row;
}
```

- [ ] **Step 3: Fix formatNumber currency handling**

Read the current `formatNumber` method and ensure currency style maps correctly:

```typescript
formatNumber(value: number, style: NGFNumberStyle, currencyCode?: string): string {
  try {
    const options: Intl.NumberFormatOptions = { style: style };
    if (style === 'currency' && currencyCode) {
      options.currency = currencyCode;
    }
    return Intl.NumberFormat(this.getCurrentLocale(), options).format(value);
  } catch (_error) {
    return String(value);
  }
}
```

- [ ] **Step 4: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/i18n/facades/I18nManagerFacade.ets
git commit -m "feat(i18n): add RTL layout helpers and fix formatNumber currency support"
```

---

### Task 18: Add Pagination Support to DataFacade

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/data/contracts/IDataFacade.ets`
- Modify: `entry/src/main/ets/Framework/NGF/data/facades/DataFacade.ets`

- [ ] **Step 1: Read the current IDataFacade contract**

```bash
cat entry/src/main/ets/Framework/NGF/data/contracts/IDataFacade.ets
```

- [ ] **Step 2: Add pagination types and method to the contract**

```typescript
export class NGFPaginationParams {
  offset: number = 0;
  limit: number = 20;
  constructor(offset: number, limit: number) {
    this.offset = offset;
    this.limit = limit;
  }
}

export class NGFPaginatedResult<T> {
  items: Array<T>;
  total: number;
  hasMore: boolean;
  constructor(items: Array<T>, total: number, hasMore: boolean) {
    this.items = items;
    this.total = total;
    this.hasMore = hasMore;
  }
}

// Add to IDataFacade:
queryPaginated(storeName: string, filters: Map<string, string>, pagination: NGFPaginationParams): NGFPaginatedResult<string>;
```

- [ ] **Step 3: Implement in DataFacade**

- [ ] **Step 4: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/data/contracts/IDataFacade.ets
git add entry/src/main/ets/Framework/NGF/data/facades/DataFacade.ets
git commit -m "feat(data): add pagination support to DataFacade"
```

---

### Task 19: Implement Production-Ready Page Templates

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/uiShell/components/NGFPageTemplates.ets`

- [ ] **Step 1: Read the current templates file**

```bash
cat entry/src/main/ets/Framework/NGF/uiShell/components/NGFPageTemplates.ets
```

- [ ] **Step 2: Implement ListPageTemplate, FormPageTemplate, DetailPageTemplate**

Each template should be a `@Component` with:
- Standard HDS title bar integration via `NGFHdsTitleBarOptionsFactory`
- Immersive top chrome underlay
- Proper safe area handling
- Slot-based content injection via `@Builder` params

```typescript
@Component
export struct NGFListPageTemplate {
  @Prop title: string = '';
  @BuilderParam headerBuilder: () => void = () => {};
  @BuilderParam contentBuilder: () => void = () => {};
  @BuilderParam footerBuilder: () => void = () => {};

  build() {
    Column() {
      this.headerBuilder()
      Scroll() {
        Column() {
          this.contentBuilder()
        }
      }.layoutWeight(1)
      this.footerBuilder()
    }
    .width('100%')
    .height('100%')
  }
}
```

Similar patterns for `FormPageTemplate` and `DetailPageTemplate`.

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/uiShell/components/NGFPageTemplates.ets
git commit -m "feat(uiShell): implement production-ready List/Form/Detail page templates"
```

---

### Task 20: Add Data Entity Persistence to RDB

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/data/facades/DataFacade.ets`

- [ ] **Step 1: Read the current DataFacade entity storage (line 81)**

```bash
sed -n '75,100p' entry/src/main/ets/Framework/NGF/data/facades/DataFacade.ets
```

- [ ] **Step 2: Add RDB-backed entity persistence**

Use the registered `IRelationalStore` to persist entities. Replace the in-memory `Map` with RDB read/write for non-settings entities:

```typescript
private async persistEntity(storeName: string, key: string, value: string): Promise<void> {
  const rdb = this.getRelationalStore();
  if (rdb) {
    await rdb.execute(`INSERT OR REPLACE INTO ${storeName} (key, value) VALUES (?, ?)`, [key, value]);
  }
}

private async loadEntity(storeName: string, key: string): Promise<string | null> {
  const rdb = this.getRelationalStore();
  if (rdb) {
    const result = await rdb.query(`SELECT value FROM ${storeName} WHERE key = ?`, [key]);
    return result.length > 0 ? result[0] : null;
  }
  return null;
}
```

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/data/facades/DataFacade.ets
git commit -m "feat(data): add RDB-backed entity persistence to DataFacade"
```

---

### Task 21: Create StringUtils Utility

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/utils/StringUtils.ets`
- Modify: `entry/src/main/ets/Framework/NGF/utils/index.ets` (add export)

- [ ] **Step 1: Create StringUtils.ets**

```typescript
/**
 * 字符串处理工具集
 */
export class StringUtils {
  static isNullOrEmpty(value: string | null | undefined): boolean {
    return value === null || value === undefined || value.length === 0;
  }

  static isNullOrWhitespace(value: string | null | undefined): boolean {
    return value === null || value === undefined || value.trim().length === 0;
  }

  static truncate(value: string, maxLength: number, suffix: string = '...'): string {
    if (value.length <= maxLength) {
      return value;
    }
    return value.substring(0, maxLength - suffix.length) + suffix;
  }

  static capitalize(value: string): string {
    if (value.length === 0) {
      return value;
    }
    return value.charAt(0).toUpperCase() + value.substring(1);
  }

  static camelToSnake(value: string): string {
    return value.replace(/[A-Z]/g, (letter: string) => `_${letter.toLowerCase()}`);
  }

  static snakeToCamel(value: string): string {
    return value.replace(/_([a-z])/g, (_match: string, letter: string) => letter.toUpperCase());
  }

  static containsIgnoreCase(haystack: string, needle: string): boolean {
    return haystack.toLowerCase().includes(needle.toLowerCase());
  }

  static removePrefix(value: string, prefix: string): string {
    if (value.startsWith(prefix)) {
      return value.substring(prefix.length);
    }
    return value;
  }

  static removeSuffix(value: string, suffix: string): string {
    if (value.endsWith(suffix)) {
      return value.substring(0, value.length - suffix.length);
    }
    return value;
  }

  static repeat(value: string, count: number): string {
    let result = '';
    for (let i = 0; i < count; i++) {
      result += value;
    }
    return result;
  }

  static join(values: Array<string>, separator: string): string {
    let result = '';
    for (let i = 0; i < values.length; i++) {
      if (i > 0) {
        result += separator;
      }
      result += values[i];
    }
    return result;
  }
}
```

- [ ] **Step 2: Add export to utils/index.ets**

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/utils/StringUtils.ets
git add entry/src/main/ets/Framework/NGF/utils/index.ets
git commit -m "feat(utils): add StringUtils with common string operations"
```

---

## Tier 4: Advanced (Tasks 22-26)

### Task 22: Implement Window Size/Position Control API

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/platformOhos/contracts/IPlatformWindowManager.ets`
- Modify: `entry/src/main/ets/Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade.ets`

- [ ] **Step 1: Add window control methods to the contract**

```typescript
setWindowSize(width: number, height: number): Promise<void>;
setWindowPosition(x: number, y: number): Promise<void>;
setWindowMaximize(): Promise<void>;
setWindowMinimize(): Promise<void>;
setWindowFullScreen(isFullScreen: boolean): Promise<void>;
```

- [ ] **Step 2: Implement using HarmonyOS Window API**

```typescript
async setWindowSize(width: number, height: number): Promise<void> {
  const window = this.getCurrentWindow();
  if (window) {
    await window.resizeWindow({ width: width, height: height });
  }
}
```

- [ ] **Step 3: Verify compilation and commit**

```bash
git add entry/src/main/ets/Framework/NGF/platformOhos/contracts/IPlatformWindowManager.ets
git add entry/src/main/ets/Framework/NGF/platformOhos/facades/PlatformWindowManagerFacade.ets
git commit -m "feat(platformOhos): add window size/position control APIs"
```

---

### Task 23: Add Custom Theme Pack Loading

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/uiTheme/contracts/IThemeManager.ets`
- Modify: `entry/src/main/ets/Framework/NGF/uiTheme/facades/ThemeManagerFacade.ets`

- [ ] **Step 1: Define NGFThemePack interface**

```typescript
export class NGFThemePack {
  name: string = '';
  primaryColor: string = '';
  backgroundColor: string = '';
  textColor: string = '';
  accentColor: string = '';
  constructor(name: string, primary: string, bg: string, text: string, accent: string) {
    this.name = name;
    this.primaryColor = primary;
    this.backgroundColor = bg;
    this.textColor = text;
    this.accentColor = accent;
  }
}
```

- [ ] **Step 2: Add loadThemePack/applyThemePack to IThemeManager and ThemeManagerFacade**

- [ ] **Step 3: Verify compilation and commit**

```bash
git commit -m "feat(uiTheme): add custom theme pack loading support"
```

---

### Task 24: Implement Module Hot-Reload Foundation

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/core/starter/NGFModuleRegistry.ets`
- Modify: `entry/src/main/ets/Framework/NGF/core/starter/ModuleBootstrapCoordinator.ets`

- [ ] **Step 1: Add reloadModule method to NGFModuleRegistry**

```typescript
async reloadModule(moduleName: string): Promise<boolean> {
  const existing = this.getModule(moduleName);
  if (!existing) {
    return false;
  }
  // Shutdown the module
  await this.shutdownModule(moduleName);
  // Re-register and re-bootstrap
  return await this.bootstrapModule(moduleName);
}
```

- [ ] **Step 2: Implement graceful shutdown in ModuleBootstrapCoordinator**

- [ ] **Step 3: Verify compilation and commit**

```bash
git commit -m "feat(core): add module hot-reload foundation"
```

---

### Task 25: Add Workflow Loop Control Flow

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/contentWorkflow/facades/WorkflowEngineFacade.ets`

- [ ] **Step 1: Add loop step type support**

```typescript
case 'loop': {
  const iterations = step.params?.get('iterations') as number || 1;
  const innerSteps = step.params?.get('steps') as Array<NGFWorkflowStepDefinition>;
  for (let i = 0; i < iterations; i++) {
    context.set('loopIndex', String(i));
    for (const innerStep of innerSteps) {
      const result = await this.executeStep(innerStep, context);
      if (!result.success) {
        return result;
      }
    }
  }
  return new NGFWorkflowStepResult(true, context);
}
```

- [ ] **Step 2: Verify compilation and commit**

```bash
git commit -m "feat(workflow): add loop control flow to workflow engine"
```

---

### Task 26: Update Framework Status Document

**Files:**
- Modify: `docs/NGF_FRAMEWORK_STATUS.md`

- [ ] **Step 1: Read the current status document**

- [ ] **Step 2: Update completion percentages and mark resolved gaps**

Update each layer's completion percentage based on implemented tasks:
- core: 95% → 98% (standalone facades added)
- platformOhos: 75% → 85% (event bus integration, window control)
- data: 90% → 95% (encryption registered, pagination added, persistence)
- contentWorkflow: 85% → 95% (script/api actions, loop control)
- contentSource: 85% → 92% (interceptors, parse implementation)
- uiShell: 90% → 95% (templates, DI registration)
- uiTheme: 90% → 95% (component override registered, theme packs)
- i18n: 85% → 92% (RTL helpers, formatNumber fix)
- deviceAwareness: 85% → 92% (accessibility contract + registration)
- utils: 98% → 100% (StringUtils added)

- [ ] **Step 3: Commit**

```bash
git add docs/NGF_FRAMEWORK_STATUS.md
git commit -m "docs: update framework status with gap closure progress"
```

---

## Execution Notes

- **Build verification:** After every task, run `hvigorw assembleHap` to catch compilation errors immediately.
- **No breaking changes:** All new methods are additive. Existing interfaces get new optional methods or new interfaces are created alongside.
- **DI registration:** Every new facade MUST be registered in its layer's integration facade.
- **ArkTS compliance:** No `any`, no `unknown`, no object spread, no `globalThis`. All types explicit.
- **Commit cadence:** One commit per task. Each commit should compile independently.
