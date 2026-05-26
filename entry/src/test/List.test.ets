import localUnitTest from './LocalUnit.test';
import dependencyContainerTest from './DependencyContainer.test';
import workflowDefinitionTest from './WorkflowDefinitionFacade.test';

export default function testsuite() {
  localUnitTest();
  dependencyContainerTest();
  workflowDefinitionTest();
}