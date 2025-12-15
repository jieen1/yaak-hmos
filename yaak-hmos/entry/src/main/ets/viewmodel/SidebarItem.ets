import { HttpRequest } from '../model/HttpRequest';
import { Folder } from '../model/Folder';

@ObservedV2
export class SidebarItem {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace type: 'folder' | 'request' = 'request';
  @Trace level: number = 0;
  @Trace expanded: boolean = true;
  @Trace data: HttpRequest | Folder | null = null;
  @Trace children: SidebarItem[] = [];

  constructor(type: 'folder' | 'request', data: HttpRequest | Folder, level: number = 0) {
    this.type = type;
    this.data = data;
    this.id = data.id;
    // Explicitly access name from concrete types or use common interface
    if (type === 'folder') {
       this.name = (data as Folder).name;
    } else {
       this.name = (data as HttpRequest).name;
    }
    this.level = level;
  }
}
