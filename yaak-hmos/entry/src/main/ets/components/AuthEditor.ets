/**
 * Auth Editor Component
 * Edits authentication configuration for requests
 */

import { AuthConfig } from '../model/HttpRequest';
import { AuthType } from '../model/Types';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { ThemedTextInput } from './ThemedTextInput';

@ComponentV2
export struct AuthEditor {
  @Param auth: AuthConfig = new AuthConfig();
  @Param onChange: (auth: AuthConfig) => void = () => {};

  private authTypeOptions: SelectOption[] = [
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

  build() {
    Column() {
      // Auth type selector
      Row() {
        Text('Auth Type:')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .margin({ right: $r('app.float.spacing_md') })

        ThemedSelect({
          options: this.authTypeOptions,
          selectedValue: this.auth.type,
          onSelectChange: (value: string) => {
            this.auth.type = value as AuthType;
            this.onChange(this.auth);
          },
          selectSize: 'sm'
        })
          .width(200)
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))

      // Auth fields based on type
      if (this.auth.type === 'none') {
        this.buildNoAuthEditor()
      } else if (this.auth.type === 'basic') {
        this.buildBasicAuthEditor()
      } else if (this.auth.type === 'bearer') {
        this.buildBearerAuthEditor()
      } else if (this.auth.type === 'api-key') {
        this.buildApiKeyAuthEditor()
      } else if (this.auth.type === 'oauth2') {
        this.buildOAuth2Editor()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
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
        }
      })
        .margin({ bottom: $r('app.float.spacing_md') })

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
        }
      })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .layoutWeight(1)
  }

  @Builder
  buildBearerAuthEditor() {
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
        }
      })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .layoutWeight(1)
  }

  @Builder
  buildApiKeyAuthEditor() {
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
        }
      })
        .margin({ bottom: $r('app.float.spacing_md') })

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
        }
      })
        .margin({ bottom: $r('app.float.spacing_md') })

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
        }
      })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .layoutWeight(1)
  }

  @Builder
  buildOAuth2Editor() {
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
        }
      })
        .margin({ bottom: $r('app.float.spacing_md') })

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
        }
      })
    }
    .width('100%')
    .padding($r('app.float.spacing_md'))
    .layoutWeight(1)
  }
}
