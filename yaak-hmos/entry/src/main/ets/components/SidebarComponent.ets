/**
 * Sidebar Component
 * Main sidebar with search, action buttons, and tree view
 * Enhanced with drag and drop reordering support
 */

import { SidebarItem } from '../viewmodel/SidebarItem';
import { HttpRequest } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { FolderItemComponent } from './FolderItemComponent';
import { RequestItemComponent } from './RequestItemComponent';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';
import { ThemedDivider } from './ThemedDivider';
import { uniformTypeDescriptor } from '@kit.ArkData';

// Drop position type
type DropPosition = 'before' | 'after' | 'inside';

// Drop target info interface
interface DropTargetInfo {
  itemId: string;
  position: DropPosition;
  targetFolderId: string | null;
}

@ComponentV2
export struct SidebarComponent {
  @Param items: SidebarItem[] = [];
  @Param selectedRequestId: string = '';
  @Param onRequestCreate: () => void = () => {};
  @Param onFolderCreate: () => void = () => {};
  @Param onRequestSelect: (requestId: string) => void = () => {};
  @Param onFolderToggle: (folderId: string) => void = () => {};
  @Param onRequestRename: (requestId: string, newName: string) => void = () => {};
  @Param onRequestDelete: (requestId: string) => void = () => {};
  @Param onRequestDuplicate: (requestId: string) => void = () => {};
  @Param onRequestSend: (requestId: string) => void = () => {};
  @Param onFolderRename: (folderId: string, newName: string) => void = () => {};
  @Param onFolderDelete: (folderId: string) => void = () => {};
  @Param onFolderDuplicate: (folderId: string) => void = () => {};
  @Param onFolderSettings: (folderId: string) => void = () => {};
  @Param onItemMove: (itemId: string, itemType: string, newFolderId: string | null, newSortPriority: number) => void = () => {};

  @Local filterText: string = '';
  @Local expandedFolders: Set<string> = new Set();

  // Computed property for filtered items - automatically updates when items or filterText changes
  @Computed
  get filteredItems(): SidebarItem[] {
    if (!this.filterText || this.filterText.trim() === '') {
      return this.items;
    }

    const searchText: string = this.filterText.toLowerCase();
    const filtered: SidebarItem[] = [];

    const filterItem = (item: SidebarItem): boolean => {
      const nameMatch: boolean = item.getName().toLowerCase().includes(searchText);

      // For requests, also check URL
      if (item.isRequest()) {
        const request: HttpRequest | null = item.getRequest();
        const urlMatch: boolean = request ? request.url.toLowerCase().includes(searchText) : false;
        return nameMatch || urlMatch;
      }

      // For folders, check if any children match
      const childrenMatch: boolean = item.children.some((child: SidebarItem) => filterItem(child));

      return nameMatch || childrenMatch;
    };

    this.items.forEach((item: SidebarItem) => {
      if (filterItem(item)) {
        filtered.push(item);
      }
    });

    return filtered;
  }

  // Drag and drop state
  @Local isDragging: boolean = false;
  @Local draggedItemId: string = '';
  @Local draggedItemType: string = '';
  @Local dropTargetId: string = '';
  @Local dropPosition: DropPosition = 'after';

  // Edit state - track which item is being edited
  @Local editingItemId: string = '';
  @Local editingItemType: string = '';

