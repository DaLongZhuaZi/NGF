import { ComponentContent } from '@kit.ArkUI';

export interface IOverlayManager {
  /**
   * Add a custom component content as a global overlay dialog.
   * @param content The component content to add.
   */
  showCustomDialog(content: ComponentContent<object>): void;

  /**
   * Remove a specific custom dialog from the overlay.
   * @param content The component content to remove.
   */
  hideCustomDialog(content: ComponentContent<object>): void;

  /**
   * Show a global toast message decoupled from the component tree.
   * @param message The text message to show.
   */
  showToast(message: string): void;

  /**
   * Open a bind sheet with the given component content.
   * @param content The component content to display in the sheet.
   * @param options Optional sheet configuration options.
   */
  showSheet(content: ComponentContent<object>, options?: SheetOptions): void;

  /**
   * Close a bind sheet associated with the given component content.
   * @param content The component content of the sheet to close.
   */
  hideSheet(content: ComponentContent<object>): void;
}
