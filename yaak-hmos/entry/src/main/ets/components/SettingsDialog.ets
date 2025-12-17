/**
 * Settings Dialog Component
 * Application settings dialog
 */

import { ThemedButton } from '.';
import { ThemedSelect, SelectOption } from './ThemedSelect';

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

  @Local settings: AppSettings = {
    theme: 'system',
    editorFontSize: 14,
    interfaceFontSize: 14,
    editorKeymap: 'default',
    softWrap: false
  };

  @Local selectedTab: string = 'appearance';

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
                if (this.selectedTab === 'appearance') {
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
    }
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
      Text('Yaak for HarmonyOS')
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

      Text('© 2024 Yaak. All rights reserved.')
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_tertiary'))
        .width('100%')
        .textAlign(TextAlign.Center)
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
  }
}
