/**
 * Headers Editor Component
 * Edits HTTP headers for requests
 */

import { HttpHeader } from '../model/HttpRequest';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct HeadersEditor {
  @Param headers: HttpHeader[] = [];
  @Param onChange: (headers: HttpHeader[]) => void = () => {};

  build() {
    Column() {
      // Header
      Row() {
        Text('Headers')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .flexGrow(1)

        ThemedButton({
          text: 'Add',
          onButtonClick: () => {
            this.addHeader();
          },
          buttonSize: 'sm'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Headers list
      if (this.headers.length === 0) {
        Text('No headers')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      } else {
        List() {
          ForEach(this.headers, (header: HttpHeader, index: number) => {
            ListItem() {
              this.buildHeaderRow(header, index)
            }
          }, (header: HttpHeader) => header.id)
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
  buildHeaderRow(header: HttpHeader, index: number) {
    Row() {
      // Enabled checkbox
      Checkbox()
        .select(header.enabled)
        .onChange((value: boolean) => {
          header.enabled = value;
          this.onChange(this.headers);
        })
        .margin({ right: $r('app.float.spacing_sm') })

      // Name input
      ThemedTextInput({
        value: header.name,
        placeholder: 'Header Name',
        onValueChange: (value: string) => {
          header.name = value;
          this.onChange(this.headers);
        },
        inputSize: 'sm'
      })
        .flexGrow(1)
        .margin({ right: $r('app.float.spacing_sm') })

      // Value input
      ThemedTextInput({
        value: header.value,
        placeholder: 'Header Value',
        onValueChange: (value: string) => {
          header.value = value;
          this.onChange(this.headers);
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
          this.deleteHeader(index);
        })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .alignItems(VerticalAlign.Center)
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
  }

  /**
   * Delete header
   */
  private deleteHeader(index: number): void {
    this.headers.splice(index, 1);
    this.onChange(this.headers);
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    return `hdr_${Date.now()}_${Math.floor(Math.random() * 10000)}`;
  }
}
