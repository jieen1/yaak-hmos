/**
 * Folder Settings Dialog Component
 * Dialog for editing folder settings including headers and auth
 */

import { Folder } from '../model/Folder';
import { Workspace } from '../model/Workspace';
import { HttpHeader, AuthConfig } from '../model/HttpRequest';
import { InheritanceService } from '../services/InheritanceService';
import type { InheritedHeaderWithSource, InheritedAuthInfo } from '../services/InheritanceService';
import { HeadersEditor } from './HeadersEditor';
import { AuthEditor } from './AuthEditor';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct FolderSettingsDialog {
  @Param visible: boolean = false;
  @Param folder: Folder | null = null;
  @Param folders: Folder[] = [];
  @Param workspace: Workspace | null = null;
  @Param onClose: () => void = () => {};
  @Param onSave: (folder: Folder) => void = () => {};
  @Param onNavigateToSource: (sourceType: string, sourceId: string) => void = () => {};

  @Local activeTab: number = 0;
  @Local editedName: string = '';
  @Local editedHeaders: HttpHeader[] = [];
  @Local editedAuth: AuthConfig = new AuthConfig();
  @Local inheritedHeaders: InheritedHeaderWithSource[] = [];
  @Local inheritedAuth: InheritedAuthInfo | null = null;

  aboutToAppear(): void {
    this.initializeEditState();
  }

  @Monitor('folder')
  onFolderChange(): void {
    this.initializeEditState();
  }

  @Monitor('visible')
  onVisibleChange(): void {
    if (this.visible) {
      this.initializeEditState();
    }
  }

  /**
   * Initialize edit state from folder
   */
  private initializeEditState(): void {
    if (this.folder === null) {
      return;
    }

    // Copy folder data for editing
    this.editedName = this.folder.name;
    
    // Deep copy headers
    this.editedHeaders = [];
    this.folder.headers.forEach((header: HttpHeader) => {
      const newHeader: HttpHeader = new HttpHeader();
      newHeader.id = header.id;
      newHeader.name = header.name;
      newHeader.value = header.value;
      newHeader.enabled = header.enabled;
      this.editedHeaders.push(newHeader);
    });

    // Copy auth
    if (this.folder.auth !== null) {
      this.editedAuth = new AuthConfig();
      this.editedAuth.type = this.folder.auth.type;
      this.editedAuth.basic_username = this.folder.auth.basic_username;
      this.editedAuth.basic_password = this.folder.auth.basic_password;
      this.editedAuth.bearer_token = this.folder.auth.bearer_token;
      this.editedAuth.api_key_name = this.folder.auth.api_key_name;
      this.editedAuth.api_key_value = this.folder.auth.api_key_value;
      this.editedAuth.api_key_location = this.folder.auth.api_key_location;
      this.editedAuth.oauth2_access_token = this.folder.auth.oauth2_access_token;
      this.editedAuth.oauth2_refresh_token = this.folder.auth.oauth2_refresh_token;
      this.editedAuth.oauth2_expires_at = this.folder.auth.oauth2_expires_at;
    } else {
      this.editedAuth = new AuthConfig();
    }

    // Get inherited headers and auth (from parent folders, not including this folder)
    this.inheritedHeaders = InheritanceService.getInheritedHeadersWithSource(
      this.folder.folder_id,
      this.folders,
      this.workspace
    );

    this.inheritedAuth = InheritanceService.getInheritedAuthWithSource(
      this.folder.folder_id,
      this.folders,
      this.workspace
    );
  }

  /**
   * Handle save
   */
  private handleSave(): void {
    if (this.folder === null) {
      return;
    }

    // Update folder with edited values
    this.folder.name = this.editedName;
    this.folder.headers = this.editedHeaders;
    this.folder.auth = this.editedAuth;
    this.folder.updated_at = Date.now();

    this.onSave(this.folder);
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

  /**
   * Handle navigate to source
   */
  private handleNavigateToSource = (sourceType: string, sourceId: string): void => {
    this.onClose();
    this.onNavigateToSource(sourceType, sourceId);
  }

  build() {
    if (this.visible && this.folder !== null) {
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
            Text(`文件夹设置: ${this.folder?.name || ''}`)
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
                inheritedHeaders: this.inheritedHeaders,
                onChange: this.handleHeadersChange,
                onNavigateToSource: this.handleNavigateToSource
              })
            }
            .tabBar('请求头')

            TabContent() {
              AuthEditor({
                auth: this.editedAuth,
                inheritedAuth: this.inheritedAuth,
                onChange: this.handleAuthChange,
                onNavigateToSource: this.handleNavigateToSource
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
      // Folder Name
      Column() {
        Text('Folder Name')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.editedName,
          placeholder: 'Enter folder name',
          onValueChange: (value: string) => {
            this.editedName = value;
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .padding($r('app.float.spacing_lg'))
    }
    .width('100%')
    .height('100%')
  }
}
