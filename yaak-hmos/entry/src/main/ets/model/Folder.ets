import { BaseModel } from './BaseModel';

@ObservedV2
export class Folder extends BaseModel {
  @Trace workspace_id: string = '';
  @Trace folder_id: string | null = null;
  @Trace name: string = '';
  @Trace sort_priority: number = 0;

  constructor() {
    super();
    this.model = 'folder';
  }
}
