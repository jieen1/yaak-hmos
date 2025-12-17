# Yaak HarmonyOS Complete Application - Design Document

## Overview

This document describes the optimized design for the Yaak HarmonyOS API Client application, following HarmonyOS native development best practices. The design focuses on:

1. **State Management V2**: Using @ObservedV2, @Trace, @ComponentV2, @Local, @Param for optimal reactivity
2. **Theme Adaptation**: Resource qualifiers (base/dark) and system resources for seamless dark/light mode
3. **Database Management**: RDB Store with connection pooling, transactions, and migration strategy
4. **Navigation**: Navigation component for proper route stack management
5. **Design Tokens**: Unified spacing, colors, typography, and animations
6. **Component Architecture**: Reusable styled components following HarmonyOS design guidelines

## Design Goals

- Professional-grade API testing tool comparable to Postman and Insomnia
- Native HarmonyOS experience with optimal performance
- Complete feature parity with original Yaak project
- No mock code, TODO items, or demo content
- Maintainable and extensible architecture


## High-Level Architecture

The application follows a 5-layer architecture optimized for HarmonyOS:

```
┌─────────────────────────────────────────────────────────┐
│                    Pages Layer                          │
│  (Entry points, @ComponentV2, Navigation routes)        │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                 Components Layer                        │
│  (Reusable UI components, @ComponentV2, @Local, @Param) │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                  Services Layer                         │
│  (Business logic, RequestExecutor, EnvironmentService)  │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                 Database Layer                          │
│  (RDB Store, Repositories, Transactions)                │
└─────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────┐
│                   Models Layer                          │
│  (@ObservedV2, @Trace, Data classes)                    │
└─────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

**Pages Layer**
- Entry points decorated with @Entry and @ComponentV2
- Navigation route definitions
- Page-level state management with @Local
- Lifecycle management (aboutToAppear, aboutToDisappear)

**Components Layer**
- Reusable UI components with @ComponentV2
- Component inputs with @Param
- Component outputs with @Event
- Local component state with @Local
- Styled components following design tokens

**Services Layer**
- Business logic implementation
- HTTP request execution
- Environment variable resolution
- Template engine processing
- Cookie management
- Authentication handling

**Database Layer**
- RDB Store connection management
- Repository pattern for data access
- Transaction management
- Database migrations
- Query optimization

**Models Layer**
- Data models with @ObservedV2 and @Trace
- Deep observation for nested properties
- Type-safe data structures
- Validation logic


## Core Data Models

All data models use State Management V2 decorators for optimal reactivity and deep observation.

### Workspace Model

```typescript
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
}

@ObservedV2
export class WorkspaceSettings {
  @Trace follow_redirects: boolean = true;
  @Trace validate_certificates: boolean = true;
  @Trace request_timeout: number = 30000;
  @Trace proxy_enabled: boolean = false;
  @Trace proxy_host: string = '';
  @Trace proxy_port: number = 0;
}
```

### HttpRequest Model

```typescript
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
  @Trace api_key_location: 'header' | 'query' = 'header';
}

type HttpMethod = 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';
type BodyType = 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text';
type AuthType = 'none' | 'basic' | 'bearer' | 'api-key' | 'oauth2';
```

### Environment Model

```typescript
@ObservedV2
export class Environment {
  @Trace id: string = '';
  @Trace model: string = 'environment';
  @Trace workspace_id: string = '';
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
  @Trace name: string = '';
  @Trace variables: EnvironmentVariable[] = [];
}

@ObservedV2
export class EnvironmentVariable {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace value: string = '';
  @Trace enabled: boolean = true;
  @Trace is_secret: boolean = false;
}
```

### Folder Model

```typescript
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
```

### HttpResponse Model

```typescript
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

type ResponseState = 'pending' | 'success' | 'error' | 'cancelled';
```

### CookieJar Model

```typescript
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
```


## Database Schema

The application uses HarmonyOS RDB Store (SQLite-based) for data persistence.

### Database Configuration

```typescript
const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'yaak.db',
  securityLevel: relationalStore.SecurityLevel.S1,
  encrypt: false,
  customDir: 'database'
};
```

### Table Definitions

**workspaces**
```sql
CREATE TABLE IF NOT EXISTS workspaces (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'workspace',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  description TEXT NOT NULL DEFAULT '',
  settings TEXT NOT NULL DEFAULT '{}'
);
```

**http_requests**
```sql
CREATE TABLE IF NOT EXISTS http_requests (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'http_request',
  workspace_id TEXT NOT NULL,
  folder_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  method TEXT NOT NULL,
  headers TEXT NOT NULL DEFAULT '[]',
  query_params TEXT NOT NULL DEFAULT '[]',
  body TEXT,
  body_type TEXT NOT NULL DEFAULT 'none',
  auth TEXT NOT NULL DEFAULT '{}',
  sort_priority REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
);

CREATE INDEX idx_http_requests_workspace ON http_requests(workspace_id);
CREATE INDEX idx_http_requests_folder ON http_requests(folder_id);
CREATE INDEX idx_http_requests_sort ON http_requests(sort_priority);
```

**http_responses**
```sql
CREATE TABLE IF NOT EXISTS http_responses (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'http_response',
  request_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  status_code INTEGER NOT NULL,
  status_text TEXT NOT NULL,
  headers TEXT NOT NULL DEFAULT '[]',
  body_path TEXT NOT NULL,
  elapsed_time INTEGER NOT NULL,
  size INTEGER NOT NULL,
  state TEXT NOT NULL DEFAULT 'pending',
  FOREIGN KEY (request_id) REFERENCES http_requests(id) ON DELETE CASCADE
);

CREATE INDEX idx_http_responses_request ON http_responses(request_id);
CREATE INDEX idx_http_responses_created ON http_responses(created_at DESC);
```

**folders**
```sql
CREATE TABLE IF NOT EXISTS folders (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'folder',
  workspace_id TEXT NOT NULL,
  folder_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  sort_priority REAL NOT NULL DEFAULT 0,
  auth TEXT,
  headers TEXT NOT NULL DEFAULT '[]',
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
);

