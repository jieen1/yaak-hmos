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
  @Param @Require request: HttpRequest;
  @Param @Require inheritedHeaders: InheritedHeaderWithSource[];
  @Param @Require inheritedAuth: InheritedAuthInfo | null;
  @Event onExecute: () => void = () => {};
  @Event onCancel: () => void = () => {};
  @Event onCopyAsCurl: () => void = () => {};
  @Event onChange: (request: HttpRequest) => void | Promise<void> = () => {};
  @Event onCurlImport: (request: HttpRequest) => void = () => {};
  @Event onNavigateToSource: (sourceType: string, sourceId: string) => void = () => {};
  @Param isLoading: boolean = false;

  @Local activeTab: number = 0;
  @Local previousUrlLength: number = 0;

  // 存储每个请求的 activeTab，key 是 requestId
  private static requestTabCache: Map<string, number> = new Map();

  aboutToAppear(): void {
    // 恢复该请求上次的 activeTab
    this.restoreActiveTab();
  }

  // 监听 request 变化，恢复对应的 activeTab
  @Monitor('request')
  onRequestChange(): void {
    console.info(`[RequestEditor] Request changed to: ${this.request.id}`);
    this.restoreActiveTab();
  }

  /**
   * 恢复该请求的 activeTab
   */
  private restoreActiveTab(): void {
    const cachedTab: number | undefined = RequestEditorComponent.requestTabCache.get(this.request.id);
    if (cachedTab !== undefined) {
      console.info(`[RequestEditor] Restored activeTab ${cachedTab} for request ${this.request.id}`);
      this.activeTab = cachedTab;
    } else {
      console.info(`[RequestEditor] No cached tab for request ${this.request.id}, using default 0`);
      this.activeTab = 0;
    }
  }

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

      // Tabs
      Tabs({ index: this.activeTab }) {
        TabContent() {
          QueryParamsEditor({
            queryParams: this.request.query_params,
            requestId: this.request.id,  // 传递请求 ID
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
            requestId: this.request.id,  // 传递请求 ID
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
        .tabBar(this.buildBodyTabBar())

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
        .tabBar(this.buildAuthTabBar())
      }
      .width('100%')
      .layoutWeight(1)
      .barMode(BarMode.Fixed)
      .barPosition(BarPosition.Start)
      .onChange((index: number) => {
        this.activeTab = index;
        // 缓存当前请求的 activeTab
        RequestEditorComponent.requestTabCache.set(this.request.id, index);
        console.info(`[RequestEditor] Saved activeTab ${index} for request ${this.request.id}`);
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
      // 直接导入 cURL，不显示确认对话框
      this.importCurlCommand(value);
      return;
    }

    // Normal URL change
    console.info(`[RequestEditor] URL changed: ${value}`);
    this.request.url = value;
    this.onChange(this.request);
  }

  /**
   * Import cURL command and populate request fields
   */
  private importCurlCommand(curlCommand: string): void {
    const parseResult = CurlImporter.parse(curlCommand, this.request.workspace_id);

    if (parseResult.success && parseResult.request) {
      // Preserve the original request's important properties
      const importedRequest = parseResult.request;
      importedRequest.id = this.request.id;
      importedRequest.workspace_id = this.request.workspace_id;
      importedRequest.folder_id = this.request.folder_id;
      // 保留原请求的名称（如果不是默认名称）
      if (this.request.name && this.request.name !== '新建请求') {
        importedRequest.name = this.request.name;
      }
      // 保留排序优先级和创建时间
      importedRequest.sort_priority = this.request.sort_priority;
      importedRequest.created_at = this.request.created_at;

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
    Column() {
      Row() {
        Text('参数')
          .fontSize($r('app.float.font_size_md'))
          .fontColor(this.activeTab === 0 ? $r('app.color.primary') : $r('app.color.text_primary'))
          .fontWeight(this.activeTab === 0 ? FontWeight.Medium : FontWeight.Normal)

        Text(`${this.request.queryParamsCount}`)
          .fontSize(10)
          .fontColor(this.activeTab === 0 ? $r('app.color.primary') : $r('app.color.text_secondary'))
          .borderRadius($r('app.float.border_radius_sm'))
          .borderColor(this.activeTab === 0 ? $r('app.color.primary') : $r('app.color.text_tertiary'))
          .borderWidth(1)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 选中指示器
      if (this.activeTab === 0) {
        Row()
          .width('100%')
          .height(2)
          .backgroundColor($r('app.color.primary'))
      }
    }
    .width('100%')
  }

  /**
   * Build headers tab bar with badge
   */
  @Builder
  buildHeadersTabBar() {
    Column() {
      Row() {
        Text('请求头')
          .fontSize($r('app.float.font_size_md'))
          .fontColor(this.activeTab === 1 ? $r('app.color.primary') : $r('app.color.text_primary'))
          .fontWeight(this.activeTab === 1 ? FontWeight.Medium : FontWeight.Normal)

        Text(`${this.request.headersCount}`)
          .fontSize(10)
          .fontColor(this.activeTab === 1 ? $r('app.color.primary') : $r('app.color.text_secondary'))
          .borderRadius($r('app.float.border_radius_sm'))
          .borderColor(this.activeTab === 1 ? $r('app.color.primary') : $r('app.color.text_tertiary'))
          .borderWidth(1)
          .padding({ left: 5, right: 5, top: 1, bottom: 1 })
          .margin({ left: 4 })
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 选中指示器
      if (this.activeTab === 1) {
        Row()
          .width('100%')
          .height(2)
          .backgroundColor($r('app.color.primary'))
      }
    }
    .width('100%')
  }

  /**
   * Build body tab bar
   */
  @Builder
  buildBodyTabBar() {
    Column() {
      Row() {
        Text('请求体')
          .fontSize($r('app.float.font_size_md'))
          .fontColor(this.activeTab === 2 ? $r('app.color.primary') : $r('app.color.text_primary'))
          .fontWeight(this.activeTab === 2 ? FontWeight.Medium : FontWeight.Normal)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 选中指示器
      if (this.activeTab === 2) {
        Row()
          .width('100%')
          .height(2)
          .backgroundColor($r('app.color.primary'))
      }
    }
    .width('100%')
  }

  /**
   * Build auth tab bar
   */
  @Builder
  buildAuthTabBar() {
    Column() {
      Row() {
        Text('认证')
          .fontSize($r('app.float.font_size_md'))
          .fontColor(this.activeTab === 3 ? $r('app.color.primary') : $r('app.color.text_primary'))
          .fontWeight(this.activeTab === 3 ? FontWeight.Medium : FontWeight.Normal)
      }
      .justifyContent(FlexAlign.Center)
      .alignItems(VerticalAlign.Center)
      .padding({ top: 8, bottom: 8 })

      // 选中指示器
      if (this.activeTab === 3) {
        Row()
          .width('100%')
          .height(2)
          .backgroundColor($r('app.color.primary'))
      }
    }
    .width('100%')
  }
}
