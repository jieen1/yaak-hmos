import { ThemeManager, ThemeColors } from '../../theme/Theme';
import { CookieManagerDialog } from '../dialogs/CookieManagerDialog';

@ComponentV2
export struct CookieDropdown {
  @Local theme: ThemeColors = ThemeManager.getInstance().currentTheme;

  dialogController: CustomDialogController = new CustomDialogController({
    builder: CookieManagerDialog(),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  @Builder
  CookieMenu() {
    Menu() {
      MenuItem({ content: "Jar 1 (Default)" })
      
      MenuItem({ 
        content: "Manage Cookies",
        startIcon: $r('sys.symbol.square_grid_2x2') // Using a generic icon available
      })
      .onClick(() => {
        this.dialogController.open();
      })
    }
  }

  build() {
    Button("Cookies") 
      .fontSize(14)
      .fontColor(this.theme.textSecondary)
      .backgroundColor(Color.Transparent)
      .height(30)
      .bindMenu(this.CookieMenu)
  }
}
