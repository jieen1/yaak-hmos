/**
 * Query Parameters Editor Component
 * Edits URL query parameters for requests
 */

import { QueryParam } from '../model/HttpRequest';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct QueryParamsEditor {
  @Param queryParams: QueryParam[] = [];
  @Param onChange: (queryParams: QueryParam[]) => void = () => {
  };

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
            this.addQueryParam();
          },
          buttonSize: 'sm'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Query Parameters list
      if (this.queryParams.length === 0) {
        Text('No query parameters')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      } else {
        List() {
          ForEach(this.queryParams, (param: QueryParam, index: number) => {
            this.buildQueryParamRow(param, index);
          }, (param: QueryParam) => param.id)
        }
        .width('100%')
        .height("100%")
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
  buildQueryParamRow(param: QueryParam, index: number) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(param.enabled)
        .onChange((value: boolean) => {
          param.enabled = value;
          this.onChange(this.queryParams);
        })
        .width(24)
        .height(24)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input - fixed width
      ThemedTextInput({
        value: param.name,
        placeholder: 'Parameter Name',
        onValueChange: (value: string) => {
          param.name = value;
          this.onChange(this.queryParams);
        },
        inputSize: 'md'
      })
        .width(200)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input - takes remaining space
      ThemedTextInput({
        value: param.value,
        placeholder: 'Parameter Value',
        onValueChange: (value: string) => {
          param.value = value;
          this.onChange(this.queryParams);
        },
        inputSize: 'md'
      })
        .layoutWeight(1)
        .margin({ right: $r('app.float.spacing_sm') })

      ThemedButton({
        symbolIcon: $r("sys.symbol.xmark"),
        onButtonClick: () => this.deleteQueryParam(index),
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

  /**
   * Add new query parameter
   */
  private addQueryParam(): void {
    const newParam = new QueryParam();
    newParam.id = this.generateId();
    newParam.name = '';
    newParam.value = '';
    newParam.enabled = true;

    this.queryParams.push(newParam);
    this.onChange(this.queryParams);
  }

  /**
   * Delete query parameter
   */
  private deleteQueryParam(index: number): void {
    this.queryParams.splice(index, 1);
    this.onChange(this.queryParams);
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    return `qp_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}
