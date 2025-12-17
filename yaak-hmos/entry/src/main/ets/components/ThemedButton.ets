/**
 * Themed Button Component
 * Reusable button with theme support
 */

@ComponentV2
export struct ThemedButton {
  @Param text: string = '';
  @Param onButtonClick: () => void = () => {};
  @Param buttonType: 'primary' | 'secondary' | 'danger' = 'primary';
  @Param disabled: boolean = false;
  @Param buttonSize: 'sm' | 'md' | 'lg' = 'md';

  build() {
    Button(this.text)
      .backgroundColor(this.getBackgroundColor())
      .fontColor($r('app.color.button_text'))
      .fontSize(this.getFontSize())
      .height(this.getHeight())
      .borderRadius($r('app.float.border_radius_md'))
      .opacity(this.disabled ? $r('app.float.opacity_disabled') : 1)
      .enabled(!this.disabled)
      .onClick(() => {
        if (!this.disabled) {
          this.onButtonClick();
        }
      })
  }

  private getBackgroundColor(): Resource {
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
      default:
        return $r('app.color.button_background');
    }
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
}
