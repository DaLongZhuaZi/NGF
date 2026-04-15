import { BackupExtensionAbility, BundleVersion } from '@kit.CoreFileKit';
import { logger } from '../Framework/NGF/utils/Logger';

const TAG: string = 'EntryBackupAbility';

export default class EntryBackupAbility extends BackupExtensionAbility {
  async onBackup() {
    logger.lifecycle(TAG, 'onBackup');
    await Promise.resolve();
  }

  async onRestore(bundleVersion: BundleVersion) {
    logger.lifecycle(TAG, 'onRestore', JSON.stringify(bundleVersion));
    await Promise.resolve();
  }
}
