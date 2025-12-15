import { HttpRequest } from '../model/HttpRequest';
import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';
import { Folder } from '../model/Folder';
import { SidebarItem } from '../viewmodel/SidebarItem';
import { RequestRepository } from '../database/RequestRepository';
import { WorkspaceRepository } from '../database/WorkspaceRepository';
import { EnvironmentRepository } from '../database/EnvironmentRepository';
import { FolderRepository } from '../database/FolderRepository';
import { DatabaseManager } from '../database/DatabaseManager';
import { RequestExecutor } from '../services/RequestExecutor';
import { EnvironmentService } from '../services/EnvironmentService';
import { SidebarComponent } from '../components/SidebarComponent';
import { RequestEditorComponent } from '../components/RequestEditorComponent';
import { ResponseViewerComponent } from '../components/ResponseViewerComponent';
import { WorkspaceHeader } from '../components/header/WorkspaceHeader';
import { SettingsDialog } from '../components/dialogs/SettingsDialog';
import { EmptyState } from '../components/EmptyState'; // Import
import { UUID } from '../common/UUID';
import { ThemeManager, ThemeColors } from '../theme/Theme';

@Entry
@ComponentV2
struct Index {
  @Local workspaces: Workspace[] = [];
  @Local requests: HttpRequest[] = [];
  @Local folders: Folder[] = [];
  @Local sidebarItems: SidebarItem[] = [];
  
  @Local environments: Environment[] = [];
  @Local selectedWorkspace: Workspace | null = null;
  @Local selectedRequest: HttpRequest | null = null;
  @Local selectedEnvironment: Environment | null = null;
  
  @Local responseBody: string = '';
  @Local responseStatus: number = 0;
  @Local responseTime: number = 0;
  @Local responseSize: number = 0;
  
  @Local isLoading: boolean = true;
  @Local isRequestLoading: boolean = false;

  @Local sidebarWidth: number = 250; 
  @Local sidebarHidden: boolean = false;
  @Local workspaceLayout: string = 'horizontal';

  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  settingsDialogController: CustomDialogController = new CustomDialogController({
    builder: SettingsDialog(),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true 
  });
  
  async aboutToAppear() {
    try {
      await DatabaseManager.getInstance().waitForInit();
      
      await this.loadWorkspaces();
      if (this.workspaces.length === 0) {
        await this.createDefaultWorkspace();
      }
      if (this.workspaces.length > 0) {
        this.selectedWorkspace = this.workspaces[0];
        await this.loadData();
      }
    } catch (e) {
      console.error("Initialization failed", e);
    } finally {
      this.isLoading = false; 
    }
  }

  async loadData() {
    if (!this.selectedWorkspace) return;
    try {
      await this.loadEnvironments();
      await this.loadFolders();
      await this.loadRequests();
      this.rebuildSidebar();
    } catch (e) {
      console.error("Error loading data", e);
    }
  }

  async loadWorkspaces() {
    this.workspaces = await WorkspaceRepository.getAllWorkspaces();
  }
  
  async loadEnvironments() {
    if (this.selectedWorkspace) {
      this.environments = await EnvironmentRepository.getEnvironmentsByWorkspaceId(this.selectedWorkspace.id);
      if (this.environments.length === 0) {
         const env = new Environment();
         env.id = UUID.randomUUID();
         env.workspace_id = this.selectedWorkspace.id;
         env.name = 'Base Environment';
         // Use JSON array for variables, empty for now
         env.variables = '[]'; 
         env.created_at = Date.now();
         env.updated_at = Date.now();
         await EnvironmentRepository.createEnvironment(env);
         this.environments = [env];
      }
      this.selectedEnvironment = null;
    }
  }

  async loadFolders() {
    if (this.selectedWorkspace) {
      this.folders = await FolderRepository.getFoldersByWorkspaceId(this.selectedWorkspace.id);
    }
  }

  async loadRequests() {
    if (this.selectedWorkspace) {
      this.requests = await RequestRepository.getRequestsByWorkspaceId(this.selectedWorkspace.id);
    }
  }

  rebuildSidebar() {
    let items: SidebarItem[] = [];
    this.processLevel(null, 0, items);
    this.sidebarItems = items;
  }
  
  processLevel(parentId: string | null, level: number, result: SidebarItem[]) {
    const currentFolders = this.folders.filter(f => f.folder_id === parentId);
    currentFolders.forEach(f => {
      const item = new SidebarItem('folder', f, level);
      result.push(item);
      this.processLevel(f.id, level + 1, result);
    });
    
    const currentRequests = this.requests.filter(r => r.folder_id === parentId);
    currentRequests.forEach(r => {
      const item = new SidebarItem('request', r, level);
      result.push(item);
    });
  }

  async createDefaultWorkspace() {
    const ws = new Workspace();
    ws.id = UUID.randomUUID();
    ws.name = 'Default Workspace';
    ws.created_at = Date.now();
    ws.updated_at = Date.now();
    await WorkspaceRepository.createWorkspace(ws);
    await this.loadWorkspaces();
  }

