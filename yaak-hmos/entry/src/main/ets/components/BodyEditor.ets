/**
 * Body Editor Component
 * Edits request body with support for multiple content types
 */

import { BodyType } from '../model/Types';
import { ThemedSelect, SelectOption } from './ThemedSelect';

@ComponentV2
export struct BodyEditor {
  @Param body: string = '';
  @Param bodyType: BodyType = 'none';
  @Param onBodyChange: (body: string) => void = () => {};
  @Param onBodyTypeChange: (bodyType: BodyType) => void = () => {};

  private bodyTypeOptions: SelectOption[] = [
    { label: 'None', value: 'none' },
    { label: 'JSON', value: 'json' },
    { label: 'XML', value: 'xml' },
    { label: 'Form Data', value: 'form-data' },
    { label: 'Form URL Encoded', value: 'form-urlencoded' },
    { label: 'Binary', value: 'binary' },
    { label: 'GraphQL', value: 'graphql' },
    { label: 'Text', value: 'text' }
  ];

  build() {
    Column() {
      // Body type selector
      Row() {
        Text('请求体类型:')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .margin({ right: $r('app.float.spacing_md') })

        ThemedSelect({
          options: this.bodyTypeOptions,
          selectedValue: this.bodyType,
          onSelectChange: (value: string) => {
            this.onBodyTypeChange(value as BodyType);
          },
          selectSize: 'sm'
        })
          .width(200)
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Body editor based on type
      if (this.bodyType === 'none') {
        this.buildNoneEditor()
      } else if (this.bodyType === 'json') {
        this.buildJsonEditor()
      } else if (this.bodyType === 'xml') {
        this.buildXmlEditor()
      } else if (this.bodyType === 'text') {
        this.buildTextEditor()
      } else if (this.bodyType === 'graphql') {
        this.buildGraphQLEditor()
      } else if (this.bodyType === 'form-data') {
        this.buildFormDataEditor()
      } else if (this.bodyType === 'form-urlencoded') {
        this.buildFormUrlencodedEditor()
      } else if (this.bodyType === 'binary') {
        this.buildBinaryEditor()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildNoneEditor() {
    Column() {
      Text('没有请求体')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding($r('app.float.spacing_2xl'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildJsonEditor() {
    TextArea({ text: this.body, placeholder: '{\n  "key": "value"\n}' })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.code_background'))
      .fontColor($r('app.color.code_text'))
      .fontSize($r('app.float.font_size_md'))
      .fontFamily('monospace')
      .padding($r('app.float.spacing_md'))
      .onChange((value: string) => {
        this.onBodyChange(value);
      })
  }

  @Builder
  buildXmlEditor() {
    TextArea({ text: this.body, placeholder: '<?xml version="1.0"?>\n<root>\n  <item>value</item>\n</root>' })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.code_background'))
      .fontColor($r('app.color.code_text'))
      .fontSize($r('app.float.font_size_md'))
      .fontFamily('monospace')
      .padding($r('app.float.spacing_md'))
      .onChange((value: string) => {
        this.onBodyChange(value);
      })
  }

  @Builder
  buildTextEditor() {
    TextArea({ text: this.body, placeholder: '输入内容...' })
      .width('100%')
      .layoutWeight(1)
      .backgroundColor($r('app.color.input_background'))
      .fontColor($r('app.color.text_primary'))
      .fontSize($r('app.float.font_size_md'))
      .padding($r('app.float.spacing_md'))
      .onChange((value: string) => {
        this.onBodyChange(value);
      })
  }

  @Builder
  buildGraphQLEditor() {
    Column() {
      Text('GraphQL查询')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .padding({
          left: $r('app.float.spacing_md'),
          top: $r('app.float.spacing_sm')
        })

      TextArea({ text: this.body, placeholder: 'query {\n  user(id: 1) {\n    name\n    email\n  }\n}' })
        .width('100%')
        .height(200)
        .backgroundColor($r('app.color.code_background'))
        .fontColor($r('app.color.code_text'))
        .fontSize($r('app.float.font_size_md'))
        .fontFamily('monospace')
        .padding($r('app.float.spacing_md'))
        .onChange((value: string) => {
          this.onBodyChange(value);
        })
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildFormDataEditor() {
    Column() {
      Text('Form Data (Multipart)')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding($r('app.float.spacing_2xl'))

      Text('Form data editor will be implemented')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildFormUrlencodedEditor() {
    Column() {
      Text('Form URL Encoded')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding($r('app.float.spacing_2xl'))

      Text('Form urlencoded editor will be implemented')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildBinaryEditor() {
    Column() {
      Text('Binary File')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding($r('app.float.spacing_2xl'))

      Text('File picker will be implemented')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .layoutWeight(1)
  }
}
