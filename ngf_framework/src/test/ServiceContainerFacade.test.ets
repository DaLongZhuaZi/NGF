import { describe, it, expect } from '@ohos/hypium';
import { ngfServiceContainerFacade } from '../main/ets/core/facades/ServiceContainerFacade';

class NGFLocalMockService {
  id: number;

  constructor(id: number) {
    this.id = id;
  }
}

export default function serviceContainerFacadeTest() {
  describe('NGFServiceContainerFacadeLocalTest', () => {
    it('shouldRegisterAndResolveInstance', 0, () => {
      const service = new NGFLocalMockService(1001);
      ngfServiceContainerFacade.registerInstance('test.local.mock.service', service);

      const resolved = ngfServiceContainerFacade.resolveInstance('test.local.mock.service') as NGFLocalMockService | null;
      expect(resolved !== null).assertTrue();
      if (resolved !== null) {
        expect(resolved.id).assertEqual(1001);
      }
    });
  });
}
