export class NGFServiceRegistration {
  readonly token: string;
  readonly implementationName: string;
  readonly service: object;

  constructor(token: string, implementationName: string, service: object) {
    this.token = token;
    this.implementationName = implementationName;
    this.service = service;
  }
}
