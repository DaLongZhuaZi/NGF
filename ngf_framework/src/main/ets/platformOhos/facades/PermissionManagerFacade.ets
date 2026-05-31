import { abilityAccessCtrl, Permissions } from '@kit.AbilityKit';
import { IPermissionManager } from '../contracts/IPermissionManager';
import { logger } from '../../utils/Logger';
import { uiContextManager } from '../UIContextManager';

const TAG: string = 'PermissionManagerFacade';

export class PermissionManagerFacade implements IPermissionManager {
  checkPermission(permission: Permissions): boolean {
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, 'checkPermission failed: Missing AbilityContext');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const tokenID = context.applicationInfo.accessTokenId;
      const grantStatus = atManager.checkAccessTokenSync(tokenID, permission);
      return grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED;
    } catch (e) {
      logger.error(TAG, `checkPermission failed: ${e}`);
      return false;
    }
  }

  async requestPermissions(permissions: Permissions[]): Promise<boolean> {
    if (permissions.length === 0) {
      return true;
    }
    
    const context = uiContextManager.getFullAbilityContext();
    if (!context) {
      logger.error(TAG, 'requestPermissions failed: Missing AbilityContext');
      return false;
    }

    try {
      const atManager = abilityAccessCtrl.createAtManager();
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const allGranted = result.authResults.every((status: number) => status === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED);
      
      if (!allGranted) {
        logger.warn(TAG, `Permissions partially denied. Requested: ${permissions.join(',')}, Results: ${result.authResults.join(',')}`);
      } else {
        logger.info(TAG, `Permissions granted: ${permissions.join(',')}`);
      }
      return allGranted;
    } catch (e) {
      logger.error(TAG, `requestPermissions failed: ${e}`);
      return false;
    }
  }
}

export const ngfPermissionManagerFacade = new PermissionManagerFacade();
