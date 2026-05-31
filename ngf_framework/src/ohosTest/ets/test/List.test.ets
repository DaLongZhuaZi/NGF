import abilityTest from './Ability.test';
import serviceContainerFacadeTest from './ServiceContainerFacade.test';
import starterKernelTest from './StarterKernel.test';

export default function testsuite() {
  abilityTest();
  serviceContainerFacadeTest();
  starterKernelTest();
}