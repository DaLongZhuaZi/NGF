import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ngfWorkflowDefinitionFacade } from '../../src/main/ets/Framework/NGF/contentWorkflow/facades/WorkflowDefinitionFacade';
import { 
  NGFWorkflowDefinition, 
  NGFWorkflowStepDefinition, 
  NGFWorkflowParallelGroup 
} from '../../src/main/ets/Framework/NGF/contentWorkflow/contracts/IWorkflowDefinition';

export default function workflowDefinitionTest() {
  describe('WorkflowDefinitionFacadeTest', () => {

    beforeEach(() => {
      // Unregister any existing test workflows to ensure clean state
      ngfWorkflowDefinitionFacade.unregisterWorkflow('test_workflow');
      ngfWorkflowDefinitionFacade.unregisterWorkflow('parallel_workflow');
      ngfWorkflowDefinitionFacade.unregisterWorkflow('timeout_workflow');
    });

    it('testSerialExecution', 0, async () => {
      const step1 = new NGFWorkflowStepDefinition('step1', 'script', '{"data":"hello"}', null, null);
      const step2 = new NGFWorkflowStepDefinition('step2', 'script', '{"data":"world"}', null, null);
      const definition = new NGFWorkflowDefinition('test_workflow', [step1, step2], []);
      
      ngfWorkflowDefinitionFacade.registerWorkflow(definition);
      
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow('test_workflow', '{}');
      
      expect(result.success).assertTrue();
      expect(result.stepResults.length).assertEqual(2);
      expect(result.stepResults[0].stepName).assertEqual('step1');
      expect(result.stepResults[1].stepName).assertEqual('step2');
    });

    it('testParallelExecution', 0, async () => {
      const pStep1 = new NGFWorkflowStepDefinition('p_step1', 'wait', '{"waitMs":100}', null, null);
      const pStep2 = new NGFWorkflowStepDefinition('p_step2', 'wait', '{"waitMs":50}', null, null);
      
      const pGroup = new NGFWorkflowParallelGroup('pGroup1', [pStep1, pStep2], null);
      
      const definition = new NGFWorkflowDefinition('parallel_workflow', [], [pGroup]);
      ngfWorkflowDefinitionFacade.registerWorkflow(definition);
      
      const start = Date.now();
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow('parallel_workflow', '{}');
      const end = Date.now();
      
      expect(result.success).assertTrue();
      expect(result.stepResults.length).assertEqual(2);
      // Wait time should be bounded by the longest wait (~100ms), not the sum (150ms).
      expect(end - start).assertLess(140);
    });

    it('testStepTimeout', 0, async () => {
      const step = new NGFWorkflowStepDefinition('timeout_step', 'wait', '{"waitMs":200}', null, 50);
      const definition = new NGFWorkflowDefinition('timeout_workflow', [step], []);
      ngfWorkflowDefinitionFacade.registerWorkflow(definition);
      
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow('timeout_workflow', '{}');
      
      expect(result.success).assertFalse();
      expect(result.stepResults.length).assertEqual(1);
      expect(result.stepResults[0].success).assertFalse();
    });

    it('testParallelGroupTimeout', 0, async () => {
      const pStep1 = new NGFWorkflowStepDefinition('p_step1', 'wait', '{"waitMs":200}', null, null);
      // Group timeout is 50ms, the step takes 200ms
      const pGroup = new NGFWorkflowParallelGroup('pGroup1', [pStep1], 50);
      
      const definition = new NGFWorkflowDefinition('parallel_timeout_workflow', [], [pGroup]);
      ngfWorkflowDefinitionFacade.registerWorkflow(definition);
      
      const result = await ngfWorkflowDefinitionFacade.executeWorkflow('parallel_timeout_workflow', '{}');
      
      expect(result.success).assertFalse();
    });
  });
}
