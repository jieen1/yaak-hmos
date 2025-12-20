/**
 * PostmanImporter - Parse Postman Collection v2/v2.1 format
 *
 * Supports:
 * - Postman Collection v2.0 and v2.1
 * - Recursive folder/item processing
 * - Request conversion with headers, body, auth
 * - Variable extraction to Environment
 * - Folder hierarchy preservation
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Environment, EnvironmentVariable } from '../model/Environment';
import { UUID } from '../common/UUID';
import type { ImportResult, ImportError } from './ImportService';

export class PostmanImporter {
  /**
   * Import Postman collection
   */
  static import(content: string, workspaceId: string): ImportResult {
    const result: ImportResult = {
      success: false,
      requestsCreated: 0,
      foldersCreated: 0,
      environmentsCreated: 0,
      requests: [],
      folders: [],
      environments: [],
      errors: []
    };

    try {
      const collection: ESObject = JSON.parse(content) as ESObject;
      
      // Validate Postman collection
      if (!collection.info) {
        const error: ImportError = {
          path: '',
          message: 'Invalid Postman collection: missing info object',
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      // Process collection variables as environment
      if (collection.variable && Array.isArray(collection.variable)) {
        const env = this.variablesToEnvironment(
          collection.variable as ESObject[],
          workspaceId,
          (collection.info as ESObject).name as string || 'Imported Variables'
        );
        if (env.variables.length > 0) {
          result.environments.push(env);
          result.environmentsCreated++;
        }
      }

      // Process items (requests and folders)
      if (collection.item && Array.isArray(collection.item)) {
        this.processItems(
          collection.item as ESObject[],
          null,
          workspaceId,
          result
        );
      }

      result.success = result.requestsCreated > 0 || result.foldersCreated > 0;
      return result;
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      const error: ImportError = {
        path: '',
        message: `Failed to parse Postman collection: ${errorMessage}`,
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }
  }


  /**
   * Process items recursively (folders and requests)
   */
  private static processItems(
    items: ESObject[],
    parentFolderId: string | null,
    workspaceId: string,
    result: ImportResult
  ): void {
    items.forEach((item: ESObject) => {
      if (!item) return;

      try {
        // Check if it's a folder (has item array) or request
        if (item.item && Array.isArray(item.item)) {
          // It's a folder
          const folder = this.createFolder(
            (item.name as string) || 'Unnamed Folder',
            workspaceId,
            parentFolderId
          );
          result.folders.push(folder);
          result.foldersCreated++;

          // Process child items
          this.processItems(
            item.item as ESObject[],
            folder.id,
            workspaceId,
            result
          );
        } else if (item.request) {
          // It's a request
          const request = this.itemToRequest(item, workspaceId, parentFolderId);
          result.requests.push(request);
          result.requestsCreated++;
        }
      } catch (e) {
        const errorMessage = e instanceof Error ? e.message : String(e);
        const error: ImportError = {
          path: (item.name as string) || 'Unknown item',
          message: errorMessage,
          recoverable: true
        };
        result.errors.push(error);
      }
    });
  }

  /**
   * Convert Postman item to HttpRequest
   */
  private static itemToRequest(
    item: ESObject,
    workspaceId: string,
    folderId: string | null
  ): HttpRequest {
    const request = new HttpRequest();
    request.id = UUID.randomUUID();
    request.workspace_id = workspaceId;
    request.folder_id = folderId;
    request.created_at = Date.now();
    request.updated_at = Date.now();

    // Set name
    request.name = (item.name as string) || 'Unnamed Request';

    const postmanRequest = item.request as ESObject;
    if (!postmanRequest) {
      return request;
    }

    // Set method
    request.method = ((postmanRequest.method as string) || 'GET').toUpperCase() as 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

    // Set URL
    const url = this.extractUrl(postmanRequest.url);
    request.url = url.baseUrl;
    request.query_params = url.queryParams;

    // Set headers
    request.headers = this.extractHeaders(postmanRequest.header);

    // Set body
    const bodyResult = this.extractBody(postmanRequest.body);
    request.body = bodyResult.body;
    request.body_type = bodyResult.bodyType;

    // Set auth
    if (postmanRequest.auth) {
      request.auth = this.extractAuth(postmanRequest.auth as ESObject);
    }

    return request;
  }

  /**
   * Extract URL from Postman URL object
   */
  private static extractUrl(url: ESObject | string | undefined): { baseUrl: string; queryParams: QueryParam[] } {
    const queryParams: QueryParam[] = [];
    
    if (!url) {
      return { baseUrl: '', queryParams: queryParams };
    }

    if (typeof url === 'string') {
      return this.parseUrlString(url);
    }

    // URL is an object
    let baseUrl = '';
    
    if (url.raw && typeof url.raw === 'string') {
      // Use raw URL but strip query params (we'll get them from query array)
      const rawUrl = url.raw as string;
      const questionIndex = rawUrl.indexOf('?');
      baseUrl = questionIndex > 0 ? rawUrl.substring(0, questionIndex) : rawUrl;
    } else {
      // Build URL from parts
      const protocol = (url.protocol as string) || 'https';
      const host = url.host as string[] | string | undefined;
      const path = url.path as string[] | string | undefined;

      let hostStr = '';
      if (Array.isArray(host)) {
        hostStr = host.join('.');
      } else if (typeof host === 'string') {
        hostStr = host;
      }

      let pathStr = '';
      if (Array.isArray(path)) {
        pathStr = '/' + path.join('/');
      } else if (typeof path === 'string') {
        pathStr = path.startsWith('/') ? path : '/' + path;
      }

      baseUrl = `${protocol}://${hostStr}${pathStr}`;
    }

    // Extract query parameters
    if (url.query && Array.isArray(url.query)) {
      const queryArray = url.query as ESObject[];
      queryArray.forEach((q: ESObject) => {
        if (q && q.key) {
          const param = new QueryParam();
          param.id = UUID.randomUUID();
          param.name = (q.key as string) || '';
          param.value = (q.value as string) || '';
          param.enabled = q.disabled !== true;
          queryParams.push(param);
        }
      });
    }

    return { baseUrl: baseUrl, queryParams: queryParams };
  }

  /**
   * Parse URL string and extract query params
   */
  private static parseUrlString(url: string): { baseUrl: string; queryParams: QueryParam[] } {
    const queryParams: QueryParam[] = [];
    
    const questionIndex = url.indexOf('?');
    if (questionIndex === -1) {
      return { baseUrl: url, queryParams: queryParams };
    }

    const baseUrl = url.substring(0, questionIndex);
    const queryString = url.substring(questionIndex + 1);

    const pairs = queryString.split('&');
    pairs.forEach((pair: string) => {
      const equalsIndex = pair.indexOf('=');
      if (equalsIndex > 0) {
        const param = new QueryParam();
        param.id = UUID.randomUUID();
        param.name = decodeURIComponent(pair.substring(0, equalsIndex));
        param.value = decodeURIComponent(pair.substring(equalsIndex + 1));
        param.enabled = true;
        queryParams.push(param);
      }
    });

    return { baseUrl: baseUrl, queryParams: queryParams };
  }

  /**
   * Extract headers from Postman header array
   */
  private static extractHeaders(headers: ESObject[] | undefined): HttpHeader[] {
    const result: HttpHeader[] = [];
    
    if (!headers || !Array.isArray(headers)) {
      return result;
    }

    headers.forEach((h: ESObject) => {
      if (h && h.key) {
        const header = new HttpHeader();
        header.id = UUID.randomUUID();
        header.name = (h.key as string) || '';
        header.value = (h.value as string) || '';
        header.enabled = h.disabled !== true;
        result.push(header);
      }
    });

    return result;
  }

  /**
   * Extract body from Postman body object
   */
  private static extractBody(
    body: ESObject | undefined
  ): { body: string; bodyType: 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text' } {
    if (!body) {
      return { body: '', bodyType: 'none' };
    }

    const mode = body.mode as string | undefined;

    switch (mode) {
      case 'raw': {
        const raw = (body.raw as string) || '';
        const options = body.options as ESObject | undefined;
        const language = options?.raw?.language as string | undefined;
        
        if (language === 'json' || raw.trim().startsWith('{') || raw.trim().startsWith('[')) {
          return { body: raw, bodyType: 'json' };
        } else if (language === 'xml' || raw.trim().startsWith('<')) {
          return { body: raw, bodyType: 'xml' };
        }
        return { body: raw, bodyType: 'text' };
      }

      case 'urlencoded': {
        const urlencoded = body.urlencoded as ESObject[] | undefined;
        if (urlencoded && Array.isArray(urlencoded)) {
          const parts: string[] = [];
          urlencoded.forEach((item: ESObject) => {
            if (item && item.key) {
              const key = encodeURIComponent((item.key as string) || '');
              const value = encodeURIComponent((item.value as string) || '');
              parts.push(`${key}=${value}`);
            }
          });
          return { body: parts.join('&'), bodyType: 'form-urlencoded' };
        }
        return { body: '', bodyType: 'form-urlencoded' };
      }

      case 'formdata':
        // Form data is complex, just mark the type
        return { body: '', bodyType: 'form-data' };

      case 'graphql': {
        const graphql = body.graphql as ESObject | undefined;
        if (graphql) {
          const query = (graphql.query as string) || '';
          const variables = graphql.variables as string | undefined;
          const graphqlBody: ESObject = { query: query };
          if (variables) {
            try {
              graphqlBody.variables = JSON.parse(variables);
            } catch (e) {
              graphqlBody.variables = variables;
            }
          }
          return { body: JSON.stringify(graphqlBody, null, 2), bodyType: 'graphql' };
        }
        return { body: '', bodyType: 'graphql' };
      }

      default:
        return { body: '', bodyType: 'none' };
    }
  }

  /**
   * Extract auth from Postman auth object
   */
  private static extractAuth(auth: ESObject): AuthConfig {
    const config = new AuthConfig();
    const type = auth.type as string | undefined;

    switch (type) {
      case 'basic': {
        config.type = 'basic';
        const basic = auth.basic as ESObject[] | undefined;
        if (basic && Array.isArray(basic)) {
          basic.forEach((item: ESObject) => {
            if (item.key === 'username') {
              config.basic_username = (item.value as string) || '';
            } else if (item.key === 'password') {
              config.basic_password = (item.value as string) || '';
            }
          });
        }
        break;
      }

      case 'bearer': {
        config.type = 'bearer';
        const bearer = auth.bearer as ESObject[] | undefined;
        if (bearer && Array.isArray(bearer)) {
          bearer.forEach((item: ESObject) => {
            if (item.key === 'token') {
              config.bearer_token = (item.value as string) || '';
            }
          });
        }
        break;
      }

      case 'apikey': {
        config.type = 'api-key';
        const apikey = auth.apikey as ESObject[] | undefined;
        if (apikey && Array.isArray(apikey)) {
          apikey.forEach((item: ESObject) => {
            if (item.key === 'key') {
              config.api_key_name = (item.value as string) || '';
            } else if (item.key === 'value') {
              config.api_key_value = (item.value as string) || '';
            } else if (item.key === 'in') {
              config.api_key_location = (item.value as string) === 'query' ? 'query' : 'header';
            }
          });
        }
        break;
      }

      default:
        config.type = 'none';
    }

    return config;
  }

  /**
   * Convert Postman variables to Environment
   */
  private static variablesToEnvironment(
    variables: ESObject[],
    workspaceId: string,
    name: string
  ): Environment {
    const env = new Environment();
    env.id = UUID.randomUUID();
    env.workspace_id = workspaceId;
    env.name = name;
    env.created_at = Date.now();
    env.updated_at = Date.now();
    env.variables = [];

    variables.forEach((v: ESObject) => {
      if (v && v.key) {
        const variable = new EnvironmentVariable();
        variable.id = UUID.randomUUID();
        variable.name = (v.key as string) || '';
        variable.value = (v.value as string) || '';
        variable.enabled = v.disabled !== true;
        env.variables.push(variable);
      }
    });

    return env;
  }

  /**
   * Create a folder
   */
  private static createFolder(
    name: string,
    workspaceId: string,
    parentFolderId: string | null
  ): Folder {
    const folder = new Folder();
    folder.id = UUID.randomUUID();
    folder.workspace_id = workspaceId;
    folder.folder_id = parentFolderId;
    folder.name = name;
    folder.created_at = Date.now();
    folder.updated_at = Date.now();
    return folder;
  }
}
