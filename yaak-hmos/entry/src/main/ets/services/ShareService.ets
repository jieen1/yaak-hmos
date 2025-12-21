/**
 * ShareService - System share service
 * Handles sharing requests, folders, and workspaces
 */

import { common, Want } from '@kit.AbilityKit';
import { ShareError } from '../common/FlareError';
import { CurlGenerator } from './CurlGenerator';
import type { HttpRequest } from '../model/HttpRequest';
import type { Folder } from '../model/Folder';
import type { Workspace } from '../model/Workspace';
import type { Environment } from '../model/Environment';

const SHARE_VERSION = '1.0.0';
const SHARE_APP_NAME = 'Flare';

/**
 * Share data type
 */
export type ShareType = 'request' | 'folder' | 'workspace' | 'curl';

/**
 * Share data interface
 */
export interface ShareData {
  type: ShareType;
  title: string;
  content: string;
  mimeType: string;
}

/**
 * Import result interface
 */
export interface ImportResult {
  success: boolean;
  importedCount: number;
  errors: string[];
}

/**
 * Exported request data
 */
interface ExportedRequest {
  id: string;
  name: string;
  method: string;
  url: string;
  headers: object[];
  queryParams: object[];
  body: string;
  bodyType: string;
  auth: object | null;
  sortOrder: number;
}

/**
 * Exported folder data
 */
interface ExportedFolder {
  id: string;
  name: string;
  parentId: string | null;
  sortOrder: number;
  requests: ExportedRequest[];
}

/**
 * Exported workspace data
 */
interface ExportedWorkspace {
  id: string;
  name: string;
  description: string;
  folders: ExportedFolder[];
  requests: ExportedRequest[];
  environments: object[];
}

/**
 * Flare export format
 */
interface FlareExportData {
  app: string;
  version: string;
  exportedAt: number;
  type: ShareType;
  data: ExportedRequest | ExportedFolder | ExportedWorkspace;
}

/**
 * Share received callback type
 */
export type ShareReceivedCallback = (data: ShareData) => void;

/**
 * ShareService - Manages sharing functionality
 */
export class ShareService {
  private static callbacks: ShareReceivedCallback[] = [];

  /**
   * Share single request
   */
  static async shareRequest(context: common.UIAbilityContext, request: HttpRequest): Promise<void> {
    const exportData = ShareService.exportRequest(request);
    const shareData: ShareData = {
      type: 'request',
      title: `${request.name} - Flare Request`,
      content: JSON.stringify(exportData, null, 2),
      mimeType: 'application/json'
    };

    await ShareService.showSharePanel(context, shareData);
  }

  /**
   * Share folder with all requests
   */
  static async shareFolder(
    context: common.UIAbilityContext,
    folder: Folder,
    requests: HttpRequest[]
  ): Promise<void> {
    const exportData = ShareService.exportFolder(folder, requests);
    const shareData: ShareData = {
      type: 'folder',
      title: `${folder.name} - Flare Folder`,
      content: JSON.stringify(exportData, null, 2),
      mimeType: 'application/json'
    };

    await ShareService.showSharePanel(context, shareData);
  }

  /**
   * Share workspace with all data
   */
  static async shareWorkspace(
    context: common.UIAbilityContext,
    workspace: Workspace,
    requests: HttpRequest[],
    folders: Folder[],
    environments: Environment[]
  ): Promise<void> {
    const exportData = ShareService.exportWorkspace(workspace, requests, folders, environments);
    const shareData: ShareData = {
      type: 'workspace',
      title: `${workspace.name} - Flare Workspace`,
      content: JSON.stringify(exportData, null, 2),
      mimeType: 'application/json'
    };

    await ShareService.showSharePanel(context, shareData);
  }