  build() {
    Column() {
      // Search/Filter input
      ThemedTextInput({
        value: this.filterText,
        placeholder: 'Search requests...',
        onValueChange: (value: string) => {
          this.filterText = value;
        }
      })
        .margin({
          left: $r('app.float.spacing_md'),
          right: $r('app.float.spacing_md'),
          top: $r('app.float.spacing_md'),
          bottom: $r('app.float.spacing_sm')
        })

      // Action buttons
      Row() {
        ThemedButton({
          text: 'New Request',
          onButtonClick: () => {
            this.onRequestCreate();
          },
          buttonSize: 'sm'
        })
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_xs') })

        ThemedButton({
          text: 'New Folder',
          onButtonClick: () => {
            this.onFolderCreate();
          },
          buttonType: 'secondary',
          buttonSize: 'sm'
        })
          .flexGrow(1)
          .margin({ left: $r('app.float.spacing_xs') })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_md'),
        right: $r('app.float.spacing_md')
      })
      .margin({ bottom: $r('app.float.spacing_sm') })

      ThemedDivider({})

      // Tree view with root-level drop zone
      List() {
        Repeat<SidebarItem>(this.filteredItems)
          .each((obj: RepeatItem<SidebarItem>) => {
            ListItem() {
              this.buildTreeItem(obj.item, obj.index)
            }
          })
          .key((item: SidebarItem) => item.getId())

        // Root level drop zone at the end of the list
        ListItem() {
          Column() {
            if (this.isDragging && this.dropTargetId === 'root') {
              Row()
                .width('100%')
                .height(40)
                .backgroundColor($r('app.color.sidebar_item_selected'))
                .border({
                  width: 2,
                  color: $r('app.color.primary'),
                  style: BorderStyle.Dashed
                })
                .borderRadius($r('app.float.border_radius_sm'))
            } else if (this.isDragging) {
              // Show a hint area when dragging
              Row() {
                Text('Drop here to move to root')
                  .fontSize($r('app.float.font_size_sm'))
                  .fontColor($r('app.color.text_secondary'))
              }
              .width('100%')
              .height(40)
              .justifyContent(FlexAlign.Center)
              .backgroundColor($r('app.color.surface'))
              .borderRadius($r('app.float.border_radius_sm'))
              .opacity(0.6)
            }
          }
          .width('100%')
          .padding({ top: $r('app.float.spacing_sm') })
        }
        .allowDrop([uniformTypeDescriptor.UniformDataType.TEXT])
        .onDrop((event: DragEvent) => {
          console.info('[Sidebar] Drop on root level');
          if (this.isDragging) {
            this.dropTargetId = 'root';
            this.dropPosition = 'inside';
            this.handleDropToRoot();
          }
        })
        .onDragEnter(() => {
          if (this.isDragging) {
            this.dropTargetId = 'root';
            this.dropPosition = 'inside';
            console.info('[Sidebar] Drag enter root level');
          }
        })
        .onDragLeave(() => {
          if (this.dropTargetId === 'root') {
            this.dropTargetId = '';
            console.info('[Sidebar] Drag leave root level');
          }
        })
      }
      .width('100%')
      .height('100%')
      .layoutWeight(1)
      .padding({
        left: $r('app.float.spacing_sm'),
        right: $r('app.float.spacing_sm')
      })
      .scrollBar(BarState.Auto)
      .onClick(() => {
        // Click on empty area clears editing state
        this.clearEditingState();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sidebar_background'))
  }

  /**
   * Build tree item (folder or request) with drag and drop support
   */
  @Builder
  buildTreeItem(item: SidebarItem, index: number) {
    Column() {
      // Main item content
      if (item.isFolder()) {
        Column() {
          // Folder item - use border for drop highlight instead of Stack
          FolderItemComponent({
            folder: item.getFolder()!,
            level: item.level,
            isExpanded: item.isExpanded,
            isEditing: this.editingItemId === item.getId() && this.editingItemType === 'folder',
            onToggle: () => {
              this.clearEditingState();
              item.toggleExpanded();
              this.onFolderToggle(item.getId());
            },
            onSelect: () => {
              this.clearEditingState();
              item.toggleExpanded();
            },
            onRename: (newName: string) => {
              this.onFolderRename(item.getId(), newName);
            },
            onDelete: () => {
              this.onFolderDelete(item.getId());
            },
            onDuplicate: () => {
              this.onFolderDuplicate(item.getId());
            },
            onSettings: () => {
              this.onFolderSettings(item.getId());
            },
            onStartEdit: () => {
              this.startEditing(item.getId(), 'folder');
            },
            onEndEdit: () => {
              this.clearEditingState();
            }
          })

          // Show children if expanded - children are stored in item.children
          if (item.isExpanded && item.children.length > 0) {
            Column() {
              Repeat<SidebarItem>(item.children)
                .each((childObj: RepeatItem<SidebarItem>) => {
                  this.buildTreeItem(childObj.item, childObj.index)
                })
                .key((child: SidebarItem) => child.getId())
            }
            .width('100%')
          }
        }
        .width('100%')
        .opacity(this.isDragging && this.draggedItemId === item.getId() ? 0.5 : 1.0)
        .backgroundColor(this.isDropTarget(item) ? $r('app.color.sidebar_item_selected') : Color.Transparent)
        .border({
          width: this.isDropTarget(item) ? 2 : 0,
          color: $r('app.color.primary'),
          style: BorderStyle.Dashed
        })
        .borderRadius($r('app.float.border_radius_sm'))
        .draggable(true)
        .onDragStart(() => {
          this.startDrag(item);
          console.info('[Sidebar] Drag start folder:', item.getId());
          return undefined;
        })
        .onDragEnd(() => {
          console.info('[Sidebar] Drag end folder:', item.getId());
          this.resetDragState();
        })
        .allowDrop([uniformTypeDescriptor.UniformDataType.TEXT])
        .onDrop((event: DragEvent) => {
          console.info('[Sidebar] Drop on folder:', item.getId());
          if (this.isDragging && this.draggedItemId !== item.getId()) {
            this.dropTargetId = item.getId();
            this.dropPosition = 'inside';
            this.handleDrop();
          }
        })
        .onDragEnter(() => {
          if (this.isDragging && this.draggedItemId !== item.getId()) {
            // Check if dragging into a descendant (prevent)
            if (!this.isDescendant(this.draggedItemId, item.getId())) {
              this.dropTargetId = item.getId();
              this.dropPosition = 'inside';
              console.info('[Sidebar] Drag enter folder:', item.getId());
            }
          }
        })
        .onDragLeave(() => {
          if (this.dropTargetId === item.getId()) {
            this.dropTargetId = '';
            console.info('[Sidebar] Drag leave folder:', item.getId());
          }
        })
      } else if (item.isRequest()) {
        Column() {
          RequestItemComponent({
            request: item.getRequest()!,
            level: item.level,
            isSelected: item.getId() === this.selectedRequestId,
            isEditing: this.editingItemId === item.getId() && this.editingItemType === 'request',
            onSelect: () => {
              this.clearEditingState();
              this.onRequestSelect(item.getId());
            },
            onRename: (newName: string) => {
              this.onRequestRename(item.getId(), newName);
            },
            onDelete: () => {
              this.onRequestDelete(item.getId());
            },
            onDuplicate: () => {
              this.onRequestDuplicate(item.getId());
            },
            onSend: () => {
              this.onRequestSend(item.getId());
            },
            onStartEdit: () => {
              this.startEditing(item.getId(), 'request');
            },
            onEndEdit: () => {
              this.clearEditingState();
            }
          })
        }
        .width('100%')
        .opacity(this.isDragging && this.draggedItemId === item.getId() ? 0.5 : 1.0)
        .draggable(true)
        .onDragStart(() => {
          this.startDrag(item);
          console.info('[Sidebar] Drag start request:', item.getId());
          return undefined;
        })
        .onDragEnd(() => {
          console.info('[Sidebar] Drag end request:', item.getId());
          this.resetDragState();
        })
      }
    }
    .width('100%')
  }

  /**
   * Check if item is current drop target
   */
  private isDropTarget(item: SidebarItem): boolean {
    return this.isDragging &&
      this.dropTargetId === item.getId() &&
      this.dropPosition === 'inside' &&
      this.draggedItemId !== item.getId();
  }

  /**
   * Check if targetId is a descendant of itemId
   */
  private isDescendant(itemId: string, targetId: string): boolean {
    const item: SidebarItem | null = this.findItemById(itemId);
    if (!item || !item.isFolder()) {
      return false;
    }

    const checkDescendant = (parent: SidebarItem): boolean => {
      for (let i = 0; i < parent.children.length; i++) {
        const child: SidebarItem | undefined = parent.children[i];
        if (child) {
          if (child.getId() === targetId) {
            return true;
          }
          if (child.isFolder() && checkDescendant(child)) {
            return true;
          }
        }
      }
      return false;
    };

    return checkDescendant(item);
  }

  /**
   * Start editing an item
   */
  private startEditing(itemId: string, itemType: string): void {
    this.editingItemId = itemId;
    this.editingItemType = itemType;
    console.info('[Sidebar] Started editing:', itemId, itemType);
  }

  /**
   * Clear editing state
   */
  private clearEditingState(): void {
    if (this.editingItemId !== '') {
      console.info('[Sidebar] Cleared editing state for:', this.editingItemId);
      this.editingItemId = '';
      this.editingItemType = '';
    }
  }

  /**
   * Start dragging an item
   */
  private startDrag(item: SidebarItem): void {
    this.clearEditingState();
    this.isDragging = true;
    this.draggedItemId = item.getId();
    this.draggedItemType = item.type;
    console.info('[Sidebar] Started dragging:', this.draggedItemId);
  }

  /**
   * Handle drop action
   */
  private handleDrop(): void {
    if (!this.isDragging || !this.draggedItemId) {
      this.resetDragState();
      return;
    }

    if (this.dropTargetId && this.dropTargetId !== this.draggedItemId) {
      // Calculate new sort priority and folder ID
      const dropInfo: DropTargetInfo | null = this.calculateDropInfo();

      if (dropInfo) {
        console.info('[Sidebar] Dropping item:', this.draggedItemId, 'to:', dropInfo);

        // Calculate new sort priority
        const newSortPriority: number = this.calculateNewSortPriority(dropInfo);

        // Notify parent to update database
        this.onItemMove(
          this.draggedItemId,
          this.draggedItemType,
          dropInfo.targetFolderId,
          newSortPriority
        );
      }
    }

    this.resetDragState();
  }

  /**
   * Handle drop to root level (outside any folder)
   */
  private handleDropToRoot(): void {
    if (!this.isDragging || !this.draggedItemId) {
      this.resetDragState();
      return;
    }

    console.info('[Sidebar] Dropping item to root:', this.draggedItemId);

    // Calculate max sort priority at root level
    let maxPriority: number = 0;
    this.items.forEach((item: SidebarItem) => {
      const priority: number = item.getSortPriority();
      if (priority > maxPriority) {
        maxPriority = priority;
      }
    });

    // Move to root level (folder_id = null) with priority after all existing items
    this.onItemMove(
      this.draggedItemId,
      this.draggedItemType,
      null, // null means root level
      maxPriority + 10
    );

    this.resetDragState();
  }

  /**
   * Calculate drop info based on current drop target
   */
  private calculateDropInfo(): DropTargetInfo | null {
    if (!this.dropTargetId) {
      return null;
    }

    const targetItem: SidebarItem | null = this.findItemById(this.dropTargetId);
    if (!targetItem) {
      return null;
    }

    let targetFolderId: string | null = null;

    if (this.dropPosition === 'inside' && targetItem.isFolder()) {
      // Dropping inside a folder
      targetFolderId = targetItem.getId();
    } else {
      // Dropping before or after an item - use the same parent folder
      if (targetItem.isFolder()) {
        const folder: Folder | null = targetItem.getFolder();
        targetFolderId = folder?.folder_id || null;
      } else {
        const request: HttpRequest | null = targetItem.getRequest();
        targetFolderId = request?.folder_id || null;
      }
    }

    const info: DropTargetInfo = {
      itemId: this.dropTargetId,
      position: this.dropPosition,
      targetFolderId: targetFolderId
    };
    return info;
  }

  /**
   * Calculate new sort priority based on drop position
   */
  private calculateNewSortPriority(dropInfo: DropTargetInfo): number {
    const targetItem: SidebarItem | null = this.findItemById(dropInfo.itemId);
    if (!targetItem) {
      return 0;
    }

    const targetPriority: number = targetItem.getSortPriority();

    if (dropInfo.position === 'before') {
      return targetPriority - 0.5;
    } else if (dropInfo.position === 'after') {
      return targetPriority + 0.5;
    } else {
      // Inside folder - use 0 as default
      return 0;
    }
  }

  /**
   * Find item by ID in the tree
   */
  private findItemById(id: string): SidebarItem | null {
    const findInItems = (items: SidebarItem[]): SidebarItem | null => {
      for (let i = 0; i < items.length; i++) {
        const item: SidebarItem | undefined = items[i];
        if (item) {
          if (item.getId() === id) {
            return item;
          }
          const found: SidebarItem | null = findInItems(item.children);
          if (found) {
            return found;
          }
        }
      }
      return null;
    };

    return findInItems(this.items);
  }

  /**
   * Reset drag state
   */
  private resetDragState(): void {
    this.isDragging = false;
    this.draggedItemId = '';
    this.draggedItemType = '';
    this.dropTargetId = '';
    this.dropPosition = 'after';
  }

}
