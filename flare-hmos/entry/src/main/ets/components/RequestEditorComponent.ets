/**
 * Request Editor Component
 * Main editor for HTTP requests with tabs for Params, Headers, Body, Auth
 */

import { HttpRequest } from '../model/HttpRequest';
import type { InheritedHeaderWithSource, InheritedAuthInfo } from '../services/InheritanceService';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';
import { ThemedText } from './ThemedText';
import { QueryParamsEditor } from './QueryParamsEditor';
import { HeadersEditor } from './HeadersEditor';
import { BodyEditor } from './BodyEditor';
import { AuthEditor } from './AuthEditor';
import { CurlImporter } from '../services/CurlImporter';
import { promptAction } from '@kit.ArkUI';
import type { DeviceInfo } from '../services/ContinuationService';

/**
 * Get color for HTTP method
 */
function getMethodColor(method: string): string {
  const m: string = method.toUpperCase();
  if (m === 'GET') {
    return '#7c3aed'; // primary/purple
  } else if (m === 'POST') {
    return '#22c55e'; // success/green
  } else if (m === 'PUT') {
    return '#f59e0b'; // warning/amber
  } else if (m === 'PATCH') {
    return '#f97316'; // notice/orange
  } else if (m === 'DELETE') {
    return '#ef4444'; // danger/red
  } else if (m === 'HEAD') {
    return '#6b7280'; // subtle/gray
  } else if (m === 'OPTIONS') {
    return '#3b82f6'; // info/blue
  }
  return '#6b7280'; // default gray
}

@ComponentV2
export struct RequestEditorComponent {
  @Param request: HttpRequest = new HttpRequest();
  @Param inheritedHeaders: InheritedHeaderWithSource[] = [];
  @Param inheritedAuth: InheritedAuthInfo | null = null;
  @Param onExecute: () => void = () => {};
  @Param onCancel: () => void = () => {};
  @Param onCopyAsCurl: () => void = () => {};
  @Param isLoading: boolean = false;
  @Param onChange: (request: HttpRequest) => void | Promise<void> = () => {};
  @Param onCurlImport: (request: HttpRequest) => void = () => {};
  @Param onNavigateToSource: (sourceType: string, sourceId: string) => void = () => {};

  @Local activeTab: number = 0;
  @Local previousUrlLength: number = 0;
  @Local showDeviceDialog: boolean = false;
  @Local discoveredDevices: DeviceInfo[] = [];
  @Local isDiscovering: boolean = false;

  /**
   * Get current method color
   */
  private getCurrentMethodColor(): string {
    return getMethodColor(this.request.method);
  }

