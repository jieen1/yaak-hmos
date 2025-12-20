import { HttpResponse, ResponseHeader } from '../model';
import { ResponseHeadersTab } from './ResponseHeadersTab';
import { ResponseInfoTab } from './ResponseInfoTab';
import { ContentTypeDetector, ContentTypeInfo } from '../services/ContentTypeDetector';
import { PreferencesService, PreferenceKeys } from '../services/PreferencesService';
import { TextViewer } from './TextViewer';
import { ImageViewer } from './ImageViewer';
import { VideoViewer, AudioViewer } from './MediaViewer';
import promptAction from '@ohos.promptAction';

@ComponentV2
export struct ResponseViewerComponent {
  @Param response: HttpResponse | null = null;
  @Param responseBody: string = '';
  @Param isLoading: boolean = false;
  @Param responseHistory: HttpResponse[] = [];
  @Param onSelectResponse: (response: HttpResponse) => void = () => {};
  @Param onClearHistory: () => void = () => {};

  @Local activeTab: string = 'body';
  @Local viewMode: string = 'pretty'; // 'pretty' or 'raw'
  @Local contentTypeInfo: ContentTypeInfo | null = null;
  @Local showHistory: boolean = false;
  @Local showLargeResponseConfirmed: boolean = false; // Large response confirmation state
  
  // Large response threshold: 1MB
  private static readonly LARGE_RESPONSE_THRESHOLD: number = 1024 * 1024;
  
  private preferencesService: PreferencesService = PreferencesService.getInstance();

  async aboutToAppear(): Promise<void> {
    await this.loadPreferences();
    this.detectContentType();
  }

  /**
   * Reset large response confirmation when response changes
   */
  @Monitor('response', 'responseBody')
  onResponseChange(): void {
    this.showLargeResponseConfirmed = false;
    this.detectContentType();
  }

  async loadPreferences(): Promise<void> {
    if (!this.response) return;

    try {
      // Load view mode preference
      const viewModeKey: string = PreferenceKeys.getViewModeKey(this.response.request_id);
      this.viewMode = await this.preferencesService.getString(viewModeKey, 'pretty');

      // Load active tab preference
      const activeTabKey: string = PreferenceKeys.getActiveTabKey(this.response.request_id);
      this.activeTab = await this.preferencesService.getString(activeTabKey, 'body');

      console.info('[ResponseViewer] Loaded preferences:', {
        viewMode: this.viewMode,
        activeTab: this.activeTab
      });
    } catch (error) {
      console.error('[ResponseViewer] Failed to load preferences:', JSON.stringify(error));
    }
  }

  detectContentType(): void {
    if (!this.response) return;

    // Get Content-Type header
    const headers: ResponseHeader[] = this.response.headers || [];
    const contentTypeHeader: ResponseHeader | undefined = headers.find(
      (h: ResponseHeader) => h.name.toLowerCase() === 'content-type'
    );

    const contentTypeValue: string | null = contentTypeHeader ? contentTypeHeader.value : null;
    
    // Detect content type
    this.contentTypeInfo = ContentTypeDetector.detect(contentTypeValue, this.responseBody);
    
    console.info('[ResponseViewer] Content type detected:', {
      category: this.contentTypeInfo.category,
      language: this.contentTypeInfo.language,
      mimeType: this.contentTypeInfo.mimeType,
      canFormat: this.contentTypeInfo.canFormat
    });
  }

  async savePreferences(): Promise<void> {
    if (!this.response) return;

    try {
      // Save view mode
      const viewModeKey: string = PreferenceKeys.getViewModeKey(this.response.request_id);
      await this.preferencesService.setString(viewModeKey, this.viewMode);

      // Save active tab
      const activeTabKey: string = PreferenceKeys.getActiveTabKey(this.response.request_id);
      await this.preferencesService.setString(activeTabKey, this.activeTab);

      console.info('[ResponseViewer] Saved preferences');
    } catch (error) {
      console.error('[ResponseViewer] Failed to save preferences:', JSON.stringify(error));
    }
  }

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

