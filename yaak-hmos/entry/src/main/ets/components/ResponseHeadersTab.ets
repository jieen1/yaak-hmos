import { ResponseHeader } from '../model';

@ComponentV2
export struct ResponseHeadersTab {
  @Param headers: ResponseHeader[] = [];

  // Helper methods to filter headers (non-UI logic)
  private getSetCookieHeaders(): ResponseHeader[] {
    const result: ResponseHeader[] = [];
    this.headers.forEach((h: ResponseHeader) => {
      if (h.name?.toLowerCase() === 'set-cookie') {
        result.push(h);
      }
    });
    return result;
  }

  private getRegularHeaders(): ResponseHeader[] {
    const result: ResponseHeader[] = [];
    this.headers.forEach((h: ResponseHeader) => {
      if (h.name?.toLowerCase() !== 'set-cookie') {
        result.push(h);
      }
    });
    return result;
  }

  build() {
    Column() {
      if (this.headers.length === 0) {
        this.buildEmptyState();
      } else {
        this.buildHeadersList();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildEmptyState() {
    Column() {
      Text('No headers')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildHeadersList() {
    Scroll() {
      Column() {
        // Separate Set-Cookie headers
        this.buildSetCookieHeaders();

        // Regular headers
        this.buildRegularHeaders();
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildSetCookieHeaders() {
    Column() {
      Text('Set-Cookie Headers')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: $r('app.float.spacing_sm') })
        .visibility(this.getSetCookieHeaders().length > 0 ? Visibility.Visible : Visibility.None)

      ForEach(this.getSetCookieHeaders(), (header: ResponseHeader, index: number) => {
        this.buildHeaderItem(header, index);
      }, (header: ResponseHeader, index: number) => `set-cookie-${index}`)

      // Divider
      Row()
        .width('100%')
        .height(1)
        .backgroundColor($r('app.color.divider'))
        .margin({
          top: $r('app.float.spacing_md'),
          bottom: $r('app.float.spacing_md')
        })
        .visibility(this.getSetCookieHeaders().length > 0 ? Visibility.Visible : Visibility.None)
    }
    .width('100%')
  }

  @Builder
  buildRegularHeaders() {
    Column() {
      Text('Response Headers')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: $r('app.float.spacing_sm') })
        .visibility(this.getRegularHeaders().length > 0 ? Visibility.Visible : Visibility.None)

      ForEach(this.getRegularHeaders(), (header: ResponseHeader, index: number) => {
        this.buildHeaderItem(header, index);
      }, (header: ResponseHeader, index: number) => `header-${index}`)
    }
    .width('100%')
  }

  @Builder
  buildHeaderItem(header: ResponseHeader, index: number) {
    Column() {
      Row() {
        // Header Name
        Text(header.name)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)
          .width('30%')

        // Header Value
        Text(header.value)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .layoutWeight(1)
          .maxLines(3)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ left: $r('app.float.spacing_md') })
      }
      .width('100%')
      .padding($r('app.float.spacing_sm'))
      .backgroundColor(index % 2 === 0 ? $r('app.color.surface') : Color.Transparent)
      .borderRadius($r('app.float.border_radius_sm'))
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_xs') })
  }
}
