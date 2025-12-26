/**
 * Themed Text Input Component
 * Reusable text input with theme support
 */

import { FontSettings } from '../services/FontService';

@ComponentV2
export struct ThemedTextInput {
  @Param value: string = '';
  @Param placeholder: ResourceStr = '';
  @Param onValueChange: (value: string) => void = () => {};
  @Param inputType: InputType = InputType.Normal;
  @Param disabled: boolean = false;
  @Param inputSize: 'sm' | 'md' | 'lg' = 'md';
  @Param maxLength: number = -1;
  @Param inputPadding: Length = $r('app.float.spacing_md');

  // 使用全局字体设置（响应式）
  @Local fontSettings: FontSettings = FontSettings.getInstance();

  build() {
    TextInput({ text: this.value, placeholder: this.placeholder })
      .type(this.inputType)
      .backgroundColor($r('app.color.input_background'))
      .fontColor($r('app.color.text_primary'))
      .placeholderColor($r('app.color.text_secondary'))
      .fontSize(this.fontSettings.editorFontSize)
      .fontFamily(this.fontSettings.editorFont)
      .height(this.getHeight())
      .borderRadius($r('app.float.border_radius_md'))
      .hoverEffect(HoverEffect.Highlight)
      .border({
        width: $r('app.float.border_width_thin'),
        color: $r('app.color.input_border')
      })
      .padding({
        left: this.inputPadding,
        right: this.inputPadding
      })
      .enabled(!this.disabled)
      .opacity(this.disabled ? $r('app.float.opacity_disabled') : 1)
      .maxLength(this.maxLength)
      .onChange((value: string) => {
        this.onValueChange(value);
      })
      .onFocus(() => {
        // Could add focus styling here
      })
  }

  private getHeight(): Resource {
    switch (this.inputSize) {
      case 'sm':
        return $r('app.float.input_height_sm');
      case 'md':
        return $r('app.float.input_height_md');
      case 'lg':
        return $r('app.float.input_height_lg');
      default:
        return $r('app.float.input_height_md');
    }
  }
}
