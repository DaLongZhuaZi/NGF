import { describe, it, expect } from '@ohos/hypium';
import { NGFEventPayload, NGFTaskInfo, ngfSystem } from 'ngf_framework';

/**
 * SystemIntegration 本地单元测试。
 *
 * 覆盖范围说明（2026-10-05 随 NGF 无障碍/测试批次修复）：
 * - `submitTask` 会申请通知权限并启动后台常驻任务，属于设备能力，
 *   在 LocalUnit 环境下不可靠，因此不在本文件覆盖，改由 entry/src/ohosTest 的设备集成测试验证。
 * - 本文件只覆盖与设备无关的部分：任务查询语义、事件监听注册/取消配对、未知事件不产生副作用。
 *
 * 历史说明：本文件旧版测试的是已被移除的 "IntentTaskExecutor" API
 * （`registerIntentTaskExecutor` / `NGFIntentTaskExecutor` 等），
 * 该 API 已被 `submitTask(name, NGFTaskExecutor)` 取代，导致整个 hypium 套件长期无法编译。
 */
export default function systemIntegrationTest() {
  describe('SystemIntegrationFacadeTest', () => {

    it('testGetTaskReturnsNullForUnknownId', 0, () => {
      expect(ngfSystem.getTask('unit.no.such.task')).assertNull();
    });

    it('testGetAllTasksReturnsArray', 0, () => {
      const tasks: Array<NGFTaskInfo> = ngfSystem.getAllTasks();
      expect(tasks.length >= 0).assertTrue();
    });

    it('testTaskListenerRegistrationIsPaired', 0, () => {
      const listenerId: string = 'unit.listener.progress';
      // 先清理可能残留的注册，保证用例可重入
      ngfSystem.removeTaskListener('ngf.task.progress', listenerId);

      expect(ngfSystem.onTaskProgress(listenerId, (info: NGFTaskInfo) => {})).assertTrue();
      // 同一 listenerId 重复注册必须被拒绝，否则会重复回调
      expect(ngfSystem.onTaskProgress(listenerId, (info: NGFTaskInfo) => {})).assertFalse();
      expect(ngfSystem.removeTaskListener('ngf.task.progress', listenerId)).assertTrue();
      // 取消一个不存在的监听必须返回 false，避免"取消失败"被误判为成功
      expect(ngfSystem.removeTaskListener('ngf.task.progress', listenerId)).assertFalse();
    });

    it('testTaskEventChannelsAreIndependent', 0, () => {
      const listenerId: string = 'unit.listener.completed';
      ngfSystem.removeTaskListener('ngf.task.completed', listenerId);
      expect(ngfSystem.onTaskCompleted(listenerId, (info: NGFTaskInfo) => {})).assertTrue();
      expect(ngfSystem.removeTaskListener('ngf.task.completed', listenerId)).assertTrue();

      const failedId: string = 'unit.listener.failed';
      ngfSystem.removeTaskListener('ngf.task.failed', failedId);
      expect(ngfSystem.onTaskFailed(failedId, (info: NGFTaskInfo) => {})).assertTrue();
      expect(ngfSystem.removeTaskListener('ngf.task.failed', failedId)).assertTrue();
    });

    it('testUnknownSystemEventDoesNotCreateTask', 0, () => {
      const before: number = ngfSystem.getAllTasks().length;
      const payload = new NGFEventPayload('ngf.unit.unknown.event', '{"name":"ShouldNotRun"}', Date.now());
      ngfSystem.publishSystemEvent('ngf.unit.unknown.event', payload);
      expect(ngfSystem.getAllTasks().length).assertEqual(before);
    });

    it('testSubscribeRejectsEmptyListenerId', 0, () => {
      // 空 listenerId 必须被拒绝：否则会注册出一个无法用 listenerId 取消的监听，
      // 与无障碍监听必须 on/off 配对的原则一致。
      const accepted: boolean = ngfSystem.subscribeSystemEvent('ngf.unit.event', '',
        (payload: NGFEventPayload) => {});
      expect(accepted).assertFalse();
    });
  });
}
