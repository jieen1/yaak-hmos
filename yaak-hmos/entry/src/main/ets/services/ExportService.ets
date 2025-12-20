/**
 * ExportService - Export workspaces and requests to various formats
 *
 * Supports:
 * - Yaak native JSON format
 */

import { Workspace } from '../model/Workspace';
import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Environment, EnvironmentVariable } from '../model/Environment';

/**
 * Export options
 */
export interface ExportOptions {
  includeResponses: boolean;
  prettify: boolean;
}

/**
 * Export result
 */
export interface ExportResult {
  success: boolean;
  data: string;
  workspacesExported: number;
  requestsExported: number;
  foldersExported: number;
  environmentsExported: number;
  error: string;
}

/**
 * Exported header structure
 */
interface ExportedHeader {
  id: string;
  name: string;
  value: string;
  enabled: boolean;
}

/**
 * Exported query param structure
 */
interface ExportedQueryParam {
  id: string;
  name: string;
  value: string;
  enabled: boolean;
}

/**
 * Exported auth config structure
 */
interface ExportedAuthConfig {
  type: string;
  basic_username: string;
  basic_password: string;
  bearer_token: string;
  api_key_name: string;
  api_key_value: string;
  api_key_location: string;
  oauth2_access_token: string;
  oauth2_refresh_token: string;
  oauth2_expires_at: number;
}

/**
 * Exported request structure
 */
interface ExportedRequest {
  id: string;
  workspace_id: string;
  folder_id: string | null;
  name: string;
  url: string;
  method: string;
  headers: ExportedHeader[];
  query_params: ExportedQueryParam[];
  body: string;
  body_type: string;
  auth: ExportedAuthConfig | null;
  sort_priority: number;
  created_at: number;
  updated_at: number;
}

/**
 * Exported folder structure
 */
interface ExportedFolder {
  id: string;
  workspace_id: string;
  folder_id: string | null;
  name: string;
  headers: ExportedHeader[];
  auth: ExportedAuthConfig | null;
  sort_priority: number;
  created_at: number;
  updated_at: number;
}

/**
 * Exported environment variable structure
 */
interface ExportedEnvVariable {
  id: string;
  name: string;
  value: string;
  enabled: boolean;
  is_secret: boolean;
}

/**
 * Exported environment structure
 */
interface ExportedEnvironment {
  id: string;
  workspace_id: string;
  name: string;
  variables: ExportedEnvVariable[];
  created_at: number;
  updated_at: number;
}

/**
 * Exported workspace structure
 */
interface ExportedWorkspace {
  workspace: WorkspaceData;
  folders: ExportedFolder[];
  requests: ExportedRequest[];
  environments: ExportedEnvironment[];
}

/**
 * Workspace data structure
 */
interface WorkspaceData {
  id: string;
  name: string;
  description: string;
  created_at: number;
  updated_at: number;
}

/**
 * Yaak export data structure
 */
interface YaakExportData {
  version: string;
  exportedAt: number;
  workspaces: ExportedWorkspace[];
}

export class ExportService {
  private static readonly EXPORT_VERSION: string = '1.0.0';

  /**
   * Export a single workspace
   */
  static exportWorkspace(
    workspace: Workspace,
    requests: HttpRequest[],
    folders: Folder[],
    environments: Environment[],
    options: ExportOptions
  ): ExportResult {
    const result: ExportResult = {
      success: false,
      data: '',
      workspacesExported: 0,
      requestsExported: 0,
      foldersExported: 0,
      environmentsExported: 0,
      error: ''
    };

    try {
      // Filter environments based on options
      let filteredEnvs: Environment[] = environments;

      // Build export data
      const exportedWorkspace: ExportedWorkspace = ExportService.buildExportedWorkspace(
        workspace,
        requests,
        folders,
        filteredEnvs
      );

      const exportData: YaakExportData = {
        version: ExportService.EXPORT_VERSION,
        exportedAt: Date.now(),
        workspaces: [exportedWorkspace]
      };

      // Convert to JSON
      if (options.prettify) {
        result.data = JSON.stringify(exportData, null, 2);
      } else {
        result.data = JSON.stringify(exportData);
      }

      result.success = true;
      result.workspacesExported = 1;
      result.requestsExported = requests.length;
      result.foldersExported = folders.length;
      result.environmentsExported = filteredEnvs.length;

    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      result.error = `Export failed: ${errorMessage}`;
    }

    return result;
  }

  /**
   * Export multiple workspaces
   */
  static exportWorkspaces(
    workspacesData: WorkspaceExportInput[],
    options: ExportOptions
  ): ExportResult {
    const result: ExportResult = {
      success: false,
      data: '',
      workspacesExported: 0,
      requestsExported: 0,
      foldersExported: 0,
      environmentsExported: 0,
      error: ''
    };

    try {
      const exportedWorkspaces: ExportedWorkspace[] = [];

      workspacesData.forEach((wsData: WorkspaceExportInput) => {
        // Filter environments based on options
        let filteredEnvs: Environment[] = wsData.environments;

        const exportedWorkspace: ExportedWorkspace = ExportService.buildExportedWorkspace(
          wsData.workspace,
          wsData.requests,
          wsData.folders,
          filteredEnvs
        );

        exportedWorkspaces.push(exportedWorkspace);

        result.requestsExported += wsData.requests.length;
        result.foldersExported += wsData.folders.length;
        result.environmentsExported += filteredEnvs.length;
      });

      const exportData: YaakExportData = {
        version: ExportService.EXPORT_VERSION,
        exportedAt: Date.now(),
        workspaces: exportedWorkspaces
      };

      // Convert to JSON
      if (options.prettify) {
        result.data = JSON.stringify(exportData, null, 2);
      } else {
        result.data = JSON.stringify(exportData);
      }

      result.success = true;
      result.workspacesExported = workspacesData.length;

    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      result.error = `Export failed: ${errorMessage}`;
    }

    return result;
  }

