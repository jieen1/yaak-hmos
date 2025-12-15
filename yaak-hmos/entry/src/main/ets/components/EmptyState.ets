import { ThemeColors, ThemeManager } from "../theme/Theme";

@ComponentV2
export struct EmptyState {
  @Event onNewRequest: () => void = () => {};
  @Event onImport: () => void = () => {};
  
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  build() {
    Column() {
      SymbolGlyph($r('sys.symbol.square_grid_2x2')) // Placeholder icon
        .fontSize(60)
        .fontColor([this.theme.textSecondary])
        .margin({ bottom: 20 })

      Text("No Request Selected")
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 10 })
        
      Text("Create a new request or import data to get started.")
        .fontSize(14)
        .fontColor(this.theme.textSecondary)
        .margin({ bottom: 30 })

      Row({ space: 15 }) {
        Button("New Request")
          .onClick(() => {
            this.onNewRequest();
          })
          .backgroundColor(this.theme.primary)
          .fontColor(Color.White)
          .height(40)
          
        Button("Import Data")
          .onClick(() => {
            this.onImport();
          })
          .backgroundColor(Color.Transparent)
          .fontColor(this.theme.text)
          .border({ width: 1, color: this.theme.border, radius: 20 }) // Pill shape-ish
          .height(40)
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.theme.background)
  }
}