  build() {
    Column() {
      // Request line (Method, URL, Send button)
      Row() {
        // Method selector with colored text
        Row() {
          ThemedText({
            content: this.request.method,
            fontWeight: FontWeight.Bold,
            fontColor: this.getCurrentMethodColor()
          })
        }
        .width(80)
        .height(36)
        .justifyContent(FlexAlign.Center)
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_sm'))
        .border({
          width: 1,
          color: $r('app.color.border')
        })
        .margin({ right: $r('app.float.spacing_sm') })
        .bindMenu(this.buildMethodMenu())

        // URL input
        ThemedTextInput({
          value: this.request.url,
          placeholder: '输入请求 URL 或粘贴 cURL',
          onValueChange: (value: string) => {
            this.handleUrlChange(value);
          },
          inputSize: 'md'
        })
          .layoutWeight(1)
          .margin({ right: $r('app.float.spacing_sm') })

        // Send/Cancel button
        if (this.isLoading) {
          ThemedButton({
            text: '取消',
            onButtonClick: () => {
              this.onCancel();
            },
            buttonType: 'danger',
            buttonSize: 'md'
          })
            .width(80)
            .flexShrink(0)
        } else {
          ThemedButton({
            text: '发送',
            onButtonClick: () => {
              this.onExecute();
            },
            buttonSize: 'md'
          })
            .width(80)
        }
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
      .backgroundColor($r('app.color.surface'))

      // Tabs
      Tabs({ index: this.activeTab }) {
        TabContent() {
          QueryParamsEditor({
            queryParams: this.request.query_params,
            onChange: (params) => {
              this.request.query_params = params;
              this.onChange(this.request);
            }
          })
        }
        .tabBar(this.buildParamsTabBar())

        TabContent() {
          HeadersEditor({
            headers: this.request.headers,
            inheritedHeaders: this.inheritedHeaders,
            onChange: (headers) => {
              this.request.headers = headers;
              this.onChange(this.request);
            },
            onNavigateToSource: (sourceType: string, sourceId: string) => {
              this.onNavigateToSource(sourceType, sourceId);
            }
          })
        }
        .tabBar(this.buildHeadersTabBar())

        TabContent() {
          BodyEditor({
            body: this.request.body || '',
            bodyType: this.request.body_type,
            onBodyChange: (body) => {
              this.request.body = body;
              this.onChange(this.request);
            },
            onBodyTypeChange: (bodyType) => {
              this.request.body_type = bodyType;
              this.onChange(this.request);
            }
          })
        }
        .tabBar('请求体')

        TabContent() {
          AuthEditor({
            auth: this.request.auth,
            inheritedAuth: this.inheritedAuth,
            onChange: (auth) => {
              this.request.auth = auth;
              this.onChange(this.request);
            },
            onNavigateToSource: (sourceType: string, sourceId: string) => {
              this.onNavigateToSource(sourceType, sourceId);
            }
          })
        }
        .tabBar('认证')
      }
      .width('100%')
      .layoutWeight(1)
      .barMode(BarMode.Fixed)
      .barPosition(BarPosition.Start)
      .onChange((index: number) => {
        this.activeTab = index;
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  /**
   * Build method menu items
   */
  @Builder
  buildMethodMenu() {
    Menu() {
      MenuItem({ content: 'GET' })
        .contentFontColor(getMethodColor('GET'))
        .onClick(() => {
          this.request.method = 'GET';
          this.onChange(this.request);
        })
      MenuItem({ content: 'POST' })
        .contentFontColor(getMethodColor('POST'))
        .onClick(() => {
          this.request.method = 'POST';
          this.onChange(this.request);
        })
      MenuItem({ content: 'PUT' })
        .contentFontColor(getMethodColor('PUT'))
        .onClick(() => {
          this.request.method = 'PUT';
          this.onChange(this.request);
        })
      MenuItem({ content: 'DELETE' })
        .contentFontColor(getMethodColor('DELETE'))
        .onClick(() => {
          this.request.method = 'DELETE';
          this.onChange(this.request);
        })
      MenuItem({ content: 'PATCH' })
        .contentFontColor(getMethodColor('PATCH'))
        .onClick(() => {
          this.request.method = 'PATCH';
          this.onChange(this.request);
        })
      MenuItem({ content: 'HEAD' })
        .contentFontColor(getMethodColor('HEAD'))
        .onClick(() => {
          this.request.method = 'HEAD';
          this.onChange(this.request);
        })
      MenuItem({ content: 'OPTIONS' })
        .contentFontColor(getMethodColor('OPTIONS'))
        .onClick(() => {
          this.request.method = 'OPTIONS';
          this.onChange(this.request);
        })
    }
  }

  /**
   * Handle URL input change with cURL auto-detection
   */
  private handleUrlChange(value: string): void {
    // Detect if this looks like a paste operation (significant length increase)
    const isPaste = value.length - this.previousUrlLength > 10;
    this.previousUrlLength = value.length;

    // Check if pasted content is a cURL command
    if (isPaste && CurlImporter.isCurlCommand(value)) {
      this.showCurlImportConfirmation(value);
      return;
    }

    // Normal URL change
    console.info(`[RequestEditor] URL changed: ${value}`);
    this.request.url = value;
    this.onChange(this.request);
  }

  /**
   * Show confirmation dialog for cURL import
   */
  private showCurlImportConfirmation(curlCommand: string): void {
    try {
      this.getUIContext().getPromptAction().showDialog({
        title: '检测到 cURL',
        message: '检测到 cURL 命令，是否导入？',
        buttons: [
          { text: '取消', color: '#666666' },
          { text: '导入', color: '#007AFF' }
        ]
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1) {
          this.importCurlCommand(curlCommand);
        } else {
          // User cancelled, just set the URL as-is
          this.request.url = curlCommand;
          this.onChange(this.request);
        }
      }).catch((error: Error) => {
        console.error('[RequestEditor] cURL import confirmation error:', error);
        // On error, just set the URL
        this.request.url = curlCommand;
        this.onChange(this.request);
      });
    } catch (error) {
      console.error('[RequestEditor] Failed to show cURL import confirmation:', error);
      this.request.url = curlCommand;
      this.onChange(this.request);
    }
  }

  /**
   * Import cURL command and populate request fields
   */
  private importCurlCommand(curlCommand: string): void {
    const parseResult = CurlImporter.parse(curlCommand, this.request.workspace_id);

    if (parseResult.success && parseResult.request) {
      // Preserve the original request ID and workspace
      const importedRequest = parseResult.request;
      importedRequest.id = this.request.id;
      importedRequest.workspace_id = this.request.workspace_id;
      importedRequest.folder_id = this.request.folder_id;

      // Notify parent to update the request
      this.onCurlImport(importedRequest);

      this.showToast('cURL 导入成功');
    } else {
      const errorMsg = parseResult.error || '未知错误';
      this.showToast(`cURL 导入失败: ${errorMsg}`);

      // Set the URL as-is on failure
      this.request.url = curlCommand;
      this.onChange(this.request);
    }
  }

  /**
   * Show toast message
   */
  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[RequestEditor] Toast error:', error);
    }
  }

  /**
   * Build params tab bar with badge
   */
  @Builder
  buildParamsTabBar() {
    Row() {
      Text('参数')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
      
      if (this.request.query_params) {
        Text(`${this.getQueryParamsCount()}`)
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .borderRadius($r('app.float.border_radius_sm'))
          .borderColor($r('app.color.text_tertiary'))
          .borderWidth(1)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .margin({ left: 4, bottom: 5 })
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * Build headers tab bar with badge
   */
  @Builder
  buildHeadersTabBar() {
    Row() {
      Text('请求头')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
      
      if (this.request.headers) {
        Text(`${this.getHeadersCount()}`)
          .fontSize(10)
          .fontColor($r('app.color.text_secondary'))
          .borderRadius($r('app.float.border_radius_sm'))
          .borderColor($r('app.color.text_tertiary'))
          .borderWidth(1)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .margin({ left: 4, bottom: 5 })
      }
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }

  /**
   * Get count of enabled query params
   */
  private getQueryParamsCount(): number {
    if (!this.request.query_params) {
      return 0;
    }
    return this.request.query_params.filter(p => p.enabled && (p.name || p.value)).length;
  }

  /**
   * Get count of enabled headers
   */

  private getHeadersCount(): number {
    if (!this.request.headers) {
      return 0;
    }
    return this.request.headers.filter(h => h.enabled && (h.name || h.value)).length;
  }
}
