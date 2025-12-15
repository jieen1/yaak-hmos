import { Workspace } from '../../model/Workspace';
import { ThemeManager, ThemeColors } from '../../theme/Theme';
import { CreateWorkspaceDialog } from '../dialogs/CreateWorkspaceDialog';
import { WorkspaceSettingsDialog } from '../dialogs/WorkspaceSettingsDialog';

@ComponentV2
export struct WorkspaceDropdown {
  @Param workspaces: Workspace[] = [];
  @Param activeWorkspace: Workspace | null = null;
  @Event onSelect: (ws: Workspace) => void = () => {};
  @Event onDataChange: () => void = () => {}; // Notify parent to reload data
  
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  createDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateWorkspaceDialog({
      onCreate: () => {
        this.onDataChange();
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  settingsDialogController: CustomDialogController = new CustomDialogController({
    builder: WorkspaceSettingsDialog({
      workspace: this.activeWorkspace, // This will capture the INITIAL value!
      onUpdate: () => { this.onDataChange() },
      onDelete: () => { this.onDataChange() }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });
  
  openSettings() {
    if (!this.activeWorkspace) return;
    const controller = new CustomDialogController({
      builder: WorkspaceSettingsDialog({
        workspace: this.activeWorkspace,
        onUpdate: () => { this.onDataChange() },
        onDelete: () => { this.onDataChange() }
      }),
      alignment: DialogAlignment.Center,
      autoCancel: true,
      customStyle: true
    });
    controller.open();
  }

  @Builder
  WorkspaceMenu() {
    Menu() {
      ForEach(this.workspaces, (ws: Workspace) => {
        MenuItem({
          content: ws.name,
          startIcon: (this.activeWorkspace?.id === ws.id) ? $r('sys.symbol.checkmark') : undefined
        })
        .onClick(() => {
          this.onSelect(ws);
        })
      })

      MenuItem({
        content: "Workspace Settings",
        startIcon: $r('sys.symbol.barrage_setting')
      })
      .onClick(() => {
        this.openSettings();
      })

      MenuItem({
        content: "New Workspace",
        startIcon: $r('sys.symbol.plus')
      })
      .onClick(() => {
        this.createDialogController.open();
      })
    }
  }

  build() {
    Row() {
      Button(this.activeWorkspace?.name ?? "Select Workspace")
        .fontSize(14)
        .fontColor(this.theme.text)
        .backgroundColor(Color.Transparent)
        .height(30)
        .bindMenu(this.WorkspaceMenu)
    }
  }
}
