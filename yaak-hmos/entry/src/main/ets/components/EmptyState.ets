/**
 * Empty State Component
 * Displayed when no request is selected
 */

import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct EmptyState {
  @Param onNewRequest: () => void = () => {};
  @Param onImport: () => void = () => {};

  build() {
    Column() {
      // Welcome Icon
      Text('📬')
        .fontSize($r('app.float.font_size_4xl'))
        .margin({ bottom: $r('app.float.spacing_lg') })

      // Welcome Message
      Text($r('app.string.welcome_to_flare'))
        .fontSize($r('app.float.font_size_2xl'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: $r('app.float.spacing_sm') })

      // Instructions
      Text($r('app.string.welcome_instruction'))
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .width('80%')
        .margin({ bottom: $r('app.float.spacing_2xl') })

      // Action Buttons
      Row() {
        ThemedButton({
          text: $r('app.string.new_request'),
          onButtonClick: () => {
            this.onNewRequest();
          },
          buttonType: 'primary',
          buttonSize: 'lg'
        })
          .margin({ right: $r('app.float.spacing_md') })

        ThemedButton({
          text: $r('app.string.import'),
          onButtonClick: () => {
            this.onImport();
          },
          buttonType: 'secondary',
          buttonSize: 'lg'
        })
      }
      .justifyContent(FlexAlign.Center)
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .backgroundColor($r('app.color.background'))
  }
}
