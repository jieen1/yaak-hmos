import { ThemeManager, ThemeColors } from '../../theme/Theme';

@ComponentV2
export struct IconButton {
  @Param icon: Resource = $r('sys.symbol.questionmark_circle'); 
  @Param iconSize: number = 20;
  @Param iconColor: ResourceColor | null = null; // Allow override
  @Param tooltip: string = '';
  @Event action: () => void = () => {};

  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  build() {
    Button({ type: ButtonType.Normal, stateEffect: true }) {
      SymbolGlyph(this.icon)
        .fontSize(this.iconSize)
        .fontColor([this.iconColor ?? this.theme.textSecondary])
    }
    .width(32)
    .height(32)
    .borderRadius(4)
    .backgroundColor(Color.Transparent)
    .onClick(() => {
      this.action();
    })
  }
}
