@ComponentV2
export struct ResponseViewerComponent {
  @Param @Require response: string;
  @Event $response: (val: string) => void;
  @Param @Require status: number;
  @Event $status: (val: number) => void;
  @Param time: number = 0;
  @Param bodySize: number = 0; // Renamed from size to avoid conflict

  @Local currentTabIndex: number = 0;

  getStatusColor(status: number): string {
    if (status >= 200 && status < 300) return '#0CBB52'; // Green
    if (status >= 300 && status < 400) return '#FFB400'; // Orange
    if (status >= 400 && status < 500) return '#EB2013'; // Red
    if (status >= 500) return '#EB2013'; // Red
    return '#808080';
  }

  build() {
    Column() {
      // 1. Status Bar
      if (this.status > 0) {
        Row() {
           Text(`${this.status} OK`) // Todo: Lookup status text
             .fontColor(this.getStatusColor(this.status))
             .fontWeight(FontWeight.Bold)
             .fontSize(14)
             .margin({ right: 15 })

           Text(`${this.time}ms`)
             .fontColor('#666666')
             .fontSize(12)
             .margin({ right: 10 })

           Text(`${(this.bodySize / 1024).toFixed(2)} KB`)
             .fontColor('#666666')
             .fontSize(12)
        }
        .width('100%')
        .padding(10)
        .backgroundColor('#f5f5f5')
        .border({ width: { bottom: 1 }, color: '#e0e0e0' })
      }

      // 2. Tabs
      Tabs({ index: this.currentTabIndex }) {
        TabContent() {
          TextArea({ text: this.response })
            .width('100%')
            .height('100%')
            .fontFamily('Monospace')
            .fontSize(13)
            .backgroundColor('#FAFAFA')
            .padding(10)
            .enabled(false) // Read-only
        }.tabBar("Preview")

        TabContent() {
           Column() {
             Text("Response Headers (TODO)").fontColor('#888888').margin(20)
           }
        }.tabBar("Headers")
      }
      .layoutWeight(1)
      .onChange((index: number) => {
        this.currentTabIndex = index;
      })
    }
    .width('100%')
    .height('100%')
    .border({ width: { left: 1 }, color: '#e0e0e0' })
  }
}