CREATE INDEX idx_folders_workspace ON folders(workspace_id);
CREATE INDEX idx_folders_parent ON folders(folder_id);
CREATE INDEX idx_folders_sort ON folders(sort_priority);
```

**environments**
```sql
CREATE TABLE IF NOT EXISTS environments (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'environment',
  workspace_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  variables TEXT NOT NULL DEFAULT '[]',
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

CREATE INDEX idx_environments_workspace ON environments(workspace_id);
```

**cookie_jars**
```sql
CREATE TABLE IF NOT EXISTS cookie_jars (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'cookie_jar',
  workspace_id TEXT NOT NULL,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  cookies TEXT NOT NULL DEFAULT '[]',
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
);

CREATE INDEX idx_cookie_jars_workspace ON cookie_jars(workspace_id);
```

**settings**
```sql
CREATE TABLE IF NOT EXISTS settings (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'settings',
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  theme TEXT NOT NULL DEFAULT 'system',
  font_size REAL NOT NULL DEFAULT 14,
  editor_font_size REAL NOT NULL DEFAULT 14,
  editor_keymap TEXT NOT NULL DEFAULT 'default',
  soft_wrap BOOLEAN NOT NULL DEFAULT 0
);
```

**grpc_requests**
```sql
CREATE TABLE IF NOT EXISTS grpc_requests (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'grpc_request',
  workspace_id TEXT NOT NULL,
  folder_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  proto_file_path TEXT,
  service_name TEXT NOT NULL,
  method_name TEXT NOT NULL,
  metadata TEXT NOT NULL DEFAULT '[]',
  message TEXT NOT NULL DEFAULT '{}',
  sort_priority REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
);

CREATE INDEX idx_grpc_requests_workspace ON grpc_requests(workspace_id);
CREATE INDEX idx_grpc_requests_folder ON grpc_requests(folder_id);
```

**websocket_requests**
```sql
CREATE TABLE IF NOT EXISTS websocket_requests (
  id TEXT PRIMARY KEY,
  model TEXT NOT NULL DEFAULT 'websocket_request',
  workspace_id TEXT NOT NULL,
  folder_id TEXT,
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER,
  name TEXT NOT NULL,
  url TEXT NOT NULL,
  headers TEXT NOT NULL DEFAULT '[]',
  sort_priority REAL NOT NULL DEFAULT 0,
  FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
  FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
);

CREATE INDEX idx_websocket_requests_workspace ON websocket_requests(workspace_id);
CREATE INDEX idx_websocket_requests_folder ON websocket_requests(folder_id);
```

### Database Migration Strategy

```typescript
export class DatabaseManager {
  private static readonly CURRENT_VERSION = 1;
  
  async initTables(): Promise<void> {
    const store = this.rdbStore;
    if (!store) return;
    
    const currentVersion = store.version;
    
    if (currentVersion === 0) {
      // Fresh install - create all tables
      await this.createAllTables(store);
      store.version = DatabaseManager.CURRENT_VERSION;
    } else if (currentVersion < DatabaseManager.CURRENT_VERSION) {
      // Migration needed
      await this.migrateDatabase(store, currentVersion);
      store.version = DatabaseManager.CURRENT_VERSION;
    }
  }
  
  private async migrateDatabase(store: RdbStore, fromVersion: number): Promise<void> {
    // Future migrations will be handled here
    // Example:
    // if (fromVersion === 1) {
    //   await store.executeSql('ALTER TABLE http_requests ADD COLUMN new_field TEXT');
    // }
  }
}
```

### Connection Management

```typescript
export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  
  // Singleton pattern ensures single database connection
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }
  
  // Initialize database with proper error handling
  public async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initPromise) return this.initPromise;
    
    this.initPromise = new Promise<void>(async (resolve, reject) => {
      try {
        this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
        await this.initTables();
        resolve();
      } catch (err) {
        console.error(`Database init failed: ${err.code}, ${err.message}`);
        reject(err);
      }
    });
    
    return this.initPromise;
  }
  
  // Wait for initialization to complete
  public async waitForInit(): Promise<void> {
    if (this.initPromise) {
      await this.initPromise;
    }
  }
  
  // Get database store instance
  public getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }
}
```

### Transaction Support

```typescript
export class BaseRepository {
  protected async executeInTransaction<T>(
    operation: (transaction: relationalStore.Transaction) => Promise<T>
  ): Promise<T> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) throw new Error('Database not initialized');
    
    const transaction = await store.createTransaction();
    try {
      const result = await operation(transaction);
      await transaction.commit();
      return result;
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
}
```


## Service Layer Design

### RequestExecutor Service

Handles HTTP request execution with full support for authentication, headers, and body types.

```typescript
export class RequestExecutor {
  static async execute(
    request: HttpRequest,
    variables: Map<string, string>
  ): Promise<http.HttpResponse> {
    // 1. Resolve template variables in URL, headers, and body
    const resolvedUrl = TemplateEngine.resolve(request.url, variables);
    const resolvedHeaders = this.resolveHeaders(request.headers, variables);
    const resolvedBody = this.resolveBody(request.body, request.body_type, variables);
    
    // 2. Apply authentication
    const authHeaders = AuthService.getAuthHeaders(request.auth, variables);
    const finalHeaders = { ...resolvedHeaders, ...authHeaders };
    
    // 3. Build HTTP request
    const httpRequest = http.createHttp();
    const options: http.HttpRequestOptions = {
      method: request.method,
      header: finalHeaders,
      extraData: resolvedBody,
      expectDataType: http.HttpDataType.STRING,
      connectTimeout: 30000,
      readTimeout: 30000
    };
    
    // 4. Execute request
    const response = await httpRequest.request(resolvedUrl, options);
    
    // 5. Store cookies
    await CookieService.storeCookies(response.header, resolvedUrl);
    
    return response;
  }
  
  private static resolveHeaders(
    headers: HttpHeader[],
    variables: Map<string, string>
  ): Record<string, string> {
    const result: Record<string, string> = {};
    headers.filter(h => h.enabled).forEach(header => {
      const name = TemplateEngine.resolve(header.name, variables);
      const value = TemplateEngine.resolve(header.value, variables);
      result[name] = value;
    });
    return result;
  }
  
  private static resolveBody(
    body: string | null,
    bodyType: BodyType,
    variables: Map<string, string>
  ): string | ArrayBuffer | null {
    if (!body) return null;
    
    switch (bodyType) {
      case 'json':
      case 'xml':
      case 'text':
      case 'graphql':
        return TemplateEngine.resolve(body, variables);
      case 'form-urlencoded':
        return this.buildFormUrlEncoded(body, variables);
      case 'form-data':
        return this.buildFormData(body, variables);
      case 'binary':
        return this.readBinaryFile(body);
      default:
        return null;
    }
  }
}
```

### EnvironmentService

Manages environment variables and variable resolution.

```typescript
export class EnvironmentService {
  static mergeVariables(environments: Environment[]): Map<string, string> {
    const variables = new Map<string, string>();
    
    // Merge all enabled environments
    environments.forEach(env => {
      env.variables
        .filter(v => v.enabled)
        .forEach(v => {
          variables.set(v.name, v.value);
        });
    });
    
    return variables;
  }
  
  static resolveVariable(
    name: string,
    variables: Map<string, string>
  ): string {
    return variables.get(name) || `{{${name}}}`;
  }
}
```

### TemplateEngine Service

Processes template syntax {{ variableName }} and {{ functionName(args) }}.

```typescript
export class TemplateEngine {
  private static readonly TEMPLATE_REGEX = /\{\{([^}]+)\}\}/g;
  
  static resolve(template: string, variables: Map<string, string>): string {
    return template.replace(this.TEMPLATE_REGEX, (match, expression) => {
      const trimmed = expression.trim();
      
      // Check if it's a function call
      if (trimmed.includes('(')) {
        return this.executeFunction(trimmed, variables);
      }
      
      // Simple variable lookup
      return variables.get(trimmed) || match;
    });
  }
  
  private static executeFunction(
    expression: string,
    variables: Map<string, string>
  ): string {
    const functionMatch = expression.match(/^(\w+)\((.*)\)$/);
    if (!functionMatch) return expression;
    
    const [, functionName, argsStr] = functionMatch;
    const args = this.parseArguments(argsStr, variables);
    
    switch (functionName) {
      case 'timestamp':
        return Date.now().toString();
      case 'uuid':
        return this.generateUUID();
      case 'random':
        return this.generateRandom(args);
      case 'base64':
        return this.base64Encode(args[0] || '');
      case 'md5':
        return this.md5Hash(args[0] || '');
      default:
        return expression;
    }
  }
  
  private static generateUUID(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }
  
  private static generateRandom(args: string[]): string {
    const min = parseInt(args[0] || '0');
    const max = parseInt(args[1] || '100');
    return Math.floor(Math.random() * (max - min + 1) + min).toString();
  }
}
```

### AuthService

Handles authentication for requests.

```typescript
export class AuthService {
  static getAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    switch (auth.type) {
      case 'basic':
        return this.getBasicAuthHeaders(auth, variables);
      case 'bearer':
        return this.getBearerAuthHeaders(auth, variables);
      case 'api-key':
        return this.getApiKeyHeaders(auth, variables);
      default:
        return {};
    }
  }
  
  private static getBasicAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const username = TemplateEngine.resolve(auth.basic_username, variables);
    const password = TemplateEngine.resolve(auth.basic_password, variables);
    const credentials = `${username}:${password}`;
    const encoded = util.Base64Helper.encodeSync(credentials);
    return { 'Authorization': `Basic ${encoded}` };
  }
  
  private static getBearerAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const token = TemplateEngine.resolve(auth.bearer_token, variables);
    return { 'Authorization': `Bearer ${token}` };
  }
  
  private static getApiKeyHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const name = TemplateEngine.resolve(auth.api_key_name, variables);
    const value = TemplateEngine.resolve(auth.api_key_value, variables);
    
    if (auth.api_key_location === 'header') {
      return { [name]: value };
    }
    // For query parameters, handled separately in URL building
    return {};
  }
}
```

### CookieService

Manages HTTP cookies with domain and path matching.

```typescript
export class CookieService {
  static async storeCookies(
    headers: Record<string, string>,
    url: string
  ): Promise<void> {
    const setCookieHeaders = headers['set-cookie'] || headers['Set-Cookie'];
    if (!setCookieHeaders) return;
    
    const cookies = Array.isArray(setCookieHeaders) 
      ? setCookieHeaders 
      : [setCookieHeaders];
    
    const parsedUrl = new URL(url);
    const domain = parsedUrl.hostname;
    
    for (const cookieStr of cookies) {
      const cookie = this.parseCookie(cookieStr, domain);
      await CookieRepository.upsertCookie(cookie);
    }
  }
  
