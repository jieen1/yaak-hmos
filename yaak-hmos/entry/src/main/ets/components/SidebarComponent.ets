/**
 * Sidebar Component
 * Main sidebar with search, action buttons, and tree view
 * Enhanced with drag and drop reordering support
 * 
 * 使用扁平化列表 + @Monitor + ForEach 模式实现列表刷新
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

// 扁平化列表项类型
type FlatItemType = 'folder' | 'request';

// 扁平化列表项接口
interface FlatListItem {
  id: string;
  type: FlatItemType;
  data: SidebarItem;
  level: number;
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
  @Param onRequestCopyAsCurl: (requestId: string) => void = () => {};
  @Param onRequestShare: (requestId: string) => void = () => {};
  @Param onFolderRename: (folderId: string, newName: string) => void = () => {};
  @Param onFolderDelete: (folderId: string) => void = () => {};
  @Param onFolderDuplicate: (folderId: string) => void = () => {};
  @Param onFolderSettings: (folderId: string) => void = () => {};
  @Param onItemMove: (itemId: string, itemType: string, newFolderId: string | null, newSortPriority: number) => void = () => {};

  @Local filterText: string = '';
  
  // 展开的文件夹集合
  @Local expandedFolders: Set<string> = new Set();
  
  // 扁平化列表 - 核心数据源
  @Local flatList: FlatListItem[] = [];

  // Drag and drop state
  @Local isDragging: boolean = false;
  @Local draggedItemId: string = '';
  @Local draggedItemType: string = '';
  @Local dropTargetId: string = '';
  @Local dropPosition: DropPosition = 'after';

  // Edit state - track which item is being edited
  @Local editingItemId: string = '';
  @Local editingItemType: string = '';

  aboutToAppear(): void {
    this.rebuildFlatList();
  }

  // 监听 items 和 filterText 变化，自动重建扁平列表
  @Monitor('items', 'filterText')
  onDataChange(): void {
    console.info('[SidebarComponent] Data changed, rebuilding flat list');
    this.rebuildFlatList();
  }

  // 重建扁平化列表
  private rebuildFlatList(): void {
    const newFlatList: FlatListItem[] = [];
    
    // 过滤后的根级项目
    const filteredRootItems: SidebarItem[] = this.getFilteredItems();
    
    // 递归扁平化，根级项目从 level 0 开始
    filteredRootItems.forEach((item: SidebarItem) => {
      this.flattenItem(item, 0, newFlatList);
    });
    
    this.flatList = newFlatList;
    console.info('[SidebarComponent] Flat list rebuilt with', this.flatList.length, 'items');
  }

  // 获取过滤后的项目
  private getFilteredItems(): SidebarItem[] {
    if (!this.filterText || this.filterText.trim() === '') {
      return this.items;
    }

    const searchText: string = this.filterText.toLowerCase();
    const filtered: SidebarItem[] = [];

    const filterItem = (item: SidebarItem): boolean => {
      const nameMatch: boolean = item.getName().toLowerCase().includes(searchText);

      if (item.isRequest()) {
        const request: HttpRequest | null = item.getRequest();
        const urlMatch: boolean = request ? request.url.toLowerCase().includes(searchText) : false;
        return nameMatch || urlMatch;
      }

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

  // 递归扁平化项目
  private flattenItem(item: SidebarItem, level: number, list: FlatListItem[]): void {
    const flatItem: FlatListItem = {
      id: item.getId(),
      type: item.type,
      data: item,
      level: level
    };
    list.push(flatItem);

    // 如果是文件夹且已展开，添加子项
    if (item.isFolder() && this.expandedFolders.has(item.getId())) {
      item.children.forEach((child: SidebarItem) => {
        this.flattenItem(child, level + 1, list);
      });
    }
  }

  // 切换文件夹展开状态
  private toggleFolder(folderId: string): void {
    const newSet: Set<string> = new Set(this.expandedFolders);
    if (newSet.has(folderId)) {
      newSet.delete(folderId);
    } else {
      newSet.add(folderId);
    }
    this.expandedFolders = newSet;
    this.rebuildFlatList();
  }

  build() {
    Column() {
      // Search/Filter input
      ThemedTextInput({
        value: this.filterText,
        placeholder: $r('app.string.search_requests'),
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
          text: $r('app.string.new_request'),
          onButtonClick: () => {
            this.onRequestCreate();
          },
          buttonSize: 'sm'
        })
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_xs') })

        ThemedButton({
          text: $r('app.string.new_folder'),
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

      // 使用 ForEach + 扁平化列表，而不是 Repeat + 嵌套树
      List() {
        ForEach(this.flatList, (flatItem: FlatListItem) => {
          ListItem() {
            if (flatItem.type === 'folder') {
              this.buildFolderItem(flatItem.data, flatItem.level)
            } else {
              this.buildRequestItem(flatItem.data, flatItem.level)
            }
          }
        }, (flatItem: FlatListItem) => flatItem.id + '_' + flatItem.type + '_' + flatItem.level + '_' + this.expandedFolders.has(flatItem.id))

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
              Row() {
                Text($r('app.string.drop_here_to_root'))
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
        this.clearEditingState();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sidebar_background'))
  }

  // 构建文件夹项
  @Builder
  buildFolderItem(item: SidebarItem, level: number) {
    Column() {
      FolderItemComponent({
        folder: item.getFolder()!,
        level: level,
        isExpanded: this.expandedFolders.has(item.getId()),
        isEditing: this.editingItemId === item.getId() && this.editingItemType === 'folder',
        onToggle: () => {
          this.clearEditingState();
          this.toggleFolder(item.getId());
          this.onFolderToggle(item.getId());
        },
        onSelect: () => {
          this.clearEditingState();
          this.toggleFolder(item.getId());
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
  }

  // 构建请求项
  @Builder
  buildRequestItem(item: SidebarItem, level: number) {
    Column() {
      RequestItemComponent({
        request: item.getRequest()!,
        level: level,
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
        onCopyAsCurl: () => {
          this.onRequestCopyAsCurl(item.getId());
        },
        onShare: () => {
          this.onRequestShare(item.getId());
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
