import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfHoldingAwarenessFacade } from './HoldingAwarenessFacade';
import { ngfDeviceAdaptationFacade } from './DeviceAdaptationFacade';
import { ngfVisualEffectsFacade } from './VisualEffectsFacade';

export class NGFDeviceAwarenessIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFDeviceAwarenessIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_device_awareness_ready';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];

    registrations.push(new NGFServiceRegistration(
      'ngf.device.holding_awareness',
      'NGFHoldingAwarenessManager',
      ngfHoldingAwarenessFacade
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.adaptation',
      'NGFDeviceAdaptationManager',
      ngfDeviceAdaptationFacade
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.visual_effects',
      'NGFVisualEffectsManager',
      ngfVisualEffectsFacade
    ));

    return registrations;
  }
}

export const ngfDeviceAwarenessIntegrationFacade: NGFDeviceAwarenessIntegrationFacade = new NGFDeviceAwarenessIntegrationFacade();
