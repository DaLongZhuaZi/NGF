import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfActionExecutorFacade } from './ActionExecutorFacade';
import { ngfRateLimitPolicyFacade } from './RateLimitPolicyFacade';
import { ngfRetryPolicyFacade } from './RetryPolicyFacade';
import { ngfWorkflowEngineFacade } from './WorkflowEngineFacade';
import { ngfWorkflowDefinitionFacade } from './WorkflowDefinitionFacade';
import { ngfWorkflowPersistenceFacade } from './WorkflowPersistenceFacade';

export class NGFContentWorkflowIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFContentWorkflowIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_content_workflow_integrated';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];
    registrations.push(new NGFServiceRegistration('ngf.workflow.engine', 'WorkflowEngineFacade', ngfWorkflowEngineFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.workflow.action_executor', 'ActionExecutorFacade', ngfActionExecutorFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.workflow.retry_policy', 'RetryPolicyFacade', ngfRetryPolicyFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.workflow.rate_limit_policy', 'RateLimitPolicyFacade', ngfRateLimitPolicyFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.workflow.definition_manager', 'WorkflowDefinitionFacade', ngfWorkflowDefinitionFacade as object));
    registrations.push(new NGFServiceRegistration('ngf.workflow.persistence', 'WorkflowPersistenceFacade', ngfWorkflowPersistenceFacade as object));
    return registrations;
  }
}

export const ngfContentWorkflowIntegrationFacade = new NGFContentWorkflowIntegrationFacade();
