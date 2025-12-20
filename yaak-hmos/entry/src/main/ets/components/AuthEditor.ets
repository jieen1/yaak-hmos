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
        Text('Auth Type')
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
          Text('Inherited from')
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
          Text('Click to edit')
            .fontSize($r('app.float.font_size_xs'))
            .fontColor($r('app.color.text_secondary'))
            .margin({ top: $r('app.float.spacing_md') })
        }
        .width('100%')
        .padding($r('app.float.spacing_2xl'))
        .alignItems(HorizontalAlign.Center)
      } else {
        // No inherited auth available
        Text('No authentication')
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
      Text('No authentication')
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
        Text('Username')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.basic_username,
          placeholder: 'Enter username',
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
        Text('Password')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.basic_password,
          placeholder: 'Enter password',
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
          placeholder: 'Enter bearer token',
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
        Text('Key Name')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.api_key_name,
          placeholder: 'e.g., X-API-Key',
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
        Text('Key Value')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.api_key_value,
          placeholder: 'Enter API key',
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
        Text('Add To')
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
          placeholder: 'Enter access token',
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
        Text('Refresh Token (Optional)')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_secondary'))
          .width('100%')
          .margin({ bottom: $r('app.float.spacing_xs') })

        ThemedTextInput({
          value: this.auth.oauth2_refresh_token,
          placeholder: 'Enter refresh token',
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
