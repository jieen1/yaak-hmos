/**
 * ExportDialog - Modal dialog for exporting workspaces
 */

import { Workspace } from '../model/Workspace';
import { HttpRequest } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Environment } from '../model/Environment';
import { ExportService, ExportOptions, ExportResult, WorkspaceExportInput } from '../services/ExportService';
import promptAction from '@ohos.promptAction';
import pasteboard from '@ohos.pasteboard';

/**
 * Workspace selection item
 */
interface WorkspaceSelection {
  workspace: Workspace;
  selected: boolean;
  requestCount: number;
  folderCount: number;
}

@ComponentV2
export struct ExportDialog {
  @Param isVisible: boolean = false;
  @Param workspaces: Workspace[] = [];
  @Param currentWorkspace: Workspace | null = null;
  @Param onClose: () => void = () => {};
  @Param onExportComplete: (result: ExportResult) => void = () => {};
  @Param getWorkspaceData: (workspaceId: string) => WorkspaceDataResult = () => {
    const emptyResult: WorkspaceDataResult = {
      requests: [],
      folders: [],
      environments: []
    };
    return emptyResult;
  };

  @Local workspaceSelections: WorkspaceSelection[] = [];
  @Local includePrivateEnvs: boolean = false;
  @Local prettifyJson: boolean = true;
  @Local isExporting: boolean = false;
  @Local exportResult: ExportResult | null = null;
  @Local errorMessage: string = '';

  @Monitor('isVisible')
  onVisibilityChange(): void {
    if (this.isVisible) {
      this.initWorkspaceSelections();
    }
  }

  aboutToAppear(): void {
    this.initWorkspaceSelections();
  }

  private initWorkspaceSelections(): void {
    const selections: WorkspaceSelection[] = [];

    this.workspaces.forEach((ws: Workspace) => {
      const data: WorkspaceDataResult = this.getWorkspaceData(ws.id);
      const selection: WorkspaceSelection = {
        workspace: ws,
        selected: this.currentWorkspace?.id === ws.id,
        requestCount: data.requests.length,
        folderCount: data.folders.length
      };
      selections.push(selection);
    });

    this.workspaceSelections = selections;
  }

  build() {
    if (this.isVisible) {
      Column() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000')
          .position({ x: 0, y: 0 })
          .onClick(() => {
            if (!this.isExporting) {
              this.handleClose();
            }
          })

        // Dialog Content
        Column() {
          // Header
          this.buildHeader()

          // Content
          this.buildContent()

          // Footer
          this.buildFooter()
        }
        .width('80%')
        .width(500)
        .backgroundColor($r('app.color.background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .padding($r('app.float.spacing_lg'))
        .position({ x: '10%', y: '15%' })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }

  @Builder
  buildHeader() {
    Row() {
      Text('导出')
        .fontSize($r('app.float.font_size_lg'))
        .fontWeight(FontWeight.Bold)
        .fontColor($r('app.color.text_primary'))

      Blank()

      Text('✕')
        .fontSize(20)
        .fontColor($r('app.color.text_secondary'))
        .onClick(() => {
          if (!this.isExporting) {
            this.handleClose();
          }
        })
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_lg') })
  }

  @Builder
  buildContent() {
    Column() {
      // Workspace Selection
      Text('选择要导出的工作区:')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_sm') })

      // Select All / Deselect All
      Row() {
        Text('全选')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            this.selectAll(true);
          })

        Text(' | ')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))

        Text('取消全选')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.primary'))
          .onClick(() => {
            this.selectAll(false);
          })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_sm') })

      // Workspace List
      Scroll() {
        Column() {
          ForEach(this.workspaceSelections, (item: WorkspaceSelection, index: number) => {
            this.buildWorkspaceItem(item, index)
          }, (item: WorkspaceSelection) => item.workspace.id)
        }
        .width('100%')
      }
      .width('100%')
      .height(150)
      .scrollBar(BarState.Auto)
      .margin({ bottom: $r('app.float.spacing_md') })

      // Options
      Column() {
        Text('选项:')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_sm') })

        Row() {
          Checkbox()
            .select(this.includePrivateEnvs)
            .onChange((value: boolean) => {
              this.includePrivateEnvs = value;
            })

          Text('包含私有环境')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_primary'))
            .margin({ left: $r('app.float.spacing_sm') })
        }
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

        Row() {
          Checkbox()
            .select(this.prettifyJson)
            .onChange((value: boolean) => {
              this.prettifyJson = value;
            })

          Text('格式化 JSON 输出')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_primary'))
            .margin({ left: $r('app.float.spacing_sm') })
        }
        .width('100%')
      }
      .width('100%')
      .alignItems(HorizontalAlign.Start)

      // Error message
      if (this.errorMessage.length > 0) {
        Text(this.errorMessage)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.danger'))
          .width('100%')
          .margin({ top: $r('app.float.spacing_md') })
      }
    }
    .width('100%')
  }

  @Builder
  buildWorkspaceItem(item: WorkspaceSelection, index: number) {
    Row() {
      Checkbox()
        .select(item.selected)
        .onChange((value: boolean) => {
          this.toggleWorkspaceSelection(index, value);
        })

      Column() {
        Text(item.workspace.name)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text(`${item.requestCount} 个请求, ${item.folderCount} 个文件夹`)
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.text_secondary'))
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: $r('app.float.spacing_sm') })
    }
    .width('100%')
    .padding($r('app.float.spacing_sm'))
    .backgroundColor(item.selected ? $r('app.color.primary_light') : $r('app.color.input_background'))
    .borderRadius($r('app.float.border_radius_sm'))
    .margin({ bottom: $r('app.float.spacing_xs') })
    .onClick(() => {
      this.toggleWorkspaceSelection(index, !item.selected);
    })
  }

