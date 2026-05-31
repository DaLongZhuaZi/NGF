import { describe, it, expect } from '@ohos/hypium';
import { serviceContainerFacade } from '../../../../src/main/ets/core/facades/ServiceContainerFacade';

export default function serviceContainerFacadeTest() {
  describe('ServiceContainerFacadeTest', () => {
    it('should_register_and_resolve_singleton', 0, () => {
      class MockService {
        id: number = Math.random();
      }

      serviceContainerFacade.register('test.mock.service', () => new MockService(), true);
      
      let instance1 = serviceContainerFacade.resolve<MockService>('test.mock.service');
      let instance2 = serviceContainerFacade.resolve<MockService>('test.mock.service');

      expect(instance1).assertNotNull();
      expect(instance1 === instance2).assertTrue();
    });

    it('should_register_and_resolve_transient', 0, () => {
      class MockTransient {
        id: number = Math.random();
      }

      serviceContainerFacade.register('test.mock.transient', () => new MockTransient(), false);
      
      let instance1 = serviceContainerFacade.resolve<MockTransient>('test.mock.transient');
      let instance2 = serviceContainerFacade.resolve<MockTransient>('test.mock.transient');

      expect(instance1).assertNotNull();
      expect(instance1 === instance2).assertFalse();
    });
  });
}