  /**
   * Share request as cURL command
   */
  static async shareAsCurl(context: common.UIAbilityContext, request: HttpRequest): Promise<void> {
    // Create empty variables map for cURL generation
    const emptyVariables: Map<string, string> = new Map();
    const curlCommand = CurlGenerator.generate(request, emptyVariables);
    const shareData: ShareData = {
      type: 'curl',
      title: `${request.name} - cURL`,
      content: curlCommand,
      mimeType: 'text/plain'
    };

    await ShareService.showSharePanel(context, shareData);
  }

  /**
   * Import share data
   */
  static async importShareData(
    dataStr: string,
    targetWorkspaceId: string
  ): Promise<ImportResult> {
    const result: ImportResult = {
      success: false,
      importedCount: 0,
      errors: []
    };

    try {
      // Validate data format
      if (!ShareService.validateShareData(dataStr)) {
        result.errors.push('无效的数据格式');
        return result;
      }

      const parsed: ESObject = JSON.parse(dataStr) as ESObject;
      const exportData = parsed as FlareExportData;

      // Check version compatibility
      if (exportData.version !== SHARE_VERSION) {
        console.warn('[ShareService] Version mismatch:', exportData.version, 'vs', SHARE_VERSION);
      }

      // Import based on type
      switch (exportData.type) {
        case 'request':
          result.importedCount = 1;
          break;
        case 'folder':
          const folderData = exportData.data as ExportedFolder;
          result.importedCount = folderData.requests.length + 1;
          break;
        case 'workspace':
          const workspaceData = exportData.data as ExportedWorkspace;
          result.importedCount = workspaceData.requests.length + 
            workspaceData.folders.length + 
            workspaceData.environments.length + 1;
          break;
        default:
          result.errors.push('未知的数据类型');
          return result;
      }

      result.success = true;
      console.info('[ShareService] Import successful, count:', result.importedCount);
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      result.errors.push(errorMsg);
      console.error('[ShareService] Import failed:', error);
    }

    return result;
  }

  /**
   * Validate share data format
   */
  static validateShareData(dataStr: string): boolean {
    try {
      const parsed: ESObject = JSON.parse(dataStr) as ESObject;
      
      // Check required fields
      if (!parsed.app || parsed.app !== SHARE_APP_NAME) {
        return false;
      }
      if (!parsed.version) {
        return false;
      }
      if (!parsed.type) {
        return false;
      }
      if (!parsed.data) {
        return false;
      }

      return true;
    } catch (error) {
      return false;
    }
  }

  /**
   * Register share received callback
   */
  static onShareReceived(callback: ShareReceivedCallback): void {
    ShareService.callbacks.push(callback);
  }

  /**
   * Unregister share received callback
   */
  static offShareReceived(callback: ShareReceivedCallback): void {
    const index = ShareService.callbacks.indexOf(callback);
    if (index > -1) {
      ShareService.callbacks.splice(index, 1);
    }
  }

  /**
   * Notify share received
   */
  static notifyShareReceived(data: ShareData): void {
    ShareService.callbacks.forEach((callback: ShareReceivedCallback) => {
      try {
        callback(data);
      } catch (error) {
        console.error('[ShareService] Callback error:', error);
      }
    });
  }

  /**
   * Show system share panel
   */
  private static async showSharePanel(
    context: common.UIAbilityContext,
    shareData: ShareData
  ): Promise<void> {
    try {
      const want: Want = {
        action: 'ohos.want.action.select',
        type: shareData.mimeType,
        parameters: {
          'ability.picker.type': 'share',
          'ability.picker.text': shareData.content,
          'ability.picker.title': shareData.title
        }
      };

      await context.startAbility(want);
      console.info('[ShareService] Share panel opened');
    } catch (error) {
      console.error('[ShareService] Show share panel failed:', error);
      throw new Error(error);
    }
  }

