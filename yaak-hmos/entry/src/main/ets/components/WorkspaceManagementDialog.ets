/**
 * Workspace Management Dialog Component
 * Create, edit, and delete workspaces
 */

import { Workspace } from '../model/Workspace';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct WorkspaceManagementDialog {
  @Param isVisible: boolean = false;
  @Param workspaces: Workspace[] = [];
  @Param onClose: () => void = () => {};
  @Param onCreate: (workspace: Workspace) => Promise<void> = async () => {};
  @Param onUpdate: (workspace: Workspace) => Promise<void> = async () => {};
  @Param onDelete: (workspaceId: string) => Promise<void> = async () => {};

  @Local showCreateForm: boolean = false;
  @Local editingWorkspace: Workspace | null = null;
  @Local newWorkspaceName: string = '';
  @Local newWorkspaceDescription: string = '';

  build() {
    if (this.isVisible) {
      Stack() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          })

        // Dialog Content
        Column() {
          // Dialog Header
          Row() {
            Text('Workspace Management')
              .fontSize($r('app.float.font_size_xl'))
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
              .flexGrow(1)

            ThemedButton({
              symbolIcon: $r("sys.symbol.xmark"),
              onButtonClick: () => this.onClose(),
              buttonType: 'ghost'
            })
          }
          .width('100%')
          .padding($r('app.float.spacing_md'))
          .border({
            width: { bottom: 1 },
            color: $r('app.color.divider')
          })

          // Content
          if (this.showCreateForm || this.editingWorkspace !== null) {
            this.buildWorkspaceForm();
          } else {
            this.buildWorkspaceList();
          }
        }
        .width('70%')
        .height('70%')
        .backgroundColor($r('app.color.background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }

  @Builder
  buildWorkspaceList() {
    Column() {
      // Add Button
      Row() {
        ThemedButton({
          text: '+ New Workspace',
          onButtonClick: () => {
            this.showCreateForm = true;
            this.newWorkspaceName = '';
            this.newWorkspaceDescription = '';
          },
          buttonSize: 'md'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Workspace List
      Scroll() {
        Column() {
          if (this.workspaces.length === 0) {
            Text('No workspaces yet')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding($r('app.float.spacing_2xl'))
          } else {
            ForEach(this.workspaces, (workspace: Workspace) => {
              this.buildWorkspaceItem(workspace);
            }, (workspace: Workspace) => workspace.id)
          }
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildWorkspaceItem(workspace: Workspace) {
    Row() {
      Column() {
        Text(workspace.name)
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .width('100%')

        if (workspace.description) {
          Text(workspace.description)
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ top: $r('app.float.spacing_xs') })
        }
      }
      .flexGrow(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        Button('Edit')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.primary'))
          .backgroundColor(Color.Transparent)
          .padding($r('app.float.spacing_sm'))
          .onClick(() => {
            this.editingWorkspace = workspace;
            this.newWorkspaceName = workspace.name;
            this.newWorkspaceDescription = workspace.description;
          })

        Button('Delete')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.danger'))
          .backgroundColor(Color.Transparent)
          .padding($r('app.float.spacing_sm'))
          .onClick(() => {
            this.handleDelete(workspace.id);
          })
      }
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .backgroundColor($r('app.color.surface'))
    .borderRadius($r('app.float.border_radius_md'))
    .margin({ bottom: $r('app.float.spacing_sm') })
  }

  @Builder
  buildWorkspaceForm() {
    Column() {
      // Form Header
      Text(this.editingWorkspace ? 'Edit Workspace' : 'Create Workspace')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .padding($r('app.float.spacing_md'))

      // Form Fields
      Scroll() {
        Column() {
          Text('Name')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_xs') })

          ThemedTextInput({
            value: this.newWorkspaceName,
            placeholder: 'Enter workspace name',
            onValueChange: (value: string) => {
              this.newWorkspaceName = value;
            }
          })
            .margin({ bottom: $r('app.float.spacing_md') })

          Text('Description (Optional)')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_xs') })

          ThemedTextInput({
            value: this.newWorkspaceDescription,
            placeholder: 'Enter workspace description',
            onValueChange: (value: string) => {
              this.newWorkspaceDescription = value;
            }
          })
        }
        .width('100%')
        .padding($r('app.float.spacing_md'))
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)

      // Form Actions
      Row() {
        Button('Cancel')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_sm') })
          .onClick(() => {
            this.showCreateForm = false;
            this.editingWorkspace = null;
          })

        Button(this.editingWorkspace ? 'Update' : 'Create')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.primary'))
          .flexGrow(1)
          .margin({ left: $r('app.float.spacing_sm') })
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
      .border({
        width: { top: 1 },
        color: $r('app.color.divider')
      })
    }
    .width('100%')
    .height('100%')
  }

  private async handleSave(): Promise<void> {
    if (!this.newWorkspaceName.trim()) {
      return;
    }

    if (this.editingWorkspace) {
      // Update existing workspace
      this.editingWorkspace.name = this.newWorkspaceName;
      this.editingWorkspace.description = this.newWorkspaceDescription;
      this.editingWorkspace.updated_at = Date.now();
      await this.onUpdate(this.editingWorkspace);
      this.editingWorkspace = null;
    } else {
      // Create new workspace
      const workspace: Workspace = new Workspace();
      workspace.id = `ws_${Date.now()}`;
      workspace.name = this.newWorkspaceName;
      workspace.description = this.newWorkspaceDescription;
      workspace.created_at = Date.now();
      workspace.updated_at = Date.now();
      await this.onCreate(workspace);
      this.showCreateForm = false;
    }
  }

  private async handleDelete(workspaceId: string): Promise<void> {
    // TODO: Add confirmation dialog
    await this.onDelete(workspaceId);
  }
}
