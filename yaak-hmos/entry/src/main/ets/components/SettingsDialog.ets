/**
 * Settings Dialog Component
 * Application settings dialog
 */

import { ThemedSelect, SelectOption } from './ThemedSelect';

interface AppSettings {
  theme: string;
  editorFontSize: number;
  interfaceFontSize: number;
  editorKeymap: string;
  softWrap: boolean;
}

@CustomDialog
@ComponentV2
export struct SettingsDialog {
  controller: CustomDialogController = new CustomDialogController({
    builder: SettingsDialog()
  });

  @Local settings: AppSettings = {
    theme: 'system',
    editorFontSize: 14,
    interfaceFontSize: 14,
    editorKeymap: 'default',
    softWrap: false
  };

  @Param onSave: (settings: AppSettings) => void = () => {};

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

  build() {
    Column() {
      // Dialog Title
      Text('Settings')
        .fontSize($r('app.float.font_size_xl'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_lg') })

      // Settings Content
      Scroll() {
        Column() {
          // Appearance Section
          this.buildSection('Appearance', () => {
            this.buildAppearanceSettings();
          });

          // Editor Section
          this.buildSection('Editor', () => {
            this.buildEditorSettings();
          });

          // Interface Section
          this.buildSection('Interface', () => {
            this.buildInterfaceSettings();
          });
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
          .onClick(() => {
            this.onSave(this.settings);
            this.controller.close();
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
  buildSection(title: string, content: () => void) {
    Column() {
      Text(title)
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_md') })

      content();
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_xl') })
  }

  @Builder
  buildAppearanceSettings() {
    Column() {
      Text('Theme')
        .fontSize($r('app.float.font_size_sm'))
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
        .fontSize($r('app.float.font_size_sm'))
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
        .fontSize($r('app.float.font_size_sm'))
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
          .fontSize($r('app.float.font_size_sm'))
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
}
