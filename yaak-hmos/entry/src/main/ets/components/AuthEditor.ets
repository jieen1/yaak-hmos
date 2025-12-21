/**
 * Auth Editor Component
 * Edits authentication configuration for requests with inheritance support
 */

import { AuthConfig } from '../model/HttpRequest';
import type { AuthType } from '../model/Types';
import type { InheritedAuthInfo } from '../services/InheritanceService';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { ThemedTextInput } from './ThemedTextInput';

@ComponentV2
export struct AuthEditor {
  @Param auth: AuthConfig = new AuthConfig();
  @Param inheritedAuth: InheritedAuthInfo | null = null;
  @Param onChange: (auth: AuthConfig) => void = () => {};
  @Param onNavigateToSource: (sourceType: string, sourceId: string) => void = () => {};

  // Local state to track auth type for reactive updates
  @Local currentAuthType: AuthType = 'none';

  private authTypeOptions: SelectOption[] = [
    { label: 'Inherit from Parent', value: 'inherit' },
    { label: 'No Auth', value: 'none' },
    { label: 'Basic Auth', value: 'basic' },
    { label: 'Bearer Token', value: 'bearer' },
    { label: 'API Key', value: 'api-key' },
    { label: 'OAuth 2.0', value: 'oauth2' }
  ];

  private apiKeyLocationOptions: SelectOption[] = [
    { label: 'Header', value: 'header' },
    { label: 'Query Parameter', value: 'query' }
  ];

  aboutToAppear(): void {
    // If auth type is 'none' and there's inherited auth, show as 'inherit'
    if ((this.auth.type === 'none' || this.auth.type === null) && this.inheritedAuth !== null) {
      this.currentAuthType = 'inherit' as AuthType;
    } else {
      this.currentAuthType = this.auth.type || 'none';
    }
  }

  @Monitor('auth')
  onAuthChange(): void {
    if ((this.auth.type === 'none' || this.auth.type === null) && this.inheritedAuth !== null) {
      this.currentAuthType = 'inherit' as AuthType;
    } else {
      this.currentAuthType = this.auth.type || 'none';
    }
  }

