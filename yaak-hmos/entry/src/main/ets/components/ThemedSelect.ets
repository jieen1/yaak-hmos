/**
 * Themed Select Component
 * Reusable select/dropdown with theme support
 */

import { SymbolGlyphModifier } from '@kit.ArkUI';
import { FontSettings } from '../services/FontService';


export interface SelectOption {
  label: string;
  value: string;
}

@ComponentV2
export struct ThemedSelect {
  @Param options: SelectOption[] = [];
  @Param selectedValue: string = '';
  @Param placeholder: string = 'Select...';
  @Param onSelectChange: (value: string) => void = () => {};
  @Param disabled: boolean = false;
  @Param selectSize: 'sm' | 'md' | 'lg' = 'md';
  @Param selectWidth: Length = '';
  
  // 使用全局字体设置（响应式）
  @Local fontSettings: FontSettings = FontSettings.getInstance();

  build() {
    Select(this.buildSelectOptions())
      .selected(this.getSelectedIndex())
      .value(this.getSelectedLabel())
      .backgroundColor($r('app.color.input_background'))
      .fontColor($r('app.color.text_primary'))
      .font({ size: this.fontSettings.editorFontSize, family: this.fontSettings.editorFont })
      .height(this.getHeight())
      .borderRadius($r('app.float.border_radius_md'))
      .hoverEffect(HoverEffect.Highlight)
      .border({
        width: $r('app.float.border_width_thin'),
        color: $r('app.color.input_border')
      })
      .enabled(!this.disabled)
      .opacity(this.disabled ? $r('app.float.opacity_disabled') : 1)
      .onSelect((index: number) => {
        if (index >= 0 && index < this.options.length) {
          this.onSelectChange(this.options[index].value);
        }
      })
      .width(this.selectWidth)
      .arrowModifier(new SymbolGlyphModifier($r('sys.symbol.chevron_down')))
  }

  private buildSelectOptions(): SelectOption[] {
    const result: SelectOption[] = [];
    this.options.forEach((opt: SelectOption) => {
      const selectOpt: SelectOption = {
        label: opt.label,
        value: opt.label
      };
      result.push(selectOpt);
    });
    return result;
  }

  private getSelectedIndex(): number {
    return this.options.findIndex(opt => opt.value === this.selectedValue);
  }

  private getSelectedLabel(): string {
    const option = this.options.find(opt => opt.value === this.selectedValue);
    return option ? option.label : this.placeholder;
  }

  private getHeight(): Resource {
    switch (this.selectSize) {
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
