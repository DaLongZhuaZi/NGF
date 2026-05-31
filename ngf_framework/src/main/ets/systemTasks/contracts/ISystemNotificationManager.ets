export enum NGFNotificationType {
  BASIC = 0,
  LONG_TEXT = 1,
  MULTILINE = 2,
  PICTURE = 3,
  PROGRESS = 4,
  CUSTOM = 5
}

export class NGFNotificationRequest {
  id: number;
  title: string;
  content: string;
  type: NGFNotificationType;
  
  progressValue: number;
  progressMax: number;
  isOngoing: boolean;

  // 扩展属性
  longText?: string;
  lines?: Array<string>;
  templateName?: string;
  templateData?: Record<string, Object>;
  
  constructor(
    id: number, 
    title: string, 
    content: string, 
    type: NGFNotificationType = NGFNotificationType.BASIC,
    progressValue: number = 0, 
    progressMax: number = 0, 
    isOngoing: boolean = false
  ) {
    this.id = id;
    this.title = title;
    this.content = content;
    this.type = type;
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
