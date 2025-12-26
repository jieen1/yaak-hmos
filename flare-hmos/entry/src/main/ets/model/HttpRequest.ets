/**
 * HTTP Request Model
 * Represents an HTTP request configuration with full metadata
 */

import { HttpMethod, BodyType, AuthType, ApiKeyLocation } from './Types';

@ObservedV2
export class HttpRequest {
  @Trace id: string = '';
  @Trace model: string = 'http_request';
  @Trace workspace_id: string = '';
  @Trace folder_id: string | null = null;
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
  @Trace name: string = '';
  @Trace url: string = '';
  @Trace method: HttpMethod = 'GET';
  @Trace headers: HttpHeader[] = [];
  @Trace query_params: QueryParam[] = [];
  @Trace body: string | null = null;
  @Trace body_type: BodyType = 'none';
  @Trace auth: AuthConfig = new AuthConfig();
  @Trace sort_priority: number = 0;

  @Computed
  get queryParamsCount(): number {
    if (!this.query_params) {
      return 0;
    }
    return this.query_params.filter(p => p.enabled && (p.name || p.value)).length;
  }

  @Computed
  get headersCount(): number {
    if (!this.headers) {
      return 0;
    }
    return this.headers.filter(h => h.enabled && (h.name || h.value)).length;
  }
}

@ObservedV2
export class HttpHeader {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace value: string = '';
  @Trace enabled: boolean = true;
}

@ObservedV2
export class QueryParam {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace value: string = '';
  @Trace enabled: boolean = true;
}

@ObservedV2
export class AuthConfig {
  @Trace type: AuthType = 'none';
  @Trace basic_username: string = '';
  @Trace basic_password: string = '';
  @Trace bearer_token: string = '';
  @Trace api_key_name: string = '';
  @Trace api_key_value: string = '';
  @Trace api_key_location: ApiKeyLocation = 'header';
  @Trace oauth2_access_token: string = '';
  @Trace oauth2_refresh_token: string = '';
  @Trace oauth2_expires_at: number = 0;
}
