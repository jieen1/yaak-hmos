import { ThemeManager, ThemeColors } from '../../theme/Theme';

@ComponentV2
export struct PillButton {
  @Param text: string = '';
  @Param color: string = 'primary'; // primary, danger
  @Event action: () => void = () => {};
  
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  build() {
    Button(this.text)
      .fontSize(12)
      .height(24)
      .borderRadius(12) // Pill shape
      .backgroundColor(this.color === 'danger' ? this.theme.danger : this.theme.primary)
      .fontColor('#FFFFFF') // Always white text on colored buttons
      .onClick(() => {
        this.action();
      })
  }
}