  /**
   * Build exported workspace structure
   */
  private static buildExportedWorkspace(
    workspace: Workspace,
    requests: HttpRequest[],
    folders: Folder[],
    environments: Environment[]
  ): ExportedWorkspace {
    const workspaceData: WorkspaceData = {
      id: workspace.id,
      name: workspace.name,
      description: workspace.description,
      created_at: workspace.created_at,
      updated_at: workspace.updated_at
    };

    const exportedFolders: ExportedFolder[] = [];
    folders.forEach((folder: Folder) => {
      const exported: ExportedFolder = ExportService.buildExportedFolder(folder);
      exportedFolders.push(exported);
    });

    const exportedRequests: ExportedRequest[] = [];
    requests.forEach((request: HttpRequest) => {
      const exported: ExportedRequest = ExportService.buildExportedRequest(request);
      exportedRequests.push(exported);
    });

    const exportedEnvironments: ExportedEnvironment[] = [];
    environments.forEach((env: Environment) => {
      const exported: ExportedEnvironment = ExportService.buildExportedEnvironment(env);
      exportedEnvironments.push(exported);
    });

    const result: ExportedWorkspace = {
      workspace: workspaceData,
      folders: exportedFolders,
      requests: exportedRequests,
      environments: exportedEnvironments
    };

    return result;
  }

  /**
   * Build exported folder structure
   */
  private static buildExportedFolder(folder: Folder): ExportedFolder {
    const exportedHeaders: ExportedHeader[] = [];
    folder.headers.forEach((header: HttpHeader) => {
      const exported: ExportedHeader = {
        id: header.id,
        name: header.name,
        value: header.value,
        enabled: header.enabled
      };
      exportedHeaders.push(exported);
    });

    let exportedAuth: ExportedAuthConfig | null = null;
    if (folder.auth) {
      exportedAuth = ExportService.buildExportedAuth(folder.auth);
    }

    const result: ExportedFolder = {
      id: folder.id,
      workspace_id: folder.workspace_id,
      folder_id: folder.folder_id,
      name: folder.name,
      headers: exportedHeaders,
      auth: exportedAuth,
      sort_priority: folder.sort_priority,
      created_at: folder.created_at,
      updated_at: folder.updated_at
    };

    return result;
  }

  /**
   * Build exported request structure
   */
  private static buildExportedRequest(request: HttpRequest): ExportedRequest {
    const exportedHeaders: ExportedHeader[] = [];
    request.headers.forEach((header: HttpHeader) => {
      const exported: ExportedHeader = {
        id: header.id,
        name: header.name,
        value: header.value,
        enabled: header.enabled
      };
      exportedHeaders.push(exported);
    });

    const exportedParams: ExportedQueryParam[] = [];
    request.query_params.forEach((param: QueryParam) => {
      const exported: ExportedQueryParam = {
        id: param.id,
        name: param.name,
        value: param.value,
        enabled: param.enabled
      };
      exportedParams.push(exported);
    });

    let exportedAuth: ExportedAuthConfig | null = null;
    if (request.auth) {
      exportedAuth = ExportService.buildExportedAuth(request.auth);
    }

    const result: ExportedRequest = {
      id: request.id,
      workspace_id: request.workspace_id,
      folder_id: request.folder_id,
      name: request.name,
      url: request.url,
      method: request.method,
      headers: exportedHeaders,
      query_params: exportedParams,
      body: request.body || '',
      body_type: request.body_type,
      auth: exportedAuth,
      sort_priority: request.sort_priority,
      created_at: request.created_at,
      updated_at: request.updated_at
    };

    return result;
  }

  /**
   * Build exported environment structure
   */
  private static buildExportedEnvironment(env: Environment): ExportedEnvironment {
    const exportedVars: ExportedEnvVariable[] = [];
    env.variables.forEach((variable: EnvironmentVariable) => {
      const exported: ExportedEnvVariable = {
        id: variable.id,
        name: variable.name,
        value: variable.value,
        enabled: variable.enabled,
        is_secret: variable.is_secret
      };
      exportedVars.push(exported);
    });

    const result: ExportedEnvironment = {
      id: env.id,
      workspace_id: env.workspace_id,
      name: env.name,
      variables: exportedVars,
      created_at: env.created_at,
      updated_at: env.updated_at
    };

    return result;
  }

  /**
   * Build exported auth config structure
   */
  private static buildExportedAuth(auth: AuthConfig): ExportedAuthConfig {
    const result: ExportedAuthConfig = {
      type: auth.type,
      basic_username: auth.basic_username,
      basic_password: auth.basic_password,
      bearer_token: auth.bearer_token,
      api_key_name: auth.api_key_name,
      api_key_value: auth.api_key_value,
      api_key_location: auth.api_key_location,
      oauth2_access_token: auth.oauth2_access_token,
      oauth2_refresh_token: auth.oauth2_refresh_token,
      oauth2_expires_at: auth.oauth2_expires_at
    };

    return result;
  }
}

/**
 * Input structure for exporting multiple workspaces
 */
export interface WorkspaceExportInput {
  workspace: Workspace;
  requests: HttpRequest[];
  folders: Folder[];
  environments: Environment[];
}