  @Builder
  buildFooter() {
    Row() {
      Button('取消')
        .type(ButtonType.Normal)
        .backgroundColor($r('app.color.button_background'))
        .fontColor($r('app.color.text_primary'))
        .height($r('app.float.button_height_md'))
        .borderRadius($r('app.float.border_radius_sm'))
        .enabled(!this.isExporting)
        .onClick(() => {
          this.handleClose();
        })

      Blank()

      Button(this.isExporting ? '导出中...' : '复制到剪贴板')
        .type(ButtonType.Normal)
        .backgroundColor($r('app.color.primary'))
        .fontColor(Color.White)
        .height($r('app.float.button_height_md'))
        .borderRadius($r('app.float.border_radius_sm'))
        .enabled(this.hasSelection() && !this.isExporting)
        .onClick(() => {
          this.handleExport();
        })
    }
    .width('100%')
    .margin({ top: $r('app.float.spacing_lg') })
  }

  private toggleWorkspaceSelection(index: number, selected: boolean): void {
    const item: WorkspaceSelection | undefined = this.workspaceSelections[index];
    if (item) {
      // Create new array to trigger UI update
      const newSelections: WorkspaceSelection[] = [];
      this.workspaceSelections.forEach((sel: WorkspaceSelection, i: number) => {
        if (i === index) {
          const updated: WorkspaceSelection = {
            workspace: sel.workspace,
            selected: selected,
            requestCount: sel.requestCount,
            folderCount: sel.folderCount
          };
          newSelections.push(updated);
        } else {
          newSelections.push(sel);
        }
      });
      this.workspaceSelections = newSelections;
    }
  }

  private selectAll(selected: boolean): void {
    const newSelections: WorkspaceSelection[] = [];
    this.workspaceSelections.forEach((sel: WorkspaceSelection) => {
      const updated: WorkspaceSelection = {
        workspace: sel.workspace,
        selected: selected,
        requestCount: sel.requestCount,
        folderCount: sel.folderCount
      };
      newSelections.push(updated);
    });
    this.workspaceSelections = newSelections;
  }

  private hasSelection(): boolean {
    for (let i = 0; i < this.workspaceSelections.length; i++) {
      const sel: WorkspaceSelection | undefined = this.workspaceSelections[i];
      if (sel && sel.selected) {
        return true;
      }
    }
    return false;
  }

  private async handleExport(): Promise<void> {
    this.errorMessage = '';

    // Get selected workspaces
    const selectedWorkspaces: WorkspaceSelection[] = [];
    this.workspaceSelections.forEach((sel: WorkspaceSelection) => {
      if (sel.selected) {
        selectedWorkspaces.push(sel);
      }
    });

    if (selectedWorkspaces.length === 0) {
      this.errorMessage = '请至少选择一个工作区';
      return;
    }

    this.isExporting = true;

    try {
      // Build export input
      const exportInputs: WorkspaceExportInput[] = [];
      selectedWorkspaces.forEach((sel: WorkspaceSelection) => {
        const data: WorkspaceDataResult = this.getWorkspaceData(sel.workspace.id);
        const input: WorkspaceExportInput = {
          workspace: sel.workspace,
          requests: data.requests,
          folders: data.folders,
          environments: data.environments
        };
        exportInputs.push(input);
      });

      // Export options
      const options: ExportOptions = {
        includeResponses: false,
        prettify: this.prettifyJson
      };

      // Perform export
      const result: ExportResult = ExportService.exportWorkspaces(exportInputs, options);

      this.exportResult = result;

      if (result.success) {
        // Copy to clipboard
        const pasteboardData: pasteboard.PasteData = pasteboard.createData(
          pasteboard.MIMETYPE_TEXT_PLAIN,
          result.data
        );
        const systemPasteboard: pasteboard.SystemPasteboard = pasteboard.getSystemPasteboard();
        await systemPasteboard.setData(pasteboardData);

        const message: string = `已导出 ${result.workspacesExported} 个工作区, ${result.requestsExported} 个请求`;
        this.showToast(message);
        this.onExportComplete(result);
        this.handleClose();
      } else {
        this.errorMessage = result.error || '导出失败';
      }
    } catch (error) {
      const errorMessage: string = error instanceof Error ? error.message : String(error);
      this.errorMessage = `导出失败: ${errorMessage}`;
    } finally {
      this.isExporting = false;
    }
  }

  private handleClose(): void {
    // Reset state
    this.exportResult = null;
    this.errorMessage = '';
    this.includePrivateEnvs = false;
    this.prettifyJson = true;

    this.onClose();
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[ExportDialog] Toast error:', error);
    }
  }
}

/**
 * Result type for getWorkspaceData callback
 */
export interface WorkspaceDataResult {
  requests: HttpRequest[];
  folders: Folder[];
  environments: Environment[];
}
