/**
 * 页面状态快照
 */
export class NGFPageStateSnapshot {
  readonly pageName: string;
  readonly stateJson: string;
  readonly savedAt: number;

  constructor(pageName: string, stateJson: string, savedAt: number) {
    this.pageName = pageName;
    this.stateJson = stateJson;
    this.savedAt = savedAt;
  }
}

/**
 * 页面状态存储接口
 */
export interface IPageStateStore {
  savePageState(pageName: string, stateJson: string): void;
  restorePageState(pageName: string): NGFPageStateSnapshot | null;
  removePageState(pageName: string): boolean;
  listSavedPages(): Array<string>;
  clearAll(): void;
}
