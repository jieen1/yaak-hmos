/**
 * Main Page - Yaak HarmonyOS Application
 * Entry point with three-pane layout
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { HttpResponse } from '../model/HttpResponse';
import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';
import { Folder } from '../model/Folder';
import { SidebarItem } from '../viewmodel/SidebarItem';
import { DatabaseManager } from '../database/DatabaseManager';
import { WorkspaceRepository } from '../database/WorkspaceRepository';
import { RequestRepository } from '../database/RequestRepository';
import { FolderRepository } from '../database/FolderRepository';
import { EnvironmentRepository } from '../database/EnvironmentRepository';
import { ResponseRepository } from '../database/ResponseRepository';
import { RequestExecutor, RequestExecutionResult } from '../services/RequestExecutor';
import { EnvironmentService } from '../services/EnvironmentService';
import { ResponseStorageService } from '../services/ResponseStorageService';
import { WorkspaceHeader } from '../components/WorkspaceHeader';
import { SidebarComponent } from '../components/SidebarComponent';
import { RequestEditorComponent } from '../components/RequestEditorComponent';
import { ResponseViewerComponent } from '../components/ResponseViewerComponent';
import { EmptyState } from '../components/EmptyState';
import { SettingsDialog } from '../components/SettingsDialog';
import { WorkspaceManagementDialog } from '../components/WorkspaceManagementDialog';
import { EnvironmentManagementDialog } from '../components/EnvironmentManagementDialog';
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

  // UI State
  @Local isLoading: boolean = true;
  @Local isRequestLoading: boolean = false;
  @Local sidebarHidden: boolean = false;
  @Local workspaceLayout: string = 'horizontal';
  @Local showSettingsDialog: boolean = false;
  @Local showWorkspaceManagementDialog: boolean = false;
  @Local showEnvironmentManagementDialog: boolean = false;

  // Context
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  // Repository Instances
  private workspaceRepo: WorkspaceRepository = new WorkspaceRepository();
  private requestRepo: RequestRepository = new RequestRepository();
  private folderRepo: FolderRepository = new FolderRepository();
  private environmentRepo: EnvironmentRepository = new EnvironmentRepository();
  private responseRepo: ResponseRepository = new ResponseRepository();

  async aboutToAppear(): Promise<void> {
    try {
      // Initialize database
      await DatabaseManager.getInstance().init(this.context);
      await DatabaseManager.getInstance().waitForInit();

      // Initialize ResponseStorageService
      ResponseStorageService.init(this.context);

      // Load workspaces
      await this.loadWorkspaces();

      // Create default workspace if none exist
      if (this.workspaces.length === 0) {
        await this.createDefaultWorkspace();
      }

      // Select first workspace and load its data
      if (this.workspaces.length > 0) {
        const firstWorkspace: Workspace | undefined = this.workspaces[0];
        this.selectedWorkspace = firstWorkspace || null;
        await this.loadWorkspaceData();
      }
    } catch (error) {
      console.error('Initialization failed:', JSON.stringify(error));
    } finally {
      this.isLoading = false;
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
    if (!this.selectedWorkspace) return;

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
    if (!this.selectedWorkspace) return;

    try {
      this.environments = await this.environmentRepo.getEnvironmentsByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load environments:', JSON.stringify(error));
    }
  }

  async loadFolders(): Promise<void> {
    if (!this.selectedWorkspace) return;

    try {
      this.folders = await this.folderRepo.getFoldersByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load folders:', JSON.stringify(error));
    }
  }

  async loadRequests(): Promise<void> {
    if (!this.selectedWorkspace) return;

    try {
      this.requests = await this.requestRepo.getRequestsByWorkspaceId(
        this.selectedWorkspace.id
      );
    } catch (error) {
      console.error('Failed to load requests:', JSON.stringify(error));
    }
  }

  // Sidebar Building
  rebuildSidebar(): void {
    const items: SidebarItem[] = [];
    this.buildSidebarLevel(null, 0, items);
    this.sidebarItems = items;
  }

  buildSidebarLevel(parentId: string | null, level: number, result: SidebarItem[]): void {
    // Add folders at this level
    const levelFolders: Folder[] = this.folders.filter((f: Folder) => f.folder_id === parentId);
    levelFolders.forEach((folder: Folder) => {
      const item: SidebarItem = new SidebarItem('folder', folder, level);
      result.push(item);
      // Recursively add children
      this.buildSidebarLevel(folder.id, level + 1, result);
    });

    // Add requests at this level
    const levelRequests: HttpRequest[] = this.requests.filter((r: HttpRequest) => r.folder_id === parentId);
    levelRequests.forEach((request: HttpRequest) => {
      const item: SidebarItem = new SidebarItem('request', request, level);
      result.push(item);
    });
  }

  // Creation Methods
  async createDefaultWorkspace(): Promise<void> {
    const workspace: Workspace = new Workspace();
    workspace.id = `ws_${Date.now()}`;
    workspace.name = 'Default Workspace';
    workspace.description = 'Your first workspace';
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
    if (!this.selectedWorkspace) return;

    const request: HttpRequest = new HttpRequest();
    request.id = `req_${Date.now()}`;
    request.workspace_id = this.selectedWorkspace.id;
    request.name = 'New Request';
    request.url = 'https://api.example.com';
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
    if (!this.selectedWorkspace) return;

    const folder: Folder = new Folder();
    folder.id = `folder_${Date.now()}`;
    folder.workspace_id = this.selectedWorkspace.id;
    folder.name = 'New Folder';
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
    if (!this.selectedWorkspace) return;

    // Create a copy of the request
    const duplicatedRequest: HttpRequest = new HttpRequest();
    
    // Generate new unique ID
    duplicatedRequest.id = `req_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    
    // Copy all configuration
    duplicatedRequest.workspace_id = request.workspace_id;
    duplicatedRequest.folder_id = request.folder_id;
    duplicatedRequest.name = `${request.name} Copy`;
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
    if (!this.selectedWorkspace) return;

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
    if (!this.selectedRequest) return;

    this.isRequestLoading = true;
    this.responseBody = '';
    this.selectedResponse = null;

    const startTime: number = Date.now();

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

      // Update UI with response
      this.selectedResponse = result.response;
      this.responseBody = result.bodyContent;

    } catch (error) {
      console.error('Request execution failed:', JSON.stringify(error));
      // RequestExecutor already creates error response, but we need to handle UI
      this.responseBody = `Error: ${JSON.stringify(error)}`;
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
  }

  handleRequestChange(request: HttpRequest): void {
    if (this.selectedRequest && request.id === this.selectedRequest.id) {
      this.selectedRequest = request;
      // Save changes to database
      this.requestRepo.updateRequest(request);
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
        }
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

      Text('Initializing...')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: $r('app.float.spacing_md') })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Local sidebarWidth: number = 250;
  @Local isSidebarDragging: boolean = false;
  @Local sidebarDragStartX: number = 0;
  @Local sidebarDragStartWidth: number = 0;

  @Local responseWidth: number = 350;
  @Local isResponseDragging: boolean = false;
  @Local responseDragStartX: number = 0;
  @Local responseDragStartWidth: number = 0;

  @Builder
  buildMainContent() {
    Row() {
      // Sidebar with inline resize logic
      if (!this.sidebarHidden) {
        Column() {
          SidebarComponent({
            items: this.sidebarItems,
            selectedRequestId: this.selectedRequest?.id || '',
            onRequestCreate: this.handleRequestCreate,
            onFolderCreate: this.handleFolderCreate,
            onRequestSelect: this.handleRequestSelectById,
            onFolderToggle: this.handleFolderToggle
          })
        }
        .width(this.sidebarWidth)
        .height('100%')
        .backgroundColor($r('app.color.sidebar_background'))

        // Resize Handle
        Column() {
          Column()
            .width(2)
            .height('100%')
            .backgroundColor(this.isSidebarDragging ? $r('app.color.primary') : $r('app.color.divider'))
        }
        .width(8)
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .backgroundColor(Color.Transparent)
        .gesture(
          PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 1 })
            .onActionStart((event: GestureEvent) => {
              this.isSidebarDragging = true;
              this.sidebarDragStartX = event.fingerList[0].globalX;
              this.sidebarDragStartWidth = this.sidebarWidth;
            })
            .onActionUpdate((event: GestureEvent) => {
              if (this.isSidebarDragging) {
                const currentX: number = event.fingerList[0].globalX;
                const deltaX: number = currentX - this.sidebarDragStartX;
                let newWidth: number = this.sidebarDragStartWidth + deltaX;

                // Apply constraints
                if (newWidth < 200) {
                  newWidth = 200;
                } else if (newWidth > 500) {
                  newWidth = 500;
                }

                this.sidebarWidth = newWidth;
              }
            })
            .onActionEnd(() => {
              this.isSidebarDragging = false;
              const storageKey: string = `sidebar_width_${this.selectedWorkspace?.id || 'default'}`;
              AppStorage.setOrCreate(storageKey, this.sidebarWidth);
            })
        )
      }

      // Request Editor - takes remaining space
      Column() {
        if (this.selectedRequest) {
          RequestEditorComponent({
            request: this.selectedRequest,
            isLoading: this.isRequestLoading,
            onExecute: this.handleExecuteRequest,
            onChange: this.handleRequestChangeCallback
          })
        } else {
          EmptyState({
            onNewRequest: this.handleRequestCreate,
            onImport: this.handleImport
          })
        }
      }
      .layoutWeight(1)
      .height('100%')
      .backgroundColor($r('app.color.background'))

      // Resize Handle for Response
      Column() {
        Column()
          .width(2)
          .height('100%')
          .backgroundColor(this.isResponseDragging ? $r('app.color.primary') : $r('app.color.divider'))
      }
      .width(8)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.Transparent)
      .gesture(
        PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 1 })
          .onActionStart((event: GestureEvent) => {
            this.isResponseDragging = true;
            this.responseDragStartX = event.fingerList[0].globalX;
            this.responseDragStartWidth = this.responseWidth;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.isResponseDragging) {
              const currentX: number = event.fingerList[0].globalX;
              const deltaX: number = this.responseDragStartX - currentX;
              let newWidth: number = this.responseDragStartWidth + deltaX;

              // Apply constraints
              if (newWidth < 300) {
                newWidth = 300;
              } else if (newWidth > 800) {
                newWidth = 800;
              }

              this.responseWidth = newWidth;
            }
          })
          .onActionEnd(() => {
            this.isResponseDragging = false;
            const storageKey: string = `response_width_${this.selectedWorkspace?.id || 'default'}`;
            AppStorage.setOrCreate(storageKey, this.responseWidth);
          })
      )

      // Response Viewer
      Column() {
        ResponseViewerComponent({
          response: this.selectedResponse,
          responseBody: this.responseBody,
          isLoading: this.isRequestLoading
        })
      }
      .width(this.responseWidth)
      .height('100%')
      .backgroundColor($r('app.color.background'))
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

  handleImport = (): void => {
    // TODO: Implement import functionality
  }

  // Callback handler for request execution
  handleExecuteRequest = (): void => {
    this.executeRequest();
  }

  handleRequestChangeCallback = (req: HttpRequest): void => {
    this.handleRequestChange(req);
  }
}
