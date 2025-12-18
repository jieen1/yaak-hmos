/**
 * Request Item Component
 * Displays an HTTP request in the sidebar with method badge
 * Enhanced with context menu, rename, and delete functionality
 */

import { HttpRequest } from '../model/HttpRequest';
import { HttpMethod } from '../model/Types';
import { ContextMenu } from './ContextMenu';
import type { ContextMenuItem, MenuPosition } from './ContextMenu';
import promptAction from '@ohos.promptAction';

@ComponentV2
export struct RequestItemComponent {
  @Param request: HttpRequest = new HttpRequest();
  @Param level: number = 0;
  @Param isSelected: boolean = false;
  @Param onSelect: () => void = () => {};
  @Param onRename: (newName: string) => void = () => {};
  @Param onDelete: () => void = () => {};
  @Param onDuplicate: () => void = () => {};
  
  @Local showContextMenu: boolean = false;
  @Local contextMenuPosition: MenuPosition = { x: 0, y: 0 };
  @Local isRenaming: boolean = false;
  @Local editingName: string = '';

  build() {
    Stack() {
      // Main request item
      Row() {
        // Indentation based on level
        Blank()
          .width(this.level * 16)

        // Spacing for alignment with folders (no expand icon)
        Blank()
          .width(20)

        // HTTP method badge
        Text(this.request.method)
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.button_text'))
          .backgroundColor(this.getMethodColor())
          .padding({
            left: $r('app.float.spacing_xs'),
            right: $r('app.float.spacing_xs'),
            top: 2,
            bottom: 2
          })
          .borderRadius($r('app.float.border_radius_sm'))
          .margin({ right: $r('app.float.spacing_sm') })
          .fontWeight(FontWeight.Bold)

        // Request name or rename input
        if (this.isRenaming) {
          TextInput({ text: this.editingName })
            .fontSize($r('app.float.font_size_md'))
            .flexGrow(1)
            .backgroundColor($r('app.color.surface'))
            .onSubmit(() => {
              this.handleRenameSubmit();
            })
            .onBlur(() => {
              this.handleRenameCancel();
            })
        } else {
          Text(this.request.name)
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_primary'))
            .flexGrow(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .width('100%')
      .height($r('app.float.list_item_height'))
      .padding({
        left: $r('app.float.spacing_sm'),
        right: $r('app.float.spacing_sm')
      })
      .backgroundColor(this.isSelected ? $r('app.color.sidebar_item_selected') : $r('app.color.sidebar_background'))
      .borderRadius($r('app.float.border_radius_sm'))
      .onClick(() => {
        if (!this.isRenaming) {
          this.onSelect();
        }
      })
      .gesture(
        LongPressGesture({ repeat: false })
          .onAction((event: GestureEvent) => {
            if (!this.isRenaming && event.fingerList && event.fingerList.length > 0) {
              const finger = event.fingerList[0];
              if (finger) {
                const pos: MenuPosition = {
                  x: finger.globalX,
                  y: finger.globalY
                };
                this.contextMenuPosition = pos;
                this.showContextMenu = true;
              }
            }
          })
      )

      // Context menu
      if (this.showContextMenu) {
        ContextMenu({
          items: this.getContextMenuItems(),
          visible: this.showContextMenu,
          menuPosition: this.contextMenuPosition,
          onItemSelect: (action: string) => {
            this.handleContextMenuAction(action);
            this.showContextMenu = false;
          }
        })
      }
    }
    .width('100%')
    .alignContent(Alignment.TopStart)
  }

  private getContextMenuItems(): ContextMenuItem[] {
    const items: ContextMenuItem[] = [
      { id: 'rename', label: 'Rename', icon: '✏️' },
      { id: 'duplicate', label: 'Duplicate', icon: '📋' },
      { id: 'separator', label: '', separator: true },
      { id: 'delete', label: 'Delete', icon: '🗑️', danger: true }
    ];
    return items;
  }

  private handleContextMenuAction(action: string): void {
    switch (action) {
      case 'rename':
        this.startRename();
        break;
      case 'duplicate':
        this.onDuplicate();
        try {
          promptAction.showToast({
            message: 'Request duplicated',
            duration: 2000
          });
        } catch (error) {
          console.error('[RequestItem] Toast error:', error);
        }
        break;
      case 'delete':
        this.showDeleteConfirmation();
        break;
    }
  }

  private startRename(): void {
    this.editingName = this.request.name;
    this.isRenaming = true;
  }

  private handleRenameSubmit(): void {
    if (this.editingName.trim().length > 0) {
      this.onRename(this.editingName.trim());
      this.isRenaming = false;
    } else {
      try {
        promptAction.showToast({
          message: 'Request name cannot be empty',
          duration: 2000
        });
      } catch (error) {
        console.error('[RequestItem] Toast error:', error);
      }
    }
  }

  private handleRenameCancel(): void {
    this.isRenaming = false;
    this.editingName = '';
  }

  private showDeleteConfirmation(): void {
    try {
      promptAction.showDialog({
        title: 'Delete Request',
        message: `Are you sure you want to delete "${this.request.name}"?`,
        buttons: [
          { text: 'Cancel', color: '#000000' },
          { text: 'Delete', color: '#ff4d4f' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.onDelete();
          try {
            promptAction.showToast({
              message: 'Request deleted',
              duration: 2000
            });
          } catch (toastError) {
            console.error('[RequestItem] Toast error:', toastError);
          }
        }
      }).catch((error: Error) => {
        console.error('[RequestItem] Delete confirmation error:', error);
      });
    } catch (error) {
      console.error('[RequestItem] Failed to show delete confirmation:', error);
    }
  }

  /**
   * Get color for HTTP method badge
   */
  private getMethodColor(): Resource {
    switch (this.request.method.toUpperCase()) {
      case 'GET':
        return $r('app.color.method_get');
      case 'POST':
        return $r('app.color.method_post');
      case 'PUT':
        return $r('app.color.method_put');
      case 'DELETE':
        return $r('app.color.method_delete');
      case 'PATCH':
        return $r('app.color.method_patch');
      case 'HEAD':
        return $r('app.color.method_head');
      case 'OPTIONS':
        return $r('app.color.method_options');
      default:
        return $r('app.color.secondary');
    }
  }
}
