/**
 * Workspace Header Component
 * Top navigation bar with workspace and environment selectors
 */

import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { ThemedButton } from '.';
import { NetworkService } from '../services/NetworkService';
import type { NetworkStatus } from '../services/NetworkService';

@ComponentV2
export struct WorkspaceHeader {
  @Param workspaces: Workspace[] = [];
  @Param activeWorkspace: Workspace | null = null;
  @Param environments: Environment[] = [];
  @Param activeEnvironment: Environment | null = null;
  @Param responseViewerHidden: boolean = true;
  @Param onWorkspaceSelect: (workspace: Workspace) => void = () => {};
  @Param onEnvironmentSelect: (environment: Environment | null) => void = () => {};
  @Param onOpenSettings: () => void = () => {};
  @Param onManageWorkspaces: () => void = () => {};
  @Param onManageEnvironments: () => void = () => {};
  @Param onToggleResponseViewer: () => void = () => {};
  @Param onExport: () => void = () => {};
  @Param onToggleCommandPalette: () => void = () => {};

  @Local isOnline: boolean = true;
  @Local networkType: string = 'unknown';

  private networkCallback = (status: NetworkStatus): void => {
    this.isOnline = status.isOnline;
    this.networkType = status.networkType;
  };

  aboutToAppear(): void {
    // Initialize network status
    const networkService = NetworkService.getInstance();
    const status = networkService.getStatus();
    this.isOnline = status.isOnline;
    this.networkType = status.networkType;

    // Register for network status changes
    networkService.onStatusChanged(this.networkCallback);
  }

  aboutToDisappear(): void {
    // Unregister network callback
    NetworkService.getInstance().offStatusChanged(this.networkCallback);
  }

  build() {
    Row() {
      // Workspace Selector with Manage Button
      Row() {
        ThemedSelect({
          options: this.buildWorkspaceOptions(),
          selectedValue: this.activeWorkspace?.id || '',
          placeholder: '选择工作区',
          onSelectChange: (value: string) => {
            const workspace: Workspace | undefined = this.workspaces.find((ws: Workspace) => ws.id === value);
            if (workspace) {
              this.onWorkspaceSelect(workspace);
            }
          },
          selectSize: 'md'
        })
          .width(180)

        ThemedButton({
          symbolIcon: $r('sys.symbol.house'),
          onButtonClick: () => {
            this.onManageWorkspaces();
          },
          buttonType: 'ghost',
          buttonSize: 'sm',
          isCircle: false
        })
          .margin({ left: $r('app.float.spacing_xs') })
      }
      .margin({ right: $r('app.float.spacing_md') })

      // Environment Selector with Manage Button
      Row() {
        ThemedSelect({
          options: this.buildEnvironmentOptions(),
          selectedValue: this.activeEnvironment?.id || 'none',
          placeholder: '无环境',
          onSelectChange: (value: string) => {
            if (value === 'none') {
              this.onEnvironmentSelect(null);
            } else {
              const env: Environment | undefined = this.environments.find((e: Environment) => e.id === value);
              if (env) {
                this.onEnvironmentSelect(env);
              }
            }
          },
          selectSize: 'md'
        })
          .width(180)

        ThemedButton({
          symbolIcon: $r('sys.symbol.glass'),
          onButtonClick: () => {
            this.onManageEnvironments();
          },
          buttonType: 'ghost',
          buttonSize: 'sm',
          isCircle: false
        })
          .margin({ left: $r('app.float.spacing_xs') })
      }

      Blank()

      // Offline indicator
      if (!this.isOnline) {
        Row() {
          Circle()
            .width(8)
            .height(8)
            .fill('#EF4444')
            .margin({ right: 6 })

          Text('离线模式')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor('#EF4444')
        }
        .padding({
          left: 12,
          right: 12,
          top: 6,
          bottom: 6
        })
        .backgroundColor('rgba(239, 68, 68, 0.1)')
        .borderRadius(16)
        .margin({ right: $r('app.float.spacing_md') })
      }

      // Import Button
      ThemedButton({
        symbolIcon: $r('sys.symbol.download'),
        onButtonClick: () => {
          // TODO
        },
        buttonType: 'ghost',
        buttonSize: 'md',
        isCircle: true
      })
        .margin({ right: $r('app.float.spacing_xs') })

      // Export Button
      ThemedButton({
        symbolIcon: $r('sys.symbol.upload'),
        onButtonClick: () => {
          this.onExport();
        },
        buttonType: 'ghost',
        buttonSize: 'md',
        isCircle: true
      })
        .margin({ right: $r('app.float.spacing_sm') })

      // Command Palette Button
      ThemedButton({
        symbolIcon: $r('sys.symbol.search_things'),
        onButtonClick: () => {
          this.onToggleCommandPalette();
        },
        buttonType: 'ghost',
        buttonSize: 'md',
        isCircle: true
      })
        .margin({ right: $r('app.float.spacing_sm') })

      // Response Viewer Toggle Button
      ThemedButton({
        symbolIcon: this.responseViewerHidden ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'),
        onButtonClick: () => {
          this.onToggleResponseViewer();
        },
        buttonType: 'ghost',
        buttonSize: 'md',
        isCircle: true
      })
        .margin({ right: $r('app.float.spacing_sm') })

      // Settings Button
      ThemedButton({
        symbolIcon: $r('sys.symbol.gearshape'),
        onButtonClick: () => {
          this.onOpenSettings();
        },
        buttonType: 'ghost',
        buttonSize: 'md',
        isCircle: true
      })
    }
    .width('100%')
    .height($r('app.float.header_height'))
    .padding({
      left: $r('app.float.spacing_lg'),
      right: $r('app.float.spacing_lg')
    })
    .backgroundColor($r('app.color.header_background'))
    .border({
      width: { bottom: $r('app.float.border_width_thin') },
      color: $r('app.color.divider')
    })
  }

  private buildWorkspaceOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    this.workspaces.forEach((ws: Workspace) => {
      const option: SelectOption = {
        label: ws.name,
        value: ws.id
      };
      options.push(option);
    });
    return options;
  }

  private buildEnvironmentOptions(): SelectOption[] {
    const options: SelectOption[] = [];
    
    // Add "No Environment" option
    const noneOption: SelectOption = {
      label: '无环境',
      value: 'none'
    };
    options.push(noneOption);

    // Add all environments
    this.environments.forEach((env: Environment) => {
      const option: SelectOption = {
        label: env.name,
        value: env.id
      };
      options.push(option);
    });

    return options;
  }
}
