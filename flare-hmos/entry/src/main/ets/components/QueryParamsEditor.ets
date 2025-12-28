/**
 * Query Parameters Editor Component
 * Edits URL query parameters for requests
 */

import { QueryParam } from '../model/HttpRequest';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

/**
 * Flat list item for query parameter rendering
 */
interface FlatQueryParamItem {
  id: string;
  name: string;
  value: string;
  enabled: boolean;
  index: number;
}

@ComponentV2
export struct QueryParamsEditor {
  @Param @Require queryParams: QueryParam[];
  @Param requestId: string = '';  // 新增：请求 ID，用于监听请求切换
  @Event onChange: (queryParams: QueryParam[]) => void = () => {
  };

  // Local flat list for UI rendering - triggers update when rebuilt
  @Local flatList: FlatQueryParamItem[] = [];

  aboutToAppear(): void {
    this.rebuildFlatList();
  }

  // Monitor queryParams and requestId changes and rebuild flat list
  // 监听 requestId 确保切换请求时强制刷新
  @Monitor('queryParams', 'requestId')
  onQueryParamsChange(): void {
    console.info(`[QueryParamsEditor] Data changed, requestId: ${this.requestId}, params count: ${this.queryParams.length}`);
    this.rebuildFlatList();
  }

  /**
   * Rebuild flat list from queryParams
   * Creates a new array to trigger UI update
   */
  private rebuildFlatList(): void {
    const newFlatList: FlatQueryParamItem[] = [];
    this.queryParams.forEach((param: QueryParam, index: number) => {
      const flatItem: FlatQueryParamItem = {
        id: param.id,
        name: param.name,
        value: param.value,
        enabled: param.enabled,
        index: index
      };
      newFlatList.push(flatItem);
    });
    this.flatList = newFlatList;
  }

  build() {
    Column() {
      // Header
      Row() {
        Text('请求参数')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .flexGrow(1)

        ThemedButton({
          text: '添加',
          onButtonClick: () => {
            this.addQueryParam();
          },
          buttonSize: 'sm'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Query Parameters list
      if (this.flatList.length === 0) {
        Text('没有请求参数')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      } else {
        List() {
          ForEach(this.flatList, (flatItem: FlatQueryParamItem) => {
            ListItem() {
              this.buildQueryParamRow(flatItem);
            }
          }, (flatItem: FlatQueryParamItem) => flatItem.id + '_' + flatItem.name + '_' + flatItem.value + '_' + flatItem.enabled)
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
  buildQueryParamRow(flatItem: FlatQueryParamItem) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(flatItem.enabled)
        .onChange((value: boolean) => {
          // Update original data
          if (flatItem.index < this.queryParams.length) {
            const param: QueryParam | undefined = this.queryParams[flatItem.index];
            if (param) {
              param.enabled = value;
              this.onChange(this.queryParams);
              this.rebuildFlatList();
            }
          }
        })
        .width(24)
        .height(24)
        .flexShrink(0)
        .selectedColor($r('app.color.button_background'))
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input - fixed width
      ThemedTextInput({
        value: flatItem.name,
        placeholder: '参数名称',
        onValueChange: (value: string) => {
          // Update original data
          if (flatItem.index < this.queryParams.length) {
            const param: QueryParam | undefined = this.queryParams[flatItem.index];
            if (param) {
              param.name = value;
              this.onChange(this.queryParams);
            }
            // Don't rebuild on every keystroke for performance
          }
        },
        inputSize: 'md'
      })
        .width(200)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input - takes remaining space
      ThemedTextInput({
        value: flatItem.value,
        placeholder: '参数值',
        onValueChange: (value: string) => {
          // Update original data
          if (flatItem.index < this.queryParams.length) {
            const param: QueryParam | undefined = this.queryParams[flatItem.index];
            if (param) {
              param.value = value;
              this.onChange(this.queryParams);
            }
            // Don't rebuild on every keystroke for performance
          }
        },
        inputSize: 'md'
      })
        .layoutWeight(1)
        .margin({ right: $r('app.float.spacing_sm') })

      ThemedButton({
        symbolIcon: $r("sys.symbol.xmark"),
        onButtonClick: () => this.deleteQueryParam(flatItem.index),
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
    this.rebuildFlatList();
  }

  /**
   * Delete query parameter
   */
  private deleteQueryParam(index: number): void {
    this.queryParams.splice(index, 1);
    this.onChange(this.queryParams);
    this.rebuildFlatList();
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    return `qp_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}
