# NGF Framework Remaining Gaps Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Close all remaining gaps across NGF's 18 layers, fix stubs, add missing framework integration, and resolve duplicate implementations.

**Architecture:** Follow existing NGF patterns — contracts/ + facades/ + IntegrationFacade + index.ets. All code must comply with ArkTS strict mode.

**Tech Stack:** ArkTS, HarmonyOS SDK 6.1.0 (API 23), hvigorw

---

## Part 1: Critical Fixes (Tasks 1-6)

### Task 1: Fix NetworkManagerFacade removeGlobalHeader() No-Op

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/network/facades/NetworkManagerFacade.ets`

- [ ] **Step 1: Read the file and find removeGlobalHeader at line 25-28**

- [ ] **Step 2: Fix the implementation — use Map or set value to empty string instead of delete**

```typescript
removeGlobalHeader(name: string): void {
  if (this.globalHeaders.has(name)) {
    this.globalHeaders.set(name, '');
    logger.info(TAG, `Global header cleared: ${name}`);
  }
}
```

Or better, change `globalHeaders` from `Record<string, string>` to `Map<string, string>` to support proper deletion.

- [ ] **Step 3: Verify and commit**

---

### Task 2: Implement PushManagerFacade onMessageReceived()

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/push/facades/PushManagerFacade.ets`

- [ ] **Step 1: Read the file**

- [ ] **Step 2: Check HarmonyOS PushKit API availability**

```bash
grep -rn "pushKit\|PushKit\|push " F:/HarmonyOS/SDK/23/ets/api/ 2>/dev/null | head -10
```

- [ ] **Step 3: Implement using @kit.PushKit if available, or store callback for later invocation**

```typescript
private messageCallback: ((message: string) => void) | null = null;

onMessageReceived(callback: (message: string) => void): void {
  this.messageCallback = callback;
  // If PushKit available: pushManager.on('pushMessage', (msg) => callback(msg));
  logger.info(TAG, 'Message received callback registered.');
}
```

- [ ] **Step 4: Verify and commit**

---

### Task 3: Fix WidgetManagerFacade.updateWidgetsByProvider()

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/systemTasks/facades/WidgetManagerFacade.ets`

- [ ] **Step 1: Read the file and the IWidgetManager contract**

- [ ] **Step 2: Check HarmonyOS FormKit/WidgetKit API**

```bash
grep -rn "formBindingData\|FormExtension\|Widget" F:/HarmonyOS/SDK/23/ets/api/ 2>/dev/null | head -10
```

- [ ] **Step 3: Implement real widget update using formBindingData or at minimum return false and log warning**

```typescript
updateWidgetsByProvider(formIds: Array<string>): boolean {
  if (formIds.length === 0) {
    return false;
  }
  // Use @kit.FormKit formBindingData.updateForm() if available
  // If not available, log clear warning and return false
  logger.warn(TAG, 'Widget update requires FormKit API. Returning false.');
  return false;
}
```

- [ ] **Step 4: Verify and commit**

---

### Task 4: Replace Interconnect AppLinkingFacade Mock with Real Implementation

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/interconnect/facades/AppLinkingFacade.ets`

- [ ] **Step 1: Read the file**

- [ ] **Step 2: Check @kit.AppLinkingKit availability**

```bash
grep -rn "appLinking\|AppLinking" F:/HarmonyOS/SDK/23/ets/api/ 2>/dev/null | head -10
```

- [ ] **Step 3: Implement using AppLinkingKit or fallback to deep link URL construction**

If AppLinkingKit is not available, construct a proper deep link URL scheme instead of mock concatenation:

```typescript
createLink(domain: string, deepLink: string): string {
  // Use proper URL construction with domain validation
  const encodedLink = encodeURIComponent(deepLink);
  return `https://${domain}/links?dl=${encodedLink}`;
}
```

- [ ] **Step 4: Verify and commit**

---

### Task 5: Fix StarterKernel Dual-Instance Problem

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/core/starter/StarterKernel.ets`

- [ ] **Step 1: Read the file and identify the inner classes (NGFStarterEventBus at line 79, NGFStarterErrorHandler at line 176, NGFStarterLifecycleOrchestrator at line 325)**

- [ ] **Step 2: Replace inner class instantiation with the standalone facade singletons**

Import and use the standalone facades instead of creating internal duplicates:

```typescript
import { ngfEventBusFacade } from '../facades/EventBusFacade';
import { ngfErrorHandlerFacade } from '../facades/ErrorHandlerFacade';
import { ngfLifecycleOrchestratorFacade } from '../facades/LifecycleOrchestratorFacade';

// In constructor or init:
this.eventBus = ngfEventBusFacade;
this.errorHandler = ngfErrorHandlerFacade;
this.lifecycle = ngfLifecycleOrchestratorFacade;
```

- [ ] **Step 3: Remove or deprecate the inner classes**

- [ ] **Step 4: Verify and commit**

---

### Task 6: Fix EncryptedSettingsStoreFacade Hardcoded Key

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/data/facades/EncryptedSettingsStoreFacade.ets`

- [ ] **Step 1: Read the file and find the hardcoded key at line 18**

- [ ] **Step 2: Replace with Keystore-based key generation or at minimum use SecurityToolkit**

```typescript
import { securityToolkit } from '../../utils/SecurityToolkit';

