import { Environment } from '../../model/Environment';
import { ThemeManager, ThemeColors } from '../../theme/Theme';
import { EnvironmentManagerDialog } from '../dialogs/EnvironmentManagerDialog';

@ComponentV2
export struct EnvironmentDropdown {
  @Param environments: Environment[] = [];
  @Param activeEnvironment: Environment | null = null;
  @Event onSelect: (env: Environment | null) => void = () => {};
  
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  getWorkspaceId(): string {
    if (this.environments.length > 0) return this.environments[0].workspace_id;
    return '';
  }

  managerDialogController: CustomDialogController = new CustomDialogController({
    builder: EnvironmentManagerDialog({
      workspaceId: this.getWorkspaceId(),
      onUpdate: () => {
        this.onDataChange();
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });
  
  @Event onDataChange: () => void = () => {};

  @Builder
  EnvironmentMenu() {
    Menu() {
      // Environment List
      ForEach(this.environments, (env: Environment) => {
        MenuItem({
          content: env.name,
          startIcon: (this.activeEnvironment?.id === env.id) ? $r('sys.symbol.checkmark') : undefined
        })
        .onClick(() => {
          this.onSelect(env);
        })
      })

      MenuItem({
        content: "No Environment",
        startIcon: (this.activeEnvironment === null) ? $r('sys.symbol.checkmark') : undefined
      })
      .onClick(() => {
        this.onSelect(null);
      })

      MenuItem({
        content: "Manage Environments",
        startIcon: $r('sys.symbol.square_grid_2x2') 
      })
      .onClick(() => {
         const wsId = this.getWorkspaceId();
         if (wsId) {
           this.managerDialogController.open();
         }
      })
    }
  }

  build() {
    Button(this.activeEnvironment?.name ?? "No Environment")
      .fontSize(14)
      .fontColor(this.activeEnvironment ? this.theme.warning : this.theme.textSecondary) 
      .backgroundColor(Color.Transparent)
      .height(30)
      .bindMenu(this.EnvironmentMenu)
  }
}
