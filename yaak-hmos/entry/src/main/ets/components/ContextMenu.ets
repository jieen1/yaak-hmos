/**
 * ContextMenu Component
 * Generic context menu for showing actions
 */

export interface ContextMenuItem {
  id: string;
  label: string;
  icon?: string;
  disabled?: boolean;
  danger?: boolean;
  separator?: boolean;
}

export interface MenuPosition {
  x: number;
  y: number;
}

@ComponentV2
export struct ContextMenu {
  @Param items: ContextMenuItem[] = [];
  @Param visible: boolean = false;
  @Param menuPosition: MenuPosition = { x: 0, y: 0 };
  @Param onItemSelect: (action: string) => void = () => {};

  build() {
    if (this.visible) {
      Column() {
        ForEach(this.items, (item: ContextMenuItem) => {
          if (item.separator) {
            Divider()
              .color($r('app.color.divider'))
              .margin({ top: 4, bottom: 4 });
          } else {
            Row() {
              if (item.icon) {
                Text(item.icon)
                  .fontSize(16)
                  .margin({ right: $r('app.float.spacing_sm') });
              }

              Text(item.label)
                .fontSize($r('app.float.font_size_sm'))
                .fontColor(item.danger ? $r('app.color.danger') : $r('app.color.text_primary'))
                .opacity(item.disabled ? 0.5 : 1.0);
            }
            .width('100%')
            .padding($r('app.float.spacing_md'))
            .onClick(() => {
              if (!item.disabled) {
                this.onItemSelect(item.id);
              }
            })
            .backgroundColor(Color.Transparent)
            .hoverEffect(HoverEffect.Highlight)
          }
        })
      }
      .position({ x: this.menuPosition.x, y: this.menuPosition.y })
      .backgroundColor($r('app.color.surface'))
      .borderRadius(8)
      .shadow({
        radius: 10,
        color: '#00000020',
        offsetX: 0,
        offsetY: 2
      })
      .padding({ top: 4, bottom: 4 })
      .zIndex(1000)
    }
  }
}
