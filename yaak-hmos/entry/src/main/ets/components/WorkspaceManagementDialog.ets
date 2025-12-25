/**
 * Workspace Management Dialog Component
 * Create, edit, and delete workspaces
 */

import { Workspace } from '../model/Workspace';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';
import { ThemedText } from './ThemedText';

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
            ThemedText({
              content: '工作区管理',
              fontWeight: FontWeight.Bold,
              fontColor: $r('app.color.text_primary')
            })
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
          text: '+ 新建工作区',
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
      if (this.workspaces.length === 0) {
        Column() {
          ThemedText({
            content: '没有工作台',
            fontColor: $r('app.color.text_secondary')
          })
        }
        .layoutWeight(1)
        .width('100%')
        .padding($r('app.float.spacing_2xl'))
        .justifyContent(FlexAlign.Center)
      } else {
        List() {
          ForEach(this.workspaces, (workspace: Workspace) => {
            ListItem() {
              this.buildWorkspaceItem(workspace);
            }
          }, (workspace: Workspace) => workspace.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.divider')
        })
        .scrollBar(BarState.Auto)
      }
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildWorkspaceItem(workspace: Workspace) {
    Row() {
      Column() {
        ThemedText({
          content: workspace.name,
          fontWeight: FontWeight.Medium,
          fontColor: $r('app.color.text_primary')
        })
          .width('100%')

        if (workspace.description) {
          ThemedText({
            content: workspace.description,
            fontColor: $r('app.color.text_secondary')
          })
            .width('100%')
            .margin({ top: $r('app.float.spacing_xs') })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        ThemedButton({
          text: '编辑',
          onButtonClick: () => {
            this.editingWorkspace = workspace;
            this.newWorkspaceName = workspace.name;
            this.newWorkspaceDescription = workspace.description;
          },
          buttonType: 'ghost',
          buttonSize: 'sm'
        })
          .margin({ right: $r('app.float.spacing_xs') })

        ThemedButton({
          text: '删除',
          onButtonClick: () => {
            this.handleDelete(workspace.id);
          },
          buttonType: 'ghost',
          buttonSize: 'sm'
        })
      }
    }
    .width('100%')
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md'),
      top: $r('app.float.spacing_md'),
      bottom: $r('app.float.spacing_md')
    })
    .alignItems(VerticalAlign.Center)
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }

  @Builder
  buildWorkspaceForm() {
    Column() {
      // Form Header with back button
      Row() {
        ThemedButton({
          symbolIcon: $r("sys.symbol.chevron_left"),
          onButtonClick: () => {
            this.showCreateForm = false;
            this.editingWorkspace = null;
          },
          buttonType: 'ghost',
          buttonSize: 'md'
        })
          .margin({ right: $r('app.float.spacing_sm') })

        ThemedText({
          content: this.editingWorkspace ? '编辑工作区' : '创建工作区',
          fontWeight: FontWeight.Medium,
          fontColor: $r('app.color.text_primary')
        })
          .layoutWeight(1)
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
      .alignItems(VerticalAlign.Center)
      .border({
        width: { bottom: 1 },
        color: $r('app.color.divider')
      })

      // Form Fields
      Scroll() {
        Column() {
          // Name Field
          Column() {
            ThemedText({
              content: '名称',
              fontColor: $r('app.color.text_secondary')
            })
              .width('100%')
              .margin({ bottom: $r('app.float.spacing_xs') })

            ThemedTextInput({
              value: this.newWorkspaceName,
              placeholder: '输入工作区名称',
              onValueChange: (value: string) => {
                this.newWorkspaceName = value;
              },
              inputSize: 'md'
            })
          }
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_lg') })

          // Description Field
          Column() {
            ThemedText({
              content: '描述（可选）',
              fontColor: $r('app.color.text_secondary')
            })
              .width('100%')
              .margin({ bottom: $r('app.float.spacing_xs') })

            ThemedTextInput({
              value: this.newWorkspaceDescription,
              placeholder: '输入工作区描述',
              onValueChange: (value: string) => {
                this.newWorkspaceDescription = value;
              },
              inputSize: 'md'
            })
          }
          .width('100%')
        }
        .width('100%')
        .padding($r('app.float.spacing_lg'))
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .align(Alignment.TopStart)

      // Form Actions
      Row() {
        ThemedButton({
          text: '取消',
          onButtonClick: () => {
            this.showCreateForm = false;
            this.editingWorkspace = null;
          },
          buttonType: 'secondary',
          buttonSize: 'md'
        })
          .layoutWeight(1)
          .margin({ right: $r('app.float.spacing_sm') })

        ThemedButton({
          text: this.editingWorkspace ? '更新' : '创建',
          onButtonClick: () => {
            this.handleSave();
          },
          buttonType: 'primary',
          buttonSize: 'md'
        })
          .layoutWeight(1)
          .margin({ left: $r('app.float.spacing_sm') })
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
