import { SidebarActions } from './SidebarActions';
import { CookieDropdown } from './CookieDropdown';
import { WorkspaceDropdown } from './WorkspaceDropdown';
import { EnvironmentDropdown } from './EnvironmentDropdown';
import { RecentRequests } from './RecentRequests';
import { SettingsDropdown } from './SettingsDropdown';
import { IconButton } from '../core/IconButton';
import { PillButton } from '../core/PillButton';
import { Workspace } from '../../model/Workspace';
import { Environment } from '../../model/Environment';
import { ThemeManager, ThemeColors } from '../../theme/Theme';

@ComponentV2
export struct WorkspaceHeader {
  @Param workspaces: Workspace[] = [];
  @Param activeWorkspace: Workspace | null = null;
  @Param environments: Environment[] = [];
  @Param activeEnvironment: Environment | null = null;
  
  @Param workspaceLayout: string = 'horizontal';
  @Param sidebarHidden: boolean = false;

  @Event onWorkspaceSelect: (ws: Workspace) => void = () => {};
  @Event onWorkspaceAdd: () => void = () => {}; // This triggers refresh
  @Event onEnvironmentSelect: (env: Environment | null) => void = () => {};
  @Event onLayoutChange: (layout: string) => void = () => {};
  @Event onSidebarToggle: () => void = () => {};
  @Event onOpenSettings: () => void = () => {};

  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  build() {
    Row() {
      // Left Section
      Row({ space: 4 }) {
        SidebarActions({
          sidebarHidden: this.sidebarHidden,
          onToggle: () => { this.onSidebarToggle() }
        })
        CookieDropdown()
        
        Row() {
          WorkspaceDropdown({
            workspaces: this.workspaces,
            activeWorkspace: this.activeWorkspace,
            onSelect: (ws: Workspace) => { this.onWorkspaceSelect(ws) },
            onDataChange: () => { this.onWorkspaceAdd() } // Reuse refresh trigger
          })
          SymbolGlyph($r('sys.symbol.chevron_right'))
            .fontSize(12)
            .fontColor([this.theme.textSecondary])
            .margin({ left: 4, right: 4 })
            
          EnvironmentDropdown({
            environments: this.environments,
            activeEnvironment: this.activeEnvironment,
            onSelect: (env: Environment | null) => { this.onEnvironmentSelect(env) },
            onDataChange: () => { this.onWorkspaceAdd() } // Reuse refresh trigger
          })
        }
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Start)
      .alignItems(VerticalAlign.Center)

      // Center Section (Recent Requests)
      Row() {
        RecentRequests()
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)

      // Right Section
      Row({ space: 8 }) {
        Button("Import cURL")
          .fontSize(12)
          .height(24)
          .backgroundColor(Color.Transparent)
          .fontColor(this.theme.primary)
          .onClick(() => {
             // Mock Import
          })

        // License Badge (Mock - "Free" or "Pro")
        PillButton({ text: "Free", color: "primary" })

        // Layout Toggle
        IconButton({
          icon: this.workspaceLayout === 'horizontal' ? $r('sys.symbol.square') : $r('sys.symbol.square_1'),
          tooltip: "Toggle Layout",
          action: () => {
            this.onLayoutChange(this.workspaceLayout === 'horizontal' ? 'vertical' : 'horizontal');
          }
        })

        // Command Palette Trigger
        IconButton({
          icon: $r('sys.symbol.magnifyingglass'),
          tooltip: "Search",
          action: () => {
            // Mock Toggle Palette
          }
        })

        SettingsDropdown({
          onOpenSettings: () => { this.onOpenSettings() }
        })
      }
      .layoutWeight(1)
      .justifyContent(FlexAlign.End)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .height(50) // Standard header height
    .backgroundColor(this.theme.headerBackground) 
    .padding({ left: 10, right: 10 })
    .border({ width: { bottom: 1 }, color: this.theme.border }) 
  }
}
