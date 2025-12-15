import { HttpRequest } from '../model/HttpRequest';
import { KeyValueTable } from './KeyValueTable';
import { UrlBar } from './UrlBar';

@ComponentV2
export struct RequestEditorComponent {
  @Param @Require request: HttpRequest | null;
  @Event $request: (val: HttpRequest | null) => void;
  @Param @Require onExecute: () => void;
  @Param isLoading: boolean = false;

  @Local currentTabIndex: number = 0;

  build() {
    Column() {
      if (this.request) {
        // 1. URL Bar
        UrlBar({
          request: this.request,
          onSend: this.onExecute,
          isLoading: this.isLoading
        })

        // 2. Tabs
        Tabs({ index: this.currentTabIndex }) {
          TabContent() {
             KeyValueTable({ 
               data: this.request.params, 
               $data: (val: string) => { if (this.request) this.request.params = val; },
               placeholderKey: "Key",
               placeholderValue: "Value"
             })
          }.tabBar("Params")
          
          TabContent() {
             Column() {
               Text("Auth configuration coming soon...").fontColor('#888888').margin(20)
             }
          }.tabBar("Auth")

          TabContent() {
             KeyValueTable({ 
               data: this.request.headers, 
               $data: (val: string) => { if (this.request) this.request.headers = val; },
               placeholderKey: "Header",
               placeholderValue: "Value"
             })
          }.tabBar("Headers")

          TabContent() {
            TextArea({ text: this.request.body || '', placeholder: 'Request Body (JSON, Text, etc.)' })
              .width('100%')
              .height('100%')
              .fontFamily('Monospace')
              .fontSize(14)
              .backgroundColor('#FAFAFA')
              .padding(10)
              .onChange((value: string) => {
                if (this.request) this.request.body = value;
              })
          }.tabBar("Body")
        }
        .barMode(BarMode.Fixed)
        .layoutWeight(1)
        .onChange((index: number) => {
          this.currentTabIndex = index;
        })
      } else {
        Column() {
          Text("Select a request to start").fontSize(16).fontColor('#888888')
        }.justifyContent(FlexAlign.Center).height('100%')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor(Color.White)
  }
}