  static async getCookiesForRequest(url: string): Promise<Cookie[]> {
    const parsedUrl = new URL(url);
    const domain = parsedUrl.hostname;
    const path = parsedUrl.pathname;
    
    const allCookies = await CookieRepository.getAllCookies();
    
    return allCookies.filter(cookie => {
      // Check domain match
      if (!this.domainMatches(cookie.domain, domain)) return false;
      
      // Check path match
      if (!path.startsWith(cookie.path)) return false;
      
      // Check expiration
      if (cookie.expires && cookie.expires < Date.now()) return false;
      
      // Check secure flag
      if (cookie.secure && !parsedUrl.protocol.includes('https')) return false;
      
      return true;
    });
  }
  
  private static domainMatches(cookieDomain: string, requestDomain: string): boolean {
    if (cookieDomain === requestDomain) return true;
    if (cookieDomain.startsWith('.')) {
      return requestDomain.endsWith(cookieDomain.substring(1));
    }
    return false;
  }
}
```

### ResponseStorageService

Manages response body storage to filesystem.

```typescript
export class ResponseStorageService {
  private static readonly RESPONSE_DIR = 'responses';
  
  static async saveResponseBody(
    responseId: string,
    body: string | ArrayBuffer,
    context: common.UIAbilityContext
  ): Promise<string> {
    const filesDir = context.filesDir;
    const responseDir = `${filesDir}/${this.RESPONSE_DIR}`;
    
    // Ensure directory exists
    await fs.mkdir(responseDir, true);
    
    const filePath = `${responseDir}/${responseId}.dat`;
    
    // Write body to file
    if (typeof body === 'string') {
      await fs.writeText(filePath, body);
    } else {
      await fs.write(filePath, body);
    }
    
    return filePath;
  }
  
  static async loadResponseBody(bodyPath: string): Promise<string> {
    try {
      return await fs.readText(bodyPath);
    } catch (error) {
      console.error(`Failed to load response body: ${error}`);
      return '';
    }
  }
  
  static async deleteResponseBody(bodyPath: string): Promise<void> {
    try {
      await fs.unlink(bodyPath);
    } catch (error) {
      console.error(`Failed to delete response body: ${error}`);
    }
  }
  
  static async cleanupOldResponses(
    maxAge: number = 7 * 24 * 60 * 60 * 1000 // 7 days
  ): Promise<void> {
    const responses = await ResponseRepository.getAllResponses();
    const now = Date.now();
    
    for (const response of responses) {
      if (now - response.created_at > maxAge) {
        await this.deleteResponseBody(response.body_path);
        await ResponseRepository.deleteResponse(response.id);
      }
    }
  }
}
```


## Theme System Design

Following HarmonyOS best practices for dark/light mode adaptation using resource qualifiers.

### Resource Directory Structure

```
entry/src/main/resources/
├── base/
│   └── element/
│       ├── color.json          # Light mode colors
│       ├── float.json          # Spacing and dimensions
│       └── string.json         # Text resources
└── dark/
    └── element/
        └── color.json          # Dark mode colors
```

### Color Resources

**base/element/color.json** (Light Mode)
```json
{
  "color": [
    { "name": "background", "value": "#FFFFFF" },
    { "name": "surface", "value": "#F3F4F6" },
    { "name": "surface_highlight", "value": "#E5E7EB" },
    { "name": "text_primary", "value": "#111827" },
    { "name": "text_secondary", "value": "#6B7280" },
    { "name": "primary", "value": "#2563EB" },
    { "name": "primary_hover", "value": "#1D4ED8" },
    { "name": "secondary", "value": "#9CA3AF" },
    { "name": "border", "value": "#E5E7EB" },
    { "name": "success", "value": "#059669" },
    { "name": "warning", "value": "#D97706" },
    { "name": "danger", "value": "#DC2626" },
    { "name": "header_background", "value": "#F9FAFB" },
    { "name": "sidebar_background", "value": "#F9FAFB" },
    { "name": "input_background", "value": "#FFFFFF" },
    { "name": "input_border", "value": "#D1D5DB" },
    { "name": "button_background", "value": "#2563EB" },
    { "name": "button_text", "value": "#FFFFFF" },
    { "name": "tab_active", "value": "#2563EB" },
    { "name": "tab_inactive", "value": "#6B7280" },
    { "name": "divider", "value": "#E5E7EB" },
    { "name": "shadow", "value": "#00000010" }
  ]
}
```

**dark/element/color.json** (Dark Mode)
```json
{
  "color": [
    { "name": "background", "value": "#111111" },
    { "name": "surface", "value": "#1E1E1E" },
    { "name": "surface_highlight", "value": "#2B2B2B" },
    { "name": "text_primary", "value": "#FFFFFF" },
    { "name": "text_secondary", "value": "#AAAAAA" },
    { "name": "primary", "value": "#3B82F6" },
    { "name": "primary_hover", "value": "#2563EB" },
    { "name": "secondary", "value": "#6B7280" },
    { "name": "border", "value": "#333333" },
    { "name": "success", "value": "#10B981" },
    { "name": "warning", "value": "#F59E0B" },
    { "name": "danger", "value": "#EF4444" },
    { "name": "header_background", "value": "#181818" },
    { "name": "sidebar_background", "value": "#181818" },
    { "name": "input_background", "value": "#252525" },
    { "name": "input_border", "value": "#404040" },
    { "name": "button_background", "value": "#3B82F6" },
    { "name": "button_text", "value": "#FFFFFF" },
    { "name": "tab_active", "value": "#3B82F6" },
    { "name": "tab_inactive", "value": "#AAAAAA" },
    { "name": "divider", "value": "#333333" },
    { "name": "shadow", "value": "#00000030" }
  ]
}
```

### Design Tokens

**base/element/float.json**
```json
{
  "float": [
    { "name": "spacing_xs", "value": "4vp" },
    { "name": "spacing_sm", "value": "8vp" },
    { "name": "spacing_md", "value": "12vp" },
    { "name": "spacing_lg", "value": "16vp" },
    { "name": "spacing_xl", "value": "24vp" },
    { "name": "spacing_2xl", "value": "32vp" },
    
    { "name": "border_radius_sm", "value": "4vp" },
    { "name": "border_radius_md", "value": "6vp" },
    { "name": "border_radius_lg", "value": "8vp" },
    { "name": "border_radius_xl", "value": "12vp" },
    
    { "name": "font_size_xs", "value": "12fp" },
    { "name": "font_size_sm", "value": "14fp" },
    { "name": "font_size_md", "value": "16fp" },
    { "name": "font_size_lg", "value": "18fp" },
    { "name": "font_size_xl", "value": "20fp" },
    { "name": "font_size_2xl", "value": "24fp" },
    
    { "name": "line_height_tight", "value": "1.25" },
    { "name": "line_height_normal", "value": "1.5" },
    { "name": "line_height_relaxed", "value": "1.75" },
    
    { "name": "shadow_sm", "value": "2vp" },
    { "name": "shadow_md", "value": "4vp" },
    { "name": "shadow_lg", "value": "8vp" },
    
    { "name": "animation_duration_fast", "value": "150" },
    { "name": "animation_duration_normal", "value": "300" },
    { "name": "animation_duration_slow", "value": "500" }
  ]
}
```

### Theme Manager (State Management V2)

```typescript
@ObservedV2
export class ThemeManager {
  @Trace isDark: boolean = false;
  @Trace followSystem: boolean = true;
  
