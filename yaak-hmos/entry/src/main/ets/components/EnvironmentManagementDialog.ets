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
            Text('环境管理')
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
          text: '+ 新建环境',
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
      if (this.environments.length === 0) {
        Column() {
          Text('No environments yet')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding($r('app.float.spacing_2xl'))
        }
        .layoutWeight(1)
        .width('100%')
      } else {
        List() {
          ForEach(this.environments, (environment: Environment) => {
            ListItem() {
              this.buildEnvironmentItem(environment);
            }
          }, (environment: Environment) => environment.id)
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
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Row() {
        ThemedButton({
          text: '编辑',
          onButtonClick: () => {
            this.editingEnvironment = environment;
            this.newEnvironmentName = environment.name;
            this.newEnvironmentVariables = [...environment.variables];
          },
          buttonType: 'ghost',
          buttonSize: 'sm'
        })
          .margin({ right: $r('app.float.spacing_xs') })

        ThemedButton({
          text: '删除',
          onButtonClick: () => {
            this.handleDelete(environment.id);
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
  buildEnvironmentForm() {
    Column() {
      // Form Header with back button
      Row() {
        ThemedButton({
          symbolIcon: $r("sys.symbol.chevron_left"),
          onButtonClick: () => {
            this.showCreateForm = false;
            this.editingEnvironment = null;
          },
          buttonType: 'ghost',
          buttonSize: 'md'
        })
          .margin({ right: $r('app.float.spacing_sm') })

        Text(this.editingEnvironment ? '编辑环境' : '创建环境')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
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
      Column() {
        // Name Field
        Column() {
          Text('名称')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_xs') })

          ThemedTextInput({
            value: this.newEnvironmentName,
            placeholder: '输入环境名称',
            onValueChange: (value: string) => {
              this.newEnvironmentName = value;
            },
            inputSize: 'md'
          })
        }
        .width('100%')
        .padding($r('app.float.spacing_lg'))

        // Variables Section Header
        Row() {
          Text('变量')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Medium)
            .layoutWeight(1)

          ThemedButton({
            text: '添加',
            onButtonClick: () => {
              this.addVariable();
            },
            buttonSize: 'sm'
          })
        }
        .width('100%')
        .padding({
          left: $r('app.float.spacing_lg'),
          right: $r('app.float.spacing_lg'),
          bottom: $r('app.float.spacing_sm')
        })
        .alignItems(VerticalAlign.Center)

        // Variables List
        if (this.newEnvironmentVariables.length === 0) {
          Text('暂无变量')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .padding($r('app.float.spacing_2xl'))
        } else {
          List() {
            ForEach(this.newEnvironmentVariables, (variable: EnvironmentVariable, index: number) => {
              ListItem() {
                this.buildVariableRow(variable, index);
              }
            }, (variable: EnvironmentVariable) => variable.id)
          }
          .width('100%')
          .layoutWeight(1)
          .divider({
            strokeWidth: 1,
            color: $r('app.color.divider')
          })
        }
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Start)

      // Form Actions
      Row() {
        ThemedButton({
          text: '取消',
          onButtonClick: () => {
            this.showCreateForm = false;
            this.editingEnvironment = null;
          },
          buttonType: 'secondary',
          buttonSize: 'md'
        })
          .layoutWeight(1)
          .margin({ right: $r('app.float.spacing_sm') })

        ThemedButton({
          text: this.editingEnvironment ? '更新' : '创建',
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

  @Builder
  buildVariableRow(variable: EnvironmentVariable, index: number) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(variable.enabled)
        .onChange((value: boolean) => {
          variable.enabled = value;
        })
        .width(24)
        .height(24)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input - fixed width
      ThemedTextInput({
        value: variable.name,
        placeholder: '变量名',
        onValueChange: (value: string) => {
          variable.name = value;
        },
        inputSize: 'md'
      })
        .width(200)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input - takes remaining space
      ThemedTextInput({
        value: variable.value,
        placeholder: '变量值',
        onValueChange: (value: string) => {
          variable.value = value;
        },
        inputSize: 'md'
      })
        .layoutWeight(1)
        .margin({ right: $r('app.float.spacing_sm') })

      // Delete button
      ThemedButton({
        symbolIcon: $r("sys.symbol.xmark"),
        onButtonClick: () => this.deleteVariable(index),
        buttonType: 'ghost'
      })
    }
    .width('100%')
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md'),
      top: $r('app.float.spacing_sm'),
      bottom: $r('app.float.spacing_sm')
    })
    .alignItems(VerticalAlign.Center)
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
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
