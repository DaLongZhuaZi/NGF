import { Permissions } from '@kit.AbilityKit';

export interface IPermissionManager {
  /**
   * Check if the application has been granted a specific permission.
   * @param permission The permission to check.
   * @returns True if granted, false otherwise.
   */
  checkPermission(permission: Permissions): boolean;

  /**
   * Request an array of permissions from the user.
   * Automatically handles UI context resolution and dialog popups.
   * @param permissions Array of permissions to request.
   * @returns A promise resolving to true if ALL permissions were granted.
   */
  requestPermissions(permissions: Permissions[]): Promise<boolean>;
}