// Generate or retrieve encryption key from secure storage
private async getOrCreateKey(): Promise<string> {
  const stored = await this.loadKeyFromKeystore();
  if (stored) {
    return stored;
  }
  const newKey = securityToolkit.generateRandomBase64(16);
  await this.saveKeyToKeystore(newKey);
  return newKey;
}
```

- [ ] **Step 3: Verify and commit**

---

## Part 2: Framework Integration (Tasks 7-13)

### Task 7: Create contracts/index.ets for security Layer

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/security/contracts/IKeyStoreManager.ets`
- Create: `entry/src/main/ets/Framework/NGF/security/contracts/IUserAuthentication.ets`
- Create: `entry/src/main/ets/Framework/NGF/security/contracts/index.ets`

- [ ] **Step 1: Read existing facades to understand their APIs**

```bash
cat entry/src/main/ets/Framework/NGF/security/facades/KeyStoreManagerFacade.ets
cat entry/src/main/ets/Framework/NGF/security/facades/UserAuthenticationFacade.ets
```

- [ ] **Step 2: Create contract interfaces matching facade public methods**

- [ ] **Step 3: Update facades to implement the contracts**

- [ ] **Step 4: Verify and commit**

---

### Task 8: Create contracts/index.ets for hardware Layer

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/hardware/contracts/ILocationManager.ets`
- Create: `entry/src/main/ets/Framework/NGF/hardware/contracts/ISensorManager.ets`
- Create: `entry/src/main/ets/Framework/NGF/hardware/contracts/index.ets`

- [ ] **Step 1: Read existing facades**

- [ ] **Step 2: Create contracts and update facades**

- [ ] **Step 3: Verify and commit**

---

### Task 9: Create contracts/index.ets for media Layer

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/media/contracts/IMediaPicker.ets`
- Create: `entry/src/main/ets/Framework/NGF/media/contracts/index.ets`

- [ ] **Step 1: Read MediaPickerFacade**

- [ ] **Step 2: Create contract and update facade**

- [ ] **Step 3: Verify and commit**

---

### Task 10: Create contracts/index.ets for interconnect Layer

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/interconnect/contracts/IAppLinking.ets`
- Create: `entry/src/main/ets/Framework/NGF/interconnect/contracts/index.ets`

- [ ] **Step 1: Read AppLinkingFacade**

- [ ] **Step 2: Create contract and update facade**

- [ ] **Step 3: Verify and commit**

---

### Task 11: Create contracts/index.ets for push Layer

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/push/contracts/IPushManager.ets`
- Create: `entry/src/main/ets/Framework/NGF/push/contracts/index.ets`

- [ ] **Step 1: Read PushManagerFacade**

- [ ] **Step 2: Create contract and update facade**

- [ ] **Step 3: Verify and commit**

---

### Task 12: Create index.ets for network, security, hardware, media, webBridge, interconnect, push Layers

**Files:**
- Create: `entry/src/main/ets/Framework/NGF/network/index.ets`
- Create: `entry/src/main/ets/Framework/NGF/security/index.ets`
- Create: `entry/src/main/ets/Framework/NGF/hardware/index.ets`
- Create: `entry/src/main/ets/Framework/NGF/media/index.ets`
- Create: `entry/src/main/ets/Framework/NGF/webBridge/index.ets` (if not exists)
- Create: `entry/src/main/ets/Framework/NGF/interconnect/index.ets`
- Create: `entry/src/main/ets/Framework/NGF/push/index.ets`

- [ ] **Step 1: For each layer, create index.ets that exports all facades and contracts**

Pattern:
```typescript
export { NetworkManagerFacade, ngfNetworkManager } from './facades/NetworkManagerFacade';
export { INetworkClient } from './contracts/INetworkClient';
```

- [ ] **Step 2: Verify and commit**

---

### Task 13: Remove Duplicate security/PermissionManagerFacade

**Files:**
- Delete or rename: `entry/src/main/ets/Framework/NGF/security/facades/PermissionManagerFacade.ets`

- [ ] **Step 1: Read both PermissionManagerFacade files to compare**

- [ ] **Step 2: Keep the platformOhos version (has contract), remove or rename the security version**

- [ ] **Step 3: Update any imports that reference the security version**

- [ ] **Step 4: Verify and commit**

---

## Part 3: Documentation Fixes (Tasks 14-15)

### Task 14: Update Framework Status Document

**Files:**
- Modify: `docs/NGF_FRAMEWORK_STATUS.md`

- [ ] **Step 1: Remove outdated gap entries for accessibility, multi-window, StringUtils**

- [ ] **Step 2: Add section for the 8 new layers (network, security, hardware, media, webBridge, interconnect, push, systemTasks)**

- [ ] **Step 3: Update all completion percentages to match current state**

- [ ] **Step 4: Commit**

---

### Task 15: Export CrashAnalyticsFacade from utils index

**Files:**
- Modify: `entry/src/main/ets/Framework/NGF/utils/index.ets`

- [ ] **Step 1: Read the index file**

- [ ] **Step 2: Add export for CrashAnalyticsFacade**

```typescript
export { CrashAnalyticsFacade } from './CrashAnalyticsFacade';
```

- [ ] **Step 3: Verify and commit**

---

## Execution Notes

- Tasks 1-6 are critical fixes — do these first
- Tasks 7-13 are framework integration — can be done in parallel
- Tasks 14-15 are documentation/cleanup
- Each task should compile independently
- Follow ArkTS strict mode rules throughout
