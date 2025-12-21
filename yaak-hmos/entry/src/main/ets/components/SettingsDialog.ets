/**
 * Settings Dialog Component
 * Application settings dialog with account and sync settings
 */

import { ThemedButton } from '.';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { HuaweiLoginButton } from './HuaweiLoginButton';
import { AuthService } from '../services/AuthService';
import type { UserInfo } from '../services/AuthService';
import { SyncService } from '../services/SyncService';
import type { SyncStatus, SyncServiceOptions } from '../services/SyncService';
import { PreferencesService, PreferenceKeys } from '../services/PreferencesService';
import { promptAction } from '@kit.ArkUI';

interface AppSettings {
  theme: string;
  editorFontSize: number;
  interfaceFontSize: number;
  editorKeymap: string;
  softWrap: boolean;
}

@ComponentV2
export struct SettingsDialog {
  @Param isVisible: boolean = false;
  @Param onClose: () => void = () => {};
  @Param onLogout: () => void = () => {};
  @Param onLogin: () => void = () => {};

  @Local settings: AppSettings = {
    theme: 'system',
    editorFontSize: 14,
    interfaceFontSize: 14,
    editorKeymap: 'default',
    softWrap: false
  };

  @Local selectedTab: string = 'account';
  @Local currentUser: UserInfo | null = null;
  @Local syncStatus: SyncStatus | null = null;
  @Local syncOptions: SyncServiceOptions | null = null;
  @Local isSyncing: boolean = false;
  @Local isLoggingIn: boolean = false;
  @Local showPrivacyPolicy: boolean = false;
  @Local privacyPolicyAccepted: boolean = false;

  private themeOptions: SelectOption[] = [
    { label: 'Light', value: 'light' },
    { label: 'Dark', value: 'dark' },
    { label: 'Auto (System)', value: 'system' }
  ];

  private keymapOptions: SelectOption[] = [
    { label: 'Default', value: 'default' },
    { label: 'Vim', value: 'vim' },
    { label: 'VSCode', value: 'vscode' },
    { label: 'Emacs', value: 'emacs' }
  ];

  aboutToAppear(): void {
    this.loadUserAndSyncStatus();
  }

  private loadUserAndSyncStatus(): void {
    this.currentUser = AuthService.getCurrentUser();
    this.syncStatus = SyncService.getInstance().getSyncStatus();
    this.syncOptions = SyncService.getInstance().getOptions();
    
    // Check if privacy policy was accepted
    this.checkPrivacyPolicyAccepted();
  }