  async createRequest(): Promise<void> {
    if (!this.selectedWorkspace) return;
    const req = new HttpRequest();
    req.id = UUID.randomUUID();
    req.workspace_id = this.selectedWorkspace.id;
    req.name = 'New Request';
    req.url = '{{ host }}/get';
    req.method = 'GET';
    req.created_at = Date.now();
    req.updated_at = Date.now();
    
    await RequestRepository.createRequest(req);
    await this.loadRequests();
    this.rebuildSidebar();
    this.selectedRequest = this.requests.find((r: HttpRequest) => r.id === req.id) || null;
  }
  
  async createFolder(): Promise<void> {
    if (!this.selectedWorkspace) return;
    const folder = new Folder();
    folder.id = UUID.randomUUID();
    folder.workspace_id = this.selectedWorkspace.id;
    folder.name = 'New Folder';
    folder.created_at = Date.now();
    folder.updated_at = Date.now();
    
    await FolderRepository.createFolder(folder);
    await this.loadFolders();
    this.rebuildSidebar();
  }

  async executeRequest(): Promise<void> {
    if (!this.selectedRequest) return;
    
    this.isRequestLoading = true;
    this.responseBody = '';
    this.responseStatus = 0;
    
    const startTime = Date.now();
    
    try {
      const variables = EnvironmentService.mergeVariables(this.environments);
      const resp = await RequestExecutor.execute(this.selectedRequest, variables);
      
      this.responseStatus = resp.responseCode;
      this.responseTime = Date.now() - startTime;
      
      let bodyStr = '';
      if (typeof resp.result === 'string') {
        bodyStr = resp.result as string;
      } else {
        bodyStr = JSON.stringify(resp.result, null, 2);
      }
      this.responseBody = bodyStr;
      this.responseSize = bodyStr.length; // Approximate bytes
      
    } catch (e) {
      this.responseBody = 'Error: ' + JSON.stringify(e);
      this.responseStatus = 0;
    } finally {
       this.isRequestLoading = false;
    }
  }

  build() {
    Column() {
      // Header (Always Visible)
      WorkspaceHeader({
        workspaces: this.workspaces,
        activeWorkspace: this.selectedWorkspace,
        environments: this.environments,
        activeEnvironment: this.selectedEnvironment,
        workspaceLayout: this.workspaceLayout,
        sidebarHidden: this.sidebarHidden,
        
        // Event Handlers
        onWorkspaceSelect: (ws: Workspace) => {
          if (this.selectedWorkspace?.id !== ws.id) {
            this.selectedWorkspace = ws;
            this.loadData();
          }
        },
        onWorkspaceAdd: () => {
           // Reload logic if needed, but the Dialog in Header does the creation
           // We just need to refresh list
           this.loadWorkspaces();
        },
        onEnvironmentSelect: (env: Environment | null) => {
          this.selectedEnvironment = env;
        },
        onLayoutChange: (layout: string) => {
          this.workspaceLayout = layout;
        },
        onSidebarToggle: () => {
          this.sidebarHidden = !this.sidebarHidden;
        },
        onOpenSettings: () => {
          this.settingsDialogController.open();
        }
      })

      Row() {
        if (this.isLoading) {
          Column() {
             LoadingProgress().width(50).height(50).color(this.theme.primary)
             Text("Initializing...").margin({ top: 10 }).fontColor(this.theme.text)
          }.width('100%').height('100%').justifyContent(FlexAlign.Center).backgroundColor(this.theme.background)
        } else {
          // Sidebar (20%)
          if (!this.sidebarHidden) {
            Column() {
              SidebarComponent({
                items: this.sidebarItems,
                selectedRequest: this.selectedRequest,
                onRequestCreate: () => { this.createRequest() },
                onFolderCreate: () => { this.createFolder() },
                $selectedRequest: (req: HttpRequest | null) => {
                   this.selectedRequest = req;
                }
              })
            }
            .width('20%')
            .height('100%')
            .backgroundColor(this.theme.sidebarBackground)

            Divider().vertical(true).height('100%').color(this.theme.border)
          }

          // Main Content (Request)
          Column() {
            if (this.selectedRequest) {
              RequestEditorComponent({
                request: this.selectedRequest,
                onExecute: () => { this.executeRequest() },
                isLoading: this.isRequestLoading,
                $request: (val: HttpRequest | null) => {
                  // Handle request updates if needed, though ObservedV2 handles props
                  if (val) this.selectedRequest = val;
                }
              })
            } else {
              EmptyState({
                onNewRequest: () => { this.createRequest() },
                onImport: () => { 
                   // TODO: Implement Import Dialog
                }
              })
            }
          }
          .layoutWeight(this.workspaceLayout === 'horizontal' ? 5 : 1)
          .height('100%')
          .backgroundColor(this.theme.background)

          if (this.workspaceLayout === 'horizontal') {
            Divider().vertical(true).height('100%').color(this.theme.border)
          } else {
            Divider().vertical(false).width('100%').color(this.theme.border)
          }

          // Response Viewer
          Column() {
            ResponseViewerComponent({
              response: this.responseBody,
              status: this.responseStatus,
              time: this.responseTime,
              bodySize: this.responseSize
            })
          }
          .layoutWeight(3)
          .height('100%')
          .backgroundColor(this.theme.background)
        }
      }
      .layoutWeight(1) // Take remaining space
      .width('100%')
      .backgroundColor(this.theme.background)
    }
    .width('100%')
    .height('100%')
    .backgroundColor(this.theme.background)
  }
}
