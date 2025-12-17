import { HttpRequest } from '../model/HttpRequest';

@ComponentV2
export struct UrlBar {
  @Param @Require request: HttpRequest;
  @Event $request: (val: HttpRequest) => void; // Though we modify properties directly via ObservedV2
  @Param @Require onSend: () => void;
  @Param isLoading: boolean = false;

  getMethodColor(method: string): string {
    switch(method) {
      case 'GET': return '#0CBB52';
      case 'POST': return '#FFB400';
      case 'PUT': return '#097BED';
      case 'DELETE': return '#EB2013';
      case 'PATCH': return '#212121';
      default: return '#808080';
    }
  }

  build() {
    Row() {
      // Method Selector
      Select([
        { value: 'GET' },
        { value: 'POST' },
        { value: 'PUT' },
        { value: 'DELETE' },
        { value: 'PATCH' },
        { value: 'HEAD' },
        { value: 'OPTIONS' }
      ])
        .value(this.request.method)
        .selected(0) // Need logic to find index
        .font({ size: 14, weight: FontWeight.Bold })
        .fontColor(this.getMethodColor(this.request.method))
        .onSelect((index: number, value: string) => {
          this.request.method = value;
        })
        .width(90)
        .height(40)
        .backgroundColor('#f0f0f0')
        .borderRadius({ topLeft: 5, bottomLeft: 5 })

      // URL Input
      TextInput({ text: this.request.url, placeholder: 'https://api.example.com/v1/resource' })
        .layoutWeight(1)
        .height(40)
        .fontSize(14)
        .backgroundColor('#ffffff')
        .borderRadius(0)
        .padding({ left: 10, right: 10 })
        .border({ width: 1, color: '#e0e0e0' })
        .onChange((value: string) => {
          this.request.url = value;
        })

      // Send Button
      Button(this.isLoading ? "..." : "Send")
        .onClick(() => {
          if (!this.isLoading) this.onSend();
        })
        .width(80)
        .height(40)
        .backgroundColor(this.isLoading ? '#cccccc' : '#097BED')
        .borderRadius({ topRight: 5, bottomRight: 5 })
        .fontColor(Color.White)
        .fontSize(14)
    }
    .width('100%')
    .padding({ left: 10, right: 10, top: 10, bottom: 5 })
  }
}


