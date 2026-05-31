export interface INGFMigrationStep {
  readonly targetVersion: number;
  readonly description: string;
  execute(): Promise<boolean>;
}

export interface IDbMigrator {
  currentVersion(): number;
  targetVersion(): number;
  migrate(): Promise<boolean>;
  rollback(toVersion: number): Promise<boolean>;
  registerStep(step: INGFMigrationStep): void;
}