  private async checkPrivacyPolicyAccepted(): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      this.privacyPolicyAccepted = await prefsService.getBoolean(
        PreferenceKeys.PRIVACY_POLICY_ACCEPTED,
        false
      );
    } catch (error) {
      console.error('[SettingsDialog] Failed to check privacy policy:', error);
      this.privacyPolicyAccepted = false;
    }
  }

  private async acceptPrivacyPolicy(): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setBoolean(PreferenceKeys.PRIVACY_POLICY_ACCEPTED, true);
      this.privacyPolicyAccepted = true;
      this.showPrivacyPolicy = false;
      
      // Enable auto sync after accepting
      SyncService.getInstance().updateOptions({ autoSync: true });
      this.syncOptions = SyncService.getInstance().getOptions();
      
      this.showToast('已启用云同步');
    } catch (error) {
      console.error('[SettingsDialog] Failed to accept privacy policy:', error);
    }
  }

  private declinePrivacyPolicy(): void {
    this.showPrivacyPolicy = false;
    this.showToast('已取消');
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => {
            this.onClose();
          })

        // Dialog Content
        Column() {
          // Dialog Header
          Row() {
            Text('Settings')
              .fontSize($r('app.float.font_size_xl'))
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Bold)
              .flexGrow(1)

            ThemedButton({
              symbolIcon: $r("sys.symbol.xmark"),
              onButtonClick: () => this.onClose(),
              buttonType: 'ghost'
            })
          }
          .width('100%')
          .padding($r('app.float.spacing_md'))
          .border({
            width: { bottom: 1 },
            color: $r('app.color.divider')
          })

          // Main Content Area with Sidebar
          Row() {
            // Left Sidebar with Tabs
            Column() {
              this.buildSidebarTab('Account', 'account');
              this.buildSidebarTab('Sync', 'sync');
              this.buildSidebarTab('Appearance', 'appearance');
              this.buildSidebarTab('Editor', 'editor');
              this.buildSidebarTab('About', 'about');
            }
            .width(180)
            .height('100%')
            .padding($r('app.float.spacing_md'))
            .backgroundColor($r('app.color.surface'))
            .border({
              width: { right: 1 },
              color: $r('app.color.divider')
            })

            // Right Content Area
            Scroll() {
              Column() {
                if (this.selectedTab === 'account') {
                  this.buildAccountSettings();
                } else if (this.selectedTab === 'sync') {
                  this.buildSyncSettings();
                } else if (this.selectedTab === 'appearance') {
                  this.buildAppearanceSettings();
                } else if (this.selectedTab === 'editor') {
                  this.buildEditorSettings();
                } else if (this.selectedTab === 'about') {
                  this.buildAboutSettings();
                }
              }
              .width('100%')
              .padding($r('app.float.spacing_xl'))
            }
            .layoutWeight(1)
            .height('100%')
            .scrollBar(BarState.Auto)
            .align(Alignment.Top)
          }
          .layoutWeight(1)
          .width('100%')
        }
        .width('80%')
        .height('80%')
        .backgroundColor($r('app.color.background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)

      // Privacy Policy Dialog
      if (this.showPrivacyPolicy) {
        this.buildPrivacyPolicyDialog()
      }
    }
  }

  @Builder
  buildPrivacyPolicyDialog() {
    Stack() {
      // Backdrop
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('rgba(0, 0, 0, 0.5)')

      // Dialog Content
      Column() {
        // Header
        Text('隐私政策')
          .fontSize($r('app.float.font_size_xl'))
          .fontColor($r('app.color.text_primary'))
          .fontWeight(FontWeight.Bold)
          .width('100%')
          .textAlign(TextAlign.Center)
          .margin({ bottom: $r('app.float.spacing_lg') })

        // Policy content
        Scroll() {
          Column() {
            Text('在启用云同步功能之前，请阅读并同意以下隐私政策：')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_primary'))
              .width('100%')
              .margin({ bottom: $r('app.float.spacing_md') })

            this.buildPolicySection('数据收集',
              '我们将收集您的 API 请求配置数据（包括 URL、请求头、请求体等）用于云端同步。敏感数据（如密码、Token）将在本地加密后再上传。')

            this.buildPolicySection('数据存储',
              '您的数据将存储在华为云服务器上，采用行业标准的加密技术保护。数据仅用于跨设备同步，不会用于其他目的。')

            this.buildPolicySection('数据共享',
              '我们不会将您的数据出售或分享给第三方。只有您本人可以通过华为账号访问您的数据。')

            this.buildPolicySection('数据删除',
              '您可以随时在设置中关闭云同步功能。退出登录后，本地数据将保留，云端数据可通过华为账号管理页面删除。')

            this.buildPolicySection('用户权利',
              '您有权访问、更正或删除您的个人数据。如有任何疑问，请联系我们的客服团队。')
          }
          .width('100%')
          .padding($r('app.float.spacing_md'))
        }
        .layoutWeight(1)
        .width('100%')
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_md'))
        .margin({ bottom: $r('app.float.spacing_lg') })

        // Buttons
        Row() {
          Button('不同意')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .backgroundColor($r('app.color.surface'))
            .fontColor($r('app.color.text_primary'))
            .borderRadius($r('app.float.border_radius_md'))
            .margin({ right: $r('app.float.spacing_sm') })
            .onClick(() => {
              this.declinePrivacyPolicy();
            })

          Button('同意并继续')
            .type(ButtonType.Normal)
            .layoutWeight(1)
            .height(44)
            .backgroundColor($r('app.color.primary'))
            .fontColor(Color.White)
            .borderRadius($r('app.float.border_radius_md'))
            .margin({ left: $r('app.float.spacing_sm') })
            .onClick(() => {
              this.acceptPrivacyPolicy();
            })
        }
        .width('100%')
      }
      .width('80%')
      .height('70%')
      .padding($r('app.float.spacing_xl'))
      .backgroundColor($r('app.color.background'))
      .borderRadius($r('app.float.border_radius_lg'))
      .shadow({
        radius: 20,
        color: 'rgba(0, 0, 0, 0.3)',
        offsetX: 0,
        offsetY: 4
      })
    }
    .width('100%')
    .height('100%')
    .position({ x: 0, y: 0 })
    .zIndex(1001)
  }

  @Builder
  buildPolicySection(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      Text(content)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .lineHeight(22)
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_md') })
  }

  @Builder
  buildSidebarTab(label: string, value: string) {
    Button(label)
      .fontSize($r('app.float.font_size_md'))
      .fontColor(this.selectedTab === value ? $r('app.color.primary') : $r('app.color.text_primary'))
      .backgroundColor(this.selectedTab === value ? $r('app.color.surface_highlight') : Color.Transparent)
      .width('100%')
      .height(40)
      .borderRadius($r('app.float.border_radius_md'))
      .margin({ bottom: $r('app.float.spacing_xs') })
      .onClick(() => {
        this.selectedTab = value;
      })
  }

  @Builder
  buildAccountSettings() {
    Column() {
      Text('账号与登录')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_lg') })

      if (this.currentUser !== null && this.currentUser.isLoggedIn) {
        // Logged in state
        Column() {
          // User avatar and info
          Row() {
            if (this.currentUser.avatarUrl.length > 0) {
              Image(this.currentUser.avatarUrl)
                .width(64)
                .height(64)
                .borderRadius(32)
                .margin({ right: 16 })
            } else {
              Column() {
                Text(this.currentUser.displayName.charAt(0).toUpperCase())
                  .fontSize(24)
                  .fontColor(Color.White)
              }
              .width(64)
              .height(64)
              .borderRadius(32)
              .backgroundColor($r('app.color.primary'))
              .justifyContent(FlexAlign.Center)
              .margin({ right: 16 })
            }

            Column() {
              Text(this.currentUser.displayName)
                .fontSize($r('app.float.font_size_lg'))
                .fontColor($r('app.color.text_primary'))
                .fontWeight(FontWeight.Medium)

              Text(this.currentUser.email || '华为账号已登录')
                .fontSize($r('app.float.font_size_sm'))
                .fontColor($r('app.color.text_secondary'))
                .margin({ top: 4 })
            }
            .alignItems(HorizontalAlign.Start)
          }
          .width('100%')
          .padding(16)
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.border_radius_md'))
          .margin({ bottom: $r('app.float.spacing_lg') })

          // Logout button
          Button('退出登录')
            .type(ButtonType.Normal)
            .width('100%')
            .height(44)
            .backgroundColor('#EF4444')
            .fontColor(Color.White)
            .borderRadius($r('app.float.border_radius_md'))
            .onClick(() => {
              this.handleLogout();
            })
        }
        .width('100%')
      } else {
        // Not logged in state
        Column() {
          Text('登录华为账号以同步数据')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: $r('app.float.spacing_lg') })

          // 使用华为账号登录按钮组件
          HuaweiLoginButton({
            onLoginSuccess: (authCode: string, idToken: string) => {
              this.handleHuaweiLoginSuccess(authCode, idToken);
            },
            onLoginError: (errorCode: number, errorMessage: string) => {
              this.handleHuaweiLoginError(errorCode, errorMessage);
            },
            buttonStyle: 'red'
          })
        }
        .width('100%')
        .padding(24)
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_md'))
      }
    }
    .width('100%')
  }

  @Builder
  buildSyncSettings() {
    Column() {
      Text('数据同步')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_lg') })

      if (this.currentUser === null || !this.currentUser.isLoggedIn) {
        Text('请先登录华为账号以使用同步功能')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
      } else {
        // Sync status
        Row() {
          Column() {
            Text('同步状态')
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.text_secondary'))

            Row() {
              Circle()
                .width(8)
                .height(8)
                .fill(this.syncStatus?.isOnline ? '#22C55E' : '#EF4444')
                .margin({ right: 8 })

              Text(this.syncStatus?.isOnline ? '在线' : '离线')
                .fontSize($r('app.float.font_size_md'))
                .fontColor($r('app.color.text_primary'))
            }
            .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Column() {
            Text('待同步')
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.text_secondary'))

            Text(`${this.syncStatus?.pendingChanges || 0} 项`)
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_primary'))
              .margin({ top: 4 })
          }
          .alignItems(HorizontalAlign.End)
        }
        .width('100%')
        .padding(16)
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_md'))
        .margin({ bottom: $r('app.float.spacing_md') })

        // Last sync time
        if (this.syncStatus !== null && this.syncStatus.lastSyncTime > 0) {
          Text(`上次同步: ${this.formatTime(this.syncStatus.lastSyncTime)}`)
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_tertiary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_lg') })
        }

        // Auto sync toggle
        Row() {
          Text('自动同步')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.syncOptions?.autoSync || false })
            .selectedColor($r('app.color.primary'))
            .onChange((isOn: boolean) => {
              if (isOn && !this.privacyPolicyAccepted) {
                // Show privacy policy first
                this.showPrivacyPolicy = true;
              } else {
                SyncService.getInstance().updateOptions({ autoSync: isOn });
                this.syncOptions = SyncService.getInstance().getOptions();
              }
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // WiFi only toggle
        Row() {
          Text('仅在 WiFi 下同步')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_primary'))
            .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.syncOptions?.wifiOnly || false })
            .selectedColor($r('app.color.primary'))
            .onChange((isOn: boolean) => {
              SyncService.getInstance().updateOptions({ wifiOnly: isOn });
              this.syncOptions = SyncService.getInstance().getOptions();
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // Sync sensitive data toggle
        Row() {
          Column() {
            Text('同步敏感数据')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_primary'))

            Text('包括密码、Token、API Key 等')
              .fontSize($r('app.float.font_size_xs'))
              .fontColor($r('app.color.text_tertiary'))
              .margin({ top: 2 })
          }
          .alignItems(HorizontalAlign.Start)
          .layoutWeight(1)

          Toggle({ type: ToggleType.Switch, isOn: this.syncOptions?.syncSensitiveData || false })
            .selectedColor($r('app.color.primary'))
            .onChange((isOn: boolean) => {
              SyncService.getInstance().updateOptions({ syncSensitiveData: isOn });
              this.syncOptions = SyncService.getInstance().getOptions();
            })
        }
        .width('100%')
        .padding({ top: 12, bottom: 12 })

        // Manual sync button
        Button(this.isSyncing ? '同步中...' : '立即同步')
          .type(ButtonType.Normal)
          .width('100%')
          .height(44)
          .backgroundColor($r('app.color.primary'))
          .fontColor(Color.White)
          .borderRadius($r('app.float.border_radius_md'))
          .enabled(!this.isSyncing)
          .margin({ top: $r('app.float.spacing_lg') })
          .onClick(() => {
            this.handleManualSync();
          })
      }
    }
    .width('100%')
  }

  private formatTime(timestamp: number): string {
    const date = new Date(timestamp);
    const now = new Date();
    const diff = now.getTime() - timestamp;

    if (diff < 60000) {
      return '刚刚';
    } else if (diff < 3600000) {
      return `${Math.floor(diff / 60000)} 分钟前`;
    } else if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)} 小时前`;
    } else {
      return `${date.getMonth() + 1}/${date.getDate()} ${date.getHours()}:${date.getMinutes().toString().padStart(2, '0')}`;
    }
  }

  private async handleLogout(): Promise<void> {
    try {
      await AuthService.logout(false);
      this.currentUser = null;
      this.onLogout();
      this.showToast('已退出登录');
    } catch (error) {
      console.error('[SettingsDialog] Logout failed:', error);
      this.showToast('退出登录失败');
    }
  }

  /**
   * 华为账号登录成功回调
   * 本地模式：直接保存登录状态，后续可接入后端 API
   */
  private handleHuaweiLoginSuccess = (authCode: string, _idToken: string): void => {
    this.isLoggingIn = true;

    try {
      // 本地模式：直接创建用户信息
      // TODO: 后续接入后端 API 时，使用 authCode 换取用户详细信息
      console.info('[SettingsDialog] Login with authCode:', authCode.substring(0, 10) + '...');
      
      const userInfo: UserInfo = {
        unionId: '',
        openId: '',
        displayName: '华为用户',
        avatarUrl: '',
        email: '',
        isLoggedIn: true,
        loginTime: Date.now()
      };
      
      AuthService.setCurrentUser(userInfo);
      this.currentUser = userInfo;
      this.showToast('登录成功');
      this.onLogin();
    } catch (error) {
      console.error('[SettingsDialog] Login error:', error);
      this.showToast('登录失败，请重试');
    } finally {
      this.isLoggingIn = false;
    }
  }

  /**
   * 华为账号登录失败回调
   */
  private handleHuaweiLoginError = (errorCode: number, errorMessage: string): void => {
    this.isLoggingIn = false;
    this.showToast(errorMessage);
    console.error('[SettingsDialog] Huawei login error:', errorCode, errorMessage);
  }

  private async handleManualSync(): Promise<void> {
    this.isSyncing = true;
    try {
      await SyncService.getInstance().forceSync();
      this.syncStatus = SyncService.getInstance().getSyncStatus();
      this.showToast('同步完成');
    } catch (error) {
      console.error('[SettingsDialog] Sync failed:', error);
      this.showToast('同步失败');
    } finally {
      this.isSyncing = false;
    }
  }

  private showToast(message: string): void {
    try {
      promptAction.showToast({ message: message, duration: 2000 });
    } catch (error) {
      console.error('[SettingsDialog] Toast error:', error);
    }
  }

  private saveSettings(): void {
    // TODO: Implement settings persistence
    console.info('Saving settings:', JSON.stringify(this.settings));
  }

  @Builder
  buildAppearanceSettings() {
    Column() {
      Text('Theme')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      ThemedSelect({
        options: this.themeOptions,
        selectedValue: this.settings.theme,
        onSelectChange: (value: string) => {
          this.settings.theme = value;
        },
        selectSize: 'md'
      })
    }
    .width('100%')
  }

  @Builder
  buildEditorSettings() {
    Column() {
      // Editor Font Size
      Text(`Editor Font Size: ${this.settings.editorFontSize}px`)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      Slider({
        value: this.settings.editorFontSize,
        min: 10,
        max: 24,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .trackColor($r('app.color.surface_highlight'))
        .selectedColor($r('app.color.primary'))
        .blockColor($r('app.color.primary'))
        .onChange((value: number) => {
          this.settings.editorFontSize = Math.round(value);
        })
        .margin({ bottom: $r('app.float.spacing_md') })

      // Editor Keymap
      Text('Editor Keymap')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      ThemedSelect({
        options: this.keymapOptions,
        selectedValue: this.settings.editorKeymap,
        onSelectChange: (value: string) => {
          this.settings.editorKeymap = value;
        },
        selectSize: 'md'
      })
        .margin({ bottom: $r('app.float.spacing_md') })

      // Soft Wrap Toggle
      Row() {
        Text('Soft Wrap')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .flexGrow(1)

        Toggle({ type: ToggleType.Switch, isOn: this.settings.softWrap })
          .selectedColor($r('app.color.primary'))
          .onChange((isOn: boolean) => {
            this.settings.softWrap = isOn;
          })
      }
      .width('100%')
    }
    .width('100%')
  }

  @Builder
  buildInterfaceSettings() {
    Column() {
      Text(`Interface Font Size: ${this.settings.interfaceFontSize}px`)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      Slider({
        value: this.settings.interfaceFontSize,
        min: 10,
        max: 20,
        step: 1,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .trackColor($r('app.color.surface_highlight'))
        .selectedColor($r('app.color.primary'))
        .blockColor($r('app.color.primary'))
        .onChange((value: number) => {
          this.settings.interfaceFontSize = Math.round(value);
        })
    }
    .width('100%')
  }

  @Builder
  buildAboutSettings() {
    Column() {
      Text('Flare for HarmonyOS')
        .fontSize($r('app.float.font_size_xl'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: $r('app.float.spacing_md') })

      Text('Version 1.0.0')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: $r('app.float.spacing_xl') })

      Text('A powerful API client for HarmonyOS')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .margin({ bottom: $r('app.float.spacing_lg') })

      Text('© 2024 Flare. All rights reserved.')
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
