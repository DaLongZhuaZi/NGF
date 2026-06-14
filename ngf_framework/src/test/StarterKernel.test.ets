import { describe, it, expect } from '@ohos/hypium';
import { ngfStarterKernel } from '../main/ets/core/starter/StarterKernel';

export default function starterKernelTest() {
  describe('NGFStarterKernelLocalTest', () => {
    it('shouldExposeLifecycleState', 0, () => {
      const state = ngfStarterKernel.lifecycle.getCurrentState();
      expect(state.phaseName.length > 0).assertTrue();
      expect(state.progress >= 0).assertTrue();
    });
  });
}
