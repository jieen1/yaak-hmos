/**
 * Environment Dialog Component
 * Dialog for creating/editing environments
 */

import { Environment, EnvironmentVariable } from '../model/Environment';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@CustomDialog
@ComponentV2
export struct EnvironmentDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: EnvironmentDialog()
  });

  @Param environment: Environment | null = null;
  @Param workspaceId: string = '';
  @Param onSave: (environment: Environment) => void = () => {};

  @Local name: string = '';
  @Local variables: EnvironmentVariable[] = [];

  aboutToAppear(): void {
    if (this.environment) {
      this.name = this.environment.name;
      this.variables = [...this.environment.variables];
    }
  }

  build() {
    Column() {
      // Dialog Title
      Text(this.environment ? 'Edit Environment' : 'New Environment')
        .fontSize($r('app.float.font_size_xl'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_lg') })

      // Content
      Column() {
        // Environment Name
        Text('Name *')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.name,
          placeholder: 'Enter environment name',
          onValueChange: (value: string) => {
            this.name = value;
          },
          inputSize: 'md'
        })
          .margin({ bottom: $r('app.float.spacing_lg') })

        // Variables Section
        Row() {
          Text('Variables')
            .fontSize($r('app.float.font_size_lg'))
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .flexGrow(1)

          ThemedButton({
            text: 'Add',
            onButtonClick: () => {
              this.addVariable();
            },
            buttonSize: 'sm'
          })
        }
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_md') })

        // Variables List
        if (this.variables.length === 0) {
          Text('No variables')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding($r('app.float.spacing_xl'))
        } else {
          Scroll() {
            Column() {
              ForEach(this.variables, (variable: EnvironmentVariable, index: number) => {
                this.buildVariableRow(variable, index);
              }, (variable: EnvironmentVariable) => variable.id)
            }
            .width('100%')
          }
          .layoutWeight(1)
          .width('100%')
          .scrollBar(BarState.Auto)
        }
      }
      .layoutWeight(1)
      .width('100%')

      // Action Buttons
      Row() {
        Button('Cancel')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_sm') })
          .onClick(() => {
            this.controller.close();
          })

        Button('Save')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.primary'))
          .flexGrow(1)
          .margin({ left: $r('app.float.spacing_sm') })
          .enabled(this.name.trim().length > 0)
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .margin({ top: $r('app.float.spacing_lg') })
    }
    .width('100%')
    .height('80%')
    .padding($r('app.float.spacing_lg'))
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildVariableRow(variable: EnvironmentVariable, index: number) {
    Column() {
      Row() {
        // Enabled Checkbox
        Checkbox()
          .select(variable.enabled)
          .onChange((value: boolean) => {
            variable.enabled = value;
          })
          .margin({ right: $r('app.float.spacing_sm') })

        Column() {
          // Name Input
          ThemedTextInput({
            value: variable.name,
            placeholder: 'Variable Name',
            onValueChange: (value: string) => {
              variable.name = value;
            },
            inputSize: 'sm'
          })
            .margin({ bottom: $r('app.float.spacing_xs') })

          // Value Input
          ThemedTextInput({
            value: variable.value,
            placeholder: 'Variable Value',
            onValueChange: (value: string) => {
              variable.value = value;
            },
            inputType: variable.is_secret ? InputType.Password : InputType.Normal,
            inputSize: 'sm'
          })
        }
        .flexGrow(1)
        .margin({ right: $r('app.float.spacing_sm') })

        // Secret Toggle
        Column() {
          Text('🔒')
            .fontSize($r('app.float.font_size_lg'))
            .fontColor(variable.is_secret ? $r('app.color.primary') : $r('app.color.text_secondary'))
            .onClick(() => {
              variable.is_secret = !variable.is_secret;
            })
            .margin({ bottom: $r('app.float.spacing_xs') })

          // Delete Button
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
      }
      .width('100%')
      .padding($r('app.float.spacing_sm'))
      .backgroundColor($r('app.color.surface'))
      .borderRadius($r('app.float.border_radius_md'))
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_sm') })
  }

  private addVariable(): void {
    const variable: EnvironmentVariable = new EnvironmentVariable();
    variable.id = `var_${Date.now()}`;
    variable.name = '';
    variable.value = '';
    variable.enabled = true;
    variable.is_secret = false;
    this.variables.push(variable);
  }

  private deleteVariable(index: number): void {
    this.variables.splice(index, 1);
  }

  private handleSave(): void {
    if (this.name.trim().length === 0) {
      return;
    }

    const env: Environment = this.environment || new Environment();
    env.name = this.name.trim();
    env.workspace_id = this.workspaceId;
    env.variables = this.variables;

    if (!this.environment) {
      env.id = `env_${Date.now()}`;
      env.created_at = Date.now();
    }
    env.updated_at = Date.now();

    this.onSave(env);
    this.controller.close();
  }
}
