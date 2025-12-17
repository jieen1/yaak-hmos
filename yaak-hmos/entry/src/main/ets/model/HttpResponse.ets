/**
 * HTTP Response Model
 * Represents the result returned from executing a request, persisted to filesystem
 */

import { ResponseState } from './Types';

@ObservedV2
export class HttpResponse {
  @Trace id: string = '';
  @Trace model: string = 'http_response';
  @Trace request_id: string = '';
  @Trace created_at: number = 0;
  @Trace status_code: number = 0;
  @Trace status_text: string = '';
  @Trace headers: ResponseHeader[] = [];
  @Trace body_path: string = ''; // File path to response body
  @Trace elapsed_time: number = 0;
  @Trace size: number = 0;
  @Trace state: ResponseState = 'pending';
}

@ObservedV2
export class ResponseHeader {
  @Trace name: string = '';
  @Trace value: string = '';
}
