export class NGFNotificationRequest {
  id: number;
  title: string;
  content: string;
  progressValue: number;
  progressMax: number;
  isOngoing: boolean;
  
  constructor(id: number, title: string, content: string, progressValue: number = 0, progressMax: number = 0, isOngoing: boolean = false) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.progressValue = progressValue;
    this.progressMax = progressMax;
    this.isOngoing = isOngoing;
  }
}

export interface ISystemNotificationManager {
  requestPermission(): Promise<boolean>;
  publish(request: NGFNotificationRequest): Promise<void>;
  cancel(id: number): Promise<void>;
}