  build() {
    Column() {
      // Auth type selector
      Row() {
        Text('认证类型')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width(100)
          .flexShrink(0)

        ThemedSelect({
          options: this.authTypeOptions,
          selectedValue: this.currentAuthType,
          onSelectChange: (value: string) => {
            this.handleAuthTypeChange(value);
          },
          selectSize: 'md'
        })
          .layoutWeight(1)
      }
      .width('100%')
      .padding($r('app.float.spacing_lg'))
      .alignItems(VerticalAlign.Center)

      // Auth fields based on type (wrapped in Scroll)
      Scroll() {
        Column() {
          if (this.currentAuthType === 'inherit') {
            this.buildInheritedAuthDisplay()
          } else if (this.currentAuthType === 'none') {
            this.buildNoAuthEditor()
          } else if (this.currentAuthType === 'basic') {
            this.buildBasicAuthEditor()
          } else if (this.currentAuthType === 'bearer') {
            this.buildBearerAuthEditor()
          } else if (this.currentAuthType === 'api-key') {
            this.buildApiKeyAuthEditor()
          } else if (this.currentAuthType === 'oauth2') {
            this.buildOAuth2Editor()
          }
        }
        .width('100%')
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .width('100%')
      .height('100%')
      .scrollBar(BarState.Auto)
      .align(Alignment.TopStart)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  /**
   * Handle auth type change
   */
  private handleAuthTypeChange(value: string): void {
    if (value === 'inherit') {
      // Set to 'none' to inherit from parent
      this.currentAuthType = 'inherit' as AuthType;
      this.auth.type = 'none';
      this.onChange(this.auth);
    } else {
      this.currentAuthType = value as AuthType;
      this.auth.type = value as AuthType;
      this.onChange(this.auth);
    }
  }

  @Builder
  buildInheritedAuthDisplay() {
    Column() {
      if (this.inheritedAuth !== null) {
        // Show inherited auth info
        Column() {
          Text('继承于')
            .fontSize($r('app.float.font_size_md'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ bottom: $r('app.float.spacing_xs') })

          // Source name (tappable)
          Text(this.getSourceDisplayName())
            .fontSize($r('app.float.font_size_lg'))
            .fontColor($r('app.color.primary'))
            .fontWeight(FontWeight.Medium)
            .onClick(() => {
              if (this.inheritedAuth !== null) {
                this.onNavigateToSource(this.inheritedAuth.sourceType, this.inheritedAuth.sourceId);
              }
            })

          // Auth type info
          Text(`(${this.getAuthTypeDisplayName(this.inheritedAuth.auth.type)})`)
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: $r('app.float.spacing_sm') })

          // Click to edit hint
          Text('点击触发编辑')
            .fontSize($r('app.float.font_size_xs'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: $r('app.float.spacing_md') })
        }
        .width('100%')
        .padding($r('app.float.spacing_2xl'))
        .alignItems(HorizontalAlign.Center)
      } else {
        // No inherited auth available
        Text('没有认证信息')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .textAlign(TextAlign.Center)
          .padding($r('app.float.spacing_2xl'))
      }
    }
    .width('100%')
    .layoutWeight(1)
  }

  /**
   * Get display name for source
   */
  private getSourceDisplayName(): string {
    if (this.inheritedAuth === null) {
      return '';
    }
    if (this.inheritedAuth.sourceType === 'workspace') {
      return 'Workspace';
    }
    return this.inheritedAuth.sourceName;
  }

  /**
   * Get display name for auth type
   */
  private getAuthTypeDisplayName(authType: AuthType): string {
    switch (authType) {
      case 'basic':
        return 'Basic Auth';
      case 'bearer':
        return 'Bearer Token';
      case 'api-key':
        return 'API Key';
      case 'oauth2':
        return 'OAuth 2.0';
      default:
        return 'No Auth';
    }
  }

  @Builder
  buildNoAuthEditor() {
    Column() {
      Text('没有认证信息')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .textAlign(TextAlign.Center)
        .padding($r('app.float.spacing_2xl'))
    }
    .width('100%')
    .layoutWeight(1)
  }

  @Builder
  buildBasicAuthEditor() {
    Column() {
      // Username Field
      Column() {
        Text('用户名')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.basic_username,
          placeholder: '输入用户名',
          onValueChange: (value: string) => {
            this.auth.basic_username = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_lg') })

      // Password Field
      Column() {
        Text('密码')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.basic_password,
          placeholder: '输入密码',
          inputType: InputType.Password,
          onValueChange: (value: string) => {
            this.auth.basic_password = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.spacing_lg'))
  }

  @Builder
  buildBearerAuthEditor() {
    Column() {
      Column() {
        Text('Token')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.bearer_token,
          placeholder: '输入bearer token',
          onValueChange: (value: string) => {
            this.auth.bearer_token = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.spacing_lg'))
  }

  @Builder
  buildApiKeyAuthEditor() {
    Column() {
      // Key Name Field
      Column() {
        Text('ApiKey名称')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.api_key_name,
          placeholder: '例如：X-API-Key',
          onValueChange: (value: string) => {
            this.auth.api_key_name = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_lg') })

      // Key Value Field
      Column() {
        Text('ApiKey')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.api_key_value,
          placeholder: '输入ApiKey',
          onValueChange: (value: string) => {
            this.auth.api_key_value = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_lg') })

      // Add To Field
      Column() {
        Text('添加到')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedSelect({
          options: this.apiKeyLocationOptions,
          selectedValue: this.auth.api_key_location,
          onSelectChange: (value: string) => {
            this.auth.api_key_location = value as 'header' | 'query';
            this.onChange(this.auth);
          },
          selectSize: 'md'
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.spacing_lg'))
  }

  @Builder
  buildOAuth2Editor() {
    Column() {
      // Access Token Field
      Column() {
        Text('Access Token')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.oauth2_access_token,
          placeholder: '输入access token',
          onValueChange: (value: string) => {
            this.auth.oauth2_access_token = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_lg') })

      // Refresh Token Field
      Column() {
        Text('Refresh Token (可选)')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.oauth2_refresh_token,
          placeholder: '输入refresh token',
          onValueChange: (value: string) => {
            this.auth.oauth2_refresh_token = value;
            this.onChange(this.auth);
          },
          inputSize: 'md'
        })
      }
      .width('100%')
    }
    .width('100%')
    .padding($r('app.float.spacing_lg'))
  }
}
