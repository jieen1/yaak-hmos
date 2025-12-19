/**
 * Request Item Component
 * Displays an HTTP request in the sidebar with method badge
 * Uses HarmonyOS native bindContextMenu for context menu
 * Supports double-click to rename and blur to save
 */

import { HttpRequest } from '../model/HttpRequest';
import promptAction from '@ohos.promptAction';
import { SymbolGlyphModifier } from '@kit.ArkUI';

@ComponentV2
export struct RequestItemComponent {
  @Param request: HttpRequest = new HttpRequest();
  @Param level: number = 0;
  @Param isSelected: boolean = false;
  @Param isEditing: boolean = false;
  @Param onSelect: () => void = () => {};
  @Param onRename: (newName: string) => void = () => {};
  @Param onDelete: () => void = () => {};
  @Param onDuplicate: () => void = () => {};
  @Param onSend: () => void = () => {};
  @Param onStartEdit: () => void = () => {};
  @Param onEndEdit: () => void = () => {};

  @Local editingName: string = '';
  @Local private lastClickTime: number = 0;
  @Local private hasInitializedEdit: boolean = false;

  /**
   * Build context menu using HarmonyOS native Menu component
   */
  @Builder
  buildContextMenu() {
    Menu() {
      MenuItem({ content: 'Send', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.cheers')) })
        .onClick(() => {
          this.onSelect();
          this.onSend();
        })

      MenuItem({ content: 'Rename', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.rename')) })
        .onClick(() => {
          this.startRename();
        })

      MenuItem({ content: 'Duplicate', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.notepad')) })
        .onClick(() => {
          this.onDuplicate();
        })

      MenuItem({ content: 'Delete', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
        .onClick(() => {
          this.showDeleteConfirmation();
        })
    }
  }

  build() {
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
      if (this.isEditing) {
        TextInput({ text: this.getEditingName() })
          .fontSize($r('app.float.font_size_md'))
          .flexGrow(1)
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.border_radius_sm'))
          .padding({
            left: $r('app.float.spacing_xs'),
            right: $r('app.float.spacing_xs')
          })
          .onChange((value: string) => {
            this.editingName = value;
          })
          .onSubmit((enterKey: EnterKeyType) => {
            this.saveRename();
          })
          .onBlur(() => {
            // Use setTimeout to allow click events to process first
            setTimeout(() => {
              this.saveRename();
            }, 100);
          })
          .focusable(true)
          .defaultFocus(true)
          .id('request_rename_input_' + this.request.id)
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
      if (this.isEditing) {
        return;
      }
      this.handleClick();
    })
    .bindContextMenu(this.buildContextMenu, ResponseType.RightClick)
  }

  /**
   * Get editing name, initialize if needed
   */
  private getEditingName(): string {
    if (!this.hasInitializedEdit && this.isEditing) {
      this.editingName = this.request.name;
      this.hasInitializedEdit = true;
    }
    return this.editingName;
  }

  /**
   * Handle click with double-click detection for rename
   */
  private handleClick(): void {
    const currentTime: number = Date.now();
    const timeDiff: number = currentTime - this.lastClickTime;

    // Double-click threshold: 300ms
    if (timeDiff < 300 && this.isSelected) {
      // Double-click on selected item - start rename
      this.startRename();
    } else {
      // Single click - select the item
      this.onSelect();
    }

    this.lastClickTime = currentTime;
  }

  private startRename(): void {
    this.editingName = this.request.name;
    this.hasInitializedEdit = true;
    this.onStartEdit();
  }

  /**
   * Save the rename (called on Enter or blur)
   */
  private saveRename(): void {
    if (!this.isEditing) {
      return;
    }

    const trimmedName: string = this.editingName.trim();
    if (trimmedName.length > 0 && trimmedName !== this.request.name) {
      this.onRename(trimmedName);
    }
    this.editingName = '';
    this.hasInitializedEdit = false;
    this.onEndEdit();
  }

  private cancelRename(): void {
    this.editingName = '';
    this.hasInitializedEdit = false;
    this.onEndEdit();
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[RequestItem] Toast error:', error);
    }
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
          this.showToast('Request deleted');
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