  private static instance: ThemeManager;
  
  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }
  
  // Called from AbilityStage.onConfigurationUpdate
  setSystemColorMode(mode: ConfigurationConstant.ColorMode): void {
    if (this.followSystem) {
      this.isDark = (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
    }
  }
  
  // Manual theme toggle
  toggleTheme(): void {
    this.followSystem = false;
    this.isDark = !this.isDark;
  }
  
  // Enable/disable system follow
  setFollowSystem(follow: boolean): void {
    this.followSystem = follow;
  }
}
```

### Theme Monitoring in AbilityStage

```typescript
export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // Initialize theme on app start
    const colorMode = this.context.config.colorMode;
    ThemeManager.getInstance().setSystemColorMode(colorMode);
  }
  
  onConfigurationUpdate(newConfig: Configuration): void {
    // Update theme when system changes
    ThemeManager.getInstance().setSystemColorMode(newConfig.colorMode);
  }
}
```

### Using Theme in Components

```typescript
@ComponentV2
struct ThemedButton {
  @Param label: string = '';
  @Param onTap: () => void = () => {};
  
  build() {
    Button(this.label)
      .backgroundColor($r('app.color.button_background'))
      .fontColor($r('app.color.button_text'))
      .fontSize($r('app.float.font_size_md'))
      .borderRadius($r('app.float.border_radius_md'))
      .padding({
        left: $r('app.float.spacing_lg'),
        right: $r('app.float.spacing_lg'),
        top: $r('app.float.spacing_sm'),
        bottom: $r('app.float.spacing_sm')
      })
      .onClick(() => this.onTap())
  }
}
```

### System Resources

For common UI elements, use HarmonyOS system resources:

```typescript
Text('Primary Text')
  .fontColor($r('sys.color.ohos_id_color_text_primary'))
  .fontSize($r('sys.float.ohos_id_text_size_body1'))

Divider()
  .color($r('sys.color.ohos_id_color_list_separator'))
```

### Animation Specifications

```typescript
// Standard animation curves
const EASE_IN_OUT = Curve.EaseInOut;
const EASE_OUT = Curve.EaseOut;
const SPRING = Curve.Spring;

// Animation durations from design tokens
const DURATION_FAST = 150;    // Quick transitions
const DURATION_NORMAL = 300;  // Standard transitions
const DURATION_SLOW = 500;    // Emphasis transitions

// Example usage
Button('Animate')
  .onClick(() => {
    animateTo({
      duration: DURATION_NORMAL,
      curve: EASE_IN_OUT
    }, () => {
      this.visible = !this.visible;
    });
  })
```


## UI Component Specifications

### Component Architecture Principles

1. **State Management V2**: All components use @ComponentV2, @Local, @Param
2. **Reusability**: Components are self-contained and reusable
3. **Theming**: All colors and dimensions use resource references
4. **Accessibility**: Proper labels and semantic structure
5. **Performance**: Minimal re-renders through precise state tracking

### Core Components

#### 1. SidebarComponent

Displays workspace tree with folders and requests.

```typescript
@ComponentV2
export struct SidebarComponent {
  @Param items: SidebarItem[] = [];
  @Param selectedRequest: HttpRequest | null = null;
  @Param onRequestCreate: () => void = () => {};
  @Param onFolderCreate: () => void = () => {};
  @Param onRequestSelect: (request: HttpRequest) => void = () => {};
  
  @Local filterText: string = '';
  @Local expandedFolders: Set<string> = new Set();
  
