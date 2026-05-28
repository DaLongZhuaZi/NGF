import { NGFIntegrationFacadeBase } from '../../core/facades/NGFIntegrationFacadeBase';
import { NGFServiceRegistration } from '../../core/contracts/NGFServiceRegistration';
import { ngfHoldingAwarenessFacade } from './HoldingAwarenessFacade';
import { ngfDeviceAdaptationFacade } from './DeviceAdaptationFacade';
import { ngfVisualEffectsFacade } from './VisualEffectsFacade';
import { ngfAdaptiveLayoutFacade } from './AdaptiveLayoutFacade';
import { ngfDeviceCapabilityDetectorFacade } from './DeviceCapabilityDetectorFacade';
import { ngfAccessibilityFacade } from './AccessibilityFacade';

export class NGFDeviceAwarenessIntegrationFacade extends NGFIntegrationFacadeBase {
  protected readonly tag: string = 'NGFDeviceAwarenessIntegrationFacade';
  protected readonly appStorageKey: string = 'ngf_device_awareness_ready';

  protected getServiceRegistrations(): Array<NGFServiceRegistration> {
    const registrations: Array<NGFServiceRegistration> = [];

    registrations.push(new NGFServiceRegistration(
      'ngf.device.holding_awareness',
      'NGFHoldingAwarenessManager',
      ngfHoldingAwarenessFacade as object
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.adaptation',
      'NGFDeviceAdaptationManager',
      ngfDeviceAdaptationFacade as object
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.visual_effects',
      'NGFVisualEffectsManager',
      ngfVisualEffectsFacade as object
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.adaptive_layout',
      'AdaptiveLayoutFacade',
      ngfAdaptiveLayoutFacade as object
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.capability_detector',
      'DeviceCapabilityDetectorFacade',
      ngfDeviceCapabilityDetectorFacade as object
    ));

    registrations.push(new NGFServiceRegistration(
      'ngf.device.accessibility',
      'AccessibilityFacade',
      ngfAccessibilityFacade as object
    ));

    return registrations;
  }
}

export const ngfDeviceAwarenessIntegrationFacade: NGFDeviceAwarenessIntegrationFacade = new NGFDeviceAwarenessIntegrationFacade();
