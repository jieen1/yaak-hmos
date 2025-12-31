/**
 * Main Page - Flare HarmonyOS Application
 * Entry point with three-pane layout
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { HttpResponse } from '../model/HttpResponse';
import { Workspace } from '../model/Workspace';
import { Environment, EnvironmentVariable } from '../model/Environment';
import { Folder } from '../model/Folder';
import { SidebarItem } from '../viewmodel/SidebarItem';
import { DatabaseManager } from '../database/DatabaseManager';
import { WorkspaceRepository } from '../database/WorkspaceRepository';
import { RequestRepository } from '../database/RequestRepository';
import { FolderRepository } from '../database/FolderRepository';
import { EnvironmentRepository } from '../database/EnvironmentRepository';
import { ResponseRepository } from '../database/ResponseRepository';
import { RequestExecutor, RequestExecutionResult } from '../services/RequestExecutor';
import promptAction from '@ohos.promptAction';
import { EnvironmentService } from '../services/EnvironmentService';
import { ResponseStorageService } from '../services/ResponseStorageService';
import { WorkspaceHeader } from '../components/WorkspaceHeader';
import { SidebarComponent } from '../components/SidebarComponent';
import { RequestEditorComponent } from '../components/RequestEditorComponent';
import { ResponseViewerComponent } from '../components/ResponseViewerComponent';
import { EmptyState } from '../components/EmptyState';
import { ThemedText } from '../components/ThemedText';
import { SettingsDialog } from '../components/SettingsDialog';
import { WorkspaceManagementDialog } from '../components/WorkspaceManagementDialog';
import { EnvironmentManagementDialog } from '../components/EnvironmentManagementDialog';
import { FolderSettingsDialog } from '../components/FolderSettingsDialog';
import { WorkspaceSettingsDialog } from '../components/WorkspaceSettingsDialog';
import { ResizeHandle, ResizeEvent } from '../components/ResizeHandle';
import { PreferencesService, PreferenceKeys } from '../services/PreferencesService';
import { ExportDialog, WorkspaceDataResult } from '../components/ExportDialog';
import { ExportResult } from '../services/ExportService';
import { InheritanceService } from '../services/InheritanceService';
import type { InheritedHeaderWithSource, InheritedAuthInfo } from '../services/InheritanceService';
import { FontSettings } from '../services/FontService';
import EntryAbility from '../entryability/EntryAbility';
import common from '@ohos.app.ability.common';

@Entry
@ComponentV2
struct Index {
  // Data Collections
  @Local workspaces: Workspace[] = [];
  @Local requests: HttpRequest[] = [];
  @Local folders: Folder[] = [];
  @Local environments: Environment[] = [];
  @Local sidebarItems: SidebarItem[] = [];
  // Selected Items
  @Local selectedWorkspace: Workspace | null = null;
  @Local selectedRequest: HttpRequest | null = null;
  @Local selectedEnvironment: Environment | null = null;
  @Local selectedResponse: HttpResponse | null = null;
  // Response Data
  @Local responseBody: string = '';
  @Local responseHistory: HttpResponse[] = [];
  // UI State
  @Local isLoading: boolean = true;
  @Local isRequestLoading: boolean = false;
  @Local sidebarHidden: boolean = false;
  @Local workspaceLayout: string = 'horizontal';
  @Local showSettingsDialog: boolean = false;
  @Local showWorkspaceManagementDialog: boolean = false;
  @Local showEnvironmentManagementDialog: boolean = false;
  @Local showExportDialog: boolean = false;
  @Local showFolderSettingsDialog: boolean = false;
  @Local showWorkspaceSettingsDialog: boolean = false;
  @Local selectedFolderForSettings: Folder | null = null;
  // Persistent UI Settings
  @Local sidebarWidth: number = 250;
  @Local responseWidth: number = 350;
  @Local responseViewerHidden: boolean = true;
  // Editor Settings
  @Local editorKeymap: string = 'default';
  @Local editorSoftWrap: boolean = false;
  // Resize state
  @Local isSidebarResizing: boolean = false;
  @Local isResponseResizing: boolean = false;
  @Local sidebarResizeStartWidth: number = 0;
  @Local responseResizeStartWidth: number = 0;
  // Context
  private context: common.UIAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext;
  // Preferences service
  private preferencesService: PreferencesService = PreferencesService.getInstance();
  // Repository Instances
  private workspaceRepo: WorkspaceRepository = new WorkspaceRepository();
  private requestRepo: RequestRepository = new RequestRepository();
  private folderRepo: FolderRepository = new FolderRepository();
  private environmentRepo: EnvironmentRepository = new EnvironmentRepository();
  private responseRepo: ResponseRepository = new ResponseRepository();

  async aboutToAppear(): Promise<void> {
    console.info('[Index] Starting application initialization');
    try {
      // Initialize preferences service
      await this.preferencesService.init(this.context);

      // Load persistent settings
      await this.loadPersistentSettings();

      // Initialize database
      console.info('[Index] Initializing database');
      await DatabaseManager.getInstance().init(this.context);
      await DatabaseManager.getInstance().waitForInit();
      console.info('[Index] Database initialized successfully');

      // Initialize ResponseStorageService
      ResponseStorageService.init(this.context);
      console.info('[Index] ResponseStorageService initialized');

      // Load workspaces
      await this.loadWorkspaces();
      console.info(`[Index] Loaded ${this.workspaces.length} workspaces`);

      // Create default workspace if none exist
      if (this.workspaces.length === 0) {
        console.info('[Index] Creating default workspace');
        await this.createDefaultWorkspace();
      }

      // Select first workspace and load its data
      if (this.workspaces.length > 0) {
        const firstWorkspace: Workspace | undefined = this.workspaces[0];
        this.selectedWorkspace = firstWorkspace || null;
        console.info(`[Index] Selected workspace: ${this.selectedWorkspace?.name}`);
        await this.loadWorkspaceData();
      }

      console.info('[Index] Application initialization completed');
    } catch (error) {
      console.error('[Index] Initialization failed:', error);
    } finally {
      this.isLoading = false;
    }
  }

  // Load persistent settings from preferences
  async loadPersistentSettings(): Promise<void> {
    try {
      // Load global settings
      this.responseViewerHidden = await this.preferencesService.getBoolean(
        PreferenceKeys.RESPONSE_VIEWER_HIDDEN,
        true
      );

      this.editorKeymap = await this.preferencesService.getString(
        PreferenceKeys.EDITOR_KEYMAP,
        'default'
      );

      this.editorSoftWrap = await this.preferencesService.getBoolean(
        PreferenceKeys.EDITOR_SOFT_WRAP,
        false
      );

      // Load font settings
      const interfaceFont: string = await this.preferencesService.getString(
        PreferenceKeys.INTERFACE_FONT,
        'system'
      );

      const interfaceFontSize: number = await this.preferencesService.getNumber(
        PreferenceKeys.INTERFACE_FONT_SIZE,
        14
      );

      const editorFont: string = await this.preferencesService.getString(
        PreferenceKeys.EDITOR_FONT,
        'system'
      );

      const editorFontSize: number = await this.preferencesService.getNumber(
        PreferenceKeys.EDITOR_FONT_SIZE,
        14
      );

      // Initialize FontSettings with loaded values
      FontSettings.getInstance().init(interfaceFont, interfaceFontSize, editorFont, editorFontSize);

      // Load workspace-specific settings if workspace is selected
      if (this.selectedWorkspace) {
        const workspaceId: string = this.selectedWorkspace.id;

        this.sidebarWidth = await this.preferencesService.getNumber(
          PreferenceKeys.getSidebarWidthKey(workspaceId),
          250
        );

        this.sidebarHidden = await this.preferencesService.getBoolean(
          PreferenceKeys.getSidebarHiddenKey(workspaceId),
          false
        );

        this.responseWidth = await this.preferencesService.getNumber(
          PreferenceKeys.getResponseWidthKey(workspaceId),
          350
        );
      }

      console.info('[Index] Loaded persistent settings:', {
        sidebarWidth: this.sidebarWidth,
        sidebarHidden: this.sidebarHidden,
        responseWidth: this.responseWidth,
        responseViewerHidden: this.responseViewerHidden,
        editorKeymap: this.editorKeymap,
        editorSoftWrap: this.editorSoftWrap,
        interfaceFont: interfaceFont,
        interfaceFontSize: interfaceFontSize,
        editorFont: editorFont,
        editorFontSize: editorFontSize
      });
    } catch (error) {
      console.error('[Index] Failed to load persistent settings:', JSON.stringify(error));
    }
  }

  // Apply theme setting via EntryAbility
  private applyThemeSetting(theme: string): void {
    const entryAbility = EntryAbility.getInstance();
    if (entryAbility !== null) {
      entryAbility.applyThemeMode(theme);
    }
  }

  // Save persistent settings to preferences
  async saveSidebarWidth(width: number): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      const key: string = PreferenceKeys.getSidebarWidthKey(this.selectedWorkspace.id);
      await this.preferencesService.setNumber(key, width);
    } catch (error) {
      console.error('[Index] Failed to save sidebar width:', JSON.stringify(error));
    }
  }

  async saveSidebarHidden(hidden: boolean): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      const key: string = PreferenceKeys.getSidebarHiddenKey(this.selectedWorkspace.id);
      await this.preferencesService.setBoolean(key, hidden);
    } catch (error) {
      console.error('[Index] Failed to save sidebar hidden:', JSON.stringify(error));
    }
  }

  async saveResponseWidth(width: number): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      const key: string = PreferenceKeys.getResponseWidthKey(this.selectedWorkspace.id);
      await this.preferencesService.setNumber(key, width);
    } catch (error) {
      console.error('[Index] Failed to save response width:', JSON.stringify(error));
    }
  }

  async saveResponseViewerHidden(hidden: boolean): Promise<void> {
    try {
      await this.preferencesService.setBoolean(PreferenceKeys.RESPONSE_VIEWER_HIDDEN, hidden);
      console.info('[Index] Saved response viewer hidden:', hidden);
    } catch (error) {
      console.error('[Index] Failed to save response viewer hidden:', JSON.stringify(error));
    }
  }

  // Data Loading Methods
  async loadWorkspaces(): Promise<void> {
    try {
      this.workspaces = await this.workspaceRepo.getAllWorkspaces();
    } catch (error) {
      console.error('Failed to load workspaces:', JSON.stringify(error));
    }
  }

  async loadWorkspaceData(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      await this.loadEnvironments();
      await this.loadFolders();
      await this.loadRequests();
      this.rebuildSidebar();
    } catch (error) {
      console.error('Failed to load workspace data:', JSON.stringify(error));
    }
  }

  async loadEnvironments(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      this.environments = await this.environmentRepo.getEnvironmentsByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load environments:', JSON.stringify(error));
    }
  }

  async loadFolders(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      this.folders = await this.folderRepo.getFoldersByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load folders:', JSON.stringify(error));
    }
  }

  async loadRequests(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      this.requests = await this.requestRepo.getRequestsByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load requests:', JSON.stringify(error));
    }
  }

  // Sidebar Building - builds a proper tree structure
  rebuildSidebar(): void {
    const items: SidebarItem[] = [];
    this.buildSidebarTree(null, 0, items);
    this.sidebarItems = items;
    console.info('[Index] Sidebar rebuilt with', items.length, 'root items');
  }

  /**
   * Build sidebar tree structure with proper parent-child relationships
   */
  buildSidebarTree(parentId: string | null, level: number, result: SidebarItem[]): void {
    // Get folders at this level, sorted by priority
    const levelFolders: Folder[] = this.folders
      .filter((f: Folder) => f.folder_id === parentId)
      .sort((a: Folder, b: Folder) => a.sort_priority - b.sort_priority);

    // Get requests at this level, sorted by priority
    const levelRequests: HttpRequest[] = this.requests
      .filter((r: HttpRequest) => r.folder_id === parentId)
      .sort((a: HttpRequest, b: HttpRequest) => a.sort_priority - b.sort_priority);

    // Add folders with their children
    levelFolders.forEach((folder: Folder) => {
      const folderItem: SidebarItem = new SidebarItem('folder', folder, level);
      // Build children into the folder's children array
      this.buildSidebarTree(folder.id, level + 1, folderItem.children);
      result.push(folderItem);
    });

    // Add requests at this level
    levelRequests.forEach((request: HttpRequest) => {
      const requestItem: SidebarItem = new SidebarItem('request', request, level);
      result.push(requestItem);
    });
  }

  // Creation Methods
  async createDefaultWorkspace(): Promise<void> {
    const workspace: Workspace = new Workspace();
    workspace.id = `ws_${Date.now()}`;
    workspace.name = '默认工作区';
    workspace.description = '您的第一个工作区';
    workspace.created_at = Date.now();
    workspace.updated_at = Date.now();

    try {
      await this.workspaceRepo.createWorkspace(workspace);
      await this.loadWorkspaces();
    } catch (error) {
      console.error('Failed to create default workspace:', JSON.stringify(error));
    }
  }

  async createRequest(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    const request: HttpRequest = new HttpRequest();
    request.id = `req_${Date.now()}`;
    request.workspace_id = this.selectedWorkspace.id;
    request.name = '新建请求';
    request.url = '';
    request.method = 'GET';
    request.created_at = Date.now();
    request.updated_at = Date.now();

    try {
      await this.requestRepo.createRequest(request);
      await this.loadRequests();
      this.rebuildSidebar();

      // Select the newly created request
      const newRequest: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === request.id);
      if (newRequest) {
        this.selectedRequest = newRequest;
      }
    } catch (error) {
      console.error('Failed to create request:', JSON.stringify(error));
    }
  }

  async createFolder(): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    const folder: Folder = new Folder();
    folder.id = `folder_${Date.now()}`;
    folder.workspace_id = this.selectedWorkspace.id;
    folder.name = '新建文件夹';
    folder.created_at = Date.now();
    folder.updated_at = Date.now();

    try {
      await this.folderRepo.createFolder(folder);
      await this.loadFolders();
      this.rebuildSidebar();
    } catch (error) {
      console.error('Failed to create folder:', JSON.stringify(error));
    }
  }

  // Duplication Methods
  async duplicateRequest(request: HttpRequest): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    // Create a copy of the request
    const duplicatedRequest: HttpRequest = new HttpRequest();

    // Generate new unique ID
    duplicatedRequest.id = `req_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // Copy all configuration
    duplicatedRequest.workspace_id = request.workspace_id;
    duplicatedRequest.folder_id = request.folder_id;
    duplicatedRequest.name = `${request.name} Copy`;
    duplicatedRequest.name_manually_set = true; // 复制的请求名称是手动设置的
    duplicatedRequest.url = request.url;
    duplicatedRequest.method = request.method;
    duplicatedRequest.body = request.body;
    duplicatedRequest.body_type = request.body_type;
    duplicatedRequest.sort_priority = request.sort_priority + 1;

    // Copy headers
    duplicatedRequest.headers = [];
    request.headers.forEach((header: HttpHeader) => {
      const newHeader: HttpHeader = new HttpHeader();
      newHeader.id = `header_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      newHeader.name = header.name;
      newHeader.value = header.value;
      newHeader.enabled = header.enabled;
      duplicatedRequest.headers.push(newHeader);
    });

    // Copy query parameters
    duplicatedRequest.query_params = [];
    request.query_params.forEach((param: QueryParam) => {
      const newParam: QueryParam = new QueryParam();
      newParam.id = `param_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      newParam.name = param.name;
      newParam.value = param.value;
      newParam.enabled = param.enabled;
      duplicatedRequest.query_params.push(newParam);
    });

    // Copy authentication
    if (request.auth !== null) {
      duplicatedRequest.auth = new AuthConfig();
      duplicatedRequest.auth.type = request.auth.type;
      duplicatedRequest.auth.basic_username = request.auth.basic_username;
      duplicatedRequest.auth.basic_password = request.auth.basic_password;
      duplicatedRequest.auth.bearer_token = request.auth.bearer_token;
      duplicatedRequest.auth.api_key_name = request.auth.api_key_name;
      duplicatedRequest.auth.api_key_value = request.auth.api_key_value;
      duplicatedRequest.auth.api_key_location = request.auth.api_key_location;
      duplicatedRequest.auth.oauth2_access_token = request.auth.oauth2_access_token;
      duplicatedRequest.auth.oauth2_refresh_token = request.auth.oauth2_refresh_token;
      duplicatedRequest.auth.oauth2_expires_at = request.auth.oauth2_expires_at;
    }

    // Set timestamps
    duplicatedRequest.created_at = Date.now();
    duplicatedRequest.updated_at = Date.now();

    try {
      await this.requestRepo.createRequest(duplicatedRequest);
      await this.loadRequests();
      this.rebuildSidebar();

      // Select the duplicated request
      const newRequest: HttpRequest | undefined = this.requests.find(
        (r: HttpRequest) => r.id === duplicatedRequest.id
      );
      if (newRequest) {
        this.selectedRequest = newRequest;
      }
    } catch (error) {
      console.error('Failed to duplicate request:', JSON.stringify(error));
    }
  }

  async duplicateFolder(folder: Folder): Promise<void> {
    if (!this.selectedWorkspace) {
      return;
    }

    try {
      // Duplicate the folder and all its children recursively
      const newFolderId: string = await this.duplicateFolderRecursive(
        folder,
        folder.folder_id
      );

      // Reload data and rebuild sidebar
      await this.loadFolders();
      await this.loadRequests();
      this.rebuildSidebar();

      console.info(`Folder duplicated successfully: ${newFolderId}`);
    } catch (error) {
      console.error('Failed to duplicate folder:', JSON.stringify(error));
    }
  }

  private async duplicateFolderRecursive(
    folder: Folder,
    parentFolderId: string | null
  ): Promise<string> {
    // Create a copy of the folder
    const duplicatedFolder: Folder = new Folder();

    // Generate new unique ID
    const newFolderId: string = `folder_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    duplicatedFolder.id = newFolderId;

    // Copy configuration
    duplicatedFolder.workspace_id = folder.workspace_id;
    duplicatedFolder.folder_id = parentFolderId;
    duplicatedFolder.name = `${folder.name} Copy`;
    duplicatedFolder.sort_priority = folder.sort_priority + 1;

    // Copy headers
    duplicatedFolder.headers = [];
    folder.headers.forEach((header: HttpHeader) => {
      const newHeader: HttpHeader = new HttpHeader();
      newHeader.id = `header_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      newHeader.name = header.name;
      newHeader.value = header.value;
      newHeader.enabled = header.enabled;
      duplicatedFolder.headers.push(newHeader);
    });

    // Copy authentication
    if (folder.auth !== null) {
      duplicatedFolder.auth = new AuthConfig();
      duplicatedFolder.auth.type = folder.auth.type;
      duplicatedFolder.auth.basic_username = folder.auth.basic_username;
      duplicatedFolder.auth.basic_password = folder.auth.basic_password;
      duplicatedFolder.auth.bearer_token = folder.auth.bearer_token;
      duplicatedFolder.auth.api_key_name = folder.auth.api_key_name;
      duplicatedFolder.auth.api_key_value = folder.auth.api_key_value;
      duplicatedFolder.auth.api_key_location = folder.auth.api_key_location;
      duplicatedFolder.auth.oauth2_access_token = folder.auth.oauth2_access_token;
      duplicatedFolder.auth.oauth2_refresh_token = folder.auth.oauth2_refresh_token;
      duplicatedFolder.auth.oauth2_expires_at = folder.auth.oauth2_expires_at;
    }

    // Set timestamps
    duplicatedFolder.created_at = Date.now();
    duplicatedFolder.updated_at = Date.now();

    // Save the duplicated folder
    await this.folderRepo.createFolder(duplicatedFolder);

    // Find and duplicate child folders
    const childFolders: Folder[] = this.folders.filter(
      (f: Folder) => f.folder_id === folder.id
    );
    for (let i = 0; i < childFolders.length; i++) {
      const childFolder: Folder | undefined = childFolders[i];
      if (childFolder) {
        await this.duplicateFolderRecursive(childFolder, newFolderId);
      }
    }

    // Find and duplicate child requests
    const childRequests: HttpRequest[] = this.requests.filter(
      (r: HttpRequest) => r.folder_id === folder.id
    );
    for (let i = 0; i < childRequests.length; i++) {
      const childRequest: HttpRequest | undefined = childRequests[i];
      if (childRequest) {
        await this.duplicateRequestToFolder(childRequest, newFolderId);
      }
    }

    return newFolderId;
  }

  private async duplicateRequestToFolder(
    request: HttpRequest,
    newFolderId: string
  ): Promise<void> {
    // Create a copy of the request
    const duplicatedRequest: HttpRequest = new HttpRequest();

    // Generate new unique ID
    duplicatedRequest.id = `req_${Date.now()}_${Math.floor(Math.random() * 1000)}`;

    // Copy all configuration
    duplicatedRequest.workspace_id = request.workspace_id;
    duplicatedRequest.folder_id = newFolderId;
    duplicatedRequest.name = request.name;
    duplicatedRequest.name_manually_set = request.name_manually_set; // 保留原请求的标记
    duplicatedRequest.url = request.url;
    duplicatedRequest.method = request.method;
    duplicatedRequest.body = request.body;
    duplicatedRequest.body_type = request.body_type;
    duplicatedRequest.sort_priority = request.sort_priority;

    // Copy headers
    duplicatedRequest.headers = [];
    request.headers.forEach((header: HttpHeader) => {
      const newHeader: HttpHeader = new HttpHeader();
      newHeader.id = `header_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      newHeader.name = header.name;
      newHeader.value = header.value;
      newHeader.enabled = header.enabled;
      duplicatedRequest.headers.push(newHeader);
    });

    // Copy query parameters
    duplicatedRequest.query_params = [];
    request.query_params.forEach((param: QueryParam) => {
      const newParam: QueryParam = new QueryParam();
      newParam.id = `param_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      newParam.name = param.name;
      newParam.value = param.value;
      newParam.enabled = param.enabled;
      duplicatedRequest.query_params.push(newParam);
    });

    // Copy authentication
    if (request.auth !== null) {
      duplicatedRequest.auth = new AuthConfig();
      duplicatedRequest.auth.type = request.auth.type;
      duplicatedRequest.auth.basic_username = request.auth.basic_username;
      duplicatedRequest.auth.basic_password = request.auth.basic_password;
      duplicatedRequest.auth.bearer_token = request.auth.bearer_token;
      duplicatedRequest.auth.api_key_name = request.auth.api_key_name;
      duplicatedRequest.auth.api_key_value = request.auth.api_key_value;
      duplicatedRequest.auth.api_key_location = request.auth.api_key_location;
      duplicatedRequest.auth.oauth2_access_token = request.auth.oauth2_access_token;
      duplicatedRequest.auth.oauth2_refresh_token = request.auth.oauth2_refresh_token;
      duplicatedRequest.auth.oauth2_expires_at = request.auth.oauth2_expires_at;
    }

    // Set timestamps
    duplicatedRequest.created_at = Date.now();
    duplicatedRequest.updated_at = Date.now();

    // Save the duplicated request
    await this.requestRepo.createRequest(duplicatedRequest);
  }

  // Request Execution
  async executeRequest(): Promise<void> {
    if (!this.selectedRequest) {
      console.warn('[Index] No request selected');
      return;
    }

    console.info(`[Index] Starting request execution: ${this.selectedRequest.method} ${this.selectedRequest.url}`);
    this.isRequestLoading = true;
    this.responseBody = '';
    this.selectedResponse = null;

    try {
      // Merge environment variables
      const envs: Environment[] = this.selectedEnvironment ? [this.selectedEnvironment] : [];
      const variables: Map<string, string> = EnvironmentService.mergeVariables(envs);

      // Execute request with inheritance support
      const result: RequestExecutionResult = await RequestExecutor.execute(
        this.selectedRequest,
        this.selectedWorkspace?.id || '',
        variables,
        this.folders,
        this.selectedWorkspace
      );

      console.info(`[Index] Request completed successfully, status: ${result.response.status_code}`);

      // Update UI with response
      this.selectedResponse = result.response;
      this.responseBody = result.bodyContent;

      // Reload response history to include the new response
      await this.loadResponseHistory(this.selectedRequest.id);

      // Auto-open response viewer when response is received
      if (this.responseViewerHidden) {
        this.responseViewerHidden = false;
        this.saveResponseViewerHidden(false);
      }

    } catch (error) {
      console.error(`[Index] Request execution failed:`, error);
      // RequestExecutor already creates error response, but we need to handle UI
      this.responseBody = `Error: ${JSON.stringify(error)}`;

      // Reload response history even on error (error response may have been saved)
      if (this.selectedRequest) {
        await this.loadResponseHistory(this.selectedRequest.id);
      }

      // Auto-open response viewer even on error
      if (this.responseViewerHidden) {
        this.responseViewerHidden = false;
        this.saveResponseViewerHidden(false);
      }
    } finally {
      this.isRequestLoading = false;
    }
  }

  // Event Handlers
  handleWorkspaceSelect(workspace: Workspace): void {
    if (this.selectedWorkspace?.id !== workspace.id) {
      this.selectedWorkspace = workspace;
      this.selectedRequest = null;
      this.selectedResponse = null;
      this.responseBody = '';
      this.loadWorkspaceData();
    }
  }

  handleEnvironmentSelect(environment: Environment | null): void {
    this.selectedEnvironment = environment;
  }

  handleRequestSelect(request: HttpRequest | null): void {
    this.selectedRequest = request;
    this.selectedResponse = null;
    this.responseBody = '';
    this.responseHistory = [];

    // Load response history for the selected request
    if (request) {
      this.loadResponseHistory(request.id);
    }
  }

  async loadResponseHistory(requestId: string): Promise<void> {
    try {
      this.responseHistory = await this.responseRepo.getResponsesByRequestId(requestId);
      console.info(`[Index] Loaded ${this.responseHistory.length} responses for request: ${requestId}`);

      // If there's history but no selected response, select the latest one
      if (this.responseHistory.length > 0 && !this.selectedResponse) {
        const latestResponse: HttpResponse | undefined = this.responseHistory[0];
        if (latestResponse) {
          await this.selectResponse(latestResponse);
        }
      }
    } catch (error) {
      console.error('[Index] Failed to load response history:', JSON.stringify(error));
    }
  }

  async selectResponse(response: HttpResponse): Promise<void> {
    try {
      this.selectedResponse = response;

      // Load response body from file
      if (response.body_path) {
        this.responseBody = await ResponseStorageService.loadResponseBody(response.body_path);
      } else {
        this.responseBody = '';
      }

      console.info(`[Index] Selected response: ${response.id}`);
    } catch (error) {
      console.error('[Index] Failed to load response body:', JSON.stringify(error));
      this.responseBody = '';
    }
  }

  async clearResponseHistory(): Promise<void> {
    if (!this.selectedRequest) {
      return;
    }

    try {
      // Delete all responses for this request
      await this.responseRepo.deleteResponsesByRequestId(this.selectedRequest.id);

      // Clear response body files
      for (let i = 0; i < this.responseHistory.length; i++) {
        const response: HttpResponse | undefined = this.responseHistory[i];
        if (response && response.body_path) {
          await ResponseStorageService.deleteResponseBody(response.body_path);
        }
      }

      // Clear UI state
      this.responseHistory = [];
      this.selectedResponse = null;
      this.responseBody = '';

      console.info(`[Index] Cleared response history for request: ${this.selectedRequest.id}`);
    } catch (error) {
      console.error('[Index] Failed to clear response history:', JSON.stringify(error));
    }
  }

  async handleRequestChange(request: HttpRequest): Promise<void> {
    if (this.selectedRequest && request.id === this.selectedRequest.id) {
      // 检查 URL 是否变化，且用户未手动设置名称
      const oldRequest: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === request.id);
      const urlChanged: boolean = oldRequest !== undefined && oldRequest.url !== request.url;
      
      if (urlChanged && !request.name_manually_set && request.url.trim().length > 0) {
        // 自动从 URL 生成名称
        const generatedName: string = this.generateNameFromUrl(request.url);
        if (generatedName.length > 0) {
          request.name = generatedName;
          console.info(`[Index] Auto-updated request name from URL: ${generatedName}`);
        }
      }

      this.selectedRequest = request;

      // 同步更新 requests 数组中的对应项，确保数据一致性
      const index: number = this.requests.findIndex((r: HttpRequest) => r.id === request.id);
      if (index >= 0) {
        this.requests[index] = request;
      }

      // Save changes to database
      try {
        await this.requestRepo.updateRequest(request);
        console.info(`[Index] Request updated: ${request.id}`);
      } catch (error) {
        console.error(`[Index] Failed to update request:`, error);
      }
    }
  }

  /**
   * Generate request name from URL
   * Returns full host:port/path format
   */
  private generateNameFromUrl(url: string): string {
    try {
      // Remove leading/trailing whitespace
      const trimmedUrl: string = url.trim();
      if (trimmedUrl.length === 0) {
        return '';
      }

      // Parse URL
      let urlToParse: string = trimmedUrl;
      
      // Add protocol if missing
      if (!urlToParse.match(/^https?:\/\//i)) {
        urlToParse = 'http://' + urlToParse;
      }

      // Remove query params and hash
      const urlWithoutQuery: string = urlToParse.split('?')[0] || '';
      const urlWithoutHash: string = urlWithoutQuery.split('#')[0] || '';

      // Extract host and path
      const protocolMatch: RegExpMatchArray | null = urlWithoutHash.match(/^https?:\/\//i);
      if (!protocolMatch) {
        return trimmedUrl;
      }

      const withoutProtocol: string = urlWithoutHash.substring(protocolMatch[0].length);
      
      // Remove trailing slash
      const cleanUrl: string = withoutProtocol.endsWith('/') 
        ? withoutProtocol.substring(0, withoutProtocol.length - 1)
        : withoutProtocol;

      return cleanUrl.length > 0 ? cleanUrl : trimmedUrl;
    } catch (error) {
      console.error('[Index] Failed to generate name from URL:', error);
      return url;
    }
  }

  build() {
    Column() {
      // Workspace Header
      WorkspaceHeader({
        workspaces: this.workspaces,
        activeWorkspace: this.selectedWorkspace,
        environments: this.environments,
        activeEnvironment: this.selectedEnvironment,
        responseViewerHidden: this.responseViewerHidden,
        onWorkspaceSelect: (ws: Workspace) => {
          this.handleWorkspaceSelect(ws);
        },
        onEnvironmentSelect: (env: Environment | null) => {
          this.handleEnvironmentSelect(env);
        },
        onOpenSettings: () => {
          this.showSettingsDialog = true;
        },
        onManageWorkspaces: () => {
          this.showWorkspaceManagementDialog = true;
        },
        onManageEnvironments: () => {
          this.showEnvironmentManagementDialog = true;
        },
        onToggleResponseViewer: () => {
          this.responseViewerHidden = !this.responseViewerHidden;
          // Save to persistent storage
          this.saveResponseViewerHidden(this.responseViewerHidden);
        },
        onExport: () => {
          this.showExportDialog = true;
        },
      })

      // Main Content
      if (this.isLoading) {
        this.buildLoadingState();
      } else {
        this.buildMainContent();
      }

      // Settings Dialog
      if (this.showSettingsDialog) {
        SettingsDialog({
          isVisible: this.showSettingsDialog,
          onClose: () => {
            this.showSettingsDialog = false;
          },
          onSettingsChange: {
            onThemeChange: (theme: string): void => {
              this.applyThemeSetting(theme);
            },
            onInterfaceFontChange: async (font: string): Promise<void> => {
              FontSettings.getInstance().setInterfaceFont(font);
              await this.preferencesService.setString(PreferenceKeys.INTERFACE_FONT, font);
            },
            onInterfaceFontSizeChange: async (size: number): Promise<void> => {
              FontSettings.getInstance().setInterfaceFontSize(size);
              await this.preferencesService.setNumber(PreferenceKeys.INTERFACE_FONT_SIZE, size);
            },
            onEditorFontChange: async (font: string): Promise<void> => {
              FontSettings.getInstance().setEditorFont(font);
              await this.preferencesService.setString(PreferenceKeys.EDITOR_FONT, font);
            },
            onEditorFontSizeChange: async (size: number): Promise<void> => {
              FontSettings.getInstance().setEditorFontSize(size);
              await this.preferencesService.setNumber(PreferenceKeys.EDITOR_FONT_SIZE, size);
            },
            onEditorKeymapChange: async (keymap: string): Promise<void> => {
              this.editorKeymap = keymap;
              await this.preferencesService.setString(PreferenceKeys.EDITOR_KEYMAP, keymap);
            },
            onSoftWrapChange: async (enabled: boolean): Promise<void> => {
              this.editorSoftWrap = enabled;
              await this.preferencesService.setBoolean(PreferenceKeys.EDITOR_SOFT_WRAP, enabled);
            }
          }
        })
      }

      // Workspace Management Dialog
      if (this.showWorkspaceManagementDialog) {
        WorkspaceManagementDialog({
          isVisible: this.showWorkspaceManagementDialog,
          workspaces: this.workspaces,
          onClose: () => {
            this.showWorkspaceManagementDialog = false;
          },
          onCreate: async (workspace: Workspace) => {
            await this.workspaceRepo.createWorkspace(workspace);
            await this.loadWorkspaces();
          },
          onUpdate: async (workspace: Workspace) => {
            await this.workspaceRepo.updateWorkspace(workspace);
            await this.loadWorkspaces();
          },
          onDelete: async (workspaceId: string) => {
            await this.workspaceRepo.deleteWorkspace(workspaceId);
            await this.loadWorkspaces();
          }
        })
      }

      // Environment Management Dialog
      if (this.showEnvironmentManagementDialog) {
        EnvironmentManagementDialog({
          isVisible: this.showEnvironmentManagementDialog,
          workspaceId: this.selectedWorkspace?.id || '',
          environments: this.environments,
          onClose: () => {
            this.showEnvironmentManagementDialog = false;
          },
          onCreate: async (environment: Environment) => {
            await this.environmentRepo.createEnvironment(environment);
            await this.loadEnvironments();
          },
          onUpdate: async (environment: Environment) => {
            await this.environmentRepo.updateEnvironment(environment);
            await this.loadEnvironments();
          },
          onDelete: async (environmentId: string) => {
            await this.environmentRepo.deleteEnvironment(environmentId);
            await this.loadEnvironments();
          }
        })
      }

      // Export Dialog
      if (this.showExportDialog) {
        ExportDialog({
          isVisible: this.showExportDialog,
          workspaces: this.workspaces,
          currentWorkspace: this.selectedWorkspace,
          onClose: () => {
            this.showExportDialog = false;
          },
          onExportComplete: (result: ExportResult) => {
            console.info('[Index] Export completed:', result.workspacesExported, 'workspaces');
          },
          getWorkspaceData: this.getWorkspaceDataForExport
        })
      }

      // Folder Settings Dialog
      if (this.showFolderSettingsDialog && this.selectedFolderForSettings !== null) {
        FolderSettingsDialog({
          visible: this.showFolderSettingsDialog,
          folder: this.selectedFolderForSettings,
          folders: this.folders,
          workspace: this.selectedWorkspace,
          onClose: () => {
            this.showFolderSettingsDialog = false;
            this.selectedFolderForSettings = null;
          },
          onSave: this.handleFolderSettingsSave,
          onNavigateToSource: this.handleNavigateToSource
        })
      }

      // Workspace Settings Dialog
      if (this.showWorkspaceSettingsDialog && this.selectedWorkspace !== null) {
        WorkspaceSettingsDialog({
          visible: this.showWorkspaceSettingsDialog,
          workspace: this.selectedWorkspace,
          onClose: () => {
            this.showWorkspaceSettingsDialog = false;
          },
          onSave: this.handleWorkspaceSettingsSave
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.primary'))

      ThemedText({
        content: 'Initializing...',
        fontColor: $r('app.color.text_secondary')
      })
        .margin({ top: $r('app.float.spacing_md') })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildMainContent() {
    Row() {
      // Sidebar toggle button when hidden
      if (this.sidebarHidden) {
        Column() {
          ThemedText({
            content: '☰',
            fontSizeOverride: 20,
            fontColor: $r('app.color.text_secondary')
          })
            .onClick(() => {
              this.sidebarHidden = false;
              this.saveSidebarHidden(false);
            })
        }
        .width(32)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.sidebar_background'))
        .borderWidth({ right: 1 })
        .borderColor($r('app.color.divider'))
      }

      // Sidebar with ResizeHandle
      if (!this.sidebarHidden) {
        Column() {
          SidebarComponent({
            items: this.sidebarItems,
            selectedRequestId: this.selectedRequest?.id || '',
            onRequestCreate: this.handleRequestCreate,
            onFolderCreate: this.handleFolderCreate,
            onRequestSelect: this.handleRequestSelectById,
            onFolderToggle: this.handleFolderToggle,
            onRequestRename: this.handleRequestRename,
            onRequestDelete: this.handleRequestDelete,
            onRequestDuplicate: this.handleRequestDuplicate,
            onRequestSend: this.handleRequestSend,
            onFolderRename: this.handleFolderRename,
            onFolderDelete: this.handleFolderDelete,
            onFolderDuplicate: this.handleFolderDuplicate,
            onFolderSettings: this.handleFolderSettings,
            onItemMove: this.handleItemMove
          })
        }
        .width(this.sidebarWidth)
        .height('100%')
        .backgroundColor($r('app.color.sidebar_background'))
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })

        // Resize Handle for Sidebar
        ResizeHandle({
          side: 'right',
          onResizeStart: this.handleSidebarResizeStart,
          onResizeMove: this.handleSidebarResizeMove,
          onResizeEnd: this.handleSidebarResizeEnd,
          onReset: this.handleSidebarReset
        })
      }

      // Request Editor - takes remaining space
      Column() {
        if (this.selectedRequest) {
          RequestEditorComponent({
            request: this.selectedRequest,
            inheritedHeaders: this.getInheritedHeadersForSelectedRequest(),
            inheritedAuth: this.getInheritedAuthForSelectedRequest(),
            variables: this.getEffectiveVariables(),
            isLoading: this.isRequestLoading,
            onExecute: this.handleExecuteRequest,
            onCancel: this.handleCancelRequest,
            onChange: this.handleRequestChangeCallback,
            onCurlImport: this.handleCurlImport,
            onNavigateToSource: this.handleNavigateToSource
          })
        } else {
          EmptyState({
            onNewRequest: this.handleRequestCreate,
            onImport: () => {
              // TODO
            }
          })
        }
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor($r('app.color.background'))

      // Response Viewer (conditionally rendered)
      if (!this.responseViewerHidden) {
        // Resize Handle for Response - using same ResizeHandle component as sidebar
        ResizeHandle({
          side: 'left',
          onResizeStart: this.handleResponseResizeStart,
          onResizeMove: this.handleResponseResizeMove,
          onResizeEnd: this.handleResponseResizeEnd,
          onReset: this.handleResponseReset
        })

        // Response Viewer
        Column() {
          ResponseViewerComponent({
            response: this.selectedResponse,
            responseBody: this.responseBody,
            isLoading: this.isRequestLoading,
            responseHistory: this.responseHistory,
            onSelectResponse: this.handleSelectResponse,
            onClearHistory: this.handleClearHistory
          })
        }
        .width(this.responseWidth)
        .margin({
          right: $r('app.float.spacing_md'),
          top: $r('app.float.spacing_md'),
          bottom: $r('app.float.spacing_md')
        })
        .border({
          width: 1,
          color: $r('app.color.border'),
          radius: $r('app.float.border_radius_lg')
        })
        .animation({
          duration: 200,
          curve: Curve.EaseOut
        })
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  // Callback handlers for sidebar
  handleRequestCreate = (): void => {
    this.createRequest();
  }
  handleFolderCreate = (): void => {
    this.createFolder();
  }
  handleRequestSelectById = (requestId: string): void => {
    const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === requestId);
    this.handleRequestSelect(request || null);
  }
  handleFolderToggle = (folderId: string): void => {
    // Handle folder toggle if needed
  }
  // Callback handler for request execution
  handleExecuteRequest = (): void => {
    this.executeRequest();
  }
  // Cancel request handler
  handleCancelRequest = (): void => {
    this.cancelRequest();
  }

  cancelRequest(): void {
    if (!this.selectedRequest) {
      console.warn('[Index] No request selected to cancel');
      return;
    }

    const cancelled: boolean = RequestExecutor.cancelRequest(this.selectedRequest.id);

    if (cancelled) {
      this.showToast('请求已取消');
    } else {
      this.showToast('没有活动的请求可取消');
    }
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[Index] Toast error:', error);
    }
  }

  handleRequestChangeCallback = async (req: HttpRequest): Promise<void> => {
    await this.handleRequestChange(req);
  }
  handleCurlImport = async (importedRequest: HttpRequest): Promise<void> => {
    // 保留原请求的一些重要属性
    const originalRequest: HttpRequest | null = this.selectedRequest;
    if (originalRequest) {
      // 保留原请求的名称和标记（如果用户已经手动命名过）
      if (originalRequest.name_manually_set) {
        importedRequest.name = originalRequest.name;
        importedRequest.name_manually_set = true;
      }
      // 保留排序优先级和创建时间
      importedRequest.sort_priority = originalRequest.sort_priority;
      importedRequest.created_at = originalRequest.created_at;
    }

    // 先更新 selectedRequest
    this.selectedRequest = importedRequest;

    // 保存到数据库并同步 requests 数组
    await this.handleRequestChange(importedRequest);

    // 重建侧边栏
    this.rebuildSidebar();

    console.info('[Index] cURL imported successfully:', importedRequest.id);
  }
  // Response history handlers
  handleSelectResponse = async (response: HttpResponse): Promise<void> => {
    await this.selectResponse(response);
  }
  handleClearHistory = async (): Promise<void> => {
    await this.clearResponseHistory();
  }
  // Sidebar Resize Handlers
  handleSidebarResizeStart = (): void => {
    this.sidebarResizeStartWidth = this.sidebarWidth;
    this.isSidebarResizing = true;
    console.info('[Index] Sidebar resize started, initial width:', this.sidebarWidth);
  }
  handleSidebarResizeMove = (event: ResizeEvent): void => {
    const delta: number = event.x - event.xStart;
    let newWidth: number = this.sidebarResizeStartWidth + delta;

    // Check for auto-hide (width < 50px)
    if (newWidth < 50) {
      this.sidebarHidden = true;
      this.sidebarWidth = 250; // Reset to default
      console.info('[Index] Sidebar auto-hidden, width reset to 250px');
    } else {
      this.sidebarHidden = false;
      // Apply constraints: min 200px, max 600px
      if (newWidth < 200) {
        newWidth = 200;
      } else if (newWidth > 600) {
        newWidth = 600;
      }
      this.sidebarWidth = newWidth;
    }
  }
  handleSidebarResizeEnd = (): void => {
    this.isSidebarResizing = false;
    console.info('[Index] Sidebar resize ended, final width:', this.sidebarWidth);

    // Persist to preferences
    this.saveSidebarWidth(this.sidebarWidth);
    this.saveSidebarHidden(this.sidebarHidden);
  }
  handleSidebarReset = (): void => {
    this.sidebarWidth = 250;
    this.sidebarHidden = false;
    console.info('[Index] Sidebar width reset to default: 250px');

    // Persist to preferences
    this.saveSidebarWidth(this.sidebarWidth);
    this.saveSidebarHidden(this.sidebarHidden);
  }
  // Response Viewer Resize Handlers
  handleResponseResizeStart = (): void => {
    this.responseResizeStartWidth = this.responseWidth;
    this.isResponseResizing = true;
    console.info('[Index] Response resize started, initial width:', this.responseWidth);
  }
  handleResponseResizeMove = (event: ResizeEvent): void => {
    // For left-side handle, negative delta increases width
    const delta: number = event.xStart - event.x;
    let newWidth: number = this.responseResizeStartWidth + delta;

    // Check for auto-hide (width < 50px)
    if (newWidth < 50) {
      this.responseViewerHidden = true;
      this.responseWidth = 350; // Reset to default
      console.info('[Index] Response viewer auto-hidden, width reset to 350px');
    } else {
      // Apply constraints: min 200px, max 800px
      if (newWidth < 200) {
        newWidth = 200;
      } else if (newWidth > 800) {
        newWidth = 800;
      }
      this.responseWidth = newWidth;
    }
  }
  handleResponseResizeEnd = (): void => {
    this.isResponseResizing = false;
    console.info('[Index] Response resize ended, final width:', this.responseWidth);

    // Persist to preferences
    this.saveResponseWidth(this.responseWidth);
    this.saveResponseViewerHidden(this.responseViewerHidden);
  }
  handleResponseReset = (): void => {
    this.responseWidth = 350;
    this.responseViewerHidden = false;
    console.info('[Index] Response width reset to default: 350px');

    // Persist to preferences
    this.saveResponseWidth(this.responseWidth);
    this.saveResponseViewerHidden(this.responseViewerHidden);
  }
  // Request Management Handlers
  handleRequestRename = async (requestId: string, newName: string): Promise<void> => {
    try {
      const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === requestId);
      if (!request) {
        console.error('[Index] Request not found for rename:', requestId);
        return;
      }

      request.name = newName;
      request.name_manually_set = true; // 标记为用户手动设置
      request.updated_at = Date.now();

      await this.requestRepo.updateRequest(request);
      await this.loadRequests();
      this.rebuildSidebar();

      console.info('[Index] Request renamed:', requestId, newName);
    } catch (error) {
      console.error('[Index] Failed to rename request:', JSON.stringify(error));
    }
  }
  handleRequestDelete = async (requestId: string): Promise<void> => {
    try {
      await this.requestRepo.deleteRequest(requestId);

      // If deleted request was selected, clear selection
      if (this.selectedRequest?.id === requestId) {
        this.selectedRequest = null;
        this.selectedResponse = null;
        this.responseBody = '';
      }

      await this.loadRequests();
      this.rebuildSidebar();

      console.info('[Index] Request deleted:', requestId);
    } catch (error) {
      console.error('[Index] Failed to delete request:', JSON.stringify(error));
    }
  }
  handleRequestDuplicate = async (requestId: string): Promise<void> => {
    try {
      const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === requestId);
      if (!request) {
        console.error('[Index] Request not found for duplicate:', requestId);
        return;
      }

      await this.duplicateRequest(request);
      console.info('[Index] Request duplicated:', requestId);
    } catch (error) {
      console.error('[Index] Failed to duplicate request:', JSON.stringify(error));
    }
  }
  handleRequestSend = async (requestId: string): Promise<void> => {
    try {
      // First select the request
      const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === requestId);
      if (!request) {
        console.error('[Index] Request not found for send:', requestId);
        return;
      }

      // Select the request
      this.selectedRequest = request;

      // Execute the request
      await this.executeRequest();
      console.info('[Index] Request sent from context menu:', requestId);
    } catch (error) {
      console.error('[Index] Failed to send request:', JSON.stringify(error));
    }
  }
  // Folder Management Handlers
  handleFolderRename = async (folderId: string, newName: string): Promise<void> => {
    try {
      const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === folderId);
      if (!folder) {
        console.error('[Index] Folder not found for rename:', folderId);
        return;
      }

      folder.name = newName;
      folder.updated_at = Date.now();

      await this.folderRepo.updateFolder(folder);
      await this.loadFolders();
      this.rebuildSidebar();

      console.info('[Index] Folder renamed:', folderId, newName);
    } catch (error) {
      console.error('[Index] Failed to rename folder:', JSON.stringify(error));
    }
  }
  handleFolderDelete = async (folderId: string): Promise<void> => {
    try {
      // Delete the folder (soft delete)
      await this.folderRepo.deleteFolder(folderId);

      // Also delete all child requests in this folder
      const childRequests: HttpRequest[] = this.requests.filter(
        (r: HttpRequest) => r.folder_id === folderId
      );
      for (let i = 0; i < childRequests.length; i++) {
        const childRequest: HttpRequest | undefined = childRequests[i];
        if (childRequest) {
          await this.requestRepo.deleteRequest(childRequest.id);
        }
      }

      // Also delete all child folders recursively
      await this.deleteFolderChildrenRecursive(folderId);

      // If deleted folder contained selected request, clear selection
      if (this.selectedRequest?.folder_id === folderId) {
        this.selectedRequest = null;
        this.selectedResponse = null;
        this.responseBody = '';
      }

      await this.loadFolders();
      await this.loadRequests();
      this.rebuildSidebar();

      console.info('[Index] Folder deleted:', folderId);
    } catch (error) {
      console.error('[Index] Failed to delete folder:', JSON.stringify(error));
    }
  }

  private async deleteFolderChildrenRecursive(parentFolderId: string): Promise<void> {
    // Find child folders
    const childFolders: Folder[] = this.folders.filter(
      (f: Folder) => f.folder_id === parentFolderId
    );

    for (let i = 0; i < childFolders.length; i++) {
      const childFolder: Folder | undefined = childFolders[i];
      if (childFolder) {
        // Delete child requests in this folder
        const childRequests: HttpRequest[] = this.requests.filter(
          (r: HttpRequest) => r.folder_id === childFolder.id
        );
        for (let j = 0; j < childRequests.length; j++) {
          const childRequest: HttpRequest | undefined = childRequests[j];
          if (childRequest) {
            await this.requestRepo.deleteRequest(childRequest.id);
          }
        }

        // Recursively delete child folders
        await this.deleteFolderChildrenRecursive(childFolder.id);

        // Delete the child folder
        await this.folderRepo.deleteFolder(childFolder.id);
      }
    }
  }

  handleFolderDuplicate = async (folderId: string): Promise<void> => {
    try {
      const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === folderId);
      if (!folder) {
        console.error('[Index] Folder not found for duplicate:', folderId);
        return;
      }

      await this.duplicateFolder(folder);
      console.info('[Index] Folder duplicated:', folderId);
    } catch (error) {
      console.error('[Index] Failed to duplicate folder:', JSON.stringify(error));
    }
  }
  handleFolderSettings = (folderId: string): void => {
    const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === folderId);
    if (folder) {
      this.selectedFolderForSettings = folder;
      this.showFolderSettingsDialog = true;
      console.info('[Index] Opening folder settings:', folderId);
    } else {
      console.error('[Index] Folder not found for settings:', folderId);
    }
  }
  // Folder Settings Save Handler
  handleFolderSettingsSave = async (folder: Folder): Promise<void> => {
    try {
      await this.folderRepo.updateFolder(folder);
      await this.loadFolders();
      this.rebuildSidebar();
      console.info('[Index] Folder settings saved:', folder.id);
    } catch (error) {
      console.error('[Index] Failed to save folder settings:', JSON.stringify(error));
    }
  }
  // Workspace Settings Save Handler
  handleWorkspaceSettingsSave = async (workspace: Workspace): Promise<void> => {
    try {
      await this.workspaceRepo.updateWorkspace(workspace);
      await this.loadWorkspaces();

      // Update selected workspace if it's the one being edited
      if (this.selectedWorkspace && this.selectedWorkspace.id === workspace.id) {
        this.selectedWorkspace = workspace;
      }

      console.info('[Index] Workspace settings saved:', workspace.id);
    } catch (error) {
      console.error('[Index] Failed to save workspace settings:', JSON.stringify(error));
    }
  }
  // Navigate to Source Handler (for inherited headers/auth)
  handleNavigateToSource = (sourceType: string, sourceId: string): void => {
    console.info('[Index] Navigate to source:', sourceType, sourceId);

    if (sourceType === 'folder') {
      const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === sourceId);
      if (folder) {
        this.selectedFolderForSettings = folder;
        this.showFolderSettingsDialog = true;
      }
    } else if (sourceType === 'workspace') {
      this.showWorkspaceSettingsDialog = true;
    }
  }

  // Get inherited headers for selected request
  private getInheritedHeadersForSelectedRequest(): InheritedHeaderWithSource[] {
    if (!this.selectedRequest) {
      return [];
    }
    return InheritanceService.getInheritedHeadersForRequest(
      this.selectedRequest,
      this.folders,
      this.selectedWorkspace
    );
  }

  // Get inherited auth for selected request
  private getInheritedAuthForSelectedRequest(): InheritedAuthInfo | null {
    if (!this.selectedRequest) {
      return null;
    }
    return InheritanceService.getInheritedAuthForRequest(
      this.selectedRequest,
      this.folders,
      this.selectedWorkspace
    );
  }

  // Get effective environment variables
  private getEffectiveVariables(): EnvironmentVariable[] {
    if (!this.selectedEnvironment) {
      return [];
    }
    return this.selectedEnvironment.variables.filter(v => v.enabled);
  }

  // Drag and Drop Handler
  handleItemMove = async (
    itemId: string,
    itemType: string,
    newFolderId: string | null,
    newSortPriority: number
  ): Promise<void> => {
    try {
      console.info('[Index] Moving item:', itemId, 'type:', itemType, 'to folder:', newFolderId, 'priority:',
        newSortPriority);

      if (itemType === 'request') {
        // Find the request
        const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === itemId);
        if (!request) {
          console.error('[Index] Request not found for move:', itemId);
          return;
        }

        // Update folder_id and sort_priority
        request.folder_id = newFolderId;
        request.sort_priority = newSortPriority;
        request.updated_at = Date.now();

        // Save to database
        await this.requestRepo.updateRequest(request);

        // Recalculate sort priorities to avoid conflicts
        await this.recalculateSortPriorities(newFolderId);

      } else if (itemType === 'folder') {
        // Find the folder
        const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === itemId);
        if (!folder) {
          console.error('[Index] Folder not found for move:', itemId);
          return;
        }

        // Prevent moving folder into itself or its descendants
        if (this.isDescendantFolder(itemId, newFolderId)) {
          console.warn('[Index] Cannot move folder into itself or its descendants');
          return;
        }

        // Update folder_id and sort_priority
        folder.folder_id = newFolderId;
        folder.sort_priority = newSortPriority;
        folder.updated_at = Date.now();

        // Save to database
        await this.folderRepo.updateFolder(folder);

        // Recalculate sort priorities to avoid conflicts
        await this.recalculateSortPriorities(newFolderId);
      }

      // Reload data and rebuild sidebar
      await this.loadFolders();
      await this.loadRequests();
      this.rebuildSidebar();

      console.info('[Index] Item moved successfully:', itemId);
    } catch (error) {
      console.error('[Index] Failed to move item:', JSON.stringify(error));
    }
  }

  /**
   * Check if targetFolderId is a descendant of folderId
   */
  private isDescendantFolder(folderId: string, targetFolderId: string | null): boolean {
    if (!targetFolderId) {
      return false;
    }
    if (folderId === targetFolderId) {
      return true;
    }

    // Find the target folder and check its parent chain
    let currentFolderId: string | null = targetFolderId;
    while (currentFolderId) {
      if (currentFolderId === folderId) {
        return true;
      }
      const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === currentFolderId);
      currentFolderId = folder?.folder_id || null;
    }

    return false;
  }

  /**
   * Recalculate sort priorities for items in a folder to avoid conflicts
   */
  private async recalculateSortPriorities(folderId: string | null): Promise<void> {
    // Get all items in the folder
    const folderItems: Folder[] = this.folders.filter((f: Folder) => f.folder_id === folderId);
    const requestItems: HttpRequest[] = this.requests.filter((r: HttpRequest) => r.folder_id === folderId);

    // Combine and sort by current priority
    interface SortableItem {
      id: string;
      type: string;
      priority: number;
    }

    const allItems: SortableItem[] = [];

    folderItems.forEach((f: Folder) => {
      const item: SortableItem = { id: f.id, type: 'folder', priority: f.sort_priority };
      allItems.push(item);
    });

    requestItems.forEach((r: HttpRequest) => {
      const item: SortableItem = { id: r.id, type: 'request', priority: r.sort_priority };
      allItems.push(item);
    });

    // Sort by priority
    allItems.sort((a: SortableItem, b: SortableItem) => a.priority - b.priority);

    // Reassign integer priorities
    for (let i = 0; i < allItems.length; i++) {
      const item: SortableItem | undefined = allItems[i];
      if (item) {
        const newPriority: number = i * 10; // Use increments of 10 for easier insertion later

        if (item.type === 'folder') {
          const folder: Folder | undefined = this.folders.find((f: Folder) => f.id === item.id);
          if (folder && folder.sort_priority !== newPriority) {
            folder.sort_priority = newPriority;
            await this.folderRepo.updateSortPriority(folder.id, newPriority);
          }
        } else {
          const request: HttpRequest | undefined = this.requests.find((r: HttpRequest) => r.id === item.id);
          if (request && request.sort_priority !== newPriority) {
            request.sort_priority = newPriority;
            await this.requestRepo.updateSortPriority(request.id, newPriority);
          }
        }
      }
    }
  }

  // Get workspace data for export
  getWorkspaceDataForExport = (workspaceId: string): WorkspaceDataResult => {
    // For current workspace, return loaded data
    if (this.selectedWorkspace && this.selectedWorkspace.id === workspaceId) {
      const result: WorkspaceDataResult = {
        requests: this.requests,
        folders: this.folders,
        environments: this.environments
      };
      return result;
    }

    // For other workspaces, return empty (would need async loading)
    const emptyResult: WorkspaceDataResult = {
      requests: [],
      folders: [],
      environments: []
    };
    return emptyResult;
  }
}
