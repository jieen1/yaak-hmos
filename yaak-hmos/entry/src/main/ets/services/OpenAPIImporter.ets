/**
 * OpenAPIImporter - Parse OpenAPI 3.0/3.1 specifications
 *
 * Supports:
 * - OpenAPI 3.0.x and 3.1.x JSON format
 * - Server extraction for base URL
 * - Path and operation parsing
 * - Parameter extraction (query, header, path)
 * - Request body generation from schema
 * - Folder creation for path groups
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { UUID } from '../common/UUID';
import type { ImportResult, ImportError } from './ImportService';

/**
 * OpenAPI Server object
 */
interface OpenAPIServer {
  url: string;
  description?: string;
}

/**
 * OpenAPI Parameter object
 */
interface OpenAPIParameter {
  name: string;
  in: string;
  description?: string;
  required?: boolean;
  schema?: ESObject;
  example?: ESObject;
}

/**
 * OpenAPI Request Body object
 */
interface OpenAPIRequestBody {
  description?: string;
  required?: boolean;
  content?: ESObject;
}

/**
 * OpenAPI Operation object
 */
interface OpenAPIOperation {
  operationId?: string;
  summary?: string;
  description?: string;
  tags?: string[];
  parameters?: OpenAPIParameter[];
  requestBody?: OpenAPIRequestBody;
  responses?: ESObject;
}


export class OpenAPIImporter {
  private static readonly HTTP_METHODS: string[] = ['get', 'post', 'put', 'delete', 'patch', 'head', 'options'];

  /**
   * Import OpenAPI specification
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
      
      // Validate OpenAPI version
      if (!spec.openapi || typeof spec.openapi !== 'string') {
        const error: ImportError = {
          path: '',
          message: 'Invalid OpenAPI specification: missing openapi version',
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      const version = spec.openapi as string;
      if (!version.startsWith('3.')) {
        const error: ImportError = {
          path: '',
          message: `Unsupported OpenAPI version: ${version}. Only 3.x is supported.`,
          recoverable: false
        };
        result.errors.push(error);
        return result;
      }

      // Extract servers for base URL
      const servers = this.extractServers(spec);
      const baseUrl = servers.length > 0 ? servers[0].url : '';

      // Extract paths and operations
      if (!spec.paths || typeof spec.paths !== 'object') {
        const error: ImportError = {
          path: '',
          message: 'Invalid OpenAPI specification: missing paths',
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

        // Get path-level parameters
        const pathParameters: OpenAPIParameter[] = this.extractParameters(pathItem.parameters);

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
              pathParameters,
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
        message: `Failed to parse OpenAPI specification: ${errorMessage}`,
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }
  }

  /**
   * Extract servers from OpenAPI spec
   */
  private static extractServers(spec: ESObject): OpenAPIServer[] {
    const servers: OpenAPIServer[] = [];
    
    if (!spec.servers || !Array.isArray(spec.servers)) {
      return servers;
    }

    const specServers = spec.servers as ESObject[];
    specServers.forEach((server: ESObject) => {
      if (server && server.url) {
        const s: OpenAPIServer = {
          url: server.url as string,
          description: server.description as string | undefined
        };
        servers.push(s);
      }
    });

    return servers;
  }

  /**
   * Extract parameters from OpenAPI spec
   */
  private static extractParameters(params: ESObject | undefined): OpenAPIParameter[] {
    const parameters: OpenAPIParameter[] = [];
    
    if (!params || !Array.isArray(params)) {
      return parameters;
    }

    const paramArray = params as ESObject[];
    paramArray.forEach((param: ESObject) => {
      if (param && param.name && param.in) {
        const p: OpenAPIParameter = {
          name: param.name as string,
          in: param.in as string,
          description: param.description as string | undefined,
          required: param.required as boolean | undefined,
          schema: param.schema as ESObject | undefined,
          example: param.example as ESObject | undefined
        };
        parameters.push(p);
      }
    });

    return parameters;
  }

