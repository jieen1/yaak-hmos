/**
 * InsomniaImporter - Parse Insomnia v4+ export format
 *
 * Supports:
 * - Insomnia v4+ export JSON
 * - Request resources
 * - Request group (folder) resources
 * - Environment resources
 * - Authentication configurations
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Environment, EnvironmentVariable } from '../model/Environment';
import { UUID } from '../common/UUID';
import type { ImportResult, ImportError } from './ImportService';

export class InsomniaImporter {
  /**
   * Import Insomnia export
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
      const data: ESObject = JSON.parse(content) as ESObject;
      
      // Check for resources array (Insomnia v4+ format)
      if (!data.resources || !Array.isArray(data.resources)) {
        const error: ImportError = {
          path: '',
          message: 'Invalid Insomnia export: missing resources array',
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      const resources = data.resources as ESObject[];
      
      // Build ID mapping for parent references
      const idMap: Map<string, string> = new Map();
      
      // First pass: create folders and build ID mapping
      resources.forEach((resource: ESObject) => {
        if (!resource || !resource._type) return;
        
        const type = resource._type as string;
        const oldId = resource._id as string;
        
        if (type === 'request_group') {
          try {
            const folder = this.resourceToFolder(resource, workspaceId);
            idMap.set(oldId, folder.id);
            result.folders.push(folder);
            result.foldersCreated++;
          } catch (e) {
            const errorMessage = e instanceof Error ? e.message : String(e);
            const error: ImportError = {
              path: (resource.name as string) || 'Unknown folder',
              message: errorMessage,
              recoverable: true
            };
            result.errors.push(error);
          }
        }
      });

      // Second pass: update folder parent references
      result.folders.forEach((folder: Folder) => {
        if (folder.folder_id) {
          const newParentId = idMap.get(folder.folder_id);
          folder.folder_id = newParentId || null;
        }
      });

      // Third pass: create requests and environments
      resources.forEach((resource: ESObject) => {
        if (!resource || !resource._type) return;
        
        const type = resource._type as string;
        
        if (type === 'request') {
          try {
            const request = this.resourceToRequest(resource, workspaceId, idMap);
            result.requests.push(request);
            result.requestsCreated++;
          } catch (e) {
            const errorMessage = e instanceof Error ? e.message : String(e);
            const error: ImportError = {
              path: (resource.name as string) || 'Unknown request',
              message: errorMessage,
              recoverable: true
            };
            result.errors.push(error);
          }
        } else if (type === 'environment') {
          try {
            const env = this.resourceToEnvironment(resource, workspaceId);
            if (env.variables.length > 0) {
              result.environments.push(env);
              result.environmentsCreated++;
            }
          } catch (e) {
            const errorMessage = e instanceof Error ? e.message : String(e);
            const error: ImportError = {
              path: (resource.name as string) || 'Unknown environment',
              message: errorMessage,
              recoverable: true
            };
            result.errors.push(error);
          }
        }
      });

      result.success = result.requestsCreated > 0 || result.foldersCreated > 0;
      return result;
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      const error: ImportError = {
        path: '',
        message: `Failed to parse Insomnia export: ${errorMessage}`,
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }
  }


  /**
   * Convert Insomnia request_group resource to Folder
   */
  private static resourceToFolder(resource: ESObject, workspaceId: string): Folder {
    const folder = new Folder();
    folder.id = UUID.randomUUID();
    folder.workspace_id = workspaceId;
    folder.name = (resource.name as string) || 'Unnamed Folder';
    folder.created_at = Date.now();
    folder.updated_at = Date.now();
    
    // Store original parent ID temporarily (will be resolved later)
    const parentId = resource.parentId as string | undefined;
    if (parentId && !parentId.startsWith('wrk_')) {
      folder.folder_id = parentId;
    }
    
    return folder;
  }

  /**
   * Convert Insomnia request resource to HttpRequest
   */
  private static resourceToRequest(
    resource: ESObject,
    workspaceId: string,
    idMap: Map<string, string>
  ): HttpRequest {
    const request = new HttpRequest();
    request.id = UUID.randomUUID();
    request.workspace_id = workspaceId;
    request.created_at = Date.now();
    request.updated_at = Date.now();

    // Set name
    request.name = (resource.name as string) || 'Unnamed Request';

    // Set method
    request.method = ((resource.method as string) || 'GET').toUpperCase() as 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

    // Set URL
    request.url = (resource.url as string) || '';

    // Set folder
    const parentId = resource.parentId as string | undefined;
    if (parentId && !parentId.startsWith('wrk_')) {
      const newParentId = idMap.get(parentId);
      request.folder_id = newParentId || null;
    }

    // Set headers
    request.headers = this.extractHeaders(resource.headers);

    // Set query parameters
    request.query_params = this.extractQueryParams(resource.parameters);

    // Set body
    const bodyResult = this.extractBody(resource.body);
    request.body = bodyResult.body;
    request.body_type = bodyResult.bodyType;

    // Set auth
    if (resource.authentication) {
      request.auth = this.extractAuth(resource.authentication as ESObject);
    }

    return request;
  }

  /**
   * Extract headers from Insomnia headers array
   */
  private static extractHeaders(headers: ESObject[] | undefined): HttpHeader[] {
    const result: HttpHeader[] = [];
    
    if (!headers || !Array.isArray(headers)) {
      return result;
    }

    headers.forEach((h: ESObject) => {
      if (h && h.name) {
        const header = new HttpHeader();
        header.id = UUID.randomUUID();
        header.name = (h.name as string) || '';
        header.value = (h.value as string) || '';
        header.enabled = h.disabled !== true;
        result.push(header);
      }
    });

    return result;
  }

  /**
   * Extract query parameters from Insomnia parameters array
   */
  private static extractQueryParams(params: ESObject[] | undefined): QueryParam[] {
    const result: QueryParam[] = [];
    
    if (!params || !Array.isArray(params)) {
      return result;
    }

    params.forEach((p: ESObject) => {
      if (p && p.name) {
        const param = new QueryParam();
        param.id = UUID.randomUUID();
        param.name = (p.name as string) || '';
        param.value = (p.value as string) || '';
        param.enabled = p.disabled !== true;
        result.push(param);
      }
    });

    return result;
  }

  /**
   * Extract body from Insomnia body object
   */
  private static extractBody(
    body: ESObject | undefined
  ): { body: string; bodyType: 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text' } {
    if (!body) {
      return { body: '', bodyType: 'none' };
    }

    const mimeType = body.mimeType as string | undefined;
    const text = body.text as string | undefined;

    if (!mimeType) {
      if (text) {
        return { body: text, bodyType: 'text' };
      }
      return { body: '', bodyType: 'none' };
    }

    if (mimeType.includes('json')) {
      return { body: text || '', bodyType: 'json' };
    }

    if (mimeType.includes('xml')) {
      return { body: text || '', bodyType: 'xml' };
    }

    if (mimeType.includes('x-www-form-urlencoded')) {
      // Convert params to urlencoded string
      const params = body.params as ESObject[] | undefined;
      if (params && Array.isArray(params)) {
        const parts: string[] = [];
        params.forEach((p: ESObject) => {
          if (p && p.name) {
            const name = encodeURIComponent((p.name as string) || '');
            const value = encodeURIComponent((p.value as string) || '');
            parts.push(`${name}=${value}`);
          }
        });
        return { body: parts.join('&'), bodyType: 'form-urlencoded' };
      }
      return { body: text || '', bodyType: 'form-urlencoded' };
    }

    if (mimeType.includes('multipart/form-data')) {
      return { body: '', bodyType: 'form-data' };
    }

    if (mimeType.includes('graphql')) {
      return { body: text || '', bodyType: 'graphql' };
    }

    return { body: text || '', bodyType: 'text' };
  }

  /**
   * Extract auth from Insomnia authentication object
   */
  private static extractAuth(auth: ESObject): AuthConfig {
    const config = new AuthConfig();
    const type = auth.type as string | undefined;

    switch (type) {
      case 'basic': {
        config.type = 'basic';
        config.basic_username = (auth.username as string) || '';
        config.basic_password = (auth.password as string) || '';
        break;
      }

      case 'bearer': {
        config.type = 'bearer';
        config.bearer_token = (auth.token as string) || '';
        break;
      }

      case 'apikey': {
        config.type = 'api-key';
        config.api_key_name = (auth.key as string) || '';
        config.api_key_value = (auth.value as string) || '';
        config.api_key_location = (auth.addTo as string) === 'queryParams' ? 'query' : 'header';
        break;
      }

      default:
        config.type = 'none';
    }

    return config;
  }

  /**
   * Convert Insomnia environment resource to Environment
   */
  private static resourceToEnvironment(resource: ESObject, workspaceId: string): Environment {
    const env = new Environment();
    env.id = UUID.randomUUID();
    env.workspace_id = workspaceId;
    env.name = (resource.name as string) || 'Unnamed Environment';
    env.created_at = Date.now();
    env.updated_at = Date.now();
    env.variables = [];

    // Insomnia stores variables in data object
    const data = resource.data as ESObject | undefined;
    if (data && typeof data === 'object') {
      Object.keys(data).forEach((key: string) => {
        const variable = new EnvironmentVariable();
        variable.id = UUID.randomUUID();
        variable.name = key;
        variable.value = String(data[key] || '');
        variable.enabled = true;
        env.variables.push(variable);
      });
    }

    return env;
  }
}
