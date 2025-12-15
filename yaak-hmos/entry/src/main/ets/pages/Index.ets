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
import { UUID } from '../common/UUID';
import http from '@ohos.net.http';

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
  
  @Local responseBody: string = '';
  @Local responseStatus: number = 0;
  @Local responseTime: number = 0;
  @Local responseSize: number = 0;
  
  @Local isLoading: boolean = true;
  @Local isRequestLoading: boolean = false;

  @Local sidebarWidth: number = 250; // default 250px (need conversion to screen density usually, but simple for now)
  
  // Layout weights (simulated resize)
  @Local sidebarWeight: number = 2;
  @Local requestWeight: number = 5;
  @Local responseWeight: number = 3;

  async aboutToAppear() {
    await DatabaseManager.getInstance().waitForInit();
    
    await this.loadWorkspaces();
    if (this.workspaces.length === 0) {
      await this.createDefaultWorkspace();
    }
    if (this.workspaces.length > 0) {
      this.selectedWorkspace = this.workspaces[0];
      await this.loadData();
    }
    this.isLoading = false;
  }

  async loadData() {
    if (!this.selectedWorkspace) return;
    await this.loadEnvironments();
    await this.loadFolders();
    await this.loadRequests();
    this.rebuildSidebar();
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
         env.data = '{"host": "https://httpbin.org"}';
         env.created_at = Date.now();
         env.updated_at = Date.now();
         await EnvironmentRepository.createEnvironment(env);
         this.environments = [env];
      }
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
    Row() {
      if (this.isLoading) {
        Column() {
           LoadingProgress().width(50).height(50)
           Text("Initializing...").margin({ top: 10 })
        }.width('100%').height('100%').justifyContent(FlexAlign.Center)
      } else {
        // Sidebar (20%)
        Column() {
          SidebarComponent({
            items: this.sidebarItems,
            selectedRequest: this.selectedRequest,
            onRequestCreate: () => { this.createRequest() },
            onFolderCreate: () => { this.createFolder() }
          })
        }
        .width('20%')
        .height('100%')

        Divider().vertical(true).height('100%').color('#e0e0e0')

        // Main Content (Request 50%)
        Column() {
          RequestEditorComponent({
            request: this.selectedRequest,
            onExecute: () => { this.executeRequest() },
            isLoading: this.isRequestLoading
          })
        }
        .layoutWeight(5)
        .height('100%')

        Divider().vertical(true).height('100%').color('#e0e0e0')

        // Response Viewer (30%)
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
      }
    }
    .width('100%')
    .height('100%')
  }
}
