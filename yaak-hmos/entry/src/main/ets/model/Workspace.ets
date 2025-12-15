import { BaseModel } from './BaseModel';

@ObservedV2
export class Workspace extends BaseModel {
  @Trace name: string = '';
  @Trace description: string = '';

  constructor() {
    super();
    this.model = 'workspace';
  }
}
