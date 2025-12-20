/**
 * ImportService - Central service for handling all import operations
 *
 * Supports:
 * - OpenAPI 3.0/3.1
 * - Postman Collection v2/v2.1
 * - Insomnia v4+
 * - Swagger 2.0
 * - cURL commands
 * - Yaak native format
 */

import { HttpRequest } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Environment } from '../model/Environment';
import { CurlImporter } from './CurlImporter';
import { OpenAPIImporter } from './OpenAPIImporter';
import { PostmanImporter } from './PostmanImporter';
import { InsomniaImporter } from './InsomniaImporter';
import { SwaggerImporter } from './SwaggerImporter';

/**
 * Supported import formats
 */
export type ImportFormat = 'openapi' | 'postman' | 'insomnia' | 'swagger' | 'curl' | 'yaak' | 'unknown';

/**
 * Import error details
 */
export interface ImportError {
  path: string;
  message: string;
  recoverable: boolean;
}

/**
 * Import result
 */
export interface ImportResult {
  success: boolean;
  requestsCreated: number;
  foldersCreated: number;
  environmentsCreated: number;
  requests: HttpRequest[];
  folders: Folder[];
  environments: Environment[];
  errors: ImportError[];
}

/**
 * Import preview item
 */
export interface ImportPreviewItem {
  type: 'request' | 'folder' | 'environment';
  name: string;
  method?: string;
  url?: string;
  children?: ImportPreviewItem[];
}

/**
 * Import preview
 */
export interface ImportPreview {
  format: ImportFormat;
  requestCount: number;
  folderCount: number;
  environmentCount: number;
  items: ImportPreviewItem[];
}


export class ImportService {
  /**
   * Detect import format from file content
   */
  static detectFormat(content: string): ImportFormat {
    if (!content || typeof content !== 'string') {
      return 'unknown';
    }

    const trimmed = content.trim();

    // Check for cURL command first (simple text check)
    if (CurlImporter.isCurlCommand(trimmed)) {
      return 'curl';
    }

    // Try to parse as JSON
    try {
      const parsed: ESObject = JSON.parse(trimmed) as ESObject;
      return this.detectFormatFromJson(parsed);
    } catch (e) {
      // Not valid JSON, might be YAML or other format
      // For now, check if it looks like YAML OpenAPI
      if (trimmed.includes('openapi:') || trimmed.includes('openapi :')) {
        return 'openapi';
      }
      if (trimmed.includes('swagger:') || trimmed.includes('swagger :')) {
        return 'swagger';
      }
    }

    return 'unknown';
  }

  /**
   * Detect format from parsed JSON object
   */
  private static detectFormatFromJson(obj: ESObject): ImportFormat {
    if (!obj || typeof obj !== 'object') {
      return 'unknown';
    }

    // OpenAPI 3.x detection
    if (obj.openapi && typeof obj.openapi === 'string') {
      const version = obj.openapi as string;
      if (version.startsWith('3.')) {
        return 'openapi';
      }
    }

    // Swagger 2.0 detection
    if (obj.swagger && typeof obj.swagger === 'string') {
      const version = obj.swagger as string;
      if (version.startsWith('2.')) {
        return 'swagger';
      }
    }

    // Postman Collection detection
    if (obj.info && typeof obj.info === 'object') {
      const info = obj.info as ESObject;
      if (info.schema && typeof info.schema === 'string') {
        const schema = info.schema as string;
        if (schema.includes('postman') || schema.includes('collection')) {
          return 'postman';
        }
      }
    }

    // Insomnia detection
    if (obj._type && typeof obj._type === 'string') {
      const type = obj._type as string;
      if (type === 'export' || type === 'workspace') {
        return 'insomnia';
      }
    }

    // Insomnia v4+ detection (resources array)
    if (Array.isArray(obj.resources)) {
      const resources = obj.resources as ESObject[];
      if (resources.length > 0) {
        const first = resources[0] as ESObject;
        if (first && first._type) {
          return 'insomnia';
        }
      }
    }

    // Yaak native format detection
    if (obj.version && obj.workspaces && Array.isArray(obj.workspaces)) {
      return 'yaak';
    }

    return 'unknown';
  }

