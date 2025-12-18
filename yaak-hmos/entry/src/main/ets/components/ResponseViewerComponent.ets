import { HttpResponse } from '../model';
import { ResponseHeadersTab } from './ResponseHeadersTab';
import { ResponseInfoTab } from './ResponseInfoTab';

@ComponentV2
export struct ResponseViewerComponent {
  @Param response: HttpResponse | null = null;
  @Param responseBody: string = '';
  @Param isLoading: boolean = false;

  @Local activeTab: string = 'body';
  @Local viewMode: string = 'pretty'; // 'pretty' or 'raw'

  build() {
    Column() {
      if (this.isLoading) {
        this.buildLoadingState();
      } else if (!this.response) {
        this.buildEmptyState();
      } else {
        this.buildResponseContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildLoadingState() {
    Column() {
      LoadingProgress()
        .width(48)
        .height(48)
        .color($r('app.color.primary'))

      Text('Loading response...')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: $r('app.float.spacing_md') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      Text('No response yet')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_secondary'))

      Text('Send a request to see the response')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: $r('app.float.spacing_sm') })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildResponseContent() {
    Column() {
      // Status Bar
      this.buildStatusBar();

      // Tabs
      this.buildTabs();

      // Tab Content
      this.buildTabContent();
    }
    .width('100%')
    .height('100%')
  }

  @Builder
  buildStatusBar() {
    Row() {
      // Status Code
      Text(`${this.response?.status_code || 0}`)
        .fontSize($r('app.float.font_size_md'))
        .fontColor(this.getStatusColor())
        .fontWeight(FontWeight.Bold)

      Text(this.response?.status_text || '')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor(this.getStatusColor())
        .margin({ left: $r('app.float.spacing_xs') })

      // Time
      Text(`${this.response?.elapsed_time || 0}ms`)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ left: $r('app.float.spacing_lg') })

      // Size
      Text(this.formatSize(this.response?.size || 0))
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ left: $r('app.float.spacing_md') })
    }
    .width('100%')
    .height(48)
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md')
    })
    .backgroundColor($r('app.color.surface'))
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }

  @Builder
  buildTabs() {
    Row() {
      // Body Tab
      Button('Body')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor(this.activeTab === 'body' ? $r('app.color.tab_active') : $r('app.color.tab_inactive'))
        .backgroundColor(Color.Transparent)
        .border({
          width: { bottom: this.activeTab === 'body' ? 2 : 0 },
          color: $r('app.color.tab_active')
        })
        .onClick(() => {
          this.activeTab = 'body';
        })

      // Headers Tab
      Button('Headers')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor(this.activeTab === 'headers' ? $r('app.color.tab_active') : $r('app.color.tab_inactive'))
        .backgroundColor(Color.Transparent)
        .border({
          width: { bottom: this.activeTab === 'headers' ? 2 : 0 },
          color: $r('app.color.tab_active')
        })
        .margin({ left: $r('app.float.spacing_md') })
        .onClick(() => {
          this.activeTab = 'headers';
        })

      // Info Tab
      Button('Info')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor(this.activeTab === 'info' ? $r('app.color.tab_active') : $r('app.color.tab_inactive'))
        .backgroundColor(Color.Transparent)
        .border({
          width: { bottom: this.activeTab === 'info' ? 2 : 0 },
          color: $r('app.color.tab_active')
        })
        .margin({ left: $r('app.float.spacing_md') })
        .onClick(() => {
          this.activeTab = 'info';
        })
    }
    .width('100%')
    .height(40)
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md')
    })
    .backgroundColor($r('app.color.surface'))
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }

  @Builder
  buildTabContent() {
    if (this.activeTab === 'body') {
      this.buildBodyTab();
    } else if (this.activeTab === 'headers') {
      ResponseHeadersTab({ headers: this.response?.headers || [] });
    } else if (this.activeTab === 'info') {
      ResponseInfoTab({ response: this.response });
    }
  }

  @Builder
  buildBodyTab() {
    Column() {
      // View Mode Toggle
      Row() {
        Button('Pretty')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor(this.viewMode === 'pretty' ? $r('app.color.button_text') : $r('app.color.text_primary'))
          .backgroundColor(this.viewMode === 'pretty' ? $r('app.color.primary') : $r('app.color.surface_highlight'))
          .height(32)
          .onClick(() => {
            this.viewMode = 'pretty';
          })

        Button('Raw')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor(this.viewMode === 'raw' ? $r('app.color.button_text') : $r('app.color.text_primary'))
          .backgroundColor(this.viewMode === 'raw' ? $r('app.color.primary') : $r('app.color.surface_highlight'))
          .height(32)
          .margin({ left: $r('app.float.spacing_sm') })
          .onClick(() => {
            this.viewMode = 'raw';
          })
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
      .backgroundColor($r('app.color.surface'))

      // Response Body
      Scroll() {
        Text(this.formatResponse())
          .fontFamily('monospace')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .width('100%')
          .padding($r('app.float.spacing_md'))
      }
      .layoutWeight(1)
      .width('100%')
      .backgroundColor($r('app.color.background'))
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .layoutWeight(1)
  }

  private getStatusColor(): ResourceStr {
    const status = this.response?.status_code || 0;
    if (status >= 200 && status < 300) {
      return $r('app.color.success');
    } else if (status >= 400) {
      return $r('app.color.danger');
    } else if (status >= 300 && status < 400) {
      return $r('app.color.warning');
    }
    return $r('app.color.text_primary');
  }

  private formatResponse(): string {
    if (!this.responseBody) {
      return 'No response body';
    }

    if (this.viewMode === 'raw') {
      return this.responseBody;
    }

    // Try to format as JSON
    try {
      const parsed: ESObject = JSON.parse(this.responseBody) as ESObject;
      return JSON.stringify(parsed, null, 2);
    } catch {
      // Not JSON, return as-is
      return this.responseBody;
    }
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    }
  }
}
