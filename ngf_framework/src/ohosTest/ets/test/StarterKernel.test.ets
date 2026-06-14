import { describe, it, expect } from '@ohos/hypium';
import { ngfStarterKernel } from '../../../../src/main/ets/core/starter/StarterKernel';

export default function starterKernelTest() {
  describe('StarterKernelTest', () => {
    it('should_have_initial_state_not_started', 0, () => {
      const state = ngfStarterKernel.lifecycle.getCurrentState();
      expect(state.phaseName).assertEqual('not_started');
      expect(state.progress).assertEqual(0);
      expect(state.isCompleted).assertFalse();
    });
  });
}
