/**
 * LoginComponent - Huawei Account login UI component
 * Provides login button and guest mode entry
 */

import { AuthService } from '../services/AuthService';
import type { UserInfo, AuthResult } from '../services/AuthService';
import { ThemedText } from './ThemedText';
import { promptAction } from '@kit.ArkUI';

/**
 * Login callback type
 */
export type LoginCallback = (user: UserInfo) => void;

/**
 * Guest mode callback type
 */
export type GuestCallback = () => void;

@ComponentV2
export struct LoginComponent {
  @Param onLoginSuccess: LoginCallback = () => {};
  @Param onGuestMode: GuestCallback = () => {};
  
  @Local isLoading: boolean = false;
  @Local errorMessage: string = '';

  build() {
    Column() {
      // App logo and name
      Column() {
        // Logo placeholder - use app icon
        Image($r('app.media.foreground'))
          .width(120)
          .height(120)
          .objectFit(ImageFit.Contain)
          .margin({ bottom: 16 })

        ThemedText({
          content: 'Flare',
          fontSizeOverride: 32,
          fontWeight: FontWeight.Bold,
          fontColor: $r('app.color.text_primary')
        })
          .margin({ bottom: 8 })

        ThemedText({
          content: 'API 调试工具',
          fontSizeOverride: 16,
          fontColor: $r('app.color.text_secondary')
        })
          .margin({ bottom: 48 })
      }
      .alignItems(HorizontalAlign.Center)

      // Login buttons
      Column() {
        // Huawei ID login button
        Button() {
          Row() {
            if (this.isLoading) {
              LoadingProgress()
                .width(20)
                .height(20)
                .color(Color.White)
                .margin({ right: 8 })
            }
            ThemedText({
              content: this.isLoading ? '登录中...' : '使用华为账号登录',
              fontSizeOverride: 16,
              fontColor: Color.White
            })
          }
        }
        .type(ButtonType.Capsule)
        .width('100%')
        .height(48)
        .backgroundColor('#CE0E2D')
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleHuaweiLogin();
        })
        .margin({ bottom: 16 })

        // Guest mode button
        Button() {
          ThemedText({
            content: '以访客模式使用',
            fontSizeOverride: 16,
            fontColor: $r('app.color.text_primary')
          })
        }
        .type(ButtonType.Capsule)
        .width('100%')
        .height(48)
        .backgroundColor($r('app.color.surface'))
        .border({
          width: 1,
          color: $r('app.color.border')
        })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleGuestMode();
        })

        // Error message
        if (this.errorMessage.length > 0) {
          Column() {
            ThemedText({
              content: this.errorMessage,
              fontSizeOverride: 14,
              fontColor: '#EF4444'
            })
          }
          .width('100%')
          .margin({ top: 16 })
          .alignItems(HorizontalAlign.Center)
        }
      }
      .width('100%')
      .padding({ left: 32, right: 32 })

      // Footer
      Column() {
        ThemedText({
          content: '登录即表示您同意',
          fontSizeOverride: 12,
          fontColor: $r('app.color.text_tertiary')
        })

        Row() {
          ThemedText({
            content: '服务条款',
            fontSizeOverride: 12,
            fontColor: $r('app.color.primary')
          })
            .onClick(() => {
              this.showTermsOfService();
            })

          ThemedText({
            content: ' 和 ',
            fontSizeOverride: 12,
            fontColor: $r('app.color.text_tertiary')
          })

          ThemedText({
            content: '隐私政策',
            fontSizeOverride: 12,
            fontColor: $r('app.color.primary')
          })
            .onClick(() => {
              this.showPrivacyPolicy();
            })
        }
      }
      .margin({ top: 48 })
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor($r('app.color.background'))
  }

  /**
   * Handle Huawei ID login
   */
  private async handleHuaweiLogin(): Promise<void> {
    this.isLoading = true;
    this.errorMessage = '';

    try {
      const result: AuthResult = await AuthService.loginWithHuaweiID();

      if (result.success && result.user !== null) {
        this.showToast('登录成功');
        this.onLoginSuccess(result.user);
      } else {
        this.errorMessage = result.error || '登录失败，请重试';
      }
    } catch (error) {
      console.error('[LoginComponent] Login error:', error);
      this.errorMessage = '登录失败，请重试';
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * Handle guest mode
   */
  private handleGuestMode(): void {
    this.onGuestMode();
  }

  /**
   * Show terms of service
   */
  private showTermsOfService(): void {
    this.showToast('服务条款');
  }

  /**
   * Show privacy policy
   */
  private showPrivacyPolicy(): void {
    this.showToast('隐私政策');
  }

  /**
   * Show toast message
   */
  private showToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[LoginComponent] Toast error:', error);
    }
  }
}
