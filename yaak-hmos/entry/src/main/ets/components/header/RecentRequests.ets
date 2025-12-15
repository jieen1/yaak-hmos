import { ThemeManager, ThemeColors } from '../../theme/Theme';

@ComponentV2
export struct RecentRequests {
  @Local searchText: string = "";
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  build() {
    Row() {
      // Simplified Search / Recent Requests Dropdown
      TextInput({ placeholder: "Search or Jump to..." })
        .height(30)
        .backgroundColor(this.theme.inputBackground) 
        .fontColor(this.theme.text)
        .placeholderColor(this.theme.textSecondary)
        .borderRadius(4)
        .padding({ left: 30, right: 10 })
        .onChange((value: string) => {
          this.searchText = value;
        })
      
      // Search Icon Overlay
      SymbolGlyph($r('sys.symbol.magnifyingglass'))
        .fontSize(14)
        .fontColor([this.theme.textSecondary])
        .position({ x: 8, y: 8 })
        .hitTestBehavior(HitTestMode.None)
    }
    .width(300) // Fixed width or relative
    .height(30)
  }
}
