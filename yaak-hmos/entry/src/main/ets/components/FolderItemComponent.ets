/**
 * Folder Item Component
 * Displays a folder in the sidebar with expand/collapse functionality
 * Uses HarmonyOS native bindContextMenu for context menu
 * Supports double-click to rename and blur to save
 */

import { Folder } from '../model/Folder';
import promptAction from '@ohos.promptAction';
import { SymbolGlyphModifier } from '@kit.ArkUI';

@ComponentV2
export struct FolderItemComponent {
  @Param folder: Folder = new Folder();
  @Param level: number = 0;
  @Param isExpanded: boolean = false;
  @Param isEditing: boolean = false;
  @Param onToggle: () => void = () => {};
  @Param onSelect: () => void = () => {};
  @Param onRename: (newName: string) => void = () => {};
  @Param onDelete: () => void = () => {};
  @Param onDuplicate: () => void = () => {};
  @Param onSettings: () => void = () => {};
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
      MenuItem({ content: '重命名', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.rename')) })
        .onClick(() => {
          this.startRename();
        })

      MenuItem({ content: '复制', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.notepad')) })
        .onClick(() => {
          this.onDuplicate();
        })

      MenuItem({ content: '文件夹设置', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape')) })
        .onClick(() => {
          this.onSettings();
        })

      MenuItem({ content: '删除', symbolStartIcon: new SymbolGlyphModifier($r('sys.symbol.trash')) })
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

      // Expand/collapse icon
      Text() {
        SymbolSpan(this.isExpanded ? $r('sys.symbol.chevron_down') : $r("sys.symbol.chevron_right"))
      }
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .width(20)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onToggle();
        })

      // Folder icon
      Text('📁')
        .fontSize($r('app.float.font_size_md'))
        .margin({ right: $r('app.float.spacing_sm') })

      // Folder name or rename input
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
          .id('folder_rename_input_' + this.folder.id)
      } else {
        Text(this.folder.name)
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
    .backgroundColor($r('app.color.sidebar_background'))
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
      this.editingName = this.folder.name;
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
    if (timeDiff < 300) {
      // Double-click - start rename
      this.startRename();
    } else {
      // Single click - select and toggle
      this.onSelect();
    }

    this.lastClickTime = currentTime;
  }

  private startRename(): void {
    this.editingName = this.folder.name;
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
    if (trimmedName.length > 0 && trimmedName !== this.folder.name) {
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
      console.error('[FolderItem] Toast error:', error);
    }
  }

  private showDeleteConfirmation(): void {
    try {
      promptAction.showDialog({
        title: '删除文件夹',
        message: `确定要删除 "${this.folder.name}" 及其所有内容吗？`,
        buttons: [
          { text: '取消', color: '#000000' },
          { text: '删除', color: '#ff4d4f' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.onDelete();
          this.showToast('文件夹已删除');
        }
      }).catch((error: Error) => {
        console.error('[FolderItem] Delete confirmation error:', error);
      });
    } catch (error) {
      console.error('[FolderItem] Failed to show delete confirmation:', error);
    }
  }
}
