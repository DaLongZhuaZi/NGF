import { describe, beforeEach, it, expect } from '@ohos/hypium';
import {
  NGFEventPayload,
  NGFIntentTaskExecutor,
  NGFSubmitTaskIntentRequest,
  NGFTaskProgressUpdater,
  ngfSystem
} from 'ngf_framework';

export default function systemIntegrationTest() {
  describe('SystemIntegrationFacadeTest', () => {
    const executorName: string = 'unit.intent.executor';

    beforeEach(() => {
      ngfSystem.unregisterIntentTaskExecutor(executorName);
    });

    it('testIntentExecutorRegistrationLifecycle', 0, () => {
      const executor: NGFIntentTaskExecutor = async (
        taskId: string,
        updateCallback: NGFTaskProgressUpdater,
        request: NGFSubmitTaskIntentRequest
      ) => {
        updateCallback(100, 100, request.payloadJson || taskId);
      };

      expect(ngfSystem.hasIntentTaskExecutor(executorName)).assertFalse();
      expect(ngfSystem.registerIntentTaskExecutor(executorName, executor)).assertTrue();
      expect(ngfSystem.hasIntentTaskExecutor(executorName)).assertTrue();
      expect(ngfSystem.registerIntentTaskExecutor(executorName, executor)).assertFalse();
      expect(ngfSystem.unregisterIntentTaskExecutor(executorName)).assertTrue();
      expect(ngfSystem.hasIntentTaskExecutor(executorName)).assertFalse();
      expect(ngfSystem.unregisterIntentTaskExecutor(executorName)).assertFalse();
    });

    it('testUnregisteredIntentDoesNotSubmitTask', 0, () => {
      const beforeCount = ngfSystem.getAllTasks().length;
      const payload = new NGFEventPayload(
        'ngf.intent.action.SUBMIT_TASK',
        '{"executorName":"unit.intent.missing","taskName":"ShouldNotRun"}',
        Date.now()
      );

      ngfSystem.publishSystemEvent('ngf.intent.action.SUBMIT_TASK', payload);

      expect(ngfSystem.getAllTasks().length).assertEqual(beforeCount);
    });
  });
}
