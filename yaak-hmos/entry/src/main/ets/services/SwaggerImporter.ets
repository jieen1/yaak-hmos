/**
 * SwaggerImporter - Parse Swagger 2.0 specifications
 *
 * Supports:
 * - Swagger 2.0 JSON format
 * - Host and basePath extraction for base URL
 * - Path and operation parsing
 * - Parameter extraction (query, header, path, body)
 * - Request body generation from definitions
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { UUID } from '../common/UUID';
import type { ImportResult, ImportError } from './ImportService';

export class SwaggerImporter {
  private static readonly HTTP_METHODS: string[] = ['get', 'post', 'put', 'delete', 'patch', 'head', 'options'];

  /**
   * Import Swagger specification
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
      const spec: ESObject = JSON.parse(content) as ESObject;
      
      // Validate Swagger version
      if (!spec.swagger || typeof spec.swagger !== 'string') {
        const error: ImportError = {
          path: '',
          message: 'Invalid Swagger specification: missing swagger version',
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      const version = spec.swagger as string;
      if (!version.startsWith('2.')) {
        const error: ImportError = {
          path: '',
          message: `Unsupported Swagger version: ${version}. Only 2.x is supported.`,
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      // Build base URL from host and basePath
      const baseUrl = this.buildBaseUrl(spec);

      // Get definitions for body generation
      const definitions = (spec.definitions as ESObject) || {};

      // Extract paths and operations
      if (!spec.paths || typeof spec.paths !== 'object') {
        const error: ImportError = {
          path: '',
          message: 'Invalid Swagger specification: missing paths',
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      const paths = spec.paths as ESObject;
      const tagFolders: Map<string, Folder> = new Map();

      // Process each path
      Object.keys(paths).forEach((path: string) => {
        const pathItem = paths[path] as ESObject;
        if (!pathItem || typeof pathItem !== 'object') {
          return;
        }

        // Process each HTTP method
        this.HTTP_METHODS.forEach((method: string) => {
          if (!pathItem[method]) {
            return;
          }

          const operation = pathItem[method] as ESObject;
          try {
            const request = this.operationToRequest(
              path,
              method,
              operation,
              baseUrl,
              definitions,
              workspaceId
            );

            // Handle tags for folder organization
            const tags = operation.tags as string[] | undefined;
            if (tags && tags.length > 0) {
              const tagName = tags[0];
              if (tagName) {
                let folder = tagFolders.get(tagName);
                if (!folder) {
                  folder = this.createFolder(tagName, workspaceId);
                  tagFolders.set(tagName, folder);
                  result.folders.push(folder);
                  result.foldersCreated++;
                }
                request.folder_id = folder.id;
              }
            }

            result.requests.push(request);
            result.requestsCreated++;
          } catch (e) {
            const errorMessage = e instanceof Error ? e.message : String(e);
            const error: ImportError = {
              path: `${method.toUpperCase()} ${path}`,
              message: errorMessage,
              recoverable: true
            };
            result.errors.push(error);
          }
        });
      });

      result.success = result.requestsCreated > 0;
      return result;
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      const error: ImportError = {
        path: '',
        message: `Failed to parse Swagger specification: ${errorMessage}`,
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }
  }


  /**
   * Build base URL from host and basePath
   */
  private static buildBaseUrl(spec: ESObject): string {
    const schemes = spec.schemes as string[] | undefined;
    const scheme = (schemes && schemes.length > 0) ? schemes[0] : 'https';
    const host = (spec.host as string) || 'localhost';
    const basePath = (spec.basePath as string) || '';

    let url = `${scheme}://${host}`;
    if (basePath && basePath !== '/') {
      url = url + basePath;
    }

    return url;
  }

  /**
   * Convert Swagger operation to HttpRequest
   */
  private static operationToRequest(
    path: string,
    method: string,
    operation: ESObject,
    baseUrl: string,
    definitions: ESObject,
    workspaceId: string
  ): HttpRequest {
    const request = new HttpRequest();
    request.id = UUID.randomUUID();
    request.workspace_id = workspaceId;
    request.created_at = Date.now();
    request.updated_at = Date.now();

    // Set method
    request.method = method.toUpperCase() as 'GET' | 'POST' | 'PUT' | 'DELETE' | 'PATCH' | 'HEAD' | 'OPTIONS';

    // Set name from summary or operationId
    const summary = operation.summary as string | undefined;
    const operationId = operation.operationId as string | undefined;
    request.name = summary || operationId || `${method.toUpperCase()} ${path}`;

    // Build URL
    let url = baseUrl;
    if (url.endsWith('/') && path.startsWith('/')) {
      url = url.slice(0, -1);
    }
    url = url + path;
    request.url = url;

    // Process parameters
    const parameters = operation.parameters as ESObject[] | undefined;
    const headers: HttpHeader[] = [];
    const queryParams: QueryParam[] = [];

    if (parameters && Array.isArray(parameters)) {
      parameters.forEach((param: ESObject) => {
        if (!param || !param.name || !param.in) return;

        const paramIn = param.in as string;
        const paramName = param.name as string;
        const value = this.getParameterValue(param);

        if (paramIn === 'query') {
          const qp = new QueryParam();
          qp.id = UUID.randomUUID();
          qp.name = paramName;
          qp.value = value;
          qp.enabled = true;
          queryParams.push(qp);
        } else if (paramIn === 'header') {
          const h = new HttpHeader();
          h.id = UUID.randomUUID();
          h.name = paramName;
          h.value = value;
          h.enabled = true;
          headers.push(h);
        } else if (paramIn === 'path') {
          // Replace path parameter placeholder
          request.url = request.url.replace(`{${paramName}}`, value || `{{${paramName}}}`);
        } else if (paramIn === 'body') {
          // Handle body parameter
          const bodyResult = this.generateBodyFromParameter(param, definitions);
          request.body = bodyResult.body;
          request.body_type = bodyResult.bodyType;

          // Add Content-Type header
          const consumes = operation.consumes as string[] | undefined;
          const contentType = (consumes && consumes.length > 0) ? consumes[0] : 'application/json';
          const ctHeader = new HttpHeader();
          ctHeader.id = UUID.randomUUID();
          ctHeader.name = 'Content-Type';
          ctHeader.value = contentType;
          ctHeader.enabled = true;
          headers.push(ctHeader);
        } else if (paramIn === 'formData') {
          // Form data parameter - set body type
          request.body_type = 'form-urlencoded';
        }
      });
    }

    request.headers = headers;
    request.query_params = queryParams;

    return request;
  }

  /**
   * Get parameter value from default or example
   */
  private static getParameterValue(param: ESObject): string {
    if (param.default !== undefined) {
      return String(param.default);
    }
    if (param.example !== undefined) {
      return String(param.example);
    }

    // Generate placeholder based on type
    const type = param.type as string | undefined;
    if (type === 'string') {
      return '';
    } else if (type === 'integer' || type === 'number') {
      return '0';
    } else if (type === 'boolean') {
      return 'false';
    }

    return '';
  }

  /**
   * Generate body from body parameter
   */
  private static generateBodyFromParameter(
    param: ESObject,
    definitions: ESObject
  ): { body: string; bodyType: 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text' } {
    const schema = param.schema as ESObject | undefined;
    if (!schema) {
      return { body: '{}', bodyType: 'json' };
    }

    try {
      const obj = this.schemaToObject(schema, definitions);
      return { body: JSON.stringify(obj, null, 2), bodyType: 'json' };
    } catch (e) {
      return { body: '{}', bodyType: 'json' };
    }
  }

  /**
   * Convert schema to object with example values
   */
  private static schemaToObject(schema: ESObject, definitions: ESObject): ESObject {
    if (!schema) {
      return {};
    }

    // Handle $ref
    if (schema.$ref && typeof schema.$ref === 'string') {
      const ref = schema.$ref as string;
      const refName = ref.replace('#/definitions/', '');
      const refSchema = definitions[refName] as ESObject | undefined;
      if (refSchema) {
        return this.schemaToObject(refSchema, definitions);
      }
      return {};
    }

    // Check for example first
    if (schema.example !== undefined) {
      return schema.example as ESObject;
    }

    const type = schema.type as string | undefined;

    if (type === 'object' || schema.properties) {
      const obj: ESObject = {};
      const properties = schema.properties as ESObject | undefined;
      if (properties) {
        Object.keys(properties).forEach((key: string) => {
          const propSchema = properties[key] as ESObject;
          obj[key] = this.schemaToObject(propSchema, definitions);
        });
      }
      return obj;
    }

    if (type === 'array') {
      const items = schema.items as ESObject | undefined;
      if (items) {
        return [this.schemaToObject(items, definitions)];
      }
      return [];
    }

    if (type === 'string') {
      if (schema.default !== undefined) {
        return schema.default as string;
      }
      if (schema.enum && Array.isArray(schema.enum)) {
        const enumValues = schema.enum as string[];
        return enumValues[0] || '';
      }
      return '';
    }

    if (type === 'integer' || type === 'number') {
      if (schema.default !== undefined) {
        return schema.default as number;
      }
      return 0;
    }

    if (type === 'boolean') {
      if (schema.default !== undefined) {
        return schema.default as boolean;
      }
      return false;
    }

    return {};
  }

  /**
   * Create a folder for tag grouping
   */
  private static createFolder(name: string, workspaceId: string): Folder {
    const folder = new Folder();
    folder.id = UUID.randomUUID();
    folder.workspace_id = workspaceId;
    folder.name = name;
    folder.created_at = Date.now();
    folder.updated_at = Date.now();
    return folder;
  }
}
