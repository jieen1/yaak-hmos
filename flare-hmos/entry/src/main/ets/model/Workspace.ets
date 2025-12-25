/**
 * Workspace Model
 * Represents a workspace container for organizing API requests, folders, and environments
 */

import { AuthConfig, HttpHeader } from './HttpRequest';

@ObservedV2
export class Workspace {
  @Trace id: string = '';
  @Trace model: string = 'workspace';
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
  @Trace name: string = '';
  @Trace description: string = '';
  @Trace settings: WorkspaceSettings = new WorkspaceSettings();
  @Trace auth: AuthConfig | null = null;
  @Trace headers: HttpHeader[] = [];
}

@ObservedV2
export class WorkspaceSettings {
  @Trace follow_redirects: boolean = true;
  @Trace validate_certificates: boolean = true;
  @Trace request_timeout: number = 30000;
  @Trace proxy_enabled: boolean = false;
  @Trace proxy_host: string = '';
  @Trace proxy_port: number = 0;
  @Trace proxy_username: string = '';
  @Trace proxy_password: string = '';
}