      // History Panel (collapsible)
      if (this.showHistory && this.responseHistory.length > 0) {
        this.buildHistoryPanel();
      }

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

      Blank()

      // History toggle button
      if (this.responseHistory.length > 0) {
        Button(this.showHistory ? '▲ History' : '▼ History')
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor(Color.Transparent)
          .height(28)
          .onClick(() => {
            this.showHistory = !this.showHistory;
          })
      }
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
  buildHistoryPanel() {
    Column() {
      // History header
      Row() {
        Text('Response History')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Medium)

        Blank()

        Button('Clear')
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.danger'))
          .backgroundColor(Color.Transparent)
          .height(24)
          .onClick(() => {
            this.showClearHistoryConfirmation();
          })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_md'),
        right: $r('app.float.spacing_md'),
        top: $r('app.float.spacing_sm'),
        bottom: $r('app.float.spacing_sm')
      })

      // History list
      List() {
        ForEach(this.responseHistory, (historyResponse: HttpResponse) => {
          ListItem() {
            this.buildHistoryItem(historyResponse)
          }
        }, (historyResponse: HttpResponse) => historyResponse.id)
      }
      .width('100%')
      .height(150)
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .backgroundColor($r('app.color.surface_highlight'))
    .border({
      width: { bottom: 1 },
      color: $r('app.color.divider')
    })
  }

  @Builder
  buildHistoryItem(historyResponse: HttpResponse) {
    Row() {
      // Status indicator
      Text(`${historyResponse.status_code}`)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor(this.getStatusColorForCode(historyResponse.status_code))
        .fontWeight(FontWeight.Bold)
        .width(40)

      // Timestamp
      Text(this.formatTimestamp(historyResponse.created_at))
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .flexGrow(1)

      // Duration
      Text(`${historyResponse.elapsed_time}ms`)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ right: $r('app.float.spacing_sm') })

      // Size
      Text(this.formatSize(historyResponse.size))
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))

      // Selected indicator
      if (this.response?.id === historyResponse.id) {
        Text('●')
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.primary'))
          .margin({ left: $r('app.float.spacing_sm') })
      }
    }
    .width('100%')
    .height(36)
    .padding({
      left: $r('app.float.spacing_md'),
      right: $r('app.float.spacing_md')
    })
    .backgroundColor(this.response?.id === historyResponse.id ? 
      $r('app.color.sidebar_item_selected') : Color.Transparent)
    .onClick(() => {
      this.onSelectResponse(historyResponse);
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
          this.savePreferences();
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
          this.savePreferences();
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
          this.savePreferences();
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
      // View Mode Toggle (only show for text content that can be formatted)
      if (this.contentTypeInfo && 
          this.contentTypeInfo.category === 'text' && 
          this.contentTypeInfo.canFormat) {
        Row() {
          Button('Pretty')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor(this.viewMode === 'pretty' ? $r('app.color.button_text') : $r('app.color.text_primary'))
            .backgroundColor(this.viewMode === 'pretty' ? $r('app.color.primary') : $r('app.color.surface_highlight'))
            .height(32)
            .onClick(() => {
              this.viewMode = 'pretty';
              this.savePreferences();
            })

          Button('Raw')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor(this.viewMode === 'raw' ? $r('app.color.button_text') : $r('app.color.text_primary'))
            .backgroundColor(this.viewMode === 'raw' ? $r('app.color.primary') : $r('app.color.surface_highlight'))
            .height(32)
            .margin({ left: $r('app.float.spacing_sm') })
            .onClick(() => {
              this.viewMode = 'raw';
              this.savePreferences();
            })
        }
        .width('100%')
        .padding($r('app.float.spacing_md'))
        .backgroundColor($r('app.color.surface'))
      }

      // Content viewer based on content type
      this.buildContentViewer();
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildContentViewer() {
    // Check for large response that needs confirmation
    if (this.isLargeResponse() && !this.showLargeResponseConfirmed) {
      Column() {
        Text('⚠️ Large Response')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.warning'))
          .fontWeight(FontWeight.Bold)
          .margin({ bottom: $r('app.float.spacing_md') })

        Text(`Response size: ${this.formatSize(this.responseBody.length)}`)
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: $r('app.float.spacing_sm') })

        Text('Large responses may affect performance.')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: $r('app.float.spacing_lg') })

        Row() {
          Button('Show Response')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.button_text'))
            .backgroundColor($r('app.color.primary'))
            .height(40)
            .onClick(() => {
              this.showLargeResponseConfirmed = true;
            })

          Button('Cancel')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_primary'))
            .backgroundColor($r('app.color.surface_highlight'))
            .height(40)
            .margin({ left: $r('app.float.spacing_md') })
            .onClick(() => {
              // Stay on confirmation screen
            })
        }
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (!this.contentTypeInfo) {
      Column() {
        Text('No content to display')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    } else if (this.contentTypeInfo.category === 'text') {
      Column() {
        TextViewer({
          text: this.responseBody,
          language: this.getTextLanguage(),
          pretty: this.viewMode === 'pretty'
        })
      }
      .width('100%')
      .layoutWeight(1)
    } else if (this.contentTypeInfo.category === 'image') {
      Column() {
        ImageViewer({
          imagePath: this.response?.body_path || ''
        })
      }
      .width('100%')
      .layoutWeight(1)
    } else if (this.contentTypeInfo.category === 'video') {
      Column() {
        VideoViewer({
          videoPath: this.response?.body_path || ''
        })
      }
      .width('100%')
      .layoutWeight(1)
    } else if (this.contentTypeInfo.category === 'audio') {
      Column() {
        AudioViewer({
          audioPath: this.response?.body_path || ''
        })
      }
      .width('100%')
      .layoutWeight(1)
    } else {
      Column() {
        Text('Unsupported content type')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .margin({ bottom: $r('app.float.spacing_sm') })

        Text(this.contentTypeInfo?.mimeType || 'Unknown')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
  }

  /**
   * Check if response is larger than threshold
   */
  private isLargeResponse(): boolean {
    return this.responseBody.length > ResponseViewerComponent.LARGE_RESPONSE_THRESHOLD;
  }

  private getTextLanguage(): 'json' | 'xml' | 'html' | 'text' {
    if (!this.contentTypeInfo) {
      return 'text';
    }
    
    if (this.contentTypeInfo.language === 'none' || 
        this.contentTypeInfo.language === 'css' ||
        this.contentTypeInfo.language === 'javascript') {
      return 'text';
    }
    
    return this.contentTypeInfo.language;
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

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    }
  }

  private getStatusColorForCode(statusCode: number): ResourceStr {
    if (statusCode >= 200 && statusCode < 300) {
      return $r('app.color.success');
    } else if (statusCode >= 400) {
      return $r('app.color.danger');
    } else if (statusCode >= 300 && statusCode < 400) {
      return $r('app.color.warning');
    }
    return $r('app.color.text_primary');
  }

  private formatTimestamp(timestamp: number): string {
    const date: Date = new Date(timestamp);
    const hours: string = date.getHours().toString().padStart(2, '0');
    const minutes: string = date.getMinutes().toString().padStart(2, '0');
    const seconds: string = date.getSeconds().toString().padStart(2, '0');
    const month: string = (date.getMonth() + 1).toString().padStart(2, '0');
    const day: string = date.getDate().toString().padStart(2, '0');
    return `${month}/${day} ${hours}:${minutes}:${seconds}`;
  }

  private showClearHistoryConfirmation(): void {
    try {
      promptAction.showDialog({
        title: 'Clear History',
        message: 'Are you sure you want to clear all response history for this request?',
        buttons: [
          { text: 'Cancel', color: '#000000' },
          { text: 'Clear', color: '#ff4d4f' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.onClearHistory();
          this.showHistory = false;
          this.showToast('History cleared');
        }
      }).catch((error: Error) => {
        console.error('[ResponseViewer] Clear history confirmation error:', error);
      });
    } catch (error) {
      console.error('[ResponseViewer] Failed to show clear history confirmation:', error);
    }
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[ResponseViewer] Toast error:', error);
    }
  }
}
