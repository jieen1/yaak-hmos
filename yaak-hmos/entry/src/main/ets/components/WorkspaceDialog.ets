/**
 * Workspace Dialog Component
 * Dialog for creating/editing workspaces
 */

import { Workspace, WorkspaceSettings } from '../model/Workspace';
import { ThemedTextInput } from './ThemedTextInput';

@CustomDialog
@ComponentV2
export struct WorkspaceDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: WorkspaceDialog()
  });

  @Param workspace: Workspace | null = null;
  @Param onSave: (workspace: Workspace) => void = () => {};

  @Local name: string = '';
  @Local description: string = '';
  @Local followRedirects: boolean = true;
  @Local validateCertificates: boolean = true;
  @Local timeout: number = 30000;
  @Local proxyEnabled: boolean = false;
  @Local proxyHost: string = '';
  @Local proxyPort: number = 0;

  aboutToAppear(): void {
    if (this.workspace) {
      this.name = this.workspace.name;
      this.description = this.workspace.description;
      this.followRedirects = this.workspace.settings.follow_redirects;
      this.validateCertificates = this.workspace.settings.validate_certificates;
      this.timeout = this.workspace.settings.request_timeout;
      this.proxyEnabled = this.workspace.settings.proxy_enabled;
      this.proxyHost = this.workspace.settings.proxy_host;
      this.proxyPort = this.workspace.settings.proxy_port;
    }
  }

  build() {
    Column() {
      // Dialog Title
      Text(this.workspace ? 'Edit Workspace' : 'New Workspace')
        .fontSize($r('app.float.font_size_xl'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_lg') })

      // Content
      Scroll() {
        Column() {
          // Basic Info
          this.buildBasicInfo();

          // Settings
          this.buildSettings();
        }
        .width('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .scrollBar(BarState.Auto)

      // Action Buttons
      Row() {
        Button('Cancel')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_primary'))
          .backgroundColor($r('app.color.surface'))
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_sm') })
          .onClick(() => {
            this.controller.close();
          })

        Button('Save')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.button_text'))
          .backgroundColor($r('app.color.primary'))
          .flexGrow(1)
          .margin({ left: $r('app.float.spacing_sm') })
          .enabled(this.name.trim().length > 0)
          .onClick(() => {
            this.handleSave();
          })
      }
      .width('100%')
      .margin({ top: $r('app.float.spacing_lg') })
    }
    .width('100%')
    .padding($r('app.float.spacing_lg'))
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildBasicInfo() {
    Column() {
      Text('Name *')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      ThemedTextInput({
        value: this.name,
        placeholder: 'Enter workspace name',
        onValueChange: (value: string) => {
          this.name = value;
        },
        inputSize: 'md'
      })
        .margin({ bottom: $r('app.float.spacing_md') })

      Text('Description')
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      ThemedTextInput({
        value: this.description,
        placeholder: 'Enter description (optional)',
        onValueChange: (value: string) => {
          this.description = value;
        },
        inputSize: 'md'
      })
        .margin({ bottom: $r('app.float.spacing_xl') })
    }
    .width('100%')
  }

  @Builder
  buildSettings() {
    Column() {
      Text('Settings')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_md') })

      // Follow Redirects
      Row() {
        Text('Follow Redirects')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .flexGrow(1)

        Toggle({ type: ToggleType.Switch, isOn: this.followRedirects })
          .selectedColor($r('app.color.primary'))
          .onChange((isOn: boolean) => {
            this.followRedirects = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_md') })

      // Validate Certificates
      Row() {
        Text('Validate SSL Certificates')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .flexGrow(1)

        Toggle({ type: ToggleType.Switch, isOn: this.validateCertificates })
          .selectedColor($r('app.color.primary'))
          .onChange((isOn: boolean) => {
            this.validateCertificates = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_md') })

      // Request Timeout
      Text(`Request Timeout: ${this.timeout / 1000}s`)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      Slider({
        value: this.timeout / 1000,
        min: 5,
        max: 120,
        step: 5,
        style: SliderStyle.OutSet
      })
        .width('100%')
        .trackColor($r('app.color.surface_highlight'))
        .selectedColor($r('app.color.primary'))
        .blockColor($r('app.color.primary'))
        .onChange((value: number) => {
          this.timeout = Math.round(value) * 1000;
        })
        .margin({ bottom: $r('app.float.spacing_md') })

      // Proxy Settings
      Row() {
        Text('Enable Proxy')
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .flexGrow(1)

        Toggle({ type: ToggleType.Switch, isOn: this.proxyEnabled })
          .selectedColor($r('app.color.primary'))
          .onChange((isOn: boolean) => {
            this.proxyEnabled = isOn;
          })
      }
      .width('100%')
      .margin({ bottom: $r('app.float.spacing_md') })

      if (this.proxyEnabled) {
        Column() {
          Text('Proxy Host')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_xs') })

          ThemedTextInput({
            value: this.proxyHost,
            placeholder: 'e.g., proxy.example.com',
            onValueChange: (value: string) => {
              this.proxyHost = value;
            },
            inputSize: 'md'
          })
            .margin({ bottom: $r('app.float.spacing_md') })

          Text('Proxy Port')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.text_secondary'))
            .width('100%')
            .margin({ bottom: $r('app.float.spacing_xs') })

          ThemedTextInput({
            value: this.proxyPort.toString(),
            placeholder: 'e.g., 8080',
            onValueChange: (value: string) => {
              const port: number = parseInt(value);
              if (!isNaN(port)) {
                this.proxyPort = port;
              }
            },
            inputType: InputType.Number,
            inputSize: 'md'
          })
        }
        .width('100%')
      }
    }
    .width('100%')
  }

  private handleSave(): void {
    if (this.name.trim().length === 0) {
      return;
    }

    const ws: Workspace = this.workspace || new Workspace();
    ws.name = this.name.trim();
    ws.description = this.description.trim();

    const settings: WorkspaceSettings = new WorkspaceSettings();
    settings.follow_redirects = this.followRedirects;
    settings.validate_certificates = this.validateCertificates;
    settings.request_timeout = this.timeout;
    settings.proxy_enabled = this.proxyEnabled;
    settings.proxy_host = this.proxyHost;
    settings.proxy_port = this.proxyPort;
    ws.settings = settings;

    if (!this.workspace) {
      ws.id = `ws_${Date.now()}`;
      ws.created_at = Date.now();
    }
    ws.updated_at = Date.now();

    this.onSave(ws);
    this.controller.close();
  }
}
