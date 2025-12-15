import { IconButton } from '../core/IconButton';
import { ThemeManager, ThemeColors } from '../../theme/Theme';

@ComponentV2
export struct SettingsDropdown {
  @Event onOpenSettings: () => void = () => {};
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  
  @Builder
  SettingsMenu() {
    Menu() {
      // User requested icon: sys.symbol.barrage_setting
      MenuItem({ content: "Settings", startIcon: $r('sys.symbol.barrage_setting') })
        .onClick(() => { this.onOpenSettings() })
      
      MenuItem({ content: "Keyboard Shortcuts", startIcon: $r('sys.symbol.keyboard') })
      MenuItem({ content: "Plugins", startIcon: $r('sys.symbol.square_grid_2x2') })
      
      MenuItem({ content: "Import Data", startIcon: $r('sys.symbol.arrow_down_circle') })
      MenuItem({ content: "Export Data", startIcon: $r('sys.symbol.arrow_up_circle') })
      
      MenuItem({ content: "Purchase License", startIcon: $r('sys.symbol.checkmark_circle') })
        .foregroundColor(this.theme.success)
      
      MenuItem({ content: "Check for Updates", startIcon: $r('sys.symbol.arrow_clockwise') })
      MenuItem({ content: "Feedback", startIcon: $r('sys.symbol.message') })
      MenuItem({ content: "Changelog", startIcon: $r('sys.symbol.doc_text') })
    }
  }

  build() {
    Row() {
       IconButton({
        // User requested icon: sys.symbol.barrage_setting
        icon: $r('sys.symbol.barrage_setting'),
        tooltip: "Main Menu"
      })
      .bindMenu(this.SettingsMenu)
    }
  }
}
