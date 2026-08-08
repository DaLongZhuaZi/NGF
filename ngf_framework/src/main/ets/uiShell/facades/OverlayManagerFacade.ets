import { ComponentContent, ImmersiveMode, promptAction } from '@kit.ArkUI';
import uiMaterial from '@ohos.arkui.uiMaterial';
import { IOverlayManager, NGFOverlayToastOptions } from '../contracts/IOverlayManager';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../../platformOhos/UIContextManager';
import { ngfVisualEffectsFacade } from '../../deviceAwareness/facades/VisualEffectsFacade';
import { NGFMaterialSheetOptions } from '../components/NGFMaterialSurfaceTokens';

const TAG: string = 'OverlayManagerFacade';

class NGFOverlayDialogOptions implements promptAction.BaseDialogOptions {
  immersiveMode?: ImmersiveMode;
  systemMaterial?: uiMaterial.Material;

  constructor(systemMaterial: uiMaterial.Material | undefined) {
    this.immersiveMode = ImmersiveMode.EXTEND;
    if (systemMaterial !== undefined) {
      this.systemMaterial = systemMaterial;
    }
  }
}

class NGFOverlayToastRequest implements promptAction.ShowToastOptions {
  message: ResourceStr;
  duration?: number;
  showMode?: promptAction.ToastShowMode;
  systemMaterial?: uiMaterial.Material;

  constructor(
    message: ResourceStr,
    duration: number,
    showMode: promptAction.ToastShowMode | undefined,
    systemMaterial: uiMaterial.Material | undefined
  ) {
    this.message = message;
    this.duration = duration;
    if (showMode !== undefined) {
      this.showMode = showMode;
    }
    if (systemMaterial !== undefined) {
      this.systemMaterial = systemMaterial;
    }
  }
}

export class OverlayManagerFacade implements IOverlayManager {
  showCustomDialog(content: ComponentContent<object>): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'showCustomDialog failed: UIContext not found.');
      return;
    }

    try {
      const promptActionController = uiContext.getPromptAction();
      const options = new NGFOverlayDialogOptions(ngfVisualEffectsFacade.buildSystemMaterialForOverlay());
      promptActionController.openCustomDialog(content, options).catch((e: Error) => {
        logger.error(TAG, 'openCustomDialog failed with promise rejection: ' + e);
      });
      logger.info(TAG, 'showCustomDialog triggered.');
    } catch (e) {
      logger.error(TAG, 'showCustomDialog failed: ' + e);
    }
  }

  hideCustomDialog(content: ComponentContent<object>): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'hideCustomDialog failed: UIContext not found.');
      return;
    }

    try {
      const promptActionController = uiContext.getPromptAction();
      promptActionController.closeCustomDialog(content).catch((e: Error) => {
        logger.error(TAG, 'closeCustomDialog failed with promise rejection: ' + e);
      });
      logger.info(TAG, 'hideCustomDialog triggered.');
    } catch (e) {
      logger.error(TAG, 'hideCustomDialog failed: ' + e);
    }
  }

  showSheet(content: ComponentContent<object>, options?: SheetOptions): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'showSheet failed: UIContext not found.');
      return;
    }

    try {
      const effectiveOptions: SheetOptions | undefined = this.buildEffectiveSheetOptions(options);
      if (effectiveOptions !== undefined) {
        uiContext.openBindSheet(content, effectiveOptions);
      } else {
        uiContext.openBindSheet(content);
      }
      logger.info(TAG, 'showSheet triggered.');
    } catch (e) {
      logger.error(TAG, 'showSheet failed: ' + e);
    }
  }

  private buildEffectiveSheetOptions(options: SheetOptions | undefined): SheetOptions | undefined {
    const defaultMaterial: uiMaterial.Material | undefined = ngfVisualEffectsFacade.buildSystemMaterialForSheet();
    const useTransparentMaterialSurface: boolean = ngfVisualEffectsFacade.shouldUseSystemMaterialSurface();
    if (options === undefined) {
      return new NGFMaterialSheetOptions(defaultMaterial, useTransparentMaterialSurface);
    }
    const hasSystemMaterial: boolean = options.systemMaterial !== undefined || defaultMaterial !== undefined;
    if (hasSystemMaterial && useTransparentMaterialSurface) {
      options.backgroundColor = Color.Transparent;
      options.blurStyle = BlurStyle.NONE;
    } else {
      if (options.backgroundColor === undefined) {
        options.backgroundColor = $r('app.color.panel_background');
      }
      if (options.blurStyle === undefined) {
        options.blurStyle = BlurStyle.NONE;
      }
    }
    if (options.keyboardAvoidMode === undefined) {
      options.keyboardAvoidMode = SheetKeyboardAvoidMode.RESIZE_ONLY;
    }
    if (options.systemMaterial === undefined && defaultMaterial !== undefined) {
      options.systemMaterial = defaultMaterial;
    }
    return options;
  }

  hideSheet(content: ComponentContent<object>): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'hideSheet failed: UIContext not found.');
      return;
    }

    try {
      uiContext.closeBindSheet(content);
      logger.info(TAG, 'hideSheet triggered.');
    } catch (e) {
      logger.error(TAG, 'hideSheet failed: ' + e);
    }
  }

  showToast(message: ResourceStr, options?: NGFOverlayToastOptions): void {
    const uiContext = uiContextManager.getUIContext();
    if (!uiContext) {
      logger.error(TAG, 'showToast failed: UIContext not found.');
      return;
    }

    try {
      const duration: number = options && options.duration !== undefined ? options.duration : 2000;
      const showMode: promptAction.ToastShowMode | undefined = options ? options.showMode : undefined;
      const request = new NGFOverlayToastRequest(
        message,
        duration,
        showMode,
        ngfVisualEffectsFacade.buildSystemMaterialForOverlay()
      );
      uiContext.getPromptAction().openToast(request).catch((e: Error) => {
        logger.error(TAG, 'openToast failed with promise rejection: ' + e);
      });
    } catch (e) {
      logger.error(TAG, 'showToast failed: ' + e);
    }
  }
}

export const ngfOverlayManagerFacade = new OverlayManagerFacade();
