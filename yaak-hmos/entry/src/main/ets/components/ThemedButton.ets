/**
 * Themed Button Component
 * Reusable button with theme support
 * Supports text, symbol icons, and circle shape
 */

@ComponentV2
export struct ThemedButton {
  @Param text: ResourceStr = '';
  @Param symbolIcon: Resource | null = null;
  @Param onButtonClick: () => void = () => {};
  @Param buttonType: 'primary' | 'secondary' | 'danger' | 'ghost' = 'primary';
  @Param disabled: boolean = false;
  @Param buttonSize: 'sm' | 'md' | 'lg' = 'md';
  @Param isCircle: boolean = false;

  build() {
    if (this.symbolIcon !== null) {
      // Symbol icon button
      Button({ type: this.isCircle ? ButtonType.Circle : ButtonType.Normal }) {
        SymbolGlyph(this.symbolIcon)
          .fontSize(this.getSymbolSize())
          .fontColor([this.getIconColor()])
      }
      .backgroundColor(this.getBackgroundColor())
      .width(this.isCircle ? this.getCircleSize() : this.getHeight())
      .height(this.isCircle ? this.getCircleSize() : this.getHeight())
      .borderRadius(this.isCircle ? '50%' : $r('app.float.border_radius_md'))
      .opacity(this.disabled ? $r('app.float.opacity_disabled') : 1)
      .enabled(!this.disabled)
      .hoverEffect(HoverEffect.Highlight)
      .onClick(() => {
        if (!this.disabled) {
          this.onButtonClick();
        }
      })
    } else {
      // Text button
      Button(this.text, { type: this.isCircle ? ButtonType.Circle : ButtonType.Normal })
        .backgroundColor(this.getBackgroundColor())
        .fontColor(this.getTextColor())
        .fontSize(this.getFontSize())
        .height(this.getHeight())
        .width(this.isCircle ? this.getCircleSize() : undefined)
        .borderRadius(this.isCircle ? '50%' : $r('app.float.border_radius_md'))
        .opacity(this.disabled ? $r('app.float.opacity_disabled') : 1)
        .enabled(!this.disabled)
        .onClick(() => {
          if (!this.disabled) {
            this.onButtonClick();
          }
        })
    }
  }

  private getBackgroundColor(): Resource | Color {
    if (this.disabled) {
      return $r('app.color.button_disabled');
    }

    switch (this.buttonType) {
      case 'primary':
        return $r('app.color.button_background');
      case 'secondary':
        return $r('app.color.secondary');
      case 'danger':
        return $r('app.color.danger');
      case 'ghost':
        return Color.Transparent;
      default:
        return $r('app.color.button_background');
    }
  }

  private getTextColor(): Resource {
    if (this.buttonType === 'ghost') {
      return $r('app.color.text_primary');
    }
    return $r('app.color.button_text');
  }

  private getIconColor(): Resource {
    if (this.buttonType === 'danger') {
      return $r('app.color.button_text');
    }
    return $r('app.color.text_primary');
  }

  private getFontSize(): Resource {
    switch (this.buttonSize) {
      case 'sm':
        return $r('app.float.font_size_sm');
      case 'md':
        return $r('app.float.font_size_md');
      case 'lg':
        return $r('app.float.font_size_lg');
      default:
        return $r('app.float.font_size_md');
    }
  }

  private getSymbolSize(): Resource {
    switch (this.buttonSize) {
      case 'sm':
        return $r('app.float.font_size_lg');
      case 'md':
        return $r('app.float.font_size_xl');
      case 'lg':
        return $r('app.float.font_size_2xl');
      default:
        return $r('app.float.font_size_xl');
    }
  }

  private getHeight(): Resource {
    switch (this.buttonSize) {
      case 'sm':
        return $r('app.float.button_height_sm');
      case 'md':
        return $r('app.float.button_height_md');
      case 'lg':
        return $r('app.float.button_height_lg');
      default:
        return $r('app.float.button_height_md');
    }
  }

  private getCircleSize(): Resource {
    switch (this.buttonSize) {
      case 'sm':
        return $r('app.float.button_height_sm');
      case 'md':
        return $r('app.float.button_height_md');
      case 'lg':
        return $r('app.float.button_height_lg');
      default:
        return $r('app.float.button_height_md');
    }
  }
}
