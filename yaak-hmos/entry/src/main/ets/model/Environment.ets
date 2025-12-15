import { BaseModel } from './BaseModel';

@ObservedV2
export class Environment extends BaseModel {
  @Trace workspace_id: string = '';
  @Trace name: string = '';
  @Trace data: string = '{}'; // JSON string

  constructor() {
    super();
    this.model = 'environment';
  }
}
