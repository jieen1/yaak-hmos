import { BaseModel } from './BaseModel';
import { HeaderItem } from './Types';

@ObservedV2
export class HttpRequest extends BaseModel {
  @Trace workspace_id: string = '';
  @Trace folder_id: string | null = null;
  @Trace name: string = '';
  @Trace url: string = '';
  @Trace method: string = 'GET';
  @Trace headers: string = '[]'; // JSON string of HeaderItem[]
  @Trace params: string = '[]';  // JSON string of HeaderItem[] (Query Params)
  @Trace body: string | null = null;
  @Trace body_type: string | null = null;

  constructor() {
    super();
    this.model = 'http_request';
  }
}
