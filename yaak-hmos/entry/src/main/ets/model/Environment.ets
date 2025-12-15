import { BaseModel } from './BaseModel';

@ObservedV2
export class Environment extends BaseModel {
  @Trace workspace_id: string = '';
  @Trace name: string = '';
  @Trace variables: string = '[]';

  constructor() {
    super();
    this.model = 'environment';
  }
}
