/**
 * Cookie Jar Model
 * Represents a storage container for HTTP cookies with domain and path management
 */

@ObservedV2
export class CookieJar {
  @Trace id: string = '';
  @Trace model: string = 'cookie_jar';
  @Trace workspace_id: string = '';
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace cookies: Cookie[] = [];
}

@ObservedV2
export class Cookie {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace value: string = '';
  @Trace domain: string = '';
  @Trace path: string = '/';
  @Trace expires: number | null = null;
  @Trace http_only: boolean = false;
  @Trace secure: boolean = false;
}
