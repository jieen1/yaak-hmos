/**
 * Folder Model
 * Represents a hierarchical container for organizing requests with inheritance support
 */

import { AuthConfig, HttpHeader } from './HttpRequest';

@ObservedV2
export class Folder {
  @Trace id: string = '';
  @Trace model: string = 'folder';
  @Trace workspace_id: string = '';
  @Trace folder_id: string | null = null;
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
  @Trace name: string = '';
  @Trace sort_priority: number = 0;
  @Trace auth: AuthConfig | null = null;
  @Trace headers: HttpHeader[] = [];
}