  build() {
    Column() {
      // Search/Filter Bar
      Row() {
        TextInput({ placeholder: 'Filter requests...' })
          .backgroundColor($r('app.color.input_background'))
          .borderColor($r('app.color.input_border'))
          .borderRadius($r('app.float.border_radius_md'))
          .fontSize($r('app.float.font_size_sm'))
          .padding($r('app.float.spacing_sm'))
          .onChange((value: string) => {
            this.filterText = value;
          })
      }
      .padding($r('app.float.spacing_md'))
      
      // Action Buttons
      Row() {
        Button('New Request')
          .fontSize($r('app.float.font_size_sm'))
          .onClick(() => this.onRequestCreate())
        
        Button('New Folder')
          .fontSize($r('app.float.font_size_sm'))
          .onClick(() => this.onFolderCreate())
      }
      .padding($r('app.float.spacing_md'))
      .justifyContent(FlexAlign.SpaceBetween)
      
      // Tree View
      List() {
        ForEach(this.getFilteredItems(), (item: SidebarItem) => {
          ListItem() {
            if (item.type === 'folder') {
              FolderItemComponent({
                folder: item.data as Folder,
                level: item.level,
                isExpanded: this.expandedFolders.has(item.data.id),
                onToggle: () => this.toggleFolder(item.data.id)
              })
            } else {
              RequestItemComponent({
                request: item.data as HttpRequest,
                level: item.level,
                isSelected: this.selectedRequest?.id === item.data.id,
                onSelect: () => this.onRequestSelect(item.data as HttpRequest)
              })
            }
          }
        })
      }
      .layoutWeight(1)
      .divider({
        strokeWidth: 1,
        color: $r('app.color.divider')
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sidebar_background'))
  }
  
  private getFilteredItems(): SidebarItem[] {
    if (!this.filterText) return this.items;
    
    const lowerFilter = this.filterText.toLowerCase();
    return this.items.filter(item => {
      if (item.type === 'request') {
        const req = item.data as HttpRequest;
        return req.name.toLowerCase().includes(lowerFilter) ||
               req.url.toLowerCase().includes(lowerFilter);
      }
      return true; // Show folders if they have matching children
    });
  }
  
  private toggleFolder(folderId: string): void {
    if (this.expandedFolders.has(folderId)) {
      this.expandedFolders.delete(folderId);
    } else {
      this.expandedFolders.add(folderId);
    }
  }
}
```

#### 2. RequestEditorComponent

Edits HTTP request configuration.

```typescript
@ComponentV2
export struct RequestEditorComponent {
  @Param request: HttpRequest;
  @Param onExecute: () => void = () => {};
  @Param isLoading: boolean = false;
  
  @Local activeTab: string = 'params';
  
  build() {
    Column() {
      // Request Line
      Row() {
        Select([
          { value: 'GET' },
          { value: 'POST' },
          { value: 'PUT' },
          { value: 'DELETE' },
          { value: 'PATCH' }
        ])
          .selected(this.getMethodIndex())
          .value(this.request.method)
          .onSelect((index: number) => {
            this.request.method = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'][index] as HttpMethod;
          })
          .width(100)
        
        TextInput({ text: this.request.url })
          .layoutWeight(1)
          .backgroundColor($r('app.color.input_background'))
          .borderColor($r('app.color.input_border'))
          .onChange((value: string) => {
            this.request.url = value;
          })
        
        Button(this.isLoading ? 'Cancel' : 'Send')
          .backgroundColor($r('app.color.primary'))
          .fontColor($r('app.color.button_text'))
          .onClick(() => this.onExecute())
      }
      .padding($r('app.float.spacing_md'))
      .width('100%')
      
      // Tabs
      Tabs({ barPosition: BarPosition.Start }) {
        TabContent() {
          QueryParamsEditor({ params: this.request.query_params })
        }.tabBar('Params')
        
        TabContent() {
          HeadersEditor({ headers: this.request.headers })
        }.tabBar('Headers')
        
        TabContent() {
          BodyEditor({
            body: this.request.body,
            bodyType: this.request.body_type,
            onBodyChange: (body: string) => { this.request.body = body; },
            onBodyTypeChange: (type: BodyType) => { this.request.body_type = type; }
          })
        }.tabBar('Body')
        
        TabContent() {
          AuthEditor({ auth: this.request.auth })
        }.tabBar('Auth')
      }
      .layoutWeight(1)
      .barMode(BarMode.Scrollable)
      .onChange((index: number) => {
        const tabs = ['params', 'headers', 'body', 'auth'];
        this.activeTab = tabs[index];
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }
  
  private getMethodIndex(): number {
    const methods = ['GET', 'POST', 'PUT', 'DELETE', 'PATCH'];
    return methods.indexOf(this.request.method);
  }
}
```

#### 3. ResponseViewerComponent

Displays HTTP response with formatting.

```typescript
@ComponentV2
export struct ResponseViewerComponent {
  @Param response: string = '';
  @Param status: number = 0;
  @Param time: number = 0;
  @Param bodySize: number = 0;
  
  @Local activeTab: string = 'body';
  @Local viewMode: string = 'pretty'; // 'pretty' or 'raw'
  
  build() {
    Column() {
      // Status Bar
      Row() {
        Text(`Status: ${this.status}`)
          .fontColor(this.getStatusColor())
          .fontSize($r('app.float.font_size_sm'))
        
        Text(`Time: ${this.time}ms`)
          .fontSize($r('app.float.font_size_sm'))
          .margin({ left: $r('app.float.spacing_md') })
        
        Text(`Size: ${this.formatSize(this.bodySize)}`)
          .fontSize($r('app.float.font_size_sm'))
          .margin({ left: $r('app.float.spacing_md') })
      }
      .padding($r('app.float.spacing_md'))
      .width('100%')
      .backgroundColor($r('app.color.surface'))
      
      // View Mode Toggle
      Row() {
        Button('Pretty')
          .type(this.viewMode === 'pretty' ? ButtonType.Normal : ButtonType.Capsule)
          .onClick(() => { this.viewMode = 'pretty'; })
        
        Button('Raw')
          .type(this.viewMode === 'raw' ? ButtonType.Normal : ButtonType.Capsule)
          .onClick(() => { this.viewMode = 'raw'; })
      }
      .padding($r('app.float.spacing_sm'))
      
      // Response Body
      Scroll() {
        Text(this.formatResponse())
          .fontFamily('monospace')
          .fontSize($r('app.float.font_size_sm'))
          .padding($r('app.float.spacing_md'))
      }
      .layoutWeight(1)
      .backgroundColor($r('app.color.surface'))
    }
    .width('100%')
    .height('100%')
  }
  
  private getStatusColor(): ResourceStr {
    if (this.status >= 200 && this.status < 300) {
      return $r('app.color.success');
    } else if (this.status >= 400) {
      return $r('app.color.danger');
    }
    return $r('app.color.text_primary');
  }
  
  private formatResponse(): string {
    if (this.viewMode === 'raw') return this.response;
    
    try {
      const parsed = JSON.parse(this.response);
      return JSON.stringify(parsed, null, 2);
    } catch {
      return this.response;
    }
  }
  
  private formatSize(bytes: number): string {
    if (bytes < 1024) return `${bytes} B`;
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`;
    return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
  }
}
```

#### 4. WorkspaceHeader

Top navigation bar with workspace and environment selectors.

```typescript
@ComponentV2
export struct WorkspaceHeader {
  @Param workspaces: Workspace[] = [];
  @Param activeWorkspace: Workspace | null = null;
  @Param environments: Environment[] = [];
  @Param activeEnvironment: Environment | null = null;
  @Param onWorkspaceSelect: (ws: Workspace) => void = () => {};
  @Param onEnvironmentSelect: (env: Environment | null) => void = () => {};
  @Param onOpenSettings: () => void = () => {};
  
  build() {
    Row() {
      // Workspace Selector
      Select(this.workspaces.map(ws => ({ value: ws.name })))
        .selected(this.getWorkspaceIndex())
        .value(this.activeWorkspace?.name || 'Select Workspace')
        .onSelect((index: number) => {
          this.onWorkspaceSelect(this.workspaces[index]);
        })
        .width(200)
      
      // Environment Selector
      Select([
        { value: 'No Environment' },
        ...this.environments.map(env => ({ value: env.name }))
      ])
        .selected(this.getEnvironmentIndex())
        .value(this.activeEnvironment?.name || 'No Environment')
        .onSelect((index: number) => {
          if (index === 0) {
            this.onEnvironmentSelect(null);
          } else {
            this.onEnvironmentSelect(this.environments[index - 1]);
          }
        })
        .width(200)
        .margin({ left: $r('app.float.spacing_md') })
      
      Blank()
      
      // Settings Button
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_settings'))
          .width(24)
          .height(24)
          .fillColor($r('app.color.text_primary'))
      }
      .backgroundColor($r('app.color.surface'))
      .onClick(() => this.onOpenSettings())
    }
    .width('100%')
    .height(56)
    .padding({
      left: $r('app.float.spacing_lg'),
      right: $r('app.float.spacing_lg')
    })
    .backgroundColor($r('app.color.header_background'))
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }
  
  private getWorkspaceIndex(): number {
    if (!this.activeWorkspace) return 0;
    return this.workspaces.findIndex(ws => ws.id === this.activeWorkspace!.id);
  }
  
  private getEnvironmentIndex(): number {
    if (!this.activeEnvironment) return 0;
    return this.environments.findIndex(env => env.id === this.activeEnvironment!.id) + 1;
  }
}
```


## Navigation Design

Using HarmonyOS Navigation component for proper route stack management.

### Navigation Structure

```typescript
@Entry
@ComponentV2
struct AppNavigation {
  @Local navPathStack: NavPathStack = new NavPathStack();
  
  build() {
    Navigation(this.navPathStack) {
      // Main page is the default route
      MainPage()
    }
    .mode(NavigationMode.Stack)
    .hideBackButton(true)
    .navDestination(this.buildNavDestination)
  }
  
  @Builder
  buildNavDestination(name: string, param: Object) {
    if (name === 'workspace') {
      WorkspacePage({ workspace: param as Workspace })
    } else if (name === 'settings') {
      SettingsPage()
    } else if (name === 'environment-editor') {
      EnvironmentEditorPage({ environment: param as Environment })
    }
  }
}
```

### Route Definitions

```typescript
export enum AppRoute {
  MAIN = 'main',
  WORKSPACE = 'workspace',
  SETTINGS = 'settings',
  ENVIRONMENT_EDITOR = 'environment-editor',
  REQUEST_HISTORY = 'request-history'
}

export class NavigationService {
  static navigate(
    navStack: NavPathStack,
    route: AppRoute,
    param?: Object
  ): void {
    navStack.pushPath({ name: route, param: param });
  }
  
  static goBack(navStack: NavPathStack): void {
    navStack.pop();
  }
  
  static replace(
    navStack: NavPathStack,
    route: AppRoute,
    param?: Object
  ): void {
    navStack.replacePath({ name: route, param: param });
  }
}
```

### Page Lifecycle

```typescript
@ComponentV2
struct WorkspacePage {
  @Param workspace: Workspace;
  @Local isLoading: boolean = true;
  
  aboutToAppear(): void {
    // Load workspace data
    this.loadWorkspaceData();
  }
  
  aboutToDisappear(): void {
    // Cleanup resources
    this.cleanup();
  }
  
  onPageShow(): void {
    // Refresh data when page becomes visible
    this.refreshData();
  }
  
  onPageHide(): void {
    // Save state when page is hidden
    this.saveState();
  }
  
  build() {
    // Page content
  }
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Workspace Loading Completeness
*For any* database state containing workspaces, loading all workspaces should return every workspace record without loss or duplication.
**Validates: Requirements 1.1**

### Property 2: Request ID Uniqueness and Format
*For any* newly created request, the generated ID should be unique across all requests and start with the prefix "rq".
**Validates: Requirements 2.1**

### Property 3: Request Deletion Cascade
*For any* request with associated responses, deleting the request should remove all associated response records and response body files from storage.
**Validates: Requirements 2.7**

### Property 4: Folder Assignment Consistency
*For any* request and any target folder, moving the request to the folder should result in the request's folder_id matching the target folder's id.
**Validates: Requirements 3.2**

### Property 5: HTTP Request Execution
*For any* valid HTTP request configuration, executing the request should produce a response with a status code, headers, and body.
**Validates: Requirements 4.1**

### Property 6: Request Cancellation
*For any* in-flight HTTP request, cancelling it should abort the network operation and set the response state to "cancelled".
**Validates: Requirements 4.8**

### Property 7: Template Variable Substitution
*For any* string containing {{ variableName }} and a defined variable, substitution should replace the placeholder with the variable's value.
**Validates: Requirements 5.3, 21.1**

### Property 8: Undefined Variable Preservation
*For any* string containing {{ variableName }} where the variable is undefined, the placeholder should remain unchanged in the output.
**Validates: Requirements 5.5**

### Property 9: Basic Auth Header Generation
*For any* username and password combination, Basic Auth should generate a valid Authorization header with properly base64-encoded credentials.
**Validates: Requirements 6.2**

### Property 10: Database Persistence Round-Trip
*For any* data model (workspace, request, folder, environment), saving to database then loading should produce an equivalent object.
**Validates: Requirements 9.1, 9.2**

### Property 11: State Management V2 Reactivity
*For any* @Trace decorated property change, only UI components that reference that specific property should re-render.
**Validates: Requirements 11.4**

### Property 12: Array Mutation Observation
*For any* array with @Trace decorator, mutations (push, pop, splice) should trigger UI updates for components observing the array.
**Validates: Requirements 11.5**

### Property 13: Cookie Storage from Response
*For any* HTTP response containing Set-Cookie headers, all cookies should be parsed and stored in the cookie jar with correct domain and path.
**Validates: Requirements 13.1**

### Property 14: Cookie Inclusion in Requests
*For any* HTTP request, cookies from the jar matching the request's domain and path should be included in the Cookie header.
**Validates: Requirements 13.2**

### Property 15: Theme Auto-Update
*For any* system theme change event, if auto-theme is enabled, the application theme should update to match the system theme.
**Validates: Requirements 15.3**

### Property 16: Nested Template Resolution
*For any* string with nested template expressions {{ outer {{ inner }} }}, resolution should correctly evaluate from innermost to outermost.
**Validates: Requirements 21.5**

### Property 17: Response Body Storage Round-Trip
*For any* response body, writing to file then reading from file should produce identical content.
**Validates: Requirements 22.1, 22.4**

### Property 18: Folder Auth Inheritance
*For any* folder with authentication configured and any child request without authentication, the request should inherit the folder's authentication.
**Validates: Requirements 24.1**

### Property 19: Explicit Auth Override
*For any* request with explicit authentication and any parent folder with authentication, the request's authentication should take precedence.
**Validates: Requirements 24.3**

### Property 20: Request Duplication Uniqueness
*For any* request, duplicating it should create a new request with a different unique ID but identical configuration.
**Validates: Requirements 25.1**

### Property 21: Recursive Folder Duplication
*For any* folder with nested children, duplicating the folder should recursively duplicate all children while preserving the tree structure.
**Validates: Requirements 25.3**

### Property 22: Multi-Part Boundary Generation
*For any* multi-part form data, the Content-Type header should include a unique boundary string that doesn't appear in the form data.
**Validates: Requirements 27.4**

### Property 23: URL Encoding Correctness
*For any* form field value containing special characters, URL encoding should produce a string that decodes back to the original value.
**Validates: Requirements 28.4**

### Property 24: Drag-Drop Database Update
*For any* request dropped into a folder, the database should reflect the updated folder_id and recalculated sort_priority.
**Validates: Requirements 39.2**


## Error Handling

### Error Categories

1. **Network Errors**: Connection failures, timeouts, DNS resolution failures
2. **Database Errors**: Query failures, constraint violations, corruption
3. **Validation Errors**: Invalid input data, malformed URLs, missing required fields
4. **File System Errors**: Permission denied, disk full, file not found
5. **Authentication Errors**: Invalid credentials, expired tokens, OAuth failures

### Error Handling Strategy

```typescript
export class AppError extends Error {
  constructor(
    public code: string,
    public message: string,
    public category: ErrorCategory,
    public details?: any
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export enum ErrorCategory {
  NETWORK = 'network',
  DATABASE = 'database',
  VALIDATION = 'validation',
  FILE_SYSTEM = 'file_system',
  AUTHENTICATION = 'authentication'
}

export class ErrorHandler {
  static handle(error: Error | AppError): void {
    if (error instanceof AppError) {
      this.handleAppError(error);
    } else {
      this.handleUnknownError(error);
    }
  }
  
  private static handleAppError(error: AppError): void {
    console.error(`[${error.category}] ${error.code}: ${error.message}`, error.details);
    
    // Show user-friendly error message
    promptAction.showToast({
      message: this.getUserMessage(error),
      duration: 3000
    });
    
    // Log to analytics if needed
    this.logError(error);
  }
  
  private static getUserMessage(error: AppError): string {
    switch (error.category) {
      case ErrorCategory.NETWORK:
        return 'Network error. Please check your connection.';
      case ErrorCategory.DATABASE:
        return 'Database error. Please try again.';
      case ErrorCategory.VALIDATION:
        return error.message; // Validation messages are user-friendly
      case ErrorCategory.FILE_SYSTEM:
        return 'File system error. Please check permissions.';
      case ErrorCategory.AUTHENTICATION:
        return 'Authentication failed. Please check your credentials.';
      default:
        return 'An unexpected error occurred.';
    }
  }
}
```

### Database Error Recovery

```typescript
export class DatabaseManager {
  async executeWithRetry<T>(
    operation: () => Promise<T>,
    maxRetries: number = 3
  ): Promise<T> {
    let lastError: Error;
    
    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error as Error;
        console.warn(`Database operation failed (attempt ${attempt + 1}/${maxRetries})`, error);
        
        // Wait before retry with exponential backoff
        await this.delay(Math.pow(2, attempt) * 100);
      }
    }
    
    throw new AppError(
      'DB_OPERATION_FAILED',
      'Database operation failed after retries',
      ErrorCategory.DATABASE,
      { lastError }
    );
  }
  
  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Network Error Handling

```typescript
export class RequestExecutor {
  static async executeWithErrorHandling(
    request: HttpRequest,
    variables: Map<string, string>
  ): Promise<HttpResponse> {
    try {
      return await this.execute(request, variables);
    } catch (error) {
      if (this.isNetworkError(error)) {
        throw new AppError(
          'NETWORK_ERROR',
          'Failed to connect to server',
          ErrorCategory.NETWORK,
          { originalError: error }
        );
      } else if (this.isTimeoutError(error)) {
        throw new AppError(
          'TIMEOUT_ERROR',
          'Request timed out',
          ErrorCategory.NETWORK,
          { originalError: error }
        );
      } else {
        throw error;
      }
    }
  }
  
  private static isNetworkError(error: any): boolean {
    return error.code === 'ECONNREFUSED' || 
           error.code === 'ENOTFOUND' ||
           error.code === 'ENETUNREACH';
  }
  
  private static isTimeoutError(error: any): boolean {
    return error.code === 'ETIMEDOUT' || error.code === 'ESOCKETTIMEDOUT';
  }
}
```

### Validation

```typescript
export class Validator {
  static validateUrl(url: string): void {
    if (!url || url.trim().length === 0) {
      throw new AppError(
        'INVALID_URL',
        'URL cannot be empty',
        ErrorCategory.VALIDATION
      );
    }
    
    try {
      new URL(url);
    } catch {
      throw new AppError(
        'INVALID_URL',
        'Invalid URL format',
        ErrorCategory.VALIDATION,
        { url }
      );
    }
  }
  
  static validateRequestName(name: string): void {
    if (!name || name.trim().length === 0) {
      throw new AppError(
        'INVALID_NAME',
        'Request name cannot be empty',
        ErrorCategory.VALIDATION
      );
    }
    
    if (name.length > 255) {
      throw new AppError(
        'INVALID_NAME',
        'Request name too long (max 255 characters)',
        ErrorCategory.VALIDATION
      );
    }
  }
}
```

## Testing Strategy

### Unit Testing

Unit tests verify specific functions and components in isolation.

**Framework**: ArkTS Test Framework (built-in)

**Coverage Areas**:
- Template engine variable substitution
- Authentication header generation
- Cookie parsing and matching
- URL encoding/decoding
- Data model validation
- Repository CRUD operations

**Example Unit Test**:
```typescript
import { describe, it, expect } from '@ohos/hypium';
import { TemplateEngine } from '../services/TemplateEngine';

describe('TemplateEngine', () => {
  it('should substitute simple variables', () => {
    const variables = new Map([['host', 'api.example.com']]);
    const result = TemplateEngine.resolve('https://{{ host }}/users', variables);
    expect(result).assertEqual('https://api.example.com/users');
  });
  
  it('should leave undefined variables unchanged', () => {
    const variables = new Map();
    const result = TemplateEngine.resolve('{{ undefined }}', variables);
    expect(result).assertEqual('{{ undefined }}');
  });
  
  it('should execute timestamp function', () => {
    const variables = new Map();
    const result = TemplateEngine.resolve('{{ timestamp() }}', variables);
    expect(parseInt(result)).toBeGreaterThan(0);
  });
});
```

### Property-Based Testing

Property-based tests verify universal properties across many randomly generated inputs.

**Framework**: fast-check (JavaScript property testing library, can be used in ArkTS)

**Configuration**: Minimum 100 iterations per property

**Coverage Areas**:
- Database persistence round-trips
- Template resolution with various inputs
- Cookie domain/path matching
- Folder hierarchy operations
- Request duplication
- Array mutation observation

**Example Property Test**:
```typescript
import { describe, it } from '@ohos/hypium';
import * as fc from 'fast-check';
import { HttpRequest } from '../model/HttpRequest';
import { RequestRepository } from '../database/RequestRepository';

describe('Request Persistence Properties', () => {
  /**
   * Feature: yaak-hmos-complete, Property 10: Database Persistence Round-Trip
   * Validates: Requirements 9.1, 9.2
   */
  it('should preserve request data through save/load cycle', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.record({
          name: fc.string({ minLength: 1, maxLength: 255 }),
          url: fc.webUrl(),
          method: fc.constantFrom('GET', 'POST', 'PUT', 'DELETE', 'PATCH'),
          body: fc.option(fc.string(), { nil: null })
        }),
        async (requestData) => {
          // Create request with random data
          const request = new HttpRequest();
          request.id = generateUUID();
          request.workspace_id = 'test-workspace';
          request.name = requestData.name;
          request.url = requestData.url;
          request.method = requestData.method;
          request.body = requestData.body;
          
          // Save to database
          await RequestRepository.createRequest(request);
          
          // Load from database
          const loaded = await RequestRepository.getRequestById(request.id);
          
          // Verify all fields match
          expect(loaded.name).assertEqual(request.name);
          expect(loaded.url).assertEqual(request.url);
          expect(loaded.method).assertEqual(request.method);
          expect(loaded.body).assertEqual(request.body);
          
          // Cleanup
          await RequestRepository.deleteRequest(request.id);
        }
      ),
      { numRuns: 100 }
    );
  });
  
  /**
   * Feature: yaak-hmos-complete, Property 2: Request ID Uniqueness and Format
   * Validates: Requirements 2.1
   */
  it('should generate unique IDs with correct prefix', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(fc.string({ minLength: 1, maxLength: 100 }), { minLength: 10, maxLength: 50 }),
        async (names) => {
          const ids = new Set<string>();
          
          for (const name of names) {
            const request = new HttpRequest();
            request.id = generateRequestId();
            request.name = name;
            request.workspace_id = 'test-workspace';
            
            // Check prefix
            expect(request.id.startsWith('rq')).assertTrue();
            
            // Check uniqueness
            expect(ids.has(request.id)).assertFalse();
            ids.add(request.id);
          }
        }
      ),
      { numRuns: 100 }
    );
  });
});
```

### Integration Testing

Integration tests verify interactions between multiple components.

**Coverage Areas**:
- Request execution flow (template resolution → auth → HTTP call → response storage)
- Database transactions with multiple operations
- Cookie storage and retrieval across requests
- Folder hierarchy with inheritance
- Theme switching with UI updates

**Example Integration Test**:
```typescript
describe('Request Execution Flow', () => {
  it('should execute request with variable substitution and auth', async () => {
    // Setup
    const workspace = await createTestWorkspace();
    const environment = await createTestEnvironment(workspace.id, {
      variables: [{ name: 'host', value: 'api.example.com' }]
    });
    const request = await createTestRequest(workspace.id, {
      url: 'https://{{ host }}/users',
      method: 'GET',
      auth: { type: 'bearer', bearer_token: 'test-token' }
    });
    
    // Execute
    const variables = EnvironmentService.mergeVariables([environment]);
    const response = await RequestExecutor.execute(request, variables);
    
    // Verify
    expect(response.request.url).assertEqual('https://api.example.com/users');
    expect(response.request.header['Authorization']).assertEqual('Bearer test-token');
    
    // Cleanup
    await cleanupTestData();
  });
});
```

### Performance Testing

**Key Metrics**:
- Database query time: < 50ms for simple queries
- Request execution time: Depends on network, but overhead < 10ms
- UI render time: < 16ms per frame (60 FPS)
- Memory usage: < 200MB for typical workload
- App startup time: < 2 seconds

**Testing Approach**:
- Use HarmonyOS Profiler for performance analysis
- Monitor frame rate during UI interactions
- Track memory usage over extended sessions
- Measure database query performance with large datasets


## Security Considerations

### Data Encryption

**Sensitive Data Storage**:
- Environment variables marked as `is_secret` should be encrypted at rest
- Authentication credentials (passwords, tokens) should be encrypted
- Use HarmonyOS HUKS (HarmonyOS Universal KeyStore) for key management

```typescript
import cryptoFramework from '@ohos.security.cryptoFramework';
import huks from '@ohos.security.huks';

export class EncryptionService {
  private static readonly KEY_ALIAS = 'yaak_encryption_key';
  
  static async encryptSensitiveData(data: string): Promise<string> {
    // Generate or retrieve encryption key from HUKS
    const key = await this.getOrCreateKey();
    
    // Encrypt data using AES-GCM
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    await cipher.init(cryptoFramework.CryptoMode.ENCRYPT_MODE, key, null);
    const encrypted = await cipher.doFinal({ data: stringToUint8Array(data) });
    
    return uint8ArrayToBase64(encrypted.data);
  }
  
  static async decryptSensitiveData(encryptedData: string): Promise<string> {
    const key = await this.getOrCreateKey();
    
    const cipher = cryptoFramework.createCipher('AES256|GCM|PKCS7');
    await cipher.init(cryptoFramework.CryptoMode.DECRYPT_MODE, key, null);
    const decrypted = await cipher.doFinal({ data: base64ToUint8Array(encryptedData) });
    
    return uint8ArrayToString(decrypted.data);
  }
  
  private static async getOrCreateKey(): Promise<cryptoFramework.Key> {
    // Check if key exists in HUKS
    const keyExists = await huks.isKeyItemExist(this.KEY_ALIAS, {});
    
    if (!keyExists) {
      // Generate new key
      const properties: huks.HuksOptions = {
        properties: [
          { tag: huks.HuksTag.HUKS_TAG_ALGORITHM, value: huks.HuksKeyAlg.HUKS_ALG_AES },
          { tag: huks.HuksTag.HUKS_TAG_KEY_SIZE, value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256 },
          { tag: huks.HuksTag.HUKS_TAG_PURPOSE, value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT }
        ]
      };
      await huks.generateKeyItem(this.KEY_ALIAS, properties);
    }
    
    // Export key for use with cryptoFramework
    const keyData = await huks.exportKeyItem(this.KEY_ALIAS, {});
    return cryptoFramework.createSymKey(keyData.outData);
  }
}
```

### Certificate Validation

**SSL/TLS Certificate Handling**:
- By default, validate all SSL certificates
- Allow users to disable validation for self-signed certificates (with warning)
- Store certificate exceptions per workspace

```typescript
export class CertificateValidator {
  static async validateCertificate(
    url: string,
    workspace: Workspace
  ): Promise<boolean> {
    if (!workspace.settings.validate_certificates) {
      return true; // User disabled validation
    }
    
    // Check if certificate is in exception list
    if (this.isInExceptionList(url, workspace)) {
      return true;
    }
    
    // Perform standard validation
    return true; // HarmonyOS HTTP module handles this automatically
  }
  
  static async addCertificateException(
    url: string,
    workspace: Workspace
  ): Promise<void> {
    // Store exception in workspace settings
    // Show warning to user about security implications
  }
}
```

### Input Sanitization

**Prevent Injection Attacks**:
- Sanitize all user input before database queries (use parameterized queries)
- Validate URLs before making requests
- Escape special characters in template variables

```typescript
export class InputSanitizer {
  static sanitizeForDatabase(input: string): string {
    // RDB Store uses parameterized queries, so this is handled automatically
    // Just validate input length and format
    if (input.length > 10000) {
      throw new AppError('INPUT_TOO_LONG', 'Input exceeds maximum length', ErrorCategory.VALIDATION);
    }
    return input;
  }
  
  static sanitizeUrl(url: string): string {
    // Remove any potentially dangerous protocols
    const dangerous = ['javascript:', 'data:', 'vbscript:'];
    const lower = url.toLowerCase();
    
    for (const protocol of dangerous) {
      if (lower.startsWith(protocol)) {
        throw new AppError('INVALID_URL', 'Dangerous URL protocol detected', ErrorCategory.VALIDATION);
      }
    }
    
    return url;
  }
}
```

### Authentication Token Storage

**Secure Token Management**:
- Store OAuth tokens encrypted
- Implement token refresh logic
- Clear tokens on logout

```typescript
@ObservedV2
export class AuthConfig {
  @Trace type: AuthType = 'none';
  @Trace bearer_token: string = ''; // Encrypted in database
  @Trace oauth2_access_token: string = ''; // Encrypted
  @Trace oauth2_refresh_token: string = ''; // Encrypted
  @Trace oauth2_expires_at: number = 0;
  
  async getDecryptedToken(): Promise<string> {
    if (this.type === 'bearer') {
      return await EncryptionService.decryptSensitiveData(this.bearer_token);
    } else if (this.type === 'oauth2') {
      // Check if token expired
      if (Date.now() >= this.oauth2_expires_at) {
        await this.refreshOAuth2Token();
      }
      return await EncryptionService.decryptSensitiveData(this.oauth2_access_token);
    }
    return '';
  }
  
  private async refreshOAuth2Token(): Promise<void> {
    // Implement OAuth2 token refresh flow
  }
}
```

## Performance Considerations

### Database Optimization

**Indexing Strategy**:
- Index foreign keys (workspace_id, folder_id, request_id)
- Index sort_priority for efficient ordering
- Index created_at for time-based queries

**Query Optimization**:
- Use batch operations for multiple inserts/updates
- Limit query results to prevent memory issues
- Use transactions for related operations

```typescript
export class RequestRepository {
  // Batch insert for better performance
  static async batchCreateRequests(requests: HttpRequest[]): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) throw new Error('Database not initialized');
    
    const transaction = await store.createTransaction();
    try {
      for (const request of requests) {
        const valueBucket = this.toValuesBucket(request);
        await transaction.insert('http_requests', valueBucket);
      }
      await transaction.commit();
    } catch (error) {
      await transaction.rollback();
      throw error;
    }
  }
  
  // Paginated query for large result sets
  static async getRequestsByWorkspaceIdPaginated(
    workspaceId: string,
    page: number,
    pageSize: number = 50
  ): Promise<HttpRequest[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return [];
    
    const predicates = new relationalStore.RdbPredicates('http_requests');
    predicates.equalTo('workspace_id', workspaceId);
    predicates.orderByAsc('sort_priority');
    predicates.limit(pageSize, page * pageSize);
    
    const resultSet = await store.query(predicates, []);
    return this.parseResultSet(resultSet);
  }
}
```

### Memory Management

**Response Body Storage**:
- Store large response bodies on disk, not in memory
- Implement LRU cache for frequently accessed responses
- Clean up old response files periodically

```typescript
export class ResponseCache {
  private static cache: Map<string, string> = new Map();
  private static readonly MAX_CACHE_SIZE = 50;
  private static accessOrder: string[] = [];
  
  static async getResponseBody(responseId: string, bodyPath: string): Promise<string> {
    // Check cache first
    if (this.cache.has(responseId)) {
      this.updateAccessOrder(responseId);
      return this.cache.get(responseId)!;
    }
    
    // Load from disk
    const body = await ResponseStorageService.loadResponseBody(bodyPath);
    
    // Add to cache
    this.addToCache(responseId, body);
    
    return body;
  }
  
  private static addToCache(responseId: string, body: string): void {
    // Evict oldest if cache is full
    if (this.cache.size >= this.MAX_CACHE_SIZE) {
      const oldest = this.accessOrder.shift();
      if (oldest) {
        this.cache.delete(oldest);
      }
    }
    
    this.cache.set(responseId, body);
    this.accessOrder.push(responseId);
  }
  
  private static updateAccessOrder(responseId: string): void {
    const index = this.accessOrder.indexOf(responseId);
    if (index > -1) {
      this.accessOrder.splice(index, 1);
      this.accessOrder.push(responseId);
    }
  }
}
```

### UI Performance

**State Management V2 Benefits**:
- Precise reactivity: Only affected components re-render
- Deep observation without performance penalty
- Minimal memory overhead

**Rendering Optimization**:
- Use LazyForEach for large lists
- Implement virtual scrolling for request history
- Debounce text input to reduce updates

```typescript
@ComponentV2
struct RequestList {
  @Param requests: HttpRequest[] = [];
  @Local visibleRange: { start: number, end: number } = { start: 0, end: 20 };
  
  build() {
    List() {
      LazyForEach(
        new RequestDataSource(this.requests),
        (request: HttpRequest) => {
          ListItem() {
            RequestItemComponent({ request: request })
          }
        },
        (request: HttpRequest) => request.id
      )
    }
    .onScrollIndex((start: number, end: number) => {
      this.visibleRange = { start, end };
    })
  }
}

class RequestDataSource implements IDataSource {
  private requests: HttpRequest[];
  
  constructor(requests: HttpRequest[]) {
    this.requests = requests;
  }
  
  totalCount(): number {
    return this.requests.length;
  }
  
  getData(index: number): HttpRequest {
    return this.requests[index];
  }
  
  registerDataChangeListener(listener: DataChangeListener): void {
    // Implement if needed
  }
  
  unregisterDataChangeListener(listener: DataChangeListener): void {
    // Implement if needed
  }
}
```

### Network Performance

**Request Optimization**:
- Reuse HTTP connections when possible
- Implement request queuing to prevent overwhelming the network
- Support HTTP/2 for multiplexing

```typescript
export class RequestQueue {
  private static queue: Array<() => Promise<any>> = [];
  private static activeRequests: number = 0;
  private static readonly MAX_CONCURRENT = 6;
  
  static async enqueue<T>(operation: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push(async () => {
        try {
          const result = await operation();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });
      
      this.processQueue();
    });
  }
  
  private static async processQueue(): Promise<void> {
    while (this.activeRequests < this.MAX_CONCURRENT && this.queue.length > 0) {
      const operation = this.queue.shift();
      if (operation) {
        this.activeRequests++;
        operation().finally(() => {
          this.activeRequests--;
          this.processQueue();
        });
      }
    }
  }
}
```

## Summary

This design document provides a comprehensive architecture for the Yaak HarmonyOS application following best practices:

1. **State Management V2**: Full adoption of @ObservedV2, @Trace, @ComponentV2 for optimal reactivity
2. **Theme System**: Resource qualifiers for seamless dark/light mode adaptation
3. **Database**: RDB Store with proper indexing, transactions, and migration strategy
4. **Navigation**: Navigation component for proper route management
5. **Services**: Clean separation of concerns with dedicated services for requests, templates, auth, cookies
6. **Components**: Reusable, themed components following HarmonyOS design guidelines
7. **Security**: Encryption for sensitive data, certificate validation, input sanitization
8. **Performance**: Database optimization, memory management, UI rendering optimization
9. **Testing**: Comprehensive strategy with unit tests, property-based tests, and integration tests
10. **Error Handling**: Robust error handling with user-friendly messages and retry logic

The design ensures a professional-grade API testing tool that leverages HarmonyOS capabilities while maintaining code quality and user experience.

