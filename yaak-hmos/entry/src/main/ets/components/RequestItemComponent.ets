/**
 * Request Item Component
 * Displays an HTTP request in the sidebar with method badge
 */

import { HttpRequest } from '../model/HttpRequest';
import { HttpMethod } from '../model/Types';

@ComponentV2
export struct RequestItemComponent {
  @Param request: HttpRequest = new HttpRequest();
  @Param level: number = 0;
  @Param isSelected: boolean = false;
  @Param onSelect: () => void = () => {};

  build() {
    Row() {
      // Indentation based on level
      Blank()
        .width(this.level * 16)

      // Spacing for alignment with folders (no expand icon)
      Blank()
        .width(20)

      // HTTP method badge
      Text(this.request.method)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.button_text'))
        .backgroundColor(this.getMethodColor())
        .padding({
          left: $r('app.float.spacing_xs'),
          right: $r('app.float.spacing_xs'),
          top: 2,
          bottom: 2
        })
        .borderRadius($r('app.float.border_radius_sm'))
        .margin({ right: $r('app.float.spacing_sm') })
        .fontWeight(FontWeight.Bold)

      // Request name
      Text(this.request.name)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
        .flexGrow(1)
        .maxLines(1)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width('100%')
    .height($r('app.float.list_item_height'))
    .padding({
      left: $r('app.float.spacing_sm'),
      right: $r('app.float.spacing_sm')
    })
    .backgroundColor(this.isSelected ? $r('app.color.sidebar_item_selected') : $r('app.color.sidebar_background'))
    .borderRadius($r('app.float.border_radius_sm'))
    .onClick(() => {
      this.onSelect();
    })
    .onHover((isHover: boolean) => {
      // Could add hover effect here
    })
  }

  /**
   * Get color for HTTP method badge
   */
  private getMethodColor(): Resource {
    switch (this.request.method.toUpperCase()) {
      case 'GET':
        return $r('app.color.method_get');
      case 'POST':
        return $r('app.color.method_post');
      case 'PUT':
        return $r('app.color.method_put');
      case 'DELETE':
        return $r('app.color.method_delete');
      case 'PATCH':
        return $r('app.color.method_patch');
      case 'HEAD':
        return $r('app.color.method_head');
      case 'OPTIONS':
        return $r('app.color.method_options');
      default:
        return $r('app.color.secondary');
    }
  }
}
