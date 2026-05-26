import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { DependencyContainer, ContainerLifecycle } from '../../src/main/ets/Framework/NGF/core/DependencyContainer';

class MockService {
  public value: number;
  constructor(val: number) {
    this.value = val;
  }
}

export default function dependencyContainerTest() {
  describe('DependencyContainerTest', () => {

    beforeEach(() => {
      DependencyContainer.getInstance().clear();
    });

    it('testSingletonLifecycle', 0, () => {
      const container = DependencyContainer.getInstance();
      let counter = 0;
      container.register('service.singleton', () => {
        counter++;
        return new MockService(counter);
      }, ContainerLifecycle.SINGLETON);

      const instance1 = container.resolve('service.singleton') as MockService;
      const instance2 = container.resolve('service.singleton') as MockService;

      expect(instance1).assertNotNull();
      expect(instance1.value).assertEqual(1);
      expect(instance2.value).assertEqual(1);
      expect(instance1).assertEqual(instance2);
    });

    it('testTransientLifecycle', 0, () => {
      const container = DependencyContainer.getInstance();
      let counter = 0;
      container.register('service.transient', () => {
        counter++;
        return new MockService(counter);
      }, ContainerLifecycle.TRANSIENT);

      const instance1 = container.resolve('service.transient') as MockService;
      const instance2 = container.resolve('service.transient') as MockService;

      expect(instance1).assertNotNull();
      expect(instance1.value).assertEqual(1);
      expect(instance2).assertNotNull();
      expect(instance2.value).assertEqual(2);
      // expect(instance1).assertNotEqual(instance2); // Ohos Hypium might not have assertNotEqual
      expect(instance1.value !== instance2.value).assertTrue();
    });

    it('testResolveUnregistered', 0, () => {
      const container = DependencyContainer.getInstance();
      const instance = container.resolve('service.unregistered');
      expect(instance).assertNull();
    });

    it('testClear', 0, () => {
      const container = DependencyContainer.getInstance();
      container.register('service.to.clear', () => new MockService(10), ContainerLifecycle.SINGLETON);
      
      let instance = container.resolve('service.to.clear');
      expect(instance).assertNotNull();

      container.clear();
      instance = container.resolve('service.to.clear');
      expect(instance).assertNull();
    });

  });
}
