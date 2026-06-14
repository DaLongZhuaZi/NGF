import { describe, it, expect } from '@ohos/hypium';
import { ngfServiceContainerFacade } from '../../../../src/main/ets/core/facades/ServiceContainerFacade';

export default function serviceContainerFacadeTest() {
  describe('ServiceContainerFacadeTest', () => {
    it('should_register_and_resolve_singleton_name', 0, () => {
      class MockService {
        id: number = Math.random();
      }

      const service = new MockService();
      ngfServiceContainerFacade.registerSingleton('test.mock.service', 'MockService');
      ngfServiceContainerFacade.registerInstance('test.mock.service.instance', service);

      const implementationName = ngfServiceContainerFacade.resolve('test.mock.service');
      const instance = ngfServiceContainerFacade.resolveInstance('test.mock.service.instance') as MockService | null;

      expect(implementationName).assertEqual('MockService');
      expect(instance !== null).assertTrue();
      if (instance !== null) {
        expect(instance.id).assertEqual(service.id);
      }
    });

    it('should_report_missing_token', 0, () => {
      expect(ngfServiceContainerFacade.contains('test.mock.missing')).assertFalse();
      expect(ngfServiceContainerFacade.resolve('test.mock.missing')).assertEqual('');
    });
  });
}
