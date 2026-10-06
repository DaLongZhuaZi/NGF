import localUnitTest from './LocalUnit.test';
import dependencyContainerTest from './DependencyContainer.test';
import systemIntegrationTest from './SystemIntegrationFacade.test';
import workflowDefinitionTest from './WorkflowDefinitionFacade.test';
import accessibilityContractTest from './AccessibilityContract.test';

export default function testsuite() {
  localUnitTest();
  dependencyContainerTest();
  systemIntegrationTest();
  workflowDefinitionTest();
  accessibilityContractTest();
}
