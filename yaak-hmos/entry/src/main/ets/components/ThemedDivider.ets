/**
 * Themed Divider Component
 * Reusable divider with theme support
 */

@ComponentV2
export struct ThemedDivider {
  @Param vertical: boolean = false;
  @Param thickness: number = 1;
  @Param color?: Resource = undefined;

  build() {
    Divider()
      .vertical(this.vertical)
      .strokeWidth(this.thickness)
      .color(this.color || $r('app.color.divider'))
      .margin(this.vertical ? {
        left: $r('app.float.spacing_sm'),
        right: $r('app.float.spacing_sm')
      } : {
        top: $r('app.float.spacing_sm'),
        bottom: $r('app.float.spacing_sm')
      })
  }
}
