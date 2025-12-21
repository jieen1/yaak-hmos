/**
 * Workspace Settings Dialog Component
 * Dialog for editing workspace settings including headers and auth
 */

import { Workspace } from '../model/Workspace';
import { HttpHeader, AuthConfig } from '../model/HttpRequest';
import { HeadersEditor } from './HeadersEditor';
import { AuthEditor } from './AuthEditor';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct WorkspaceSettingsDialog {
  @Param visible: boolean = false;
  @Param workspace: Workspace | null = null;
  @Param onClose: () => void = () => {};
  @Param onSave: (workspace: Workspace) => void = () => {};

  @Local activeTab: number = 0;
  @Local editedName: string = '';
  @Local editedDescription: string = '';
  @Local editedHeaders: HttpHeader[] = [];
  @Local editedAuth: AuthConfig = new AuthConfig();

  aboutToAppear(): void {
    this.initializeEditState();
  }

  @Monitor('workspace')
  onWorkspaceChange(): void {
    this.initializeEditState();
  }

  @Monitor('visible')
  onVisibleChange(): void {
    if (this.visible) {
      this.initializeEditState();
    }
  }

  /**
   * Initialize edit state from workspace
   */
  private initializeEditState(): void {
    if (this.workspace === null) {
      return;
    }

    // Copy workspace data for editing
    this.editedName = this.workspace.name;
    this.editedDescription = this.workspace.description;
    
    // Deep copy headers
    this.editedHeaders = [];
    this.workspace.headers.forEach((header: HttpHeader) => {
      const newHeader: HttpHeader = new HttpHeader();
      newHeader.id = header.id;
      newHeader.name = header.name;
      newHeader.value = header.value;
      newHeader.enabled = header.enabled;
      this.editedHeaders.push(newHeader);
    });

    // Copy auth
    if (this.workspace.auth !== null) {
      this.editedAuth = new AuthConfig();
      this.editedAuth.type = this.workspace.auth.type;
      this.editedAuth.basic_username = this.workspace.auth.basic_username;
      this.editedAuth.basic_password = this.workspace.auth.basic_password;
      this.editedAuth.bearer_token = this.workspace.auth.bearer_token;
      this.editedAuth.api_key_name = this.workspace.auth.api_key_name;
      this.editedAuth.api_key_value = this.workspace.auth.api_key_value;
      this.editedAuth.api_key_location = this.workspace.auth.api_key_location;
      this.editedAuth.oauth2_access_token = this.workspace.auth.oauth2_access_token;
      this.editedAuth.oauth2_refresh_token = this.workspace.auth.oauth2_refresh_token;
      this.editedAuth.oauth2_expires_at = this.workspace.auth.oauth2_expires_at;
    } else {
      this.editedAuth = new AuthConfig();
    }
  }

  /**
   * Handle save
   */
  private handleSave(): void {
    if (this.workspace === null) {
      return;
    }

    // Update workspace with edited values
    this.workspace.name = this.editedName;
    this.workspace.description = this.editedDescription;
    this.workspace.headers = this.editedHeaders;
    this.workspace.auth = this.editedAuth;
    this.workspace.updated_at = Date.now();

    this.onSave(this.workspace);
    this.onClose();
  }

  /**
   * Handle headers change
   */
  private handleHeadersChange = (headers: HttpHeader[]): void => {
    this.editedHeaders = headers;
  }

  /**
   * Handle auth change
   */
  private handleAuthChange = (auth: AuthConfig): void => {
    this.editedAuth = auth;
  }

  build() {
    if (this.visible && this.workspace !== null) {
      Column() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#00000066')
          .position({ x: 0, y: 0 })
          .onClick(() => {
            this.onClose();
          })

        // Dialog
        Column() {
          // Header
          Row() {
            Text(`工作区设置: ${this.workspace?.name || ''}`)
              .fontSize($r('app.float.font_size_lg'))
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
              .flexGrow(1)

            ThemedButton({
              text: '×',
              onButtonClick: () => {
                this.onClose();
              },
              buttonType: 'ghost'
            })
          }
          .width('100%')
          .padding($r('app.float.spacing_md'))
          .border({
            width: { bottom: 1 },
            color: $r('app.color.divider')
          })

          // Tabs
          Tabs({ index: this.activeTab }) {
            TabContent() {
              this.buildGeneralTab()
            }
            .tabBar('通用')

            TabContent() {
              HeadersEditor({
                headers: this.editedHeaders,
                inheritedHeaders: [], // Workspace has no inherited headers
                onChange: this.handleHeadersChange,
                onNavigateToSource: () => {}
              })
            }
            .tabBar('请求头')

            TabContent() {
              AuthEditor({
                auth: this.editedAuth,
                inheritedAuth: null, // Workspace has no inherited auth
                onChange: this.handleAuthChange,
                onNavigateToSource: () => {}
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

          // Footer
          Row() {
            Blank()

            ThemedButton({
              text: '取消',
              onButtonClick: () => {
                this.onClose();
              },
              buttonType: 'secondary',
              buttonSize: 'md'
            })
              .margin({ right: $r('app.float.spacing_sm') })

            ThemedButton({
              text: '保存',
              onButtonClick: () => {
                this.handleSave();
              },
              buttonSize: 'md'
            })
          }
          .width('100%')
          .padding($r('app.float.spacing_md'))
          .border({
            width: { top: 1 },
            color: $r('app.color.divider')
          })
        }
        .width('80%')
        .height('80%')
        .backgroundColor($r('app.color.background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .position({ x: '10%', y: '10%' })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }

  @Builder
  buildGeneralTab() {
    Column() {
      // Workspace Name
      Column() {
        Text('Workspace Name')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.editedName,
          placeholder: 'Enter workspace name',
          onValueChange: (value: string) => {
            this.editedName = value;
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_lg') })

      // Workspace Description
      Column() {
        Text('Description (Optional)')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.editedDescription,
          placeholder: 'Enter workspace description',
          onValueChange: (value: string) => {
            this.editedDescription = value;
          },
          inputSize: 'md'
        })
      }
      .width('100%')

      // Info text
      Column() {
        Text('Headers and authentication configured here will be inherited by all requests in this workspace.')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ top: $r('app.float.spacing_xl') })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .padding($r('app.float.spacing_lg'))
  }
}