  /**
   * Import from detected or specified format
   */
  static async import(
    content: string,
    format: ImportFormat,
    workspaceId: string
  ): Promise<ImportResult> {
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

    if (!content || !workspaceId) {
      const error: ImportError = {
        path: '',
        message: 'Invalid content or workspace ID',
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }

    try {
      switch (format) {
        case 'curl':
          return this.importCurl(content, workspaceId);
        case 'openapi':
          return this.importOpenAPI(content, workspaceId);
        case 'postman':
          return this.importPostman(content, workspaceId);
        case 'insomnia':
          return this.importInsomnia(content, workspaceId);
        case 'swagger':
          return this.importSwagger(content, workspaceId);
        case 'yaak':
          return this.importYaak(content, workspaceId);
        default: {
          const error: ImportError = {
            path: '',
            message: `Unsupported import format: ${format}`,
            recoverable: false
          };
          result.errors.push(error);
          return result;
        }
      }
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      const error: ImportError = {
        path: '',
        message: `Import failed: ${errorMessage}`,
        recoverable: false
      };
      result.errors.push(error);
      return result;
    }
  }

  /**
   * Import cURL command
   */
  private static importCurl(content: string, workspaceId: string): ImportResult {
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

    const parseResult = CurlImporter.parse(content, workspaceId);
    
    if (parseResult.success && parseResult.request) {
      result.success = true;
      result.requestsCreated = 1;
      result.requests.push(parseResult.request);
    } else {
      const error: ImportError = {
        path: '',
        message: parseResult.error || 'Failed to parse cURL command',
        recoverable: false
      };
      result.errors.push(error);
    }

    return result;
  }

  /**
   * Import OpenAPI specification
   */
  private static importOpenAPI(content: string, workspaceId: string): ImportResult {
    return OpenAPIImporter.import(content, workspaceId);
  }

  /**
   * Import Postman collection
   */
  private static importPostman(content: string, workspaceId: string): ImportResult {
    return PostmanImporter.import(content, workspaceId);
  }

  /**
   * Import Insomnia export
   */
  private static importInsomnia(content: string, workspaceId: string): ImportResult {
    return InsomniaImporter.import(content, workspaceId);
  }

  /**
   * Import Swagger specification
   */
  private static importSwagger(content: string, workspaceId: string): ImportResult {
    return SwaggerImporter.import(content, workspaceId);
  }

  /**
   * Import Yaak native format
   */
  private static importYaak(content: string, workspaceId: string): ImportResult {
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

    // TODO: Implement Yaak import
    const error: ImportError = {
      path: '',
      message: 'Yaak import not yet implemented',
      recoverable: false
    };
    result.errors.push(error);
    return result;
  }

  /**
   * Generate import preview without actually importing
   */
  static preview(content: string): ImportPreview {
    const format = this.detectFormat(content);
    const preview: ImportPreview = {
      format: format,
      requestCount: 0,
      folderCount: 0,
      environmentCount: 0,
      items: []
    };

    if (format === 'unknown') {
      return preview;
    }

    // For cURL, we can preview immediately
    if (format === 'curl') {
      const parseResult = CurlImporter.parse(content, '');
      if (parseResult.success && parseResult.request) {
        preview.requestCount = 1;
        const item: ImportPreviewItem = {
          type: 'request',
          name: parseResult.request.name,
          method: parseResult.request.method,
          url: parseResult.request.url
        };
        preview.items.push(item);
      }
      return preview;
    }

    // For JSON formats, try to parse and count items
    try {
      const parsed: ESObject = JSON.parse(content) as ESObject;
      this.countItemsFromJson(parsed, format, preview);
    } catch (e) {
      // Unable to preview
    }

    return preview;
  }

  /**
   * Count items from parsed JSON for preview
   */
  private static countItemsFromJson(
    obj: ESObject,
    format: ImportFormat,
    preview: ImportPreview
  ): void {
    switch (format) {
      case 'openapi':
      case 'swagger':
        this.countOpenAPIItems(obj, preview);
        break;
      case 'postman':
        this.countPostmanItems(obj, preview);
        break;
      case 'insomnia':
        this.countInsomniaItems(obj, preview);
        break;
      case 'yaak':
        this.countYaakItems(obj, preview);
        break;
    }
  }

  /**
   * Count items from OpenAPI/Swagger spec
   */
  private static countOpenAPIItems(obj: ESObject, preview: ImportPreview): void {
    if (!obj.paths || typeof obj.paths !== 'object') {
      return;
    }

    const paths = obj.paths as ESObject;
    const methods: string[] = ['get', 'post', 'put', 'delete', 'patch', 'head', 'options'];

    Object.keys(paths).forEach((path: string) => {
      const pathItem = paths[path] as ESObject;
      if (!pathItem || typeof pathItem !== 'object') {
        return;
      }

      methods.forEach((method: string) => {
        if (pathItem[method]) {
          preview.requestCount++;
          const operation = pathItem[method] as ESObject;
          const item: ImportPreviewItem = {
            type: 'request',
            name: (operation.summary as string) || (operation.operationId as string) || `${method.toUpperCase()} ${path}`,
            method: method.toUpperCase(),
            url: path
          };
          preview.items.push(item);
        }
      });
    });
  }

  /**
   * Count items from Postman collection
   */
  private static countPostmanItems(obj: ESObject, preview: ImportPreview): void {
    if (!obj.item || !Array.isArray(obj.item)) {
      return;
    }

    const countItems = (items: ESObject[], parentPreview: ImportPreviewItem[]): void => {
      items.forEach((item: ESObject) => {
        if (!item) return;

        // Check if it's a folder (has item array) or request
        if (item.item && Array.isArray(item.item)) {
          // It's a folder
          preview.folderCount++;
          const folderItem: ImportPreviewItem = {
            type: 'folder',
            name: (item.name as string) || 'Unnamed Folder',
            children: []
          };
          parentPreview.push(folderItem);
          countItems(item.item as ESObject[], folderItem.children!);
        } else if (item.request) {
          // It's a request
          preview.requestCount++;
          const request = item.request as ESObject;
          let url = '';
          if (typeof request.url === 'string') {
            url = request.url;
          } else if (request.url && typeof request.url === 'object') {
            const urlObj = request.url as ESObject;
            url = (urlObj.raw as string) || '';
          }
          const requestItem: ImportPreviewItem = {
            type: 'request',
            name: (item.name as string) || 'Unnamed Request',
            method: (request.method as string) || 'GET',
            url: url
          };
          parentPreview.push(requestItem);
        }
      });
    };

    countItems(obj.item as ESObject[], preview.items);
  }

  /**
   * Count items from Insomnia export
   */
  private static countInsomniaItems(obj: ESObject, preview: ImportPreview): void {
    if (!obj.resources || !Array.isArray(obj.resources)) {
      return;
    }

    const resources = obj.resources as ESObject[];
    resources.forEach((resource: ESObject) => {
      if (!resource || !resource._type) return;

      const type = resource._type as string;
      if (type === 'request') {
        preview.requestCount++;
        const item: ImportPreviewItem = {
          type: 'request',
          name: (resource.name as string) || 'Unnamed Request',
          method: (resource.method as string) || 'GET',
          url: (resource.url as string) || ''
        };
        preview.items.push(item);
      } else if (type === 'request_group') {
        preview.folderCount++;
        const item: ImportPreviewItem = {
          type: 'folder',
          name: (resource.name as string) || 'Unnamed Folder'
        };
        preview.items.push(item);
      } else if (type === 'environment') {
        preview.environmentCount++;
        const item: ImportPreviewItem = {
          type: 'environment',
          name: (resource.name as string) || 'Unnamed Environment'
        };
        preview.items.push(item);
      }
    });
  }

  /**
   * Count items from Yaak export
   */
  private static countYaakItems(obj: ESObject, preview: ImportPreview): void {
    if (!obj.workspaces || !Array.isArray(obj.workspaces)) {
      return;
    }

    const workspaces = obj.workspaces as ESObject[];
    workspaces.forEach((ws: ESObject) => {
      if (!ws) return;

      if (ws.requests && Array.isArray(ws.requests)) {
        const requests = ws.requests as ESObject[];
        preview.requestCount += requests.length;
        requests.forEach((req: ESObject) => {
          const item: ImportPreviewItem = {
            type: 'request',
            name: (req.name as string) || 'Unnamed Request',
            method: (req.method as string) || 'GET',
            url: (req.url as string) || ''
          };
          preview.items.push(item);
        });
      }

      if (ws.folders && Array.isArray(ws.folders)) {
        const folders = ws.folders as ESObject[];
        preview.folderCount += folders.length;
        folders.forEach((folder: ESObject) => {
          const item: ImportPreviewItem = {
            type: 'folder',
            name: (folder.name as string) || 'Unnamed Folder'
          };
          preview.items.push(item);
        });
      }

      if (ws.environments && Array.isArray(ws.environments)) {
        const environments = ws.environments as ESObject[];
        preview.environmentCount += environments.length;
        environments.forEach((env: ESObject) => {
          const item: ImportPreviewItem = {
            type: 'environment',
            name: (env.name as string) || 'Unnamed Environment'
          };
          preview.items.push(item);
        });
      }
    });
  }
}
