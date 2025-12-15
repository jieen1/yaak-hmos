import { ThemeColors, ThemeManager } from "../../theme/Theme";

@CustomDialog
@Component
export struct SettingsDialog {
  controller: CustomDialogController;
  
  // Use AppStorage/StorageLink for V1 compatibility as CustomDialog must be V1
  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  @StorageLink('isDark') isDark: boolean = ThemeManager.getInstance().isDark;
  
  // We can access singleton but it won't be reactive directly in V1 unless we use the stored props
  // So we use the method for actions
  
  build() {
    Column() {
      Text("Settings")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 20 })

      Row() {
        Text("Theme Mode")
          .fontSize(16)
          .fontColor(this.theme.text)
          .layoutWeight(1)
        
        // Manual Toggle
        Toggle({ type: ToggleType.Switch, isOn: this.isDark })
          .onChange((isOn: boolean) => {
             // We call singleton method which updates AppStorage, triggering UI update here
             ThemeManager.getInstance().toggleTheme();
          })
      }
      .width('100%')
      .padding({ top: 10, bottom: 10 })
      .border({ width: { bottom: 1 }, color: this.theme.border })

      Blank().height(20)

      Button("Close")
        .onClick(() => {
          this.controller.close();
        })
        .backgroundColor(this.theme.primary)
        .fontColor(Color.White)
    }
    .backgroundColor(this.theme.background)
    .padding(20)
    .borderRadius(10)
    .width('80%')
  }
}