  /**
   * Export single request
   */
  private static exportRequest(request: HttpRequest): FlareExportData {
    const exportedRequest: ExportedRequest = {
      id: request.id,
      name: request.name,
      method: request.method,
      url: request.url,
      headers: request.headers as object[],
      queryParams: request.query_params as object[],
      body: request.body || '',
      bodyType: request.body_type,
      auth: request.auth as object | null,
      sortOrder: request.sort_priority
    };

    const exportData: FlareExportData = {
      app: SHARE_APP_NAME,
      version: SHARE_VERSION,
      exportedAt: Date.now(),
      type: 'request',
      data: exportedRequest
    };

    return exportData;
  }

  /**
   * Export folder with requests
   */
  private static exportFolder(folder: Folder, requests: HttpRequest[]): FlareExportData {
    const exportedRequests: ExportedRequest[] = [];
    
    requests.forEach((request: HttpRequest) => {
      const exported: ExportedRequest = {
        id: request.id,
        name: request.name,
        method: request.method,
        url: request.url,
        headers: request.headers as object[],
        queryParams: request.query_params as object[],
        body: request.body || '',
        bodyType: request.body_type,
        auth: request.auth as object | null,
        sortOrder: request.sort_priority
      };
      exportedRequests.push(exported);
    });

    const exportedFolder: ExportedFolder = {
      id: folder.id,
      name: folder.name,
      parentId: folder.folder_id,
      sortOrder: folder.sort_priority,
      requests: exportedRequests
    };

    const exportData: FlareExportData = {
      app: SHARE_APP_NAME,
      version: SHARE_VERSION,
      exportedAt: Date.now(),
      type: 'folder',
      data: exportedFolder
    };

    return exportData;
  }

  /**
   * Export workspace with all data
   */
  private static exportWorkspace(
    workspace: Workspace,
    requests: HttpRequest[],
    folders: Folder[],
    environments: Environment[]
  ): FlareExportData {
    // Export folders with their requests
    const exportedFolders: ExportedFolder[] = [];
    folders.forEach((folder: Folder) => {
      const folderRequests = requests.filter((r: HttpRequest) => r.folder_id === folder.id);
      const exportedRequests: ExportedRequest[] = [];
      
      folderRequests.forEach((request: HttpRequest) => {
        const exported: ExportedRequest = {
          id: request.id,
          name: request.name,
          method: request.method,
          url: request.url,
          headers: request.headers as object[],
          queryParams: request.query_params as object[],
          body: request.body || '',
          bodyType: request.body_type,
          auth: request.auth as object | null,
          sortOrder: request.sort_priority
        };
        exportedRequests.push(exported);
      });

      const exportedFolder: ExportedFolder = {
        id: folder.id,
        name: folder.name,
        parentId: folder.folder_id,
        sortOrder: folder.sort_priority,
        requests: exportedRequests
      };
      exportedFolders.push(exportedFolder);
    });

    // Export root-level requests
    const rootRequests = requests.filter((r: HttpRequest) => !r.folder_id);
    const exportedRootRequests: ExportedRequest[] = [];
    rootRequests.forEach((request: HttpRequest) => {
      const exported: ExportedRequest = {
        id: request.id,
        name: request.name,
        method: request.method,
        url: request.url,
        headers: request.headers as object[],
        queryParams: request.query_params as object[],
        body: request.body || '',
        bodyType: request.body_type,
        auth: request.auth as object | null,
        sortOrder: request.sort_priority
      };
      exportedRootRequests.push(exported);
    });

    // Export environments
    const exportedEnvironments: object[] = [];
    environments.forEach((env: Environment) => {
      exportedEnvironments.push(env as object);
    });

    const exportedWorkspace: ExportedWorkspace = {
      id: workspace.id,
      name: workspace.name,
      description: workspace.description || '',
      folders: exportedFolders,
      requests: exportedRootRequests,
      environments: exportedEnvironments
    };

    const exportData: FlareExportData = {
      app: SHARE_APP_NAME,
      version: SHARE_VERSION,
      exportedAt: Date.now(),
      type: 'workspace',
      data: exportedWorkspace
    };

    return exportData;
  }
}
