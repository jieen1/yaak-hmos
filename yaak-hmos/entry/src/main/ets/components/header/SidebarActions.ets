import { IconButton } from '../core/IconButton';

@ComponentV2
export struct SidebarActions {
  @Param sidebarHidden: boolean = false;
  @Event onToggle: () => void = () => {};

  build() {
    Row() {
      IconButton({
        // User requested icons
        icon: this.sidebarHidden ? $r('sys.symbol.open_sidebar') : $r('sys.symbol.close_sidebar'),
        tooltip: "Toggle sidebar",
        action: () => {
          this.onToggle();
        }
      })

      IconButton({
        icon: $r('sys.symbol.plus_circle'),
        tooltip: "Add Resource",
        action: () => {
          // TODO: Open Create Menu
        }
      })
    }
    .height('100%')
  }
}
