/**
 * Folder Item Component
 * Displays a folder in the sidebar with expand/collapse functionality
 */

import { Folder } from '../model/Folder';

@ComponentV2
export struct FolderItemComponent {
  @Param folder: Folder = new Folder();
  @Param level: number = 0;
  @Param isExpanded: boolean = false;
  @Param onToggle: () => void = () => {};
  @Param onSelect: () => void = () => {};

  build() {
    Row() {
      // Indentation based on level
      Blank()
        .width(this.level * 16)

      // Expand/collapse icon
      Text(this.isExpanded ? '▼' : '▶')
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .width(20)
        .textAlign(TextAlign.Center)
        .onClick(() => {
          this.onToggle();
        })

      // Folder icon
      Text('📁')
        .fontSize($r('app.float.font_size_md'))
        .margin({ right: $r('app.float.spacing_sm') })

      // Folder name
      Text(this.folder.name)
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
    .backgroundColor($r('app.color.sidebar_background'))
    .borderRadius($r('app.float.border_radius_sm'))
    .onClick(() => {
      this.onSelect();
    })
    .onHover((isHover: boolean) => {
      // Could add hover effect here
    })
  }
}
