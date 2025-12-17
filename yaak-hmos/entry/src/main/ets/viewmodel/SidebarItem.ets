/**
 * Sidebar Item View Model
 * Represents tree nodes in the sidebar (folders and requests)
 */

import { Folder } from '../model/Folder';
import { HttpRequest } from '../model/HttpRequest';

export type SidebarItemType = 'folder' | 'request';

@ObservedV2
export class SidebarItem {
  @Trace type: SidebarItemType;
  @Trace data: Folder | HttpRequest;
  @Trace level: number;
  @Trace isExpanded: boolean = false;
  @Trace children: SidebarItem[] = [];

  constructor(type: SidebarItemType, data: Folder | HttpRequest, level: number = 0) {
    this.type = type;
    this.data = data;
    this.level = level;
  }

  /**
   * Get item ID
   */
  getId(): string {
    return this.data.id;
  }

  /**
   * Get item name
   */
  getName(): string {
    return this.data.name;
  }

  /**
   * Get sort priority
   */
  getSortPriority(): number {
    return this.data.sort_priority;
  }

  /**
   * Check if item is a folder
   */
  isFolder(): boolean {
    return this.type === 'folder';
  }

  /**
   * Check if item is a request
   */
  isRequest(): boolean {
    return this.type === 'request';
  }

  /**
   * Get folder data (if type is folder)
   */
  getFolder(): Folder | null {
    return this.isFolder() ? this.data as Folder : null;
  }

  /**
   * Get request data (if type is request)
   */
  getRequest(): HttpRequest | null {
    return this.isRequest() ? this.data as HttpRequest : null;
  }

  /**
   * Toggle expanded state
   */
  toggleExpanded(): void {
    if (this.isFolder()) {
      this.isExpanded = !this.isExpanded;
    }
  }

  /**
   * Add child item
   */
  addChild(child: SidebarItem): void {
    this.children.push(child);
  }

  /**
   * Remove child item
   */
  removeChild(childId: string): void {
    this.children = this.children.filter(child => child.getId() !== childId);
  }

  /**
   * Sort children by sort_priority
   */
  sortChildren(): void {
    this.children.sort((a, b) => a.getSortPriority() - b.getSortPriority());
  }

  /**
   * Get all descendant items (flattened)
   */
  getDescendants(): SidebarItem[] {
    const descendants: SidebarItem[] = [];

    const traverse = (item: SidebarItem) => {
      item.children.forEach(child => {
        descendants.push(child);
        traverse(child);
      });
    };

    traverse(this);
    return descendants;
  }

  /**
   * Find child by ID
   */
  findChild(id: string): SidebarItem | null {
    for (const child of this.children) {
      if (child.getId() === id) {
        return child;
      }
      const found = child.findChild(id);
      if (found) {
        return found;
      }
    }
    return null;
  }
}
