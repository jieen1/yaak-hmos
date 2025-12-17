/**
 * Workspace Header Component
 * Top navigation bar with workspace and environment selectors
 */

import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';
import { ThemedSelect, SelectOption } from './ThemedSelect';

@ComponentV2
export struct WorkspaceHeader {
  @Param workspaces: Workspace[] = [];
  @Param activeWorkspace: Workspace | null = null;
  @Param environments: Environment[] = [];
  @Param activeEnvironment: Environment | null = null;
  @Param onWorkspaceSelect: (workspace: Workspace) => void = () => {};
  @Param onEnvironmentSelect: (environment: Environment | null) => void = () => {};
  @Param onOpenSettings: () => void = () => {};

  build() {
    Row() {
      // Workspace Selector
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
        .width(200)
        .margin({ right: $r('app.float.spacing_md') })

      // Environment Selector
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
        .width(200)

      Blank()

      // Settings Button
      Button({ type: ButtonType.Circle }) {
        Text('⚙')
          .fontSize($r('app.float.font_size_xl'))
          .fontColor($r('app.color.text_primary'))
      }
      .backgroundColor($r('app.color.surface'))
      .width(40)
      .height(40)
      .onClick(() => {
        this.onOpenSettings();
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
