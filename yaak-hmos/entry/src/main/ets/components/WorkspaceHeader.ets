/**
 * Workspace Header Component
 * Top navigation bar with workspace and environment selectors
 */

import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { ThemedButton } from '.';

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

  build() {
    Row() {
      // Workspace Selector with Manage Button
      Row() {
        ThemedSelect({
          options: this.buildWorkspaceOptions(),
          selectedValue: this.activeWorkspace?.id || '',
          placeholder: 'Select Workspace',
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
          placeholder: 'No Environment',
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
      label: 'No Environment',
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
