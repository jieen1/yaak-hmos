/**
 * Query Params Editor Component
 * Edits query parameters for HTTP requests
 */

import { QueryParam } from '../model/HttpRequest';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct QueryParamsEditor {
  @Param params: QueryParam[] = [];
  @Param onChange: (params: QueryParam[]) => void = () => {};

  build() {
    Column() {
      // Header
      Row() {
        Text('Query Parameters')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .flexGrow(1)

        ThemedButton({
          text: 'Add',
          onButtonClick: () => {
            this.addParam();
          },
          buttonSize: 'sm'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Parameters list
      if (this.params.length === 0) {
        Text('No query parameters')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      } else {
        List() {
          ForEach(this.params, (param: QueryParam, index: number) => {
            ListItem() {
              this.buildParamRow(param, index)
            }
          }, (param: QueryParam) => param.id)
        }
        .width('100%')
        .layoutWeight(1)
        .divider({
          strokeWidth: 1,
          color: $r('app.color.divider')
        })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildParamRow(param: QueryParam, index: number) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(param.enabled)
        .onChange((value: boolean) => {
          param.enabled = value;
          this.onChange(this.params);
        })
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input
      ThemedTextInput({
        value: param.name,
        placeholder: 'Name',
        onValueChange: (value: string) => {
          param.name = value;
          this.onChange(this.params);
        },
        inputSize: 'sm'
      })
        .flexGrow(1)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input
      ThemedTextInput({
        value: param.value,
        placeholder: 'Value',
        onValueChange: (value: string) => {
          param.value = value;
          this.onChange(this.params);
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
          this.deleteParam(index);
        })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .alignItems(VerticalAlign.Center)
  }

  /**
   * Add new parameter
   */
  private addParam(): void {
    const newParam = new QueryParam();
    newParam.id = this.generateId();
    newParam.name = '';
    newParam.value = '';
    newParam.enabled = true;

    this.params.push(newParam);
    this.onChange(this.params);
  }

  /**
   * Delete parameter
   */
  private deleteParam(index: number): void {
    this.params.splice(index, 1);
    this.onChange(this.params);
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    return `qp_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}
