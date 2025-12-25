import { HttpRequest } from '../model/HttpRequest';
import { Workspace } from '../model/Workspace';

@Observed
export class MainViewModel {
  selectedWorkspace: Workspace | null = null;
  selectedRequest: HttpRequest | null = null;
  workspaces: Workspace[] = [];
  requests: HttpRequest[] = [];

  constructor() {
  }
}


