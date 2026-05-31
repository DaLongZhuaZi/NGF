import { describe, it, expect } from '@ohos/hypium';
import { ngfStarterKernel } from '../../../../src/main/ets/core/starter/StarterKernel';
import { NGFPhaseState } from '../../../../src/main/ets/core/contracts/ILifecycleOrchestrator';

export default function starterKernelTest() {
  describe('StarterKernelTest', () => {
    it('should_have_initial_state_not_started', 0, () => {
      let state = ngfStarterKernel.getCurrentPhase();
      expect(state).assertEqual(NGFPhaseState.NOT_STARTED);
    });
  });
}
