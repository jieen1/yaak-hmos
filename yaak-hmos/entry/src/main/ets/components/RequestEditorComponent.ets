/**
 * Request Editor Component
 * Main editor for HTTP requests with tabs for Params, Headers, Body, Auth
 */

import { HttpRequest } from '../model/HttpRequest';
import { HttpMethod } from '../model/Types';
import { ThemedSelect, SelectOption } from './ThemedSelect';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';
import { QueryParamsEditor } from './QueryParamsEditor';
import { HeadersEditor } from './HeadersEditor';
import { BodyEditor } from './BodyEditor';
import { AuthEditor } from './AuthEditor';

@ComponentV2
export struct RequestEditorComponent {
  @Param request: HttpRequest = new HttpRequest();
  @Param onExecute: () => void = () => {};
  @Param onCancel: () => void = () => {};
  @Param onCopyAsCurl: () => void = () => {};
  @Param isLoading: boolean = false;
  @Param onChange: (request: HttpRequest) => void | Promise<void> = () => {};

  @Local activeTab: number = 0;

  private methodOptions: SelectOption[] = [
    { label: 'GET', value: 'GET' },
    { label: 'POST', value: 'POST' },
    { label: 'PUT', value: 'PUT' },
    { label: 'DELETE', value: 'DELETE' },
    { label: 'PATCH', value: 'PATCH' },
    { label: 'HEAD', value: 'HEAD' },
    { label: 'OPTIONS', value: 'OPTIONS' }
  ];

  build() {
    Column() {
      // Request line (Method, URL, Send button)
      Row() {
        // Method selector
        ThemedSelect({
          options: this.methodOptions,
          selectedValue: this.request.method,
          onSelectChange: (value: string) => {
            this.request.method = value as HttpMethod;
            this.onChange(this.request);
          },
          selectSize: 'md'
        })
          .width(100)
          .flexShrink(0)
          .margin({ right: $r('app.float.spacing_sm') })

        // URL input
        ThemedTextInput({
          value: this.request.url,
          placeholder: 'Enter request URL',
          onValueChange: (value: string) => {
            this.request.url = value;
            this.onChange(this.request);
          },
          inputSize: 'md'
        })
          .layoutWeight(1)
          .margin({ right: $r('app.float.spacing_sm') })

        // Copy as cURL button
        Button() {
          Text('📋')
            .fontSize(18)
        }
        .type(ButtonType.Normal)
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_sm'))
        .width(36)
        .height(36)
        .margin({ right: $r('app.float.spacing_xs') })
        .onClick(() => {
          this.onCopyAsCurl();
        })

        // Send/Cancel button
        if (this.isLoading) {
          ThemedButton({
            text: 'Cancel',
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
            text: 'Send',
            onButtonClick: () => {
              this.onExecute();
            },
            buttonSize: 'md'
          })
            .width(80)
            .flexShrink(0)
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
        .tabBar('Params')

        TabContent() {
          HeadersEditor({
            headers: this.request.headers,
            onChange: (headers) => {
              this.request.headers = headers;
              this.onChange(this.request);
            }
          })
        }
        .tabBar('Headers')

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
        .tabBar('Body')

        TabContent() {
          AuthEditor({
            auth: this.request.auth,
            onChange: (auth) => {
              this.request.auth = auth;
              this.onChange(this.request);
            }
          })
        }
        .tabBar('Auth')
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
}
