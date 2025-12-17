/**
 * Environment Management Dialog Component
 * Create, edit, and delete environments
 */

import { Environment, EnvironmentVariable } from '../model/Environment';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct EnvironmentManagementDialog {
  @Param isVisible: boolean = false;
  @Param workspaceId: string = '';
  @Param environments: Environment[] = [];
  @Param onClose: () => void = () => {};
  @Param onCreate: (environment: Environment) => Promise<void> = async () => {};
  @Param onUpdate: (environment: Environment) => Promise<void> = async () => {};
  @Param onDelete: (environmentId: string) => Promise<void> = async () => {};

  @Local showCreateForm: boolean = false;
  @Local editingEnvironment: Environment | null = null;
  @Local newEnvironmentName: string = '';
  @Local newEnvironmentVariables: EnvironmentVariable[] = [];

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
            Text('Environment Management')
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
          if (this.showCreateForm || this.editingEnvironment !== null) {
            this.buildEnvironmentForm();
          } else {
            this.buildEnvironmentList();
          }
        }
        .width('70%')
        .height('80%')
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
  buildEnvironmentList() {
    Column() {
      // Add Button
      Row() {
        ThemedButton({
          text: '+ New Environment',
          onButtonClick: () => {
            this.showCreateForm = true;
            this.newEnvironmentName = '';
            this.newEnvironmentVariables = [];
          },
          buttonSize: 'md'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Environment List
      Scroll() {
        Column() {
          if (this.environments.length === 0) {
            Text('No environments yet')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding($r('app.float.spacing_2xl'))
          } else {
            ForEach(this.environments, (environment: Environment) => {
              this.buildEnvironmentItem(environment);
            }, (environment: Environment) => environment.id)
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
  buildEnvironmentItem(environment: Environment) {
    Row() {
      Column() {
        Text(environment.name)
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .width('100%')

        Text(`${environment.variables.length} variables`)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: $r('app.float.spacing_xs') })
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
            this.editingEnvironment = environment;
            this.newEnvironmentName = environment.name;
            this.newEnvironmentVariables = [...environment.variables];
          })

        Button('Delete')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.danger'))
          .backgroundColor(Color.Transparent)
          .padding($r('app.float.spacing_sm'))
          .onClick(() => {
            this.handleDelete(environment.id);
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
  buildEnvironmentForm() {
    Column() {
      // Form Header
      Text(this.editingEnvironment ? 'Edit Environment' : 'Create Environment')
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
            value: this.newEnvironmentName,
            placeholder: 'Enter environment name',
            onValueChange: (value: string) => {
              this.newEnvironmentName = value;
            }
          })
            .margin({ bottom: $r('app.float.spacing_lg') })

          // Variables Section
          Row() {
            Text('Variables')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)
              .flexGrow(1)

            Button('+ Add')
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.button_text'))
              .backgroundColor($r('app.color.primary'))
              .padding({
                left: $r('app.float.spacing_md'),
                right: $r('app.float.spacing_md'),
                top: $r('app.float.spacing_xs'),
                bottom: $r('app.float.spacing_xs')
              })
              .onClick(() => {
                this.addVariable();
              })
          }
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_md') })

          // Variables List
          if (this.newEnvironmentVariables.length === 0) {
            Text('No variables yet')
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.text_secondary'))
              .width('100%')
              .textAlign(TextAlign.Center)
              .padding($r('app.float.spacing_lg'))
          } else {
            ForEach(this.newEnvironmentVariables, (variable: EnvironmentVariable, index: number) => {
              this.buildVariableRow(variable, index);
            }, (variable: EnvironmentVariable) => variable.id)
          }
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
            this.editingEnvironment = null;
          })

        Button(this.editingEnvironment ? 'Update' : 'Create')
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

  @Builder
  buildVariableRow(variable: EnvironmentVariable, index: number) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(variable.enabled)
        .onChange((value: boolean) => {
          variable.enabled = value;
        })
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input
      ThemedTextInput({
        value: variable.name,
        placeholder: 'Variable Name',
        onValueChange: (value: string) => {
          variable.name = value;
        },
        inputSize: 'sm'
      })
        .flexGrow(1)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input
      ThemedTextInput({
        value: variable.value,
        placeholder: 'Variable Value',
        onValueChange: (value: string) => {
          variable.value = value;
        },
        inputSize: 'sm'
      })
        .flexGrow(1)
        .margin({ right: $r('app.float.spacing_sm') })

      // Delete button
      Button('×')
        .fontSize($r('app.float.font_size_2xl'))
        .fontColor($r('app.color.danger'))
        .backgroundColor(Color.Transparent)
        .width(32)
        .height(32)
        .onClick(() => {
          this.deleteVariable(index);
        })
    }
    .width('100%')
    .padding($r('app.float.spacing_sm'))
    .margin({ bottom: $r('app.float.spacing_xs') })
    .backgroundColor($r('app.color.surface_highlight'))
    .borderRadius($r('app.float.border_radius_sm'))
  }

  private addVariable(): void {
    const newVariable: EnvironmentVariable = new EnvironmentVariable();
    newVariable.id = `var_${Date.now()}`;
    newVariable.name = '';
    newVariable.value = '';
    newVariable.enabled = true;
    this.newEnvironmentVariables.push(newVariable);
  }

  private deleteVariable(index: number): void {
    this.newEnvironmentVariables.splice(index, 1);
  }

  private async handleSave(): Promise<void> {
    if (!this.newEnvironmentName.trim()) {
      return;
    }

    if (this.editingEnvironment) {
      // Update existing environment
      this.editingEnvironment.name = this.newEnvironmentName;
      this.editingEnvironment.variables = this.newEnvironmentVariables;
      this.editingEnvironment.updated_at = Date.now();
      await this.onUpdate(this.editingEnvironment);
      this.editingEnvironment = null;
    } else {
      // Create new environment
      const environment: Environment = new Environment();
      environment.id = `env_${Date.now()}`;
      environment.workspace_id = this.workspaceId;
      environment.name = this.newEnvironmentName;
      environment.variables = this.newEnvironmentVariables;
      environment.created_at = Date.now();
      environment.updated_at = Date.now();
      await this.onCreate(environment);
      this.showCreateForm = false;
    }
  }

  private async handleDelete(environmentId: string): Promise<void> {
    // TODO: Add confirmation dialog
    await this.onDelete(environmentId);
  }
}