  /**
   * Convert OpenAPI operation to HttpRequest
   */
  private static operationToRequest(
    path: string,
    method: string,
    operation: ESObject,
    baseUrl: string,
    pathParameters: OpenAPIParameter[],
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

    // Build URL with base URL and path
    let url = baseUrl;
    if (url.endsWith('/') && path.startsWith('/')) {
      url = url.slice(0, -1);
    }
    url = url + path;
    request.url = url;

    // Combine path-level and operation-level parameters
    const operationParams = this.extractParameters(operation.parameters);
    const allParams: OpenAPIParameter[] = [...pathParameters, ...operationParams];

    // Process parameters
    const headers: HttpHeader[] = [];
    const queryParams: QueryParam[] = [];

    allParams.forEach((param: OpenAPIParameter) => {
      const value = this.getParameterValue(param);

      if (param.in === 'query') {
        const qp = new QueryParam();
        qp.id = UUID.randomUUID();
        qp.name = param.name;
        qp.value = value;
        qp.enabled = true;
        queryParams.push(qp);
      } else if (param.in === 'header') {
        const h = new HttpHeader();
        h.id = UUID.randomUUID();
        h.name = param.name;
        h.value = value;
        h.enabled = true;
        headers.push(h);
      } else if (param.in === 'path') {
        // Replace path parameter placeholder
        request.url = request.url.replace(`{${param.name}}`, value || `{{${param.name}}}`);
      }
    });

    request.headers = headers;
    request.query_params = queryParams;

    // Process request body
    if (operation.requestBody) {
      const bodyResult = this.generateBodyFromRequestBody(operation.requestBody as ESObject);
      if (bodyResult.body) {
        request.body = bodyResult.body;
        request.body_type = bodyResult.bodyType;

        // Add Content-Type header if not present
        const hasContentType = headers.some((h: HttpHeader) => 
          h.name.toLowerCase() === 'content-type'
        );
        if (!hasContentType && bodyResult.contentType) {
          const ctHeader = new HttpHeader();
          ctHeader.id = UUID.randomUUID();
          ctHeader.name = 'Content-Type';
          ctHeader.value = bodyResult.contentType;
          ctHeader.enabled = true;
          request.headers.push(ctHeader);
        }
      }
    }

    return request;
  }

  /**
   * Get parameter value from example or schema default
   */
  private static getParameterValue(param: OpenAPIParameter): string {
    if (param.example !== undefined) {
      return String(param.example);
    }

    if (param.schema) {
      const schema = param.schema;
      if (schema.default !== undefined) {
        return String(schema.default);
      }
      if (schema.example !== undefined) {
        return String(schema.example);
      }
      // Generate placeholder based on type
      const type = schema.type as string | undefined;
      if (type === 'string') {
        return '';
      } else if (type === 'integer' || type === 'number') {
        return '0';
      } else if (type === 'boolean') {
        return 'false';
      }
    }

    return '';
  }

  /**
   * Generate request body from OpenAPI requestBody
   */
  private static generateBodyFromRequestBody(
    requestBody: ESObject
  ): { body: string; bodyType: 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text'; contentType: string } {
    const result: { body: string; bodyType: 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text'; contentType: string } = {
      body: '',
      bodyType: 'none',
      contentType: ''
    };

    if (!requestBody.content || typeof requestBody.content !== 'object') {
      return result;
    }

    const content = requestBody.content as ESObject;

    // Prefer JSON
    if (content['application/json']) {
      const jsonContent = content['application/json'] as ESObject;
      result.contentType = 'application/json';
      result.bodyType = 'json';
      result.body = this.generateBodyFromSchema(jsonContent.schema as ESObject);
      return result;
    }

    // Try XML
    if (content['application/xml'] || content['text/xml']) {
      const xmlContent = (content['application/xml'] || content['text/xml']) as ESObject;
      result.contentType = content['application/xml'] ? 'application/xml' : 'text/xml';
      result.bodyType = 'xml';
      result.body = this.generateXmlFromSchema(xmlContent.schema as ESObject);
      return result;
    }

    // Try form-urlencoded
    if (content['application/x-www-form-urlencoded']) {
      result.contentType = 'application/x-www-form-urlencoded';
      result.bodyType = 'form-urlencoded';
      return result;
    }

    // Try multipart/form-data
    if (content['multipart/form-data']) {
      result.contentType = 'multipart/form-data';
      result.bodyType = 'form-data';
      return result;
    }

    // Try plain text
    if (content['text/plain']) {
      result.contentType = 'text/plain';
      result.bodyType = 'text';
      return result;
    }

    return result;
  }

  /**
   * Generate JSON body from schema
   */
  private static generateBodyFromSchema(schema: ESObject | undefined): string {
    if (!schema) {
      return '{}';
    }

    try {
      const obj = this.schemaToObject(schema);
      return JSON.stringify(obj, null, 2);
    } catch (e) {
      return '{}';
    }
  }

  /**
   * Convert schema to object with example values
   */
  private static schemaToObject(schema: ESObject): ESObject {
    if (!schema) {
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
          obj[key] = this.schemaToObject(propSchema);
        });
      }
      return obj;
    }

    if (type === 'array') {
      const items = schema.items as ESObject | undefined;
      if (items) {
        return [this.schemaToObject(items)];
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
   * Generate XML body from schema (simplified)
   */
  private static generateXmlFromSchema(schema: ESObject | undefined): string {
    if (!schema) {
      return '<root></root>';
    }

    // Simplified XML generation
    const rootName = (schema.xml && (schema.xml as ESObject).name) || 'root';
    return `<${rootName}></${rootName}>`;
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
