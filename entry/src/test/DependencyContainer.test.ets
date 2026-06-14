import { describe, beforeEach, it, expect } from '@ohos/hypium';
import { DependencyContainer, ContainerLifecycle } from 'ngf_framework';

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
      container.register('service.singleton', (): object => {
        counter++;
        return new MockService(counter);
      }, ContainerLifecycle.SINGLETON);

      const resolved1: object | null = container.resolve('service.singleton');
      const resolved2: object | null = container.resolve('service.singleton');

      expect(resolved1 !== null).assertTrue();
      expect(resolved2 !== null).assertTrue();
      if (resolved1 !== null && resolved2 !== null) {
        const instance1 = resolved1 as MockService;
        const instance2 = resolved2 as MockService;
        expect(instance1.value).assertEqual(1);
        expect(instance2.value).assertEqual(1);
        expect(instance1).assertEqual(instance2);
      }
    });

    it('testTransientLifecycle', 0, () => {
      const container = DependencyContainer.getInstance();
      let counter = 0;
      container.register('service.transient', (): object => {
        counter++;
        return new MockService(counter);
      }, ContainerLifecycle.TRANSIENT);

      const resolved1: object | null = container.resolve('service.transient');
      const resolved2: object | null = container.resolve('service.transient');

      expect(resolved1 !== null).assertTrue();
      expect(resolved2 !== null).assertTrue();
      if (resolved1 !== null && resolved2 !== null) {
        const instance1 = resolved1 as MockService;
        const instance2 = resolved2 as MockService;
        expect(instance1.value).assertEqual(1);
        expect(instance2.value).assertEqual(2);
        expect(instance1.value !== instance2.value).assertTrue();
      }
    });

    it('testResolveUnregistered', 0, () => {
      const container = DependencyContainer.getInstance();
      const instance: object | null = container.resolve('service.unregistered');
      expect(instance).assertNull();
    });

    it('testClear', 0, () => {
      const container = DependencyContainer.getInstance();
      container.register('service.to.clear', (): object => new MockService(10), ContainerLifecycle.SINGLETON);
      
      let instance: object | null = container.resolve('service.to.clear');
      expect(instance !== null).assertTrue();

      container.clear();
      instance = container.resolve('service.to.clear');
      expect(instance).assertNull();
    });

  });
}
