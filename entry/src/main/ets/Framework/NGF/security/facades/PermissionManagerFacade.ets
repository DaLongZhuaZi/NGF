import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { logger } from '../../utils/Logger';

const TAG: string = 'PermissionManagerFacade';

export class PermissionManagerFacade {
  /**
   * 动态申请权限 (User Grant)
   * @param context UIAbilityContext
   * @param permissions 权限列表
   * @returns 是否全部授权成功
   */
  static async requestPermissions(context: common.UIAbilityContext, permissions: Array<Permissions>): Promise<boolean> {
    const atManager = abilityAccessCtrl.createAtManager();
    try {
      logger.info(TAG, `Requesting permissions: ${JSON.stringify(permissions)}`);
      const result = await atManager.requestPermissionsFromUser(context, permissions);
      const allGranted = result.authResults.every(authResult => authResult === 0);
      logger.info(TAG, `Permissions request result: ${allGranted}`);
      return allGranted;
    } catch (e) {
      logger.error(TAG, `Failed to request permissions: ${e}`);
      return false;
    }
  }
}
