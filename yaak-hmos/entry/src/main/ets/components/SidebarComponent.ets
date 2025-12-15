import { HttpRequest } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { SidebarItem } from '../viewmodel/SidebarItem';

@ComponentV2
export struct SidebarComponent {
  @Param @Require items: SidebarItem[];
  @Event $items: (val: SidebarItem[]) => void;
  @Param @Require selectedRequest: HttpRequest | null;
  @Event $selectedRequest: (val: HttpRequest | null) => void;
  
  // Callback for creating new request
  @Param onRequestCreate: () => void = () => {};
  @Param onFolderCreate: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text("Requests").fontSize(20).fontWeight(FontWeight.Bold)
        Blank()
        Button("F+")
          .onClick(() => {
            this.onFolderCreate();
          })
          .width(30)
          .height(30)
          .margin({ right: 5 })
          .backgroundColor('#cccccc')

        Button("R+")
          .onClick(() => {
            this.onRequestCreate();
          })
          .width(30)
          .height(30)
      }
      .width('100%')
      .padding(10)

      List() {
        ForEach(this.items, (item: SidebarItem) => {
          ListItem() {
            Row() {
              // Indentation
              if (item.level > 0) {
                 Blank().width(item.level * 15)
              }

              if (item.type === 'folder') {
                Text(item.expanded ? "▼" : "▶")
                  .fontSize(10)
                  .width(15)
                  .onClick(() => {
                    item.expanded = !item.expanded;
                  })
                Text(item.name).fontWeight(FontWeight.Bold).fontSize(14)
              } else {
                Text((item.data as HttpRequest).method)
                  .fontSize(10)
                  .fontColor(Color.Blue)
                  .width(35)
                  .margin({ left: 15 }) 
                Text(item.name).fontSize(14).layoutWeight(1)
              }
            }
            .width('100%')
            .padding({ top: 8, bottom: 8, left: 5, right: 5 })
            .backgroundColor(this.selectedRequest?.id === item.id ? '#e0e0e0' : Color.Transparent)
            .onClick(() => {
              if (item.type === 'request') {
                this.$selectedRequest(item.data as HttpRequest);
              } else {
                item.expanded = !item.expanded;
              }
            })
          }
        }, (item: SidebarItem) => item.id + item.expanded) 
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#f5f5f5')
  }
}
