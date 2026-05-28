import { IEventBus, NGFEventListener, NGFEventPayload } from '../contracts/IEventBus';
import { logger } from '../../utils/Logger';

const LOG_TAG: string = 'EventBusFacade';

class NGFEventSubscriptionInternal {
  readonly listenerId: string;
  readonly listener: NGFEventListener;

  constructor(listenerId: string, listener: NGFEventListener) {
    this.listenerId = listenerId;
    this.listener = listener;
  }
}

export class EventBusFacade implements IEventBus {
  private readonly subscriptions: Map<string, Array<NGFEventSubscriptionInternal>> =
    new Map<string, Array<NGFEventSubscriptionInternal>>();

  publish(eventName: string, payload: NGFEventPayload): void {
    const normalizedEventName = eventName.trim();
    if (normalizedEventName.length <= 0) {
      logger.warn(LOG_TAG, 'publish ignored: eventName is empty');
      return;
    }

    const listeners = this.subscriptions.get(normalizedEventName);
    if (!listeners || listeners.length <= 0) {
      logger.debug(LOG_TAG, `publish skipped: event=${normalizedEventName}, listeners=0`);
      return;
    }

    logger.debug(LOG_TAG, `publishing event: event=${normalizedEventName}, listeners=${listeners.length}`);
    for (let i = 0; i < listeners.length; i++) {
      const subscription: NGFEventSubscriptionInternal = listeners[i];
      try {
        subscription.listener(payload);
      } catch (error) {
        logger.error(LOG_TAG, `listener execution failed: event=${normalizedEventName}, listenerId=${subscription.listenerId}, error=${errorToString(error as Object | string | number | boolean)}`);
      }
    }
  }

  subscribe(eventName: string, listenerId: string, listener: NGFEventListener): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    if (normalizedEventName.length <= 0 || normalizedListenerId.length <= 0) {
      logger.warn(LOG_TAG, `subscribe ignored: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    const listeners = this.ensureSubscriptions(normalizedEventName);
    for (let i = 0; i < listeners.length; i++) {
      if (listeners[i].listenerId === normalizedListenerId) {
        logger.debug(LOG_TAG, `subscribe skipped (already exists): event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
        return false;
      }
    }

    const subscription = new NGFEventSubscriptionInternal(normalizedListenerId, listener);
    listeners.push(subscription);
    logger.info(LOG_TAG, `subscribed listener: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
    return true;
  }

  unsubscribe(eventName: string, listenerId: string): boolean {
    const normalizedEventName = eventName.trim();
    const normalizedListenerId = listenerId.trim();
    const listeners = this.subscriptions.get(normalizedEventName);
    if (!listeners || listeners.length <= 0) {
      logger.debug(LOG_TAG, `unsubscribe skipped: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    let foundIndex = -1;
    for (let i = 0; i < listeners.length; i++) {
      if (listeners[i].listenerId === normalizedListenerId) {
        foundIndex = i;
        break;
      }
    }

    if (foundIndex < 0) {
      logger.debug(LOG_TAG, `unsubscribe skipped (not found): event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
      return false;
    }

    listeners.splice(foundIndex, 1);
    if (listeners.length <= 0) {
      this.subscriptions.delete(normalizedEventName);
    }
    logger.info(LOG_TAG, `unsubscribed listener: event=${normalizedEventName}, listenerId=${normalizedListenerId}`);
    return true;
  }

  clear(eventName: string): void {
    const normalizedEventName = eventName.trim();
    const existed = this.subscriptions.delete(normalizedEventName);
    logger.info(LOG_TAG, `cleared event subscriptions: event=${normalizedEventName}, existed=${existed}`);
  }

  getSubscriptionCount(eventName: string): number {
    const normalizedEventName = eventName.trim();
    const listeners = this.subscriptions.get(normalizedEventName);
    if (!listeners) {
      return 0;
    }
    return listeners.length;
  }

  getSubscribedEvents(): string[] {
    const result: string[] = [];
    const keys = this.subscriptions.keys();
    for (const key of keys) {
      result.push(key);
    }
    return result;
  }

  private ensureSubscriptions(eventName: string): Array<NGFEventSubscriptionInternal> {
    const existing = this.subscriptions.get(eventName);
    if (existing) {
      return existing;
    }
    const created: Array<NGFEventSubscriptionInternal> = [];
    this.subscriptions.set(eventName, created);
    return created;
  }
}

function errorToString(error: Object | string | number | boolean): string {
  if (typeof error === 'string') {
    return error;
  }
  if (typeof error === 'number' || typeof error === 'boolean') {
    return String(error);
  }
  if (error instanceof Error) {
    return error.message;
  }
  return String(error);
}

export const ngfEventBusFacade: EventBusFacade = new EventBusFacade();
