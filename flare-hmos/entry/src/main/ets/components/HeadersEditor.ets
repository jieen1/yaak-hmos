/**
 * Headers Editor Component
 * Edits HTTP headers for requests with inherited headers display
 */

import { HttpHeader } from '../model/HttpRequest';
import type { InheritedHeaderWithSource } from '../services/InheritanceService';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

/**
 * Flat list item for header rendering
 */
interface FlatHeaderItem {
  id: string;
  name: string;
  value: string;
  enabled: boolean;
  index: number;
}

@ComponentV2
export struct HeadersEditor {
  @Param headers: HttpHeader[] = [];
  @Param requestId: string = '';  // 新增：请求 ID，用于监听请求切换
  @Param inheritedHeaders: InheritedHeaderWithSource[] = [];
  @Event onChange: (headers: HttpHeader[]) => void = () => {};
  @Event onNavigateToSource: (sourceType: string, sourceId: string) => void = () => {};

  @Local showInheritedHeaders: boolean = true;
  // Local flat list for UI rendering - triggers update when rebuilt
  @Local private flatList: FlatHeaderItem[] = [];

  aboutToAppear(): void {
    this.rebuildFlatList();
  }

  @Monitor('headers', 'requestId')
  onHeadersChange(): void {
    console.info(`[HeadersEditor] Data changed, requestId: ${this.requestId}, headers count: ${this.headers.length}`);
    this.rebuildFlatList();
  }

  /**
   * Rebuild flat list from headers
   * Creates a new array to trigger UI update
   */
  private rebuildFlatList(): void {
    const newFlatList: FlatHeaderItem[] = [];
    this.headers.forEach((header: HttpHeader, index: number) => {
      const flatItem: FlatHeaderItem = {
        id: header.id,
        name: header.name,
        value: header.value,
        enabled: header.enabled,
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
        Text('请求头')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .flexGrow(1)

        ThemedButton({
          text: '添加',
          onButtonClick: () => {
            this.addHeader();
          },
          buttonSize: 'sm'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Inherited headers section (collapsible)
      if (this.inheritedHeaders.length > 0) {
        this.buildInheritedHeadersSection()
      }

      // Editable headers list
      if (this.flatList.length === 0 && this.inheritedHeaders.length === 0) {
        Text('没有请求头')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      } else {
        List() {
          ForEach(this.flatList, (flatItem: FlatHeaderItem) => {
            ListItem() {
              this.buildHeaderRow(flatItem)
            }
          }, (flatItem: FlatHeaderItem) => flatItem.id + '_' + flatItem.name + '_' + flatItem.value + '_' + flatItem.enabled)
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
  buildInheritedHeadersSection() {
    Column() {
      // Collapsible header
      Row() {
        Text(this.showInheritedHeaders ? '▼' : '▶')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ right: $r('app.float.spacing_xs') })

        Text('继承')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .fontWeight(FontWeight.Medium)

        // Count badge
        Text(`${this.inheritedHeaders.length}`)
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.primary'))
          .borderRadius(10)
          .padding({
            left: 6,
            right: 6,
            top: 2,
            bottom: 2
          })
          .margin({ left: $r('app.float.spacing_sm') })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_md'),
        right: $r('app.float.spacing_md'),
        top: $r('app.float.spacing_sm'),
        bottom: $r('app.float.spacing_sm')
      })
      .backgroundColor($r('app.color.surface_highlight'))
      .onClick(() => {
        this.showInheritedHeaders = !this.showInheritedHeaders;
      })

      // Inherited headers list (when expanded)
      if (this.showInheritedHeaders) {
        Column() {
          ForEach(this.inheritedHeaders, (inheritedHeader: InheritedHeaderWithSource) => {
            this.buildInheritedHeaderRow(inheritedHeader)
          }, (inheritedHeader: InheritedHeaderWithSource) => inheritedHeader.header.id + '_' + inheritedHeader.sourceId)
        }
        .width('100%')
        .padding({ bottom: $r('app.float.spacing_sm') })
        .backgroundColor($r('app.color.surface_highlight'))
      }
    }
    .width('100%')
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }

  @Builder
  buildInheritedHeaderRow(inheritedHeader: InheritedHeaderWithSource) {
    Row() {
      // Checkbox (disabled, always checked for inherited)
      Checkbox()
        .select(true)
        .enabled(false)
        .width(24)
        .height(24)
        .flexShrink(0)
        .selectedColor($r('app.color.button_background'))
        .margin({ right: $r('app.float.spacing_sm') })

      // Name (read-only)
      Text(inheritedHeader.header.name)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width(180)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value (read-only, masked if sensitive)
      Text(this.maskSensitiveValue(inheritedHeader.header.name, inheritedHeader.header.value))
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .layoutWeight(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ right: $r('app.float.spacing_sm') })

      // Source indicator (tappable)
      Text(`(${inheritedHeader.sourceName})`)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.primary'))
        .onClick(() => {
          this.onNavigateToSource(inheritedHeader.sourceType, inheritedHeader.sourceId);
        })
    }
    .width('100%')
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md'),
      top: $r('app.float.spacing_xs'),
      bottom: $r('app.float.spacing_xs')
    })
    .alignItems(VerticalAlign.Center)
  }

  @Builder
  buildHeaderRow(flatItem: FlatHeaderItem) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(flatItem.enabled)
        .onChange((value: boolean) => {
          // Update original data
          if (flatItem.index < this.headers.length) {
            const header: HttpHeader | undefined = this.headers[flatItem.index];
            if (header) {
              header.enabled = value;
              this.onChange(this.headers);
              this.rebuildFlatList();
            }
          }
        })
        .selectedColor($r('app.color.button_background'))
        .width(24)
        .height(24)
        .flexShrink(0)
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input - fixed width
      ThemedTextInput({
        value: flatItem.name,
        placeholder: '请求头名称',
        onValueChange: (value: string) => {
          // Update original data
          if (flatItem.index < this.headers.length) {
            const header: HttpHeader | undefined = this.headers[flatItem.index];
            if (header) {
              header.name = value;
              this.onChange(this.headers);
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
        placeholder: '请求头值',
        onValueChange: (value: string) => {
          // Update original data
          if (flatItem.index < this.headers.length) {
            const header: HttpHeader | undefined = this.headers[flatItem.index];
            if (header) {
              header.value = value;
              this.onChange(this.headers);
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
        onButtonClick: () => this.deleteHeader(flatItem.index),
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
  }

  /**
   * Mask sensitive header values
   */
  private maskSensitiveValue(name: string, value: string): string {
    const lowerName: string = name.toLowerCase();
    if (lowerName.includes('authorization') ||
        lowerName.includes('api-key') ||
        lowerName.includes('access-token') ||
        lowerName.includes('auth') ||
        lowerName.includes('secret') ||
        lowerName.includes('token') ||
        lowerName === 'cookie' ||
        lowerName === 'set-cookie') {
      if (value.length > 8) {
        return value.substring(0, 4) + '****' + value.substring(value.length - 4);
      }
      return '****';
    }
    return value;
  }

  /**
   * Add new header
   */
  private addHeader(): void {
    const newHeader = new HttpHeader();
    newHeader.id = this.generateId();
    newHeader.name = '';
    newHeader.value = '';
    newHeader.enabled = true;

    this.headers.push(newHeader);
    this.onChange(this.headers);
    this.rebuildFlatList();
  }

  /**
   * Delete header
   */
  private deleteHeader(index: number): void {
    this.headers.splice(index, 1);
    this.onChange(this.headers);
    this.rebuildFlatList();
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    return `hdr_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}
