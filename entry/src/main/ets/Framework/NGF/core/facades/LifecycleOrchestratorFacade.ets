import { ILifecycleOrchestrator, NGFPhaseState } from '../contracts/ILifecycleOrchestrator';
import { logger } from '../../utils/Logger';

const LOG_TAG: string = 'LifecycleOrchestratorFacade';

export class NGFPhaseHistoryEntry {
  readonly phaseName: string;
  readonly progress: number;
  readonly isCompleted: boolean;
  readonly timestamp: number;

  constructor(phaseName: string, progress: number, isCompleted: boolean, timestamp: number) {
    this.phaseName = phaseName;
    this.progress = progress;
    this.isCompleted = isCompleted;
    this.timestamp = timestamp;
  }
}

export type NGFPhaseListener = (state: NGFPhaseState) => void;

export class LifecycleOrchestratorFacade implements ILifecycleOrchestrator {
  private currentPhase: string = 'not_started';
  private progress: number = 0;
  private completed: boolean = false;
  private readonly phaseHistory: Array<NGFPhaseHistoryEntry> = [];
  private readonly phaseListeners: Array<NGFPhaseListener> = [];
  private readonly defaultPhaseOrder: string[] = ['context_setup', 'core_services', 'ready'];

  startInitialization(): void {
    this.currentPhase = 'not_started';
    this.progress = 0;
    this.completed = false;
    this.phaseHistory.length = 0;
    logger.lifecycle(LOG_TAG, 'lifecycle initialization reset');
  }

  beginPhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, false);
    this.completed = false;
    this.pushHistory(normalized, this.progress, false);
    logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, `progress=${this.progress}`);
    this.notifyListeners();
  }

  completePhase(phaseName: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.progress = this.resolveProgress(normalized, true);
    this.pushHistory(normalized, this.progress, true);
    logger.stateChange(LOG_TAG, previousPhase, `${this.currentPhase}:completed`, `progress=${this.progress}`);
    this.notifyListeners();
  }

  failPhase(phaseName: string, reason: string): void {
    const previousPhase = this.currentPhase;
    const normalized = this.normalizePhaseName(phaseName);
    this.currentPhase = normalized;
    this.completed = false;
    this.progress = Math.max(0, this.resolveProgress(normalized, false));
    const failedPhaseName = reason.trim().length > 0 ? `${normalized}:failed` : normalized;
    this.currentPhase = failedPhaseName;
    this.pushHistory(failedPhaseName, this.progress, false);
    logger.warn(LOG_TAG, `phase failed: from=${previousPhase}, to=${this.currentPhase}, reason=${reason}`);
    this.notifyListeners();
  }

  markCompleted(): void {
    const previousPhase = this.currentPhase;
    this.currentPhase = 'completed';
    this.progress = 100;
    this.completed = true;
    this.pushHistory('completed', 100, true);
    logger.stateChange(LOG_TAG, previousPhase, this.currentPhase, 'progress=100');
    this.notifyListeners();
  }

  getCurrentState(): NGFPhaseState {
    return new NGFPhaseState(this.currentPhase, this.progress, this.completed);
  }

  isCompleted(): boolean {
    return this.completed;
  }

  advancePhase(): void {
    const currentState = this.getCurrentState();
    if (currentState.isCompleted) {
      logger.debug(LOG_TAG, 'advancePhase skipped: already completed');
      return;
    }

    const currentPhaseName = currentState.phaseName;
    const currentPhaseIndex = this.defaultPhaseOrder.indexOf(currentPhaseName);

    if (currentPhaseIndex < 0) {
      // Not a known phase in the default order; begin the first phase
      if (this.defaultPhaseOrder.length > 0) {
        this.beginPhase(this.defaultPhaseOrder[0]);
      }
      return;
    }

    // Complete the current phase first if not already completed
    if (!currentState.isCompleted) {
      this.completePhase(currentPhaseName);
    }

    // Begin the next phase if available
    const nextPhaseIndex = currentPhaseIndex + 1;
    if (nextPhaseIndex < this.defaultPhaseOrder.length) {
      this.beginPhase(this.defaultPhaseOrder[nextPhaseIndex]);
    } else {
      this.markCompleted();
    }
  }

  addListener(listener: NGFPhaseListener): void {
    for (let i = 0; i < this.phaseListeners.length; i++) {
      if (this.phaseListeners[i] === listener) {
        logger.debug(LOG_TAG, 'addListener skipped: listener already registered');
        return;
      }
    }
    this.phaseListeners.push(listener);
    logger.info(LOG_TAG, `added phase listener: total=${this.phaseListeners.length}`);
  }

  removeListener(listener: NGFPhaseListener): void {
    for (let i = 0; i < this.phaseListeners.length; i++) {
      if (this.phaseListeners[i] === listener) {
        this.phaseListeners.splice(i, 1);
        logger.info(LOG_TAG, `removed phase listener: total=${this.phaseListeners.length}`);
        return;
      }
    }
    logger.debug(LOG_TAG, 'removeListener skipped: listener not found');
  }

  getPhaseHistory(): Array<NGFPhaseHistoryEntry> {
    const copy: Array<NGFPhaseHistoryEntry> = [];
    for (let i = 0; i < this.phaseHistory.length; i++) {
      copy.push(this.phaseHistory[i]);
    }
    return copy;
  }

  private normalizePhaseName(phaseName: string): string {
    const normalized = phaseName.trim().toLowerCase();
    if (normalized.length <= 0) {
      return 'not_started';
    }
    return normalized;
  }

  private resolveProgress(phaseName: string, isPhaseCompleted: boolean): number {
    if (phaseName === 'not_started') {
      return 0;
    }
    if (phaseName === 'completed') {
      return 100;
    }

    const index = this.defaultPhaseOrder.indexOf(phaseName);
    if (index < 0) {
      return this.progress;
    }

    const totalPhases = this.defaultPhaseOrder.length;
    if (isPhaseCompleted) {
      return Math.floor(((index + 1) * 100) / totalPhases);
    }
    return Math.floor((index * 100) / totalPhases);
  }

  private pushHistory(phaseName: string, progress: number, isCompleted: boolean): void {
    const entry = new NGFPhaseHistoryEntry(phaseName, progress, isCompleted, Date.now());
    this.phaseHistory.push(entry);
  }

  private notifyListeners(): void {
    const currentState = this.getCurrentState();
    for (let i = 0; i < this.phaseListeners.length; i++) {
      try {
        this.phaseListeners[i](currentState);
      } catch (error) {
        logger.warn(LOG_TAG, `phase listener execution failed: ${errorToString(error as Object | string | number | boolean)}`);
      }
    }
  }
}

function errorToString(error: Object | string | number | boolean): string {
  if (typeof error === 'string') {
    return error;
  }
  if (typeof error === 'number' || typeof error === 'boolean') {
    return String(error);
  }
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

export const ngfLifecycleOrchestratorFacade: LifecycleOrchestratorFacade = new LifecycleOrchestratorFacade();
