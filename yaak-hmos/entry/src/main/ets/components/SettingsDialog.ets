/**
 * Settings Dialog Component
 * 设置对话框 - 简洁统一的设置界面
 */

import { ThemedSelect, SelectOption } from './ThemedSelect';
import { PreferencesService, PreferenceKeys } from '../services/PreferencesService';
import EntryAbility from '../entryability/EntryAbility';

/**
 * Settings change callback interface
 */
export interface SettingsChangeCallback {
  onThemeChange?: (theme: string) => void;
  onInterfaceFontChange?: (font: string) => void;
  onInterfaceFontSizeChange?: (size: number) => void;
  onEditorFontChange?: (font: string) => void;
  onEditorFontSizeChange?: (size: number) => void;
  onEditorKeymapChange?: (keymap: string) => void;
  onSoftWrapChange?: (enabled: boolean) => void;
}

@ComponentV2
export struct SettingsDialog {
  @Param isVisible: boolean = false;
  @Param onClose: () => void = () => {};
  @Param onSettingsChange: SettingsChangeCallback = {};

  @Local selectedTab: string = 'theme';
  @Local isSettingsLoaded: boolean = false;

  // Settings values
  @Local themeValue: string = 'system';
  @Local interfaceFont: string = 'system';
  @Local interfaceFontSize: number = 14;
  @Local editorFont: string = 'system';
  @Local editorFontSize: number = 14;
  @Local editorKeymap: string = 'default';
  @Local softWrap: boolean = false;

  // Options
  private themeOptions: SelectOption[] = [
    { label: '浅色', value: 'light' },
    { label: '深色', value: 'dark' },
    { label: '跟随系统', value: 'system' }
  ];

  private fontOptions: SelectOption[] = [
    { label: '系统默认', value: 'system' },
    { label: 'HarmonyOS Sans', value: 'HarmonyOS Sans' },
    { label: 'Source Han Sans', value: 'Source Han Sans' },
    { label: 'Noto Sans SC', value: 'Noto Sans SC' }
  ];

  private monoFontOptions: SelectOption[] = [
    { label: '系统默认', value: 'system' },
    { label: 'JetBrains Mono', value: 'JetBrains Mono' },
    { label: 'Fira Code', value: 'Fira Code' },
    { label: 'Source Code Pro', value: 'Source Code Pro' },
    { label: 'Consolas', value: 'Consolas' }
  ];

  private fontSizeOptions: SelectOption[] = [
    { label: '12', value: '12' },
    { label: '13', value: '13' },
    { label: '14', value: '14' },
    { label: '15', value: '15' },
    { label: '16', value: '16' },
    { label: '18', value: '18' },
    { label: '20', value: '20' }
  ];

  private keymapOptions: SelectOption[] = [
    { label: 'Default', value: 'default' },
    { label: 'Vim', value: 'vim' },
    { label: 'Emacs', value: 'emacs' }
  ];

  aboutToAppear(): void {
    this.loadSettings();
  }

  private async loadSettings(): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();

      this.themeValue = await prefsService.getString(PreferenceKeys.THEME_MODE, 'system');
      this.interfaceFont = await prefsService.getString(PreferenceKeys.INTERFACE_FONT, 'system');
      this.interfaceFontSize = await prefsService.getNumber(PreferenceKeys.INTERFACE_FONT_SIZE, 14);
      this.editorFont = await prefsService.getString(PreferenceKeys.EDITOR_FONT, 'system');
      this.editorFontSize = await prefsService.getNumber(PreferenceKeys.EDITOR_FONT_SIZE, 14);
      this.editorKeymap = await prefsService.getString(PreferenceKeys.EDITOR_KEYMAP, 'default');
      this.softWrap = await prefsService.getBoolean(PreferenceKeys.EDITOR_SOFT_WRAP, false);

      this.isSettingsLoaded = true;
    } catch (error) {
      console.error('[SettingsDialog] Failed to load settings:', error);
      this.isSettingsLoaded = true;
    }
  }

  build() {
    if (this.isVisible) {
      Stack() {
        // 背景遮罩
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')
          .onClick(() => this.onClose())

        // 对话框
        Column() {
          // 标题栏
          Row() {
            Text('设置')
              .fontSize(18)
              .fontColor($r('app.color.text_primary'))
              .fontWeight(FontWeight.Medium)

            Blank()

            Text('×')
              .fontSize(24)
              .fontColor($r('app.color.text_secondary'))
              .onClick(() => this.onClose())
          }
          .width('100%')
          .height(52)
          .padding({ left: 20, right: 20 })
          .border({ width: { bottom: 1 }, color: $r('app.color.divider') })

          // 内容区
          Row() {
            // 左侧导航
            Column() {
              this.buildNavItem('主题', 'theme')
              this.buildNavItem('界面', 'interface')
              this.buildNavItem('关于', 'about')
            }
            .width(120)
            .height('100%')
            .padding({ top: 8 })
            .alignItems(HorizontalAlign.Start)

            // 分隔线
            Column()
              .width(1)
              .height('100%')
              .backgroundColor($r('app.color.divider'))

            // 右侧内容
            Scroll() {
              Column() {
                if (this.selectedTab === 'theme') {
                  this.buildThemeContent()
                } else if (this.selectedTab === 'interface') {
                  this.buildInterfaceContent()
                } else if (this.selectedTab === 'about') {
                  this.buildAboutContent()
                }
              }
              .width('100%')
              .padding(24)
              .alignItems(HorizontalAlign.Start)
            }
            .layoutWeight(1)
            .height('100%')
            .align(Alignment.TopStart)
          }
          .layoutWeight(1)
          .width('100%')
        }
        .width('65%')
        .height('70%')
        .backgroundColor($r('app.color.background'))
        .borderRadius(8)
        .clip(true)
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1000)
    }
  }

  @Builder
  buildNavItem(label: string, value: string) {
    Row() {
      // 选中指示条
      Column()
        .width(3)
        .height(18)
        .backgroundColor(this.selectedTab === value ? $r('app.color.primary') : Color.Transparent)
        .borderRadius(2)

      Text(label)
        .fontSize(14)
        .fontColor(this.selectedTab === value ? $r('app.color.primary') : $r('app.color.text_primary'))
        .margin({ left: 12 })
    }
    .width('100%')
    .height(38)
    .padding({ left: 8 })
    .backgroundColor(this.selectedTab === value ? $r('app.color.surface_highlight') : Color.Transparent)
    .onClick(() => {
      this.selectedTab = value;
    })
  }

  @Builder
  buildThemeContent() {
    Column() {
      // 颜色模式
      Text('颜色模式')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      ThemedSelect({
        options: this.themeOptions,
        selectedValue: this.themeValue,
        onSelectChange: (value: string) => {
          this.themeValue = value;
          this.saveThemeSetting(value);
        },
        selectSize: 'md',
        selectWidth: '100%'
      })
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildInterfaceContent() {
    Column() {
      // 界面字体
      Text('界面字体')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      Row() {
        ThemedSelect({
          options: this.fontOptions,
          selectedValue: this.interfaceFont,
          onSelectChange: (value: string) => {
            this.interfaceFont = value;
            this.saveInterfaceFont(value);
          },
          selectSize: 'lg',
          selectWidth: '50%'
        })
          .margin({right: $r('app.float.spacing_lg')})

        ThemedSelect({
          options: this.fontSizeOptions,
          selectedValue: this.interfaceFontSize.toString(),
          onSelectChange: (value: string) => {
            const size: number = parseInt(value);
            this.interfaceFontSize = size;
            this.saveInterfaceFontSize(size);
          },
          selectSize: 'lg',
          selectWidth: '50%'
        })

      }
      .width('100%')

      Column().height(20)

      // 编辑器字体
      Text('编辑器字体')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      Row() {
        ThemedSelect({
          options: this.monoFontOptions,
          selectedValue: this.editorFont,
          onSelectChange: (value: string) => {
            this.editorFont = value;
            this.saveEditorFont(value);
          },
          selectSize: 'md',
          selectWidth: '50%'
        })
          .margin({right: $r('app.float.spacing_lg')})

        ThemedSelect({
          options: this.fontSizeOptions,
          selectedValue: this.editorFontSize.toString(),
          onSelectChange: (value: string) => {
            const size: number = parseInt(value);
            this.editorFontSize = size;
            this.saveEditorFontSize(size);
          },
          selectSize: 'md',
          selectWidth: '50%'
        })
      }
      .width('100%')

      Column().height(20)

      // 编辑器快捷键
      Text('编辑器快捷键')
        .fontSize($r('app.float.font_size_lg'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ bottom: 8 })

      ThemedSelect({
        options: this.keymapOptions,
        selectedValue: this.editorKeymap,
        onSelectChange: (value: string) => {
          this.editorKeymap = value;
          this.saveEditorKeymap(value);
        },
        selectSize: 'md',
        selectWidth: '100%'
      })

      Column().height(20)

      // 复选框选项
      Row() {
        Checkbox()
          .select(this.softWrap)
          .selectedColor($r('app.color.primary'))
          .shape(CheckBoxShape.ROUNDED_SQUARE)
          .width(18)
          .height(18)
          .onChange((value: boolean) => {
            this.softWrap = value;
            this.saveSoftWrap(value);
          })

        Text('编辑器自动换行')
          .fontSize($r('app.float.font_size_lg'))
          .fontColor($r('app.color.text_primary'))
          .margin({ left: 10 })
      }
      .width('100%')
      .height(36)
      .alignItems(VerticalAlign.Center)
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  @Builder
  buildAboutContent() {
    Column() {
      Text('Flare')
        .fontSize(22)
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)

      Text('版本 1.0.0')
        .fontSize(13)
        .fontColor($r('app.color.text_secondary'))
        .margin({ top: 4 })

      Column().height(20)

      Text('HarmonyOS API 调试工具')
        .fontSize(14)
        .fontColor($r('app.color.text_secondary'))

      Column().height(12)

      Text('© 2025 Flare')
        .fontSize(12)
        .fontColor($r('app.color.text_tertiary'))
    }
    .width('100%')
    .alignItems(HorizontalAlign.Start)
  }

  // 保存方法
  private async saveThemeSetting(theme: string): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setString(PreferenceKeys.THEME_MODE, theme);

      const entryAbility = EntryAbility.getInstance();
      if (entryAbility !== null) {
        entryAbility.applyThemeMode(theme);
      }

      if (this.onSettingsChange.onThemeChange) {
        this.onSettingsChange.onThemeChange(theme);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save theme:', error);
    }
  }

  private async saveInterfaceFont(font: string): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setString(PreferenceKeys.INTERFACE_FONT, font);

      if (this.onSettingsChange.onInterfaceFontChange) {
        this.onSettingsChange.onInterfaceFontChange(font);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save interface font:', error);
    }
  }

  private async saveInterfaceFontSize(size: number): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setNumber(PreferenceKeys.INTERFACE_FONT_SIZE, size);

      if (this.onSettingsChange.onInterfaceFontSizeChange) {
        this.onSettingsChange.onInterfaceFontSizeChange(size);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save interface font size:', error);
    }
  }

  private async saveEditorFont(font: string): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setString(PreferenceKeys.EDITOR_FONT, font);

      if (this.onSettingsChange.onEditorFontChange) {
        this.onSettingsChange.onEditorFontChange(font);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save editor font:', error);
    }
  }

  private async saveEditorFontSize(size: number): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setNumber(PreferenceKeys.EDITOR_FONT_SIZE, size);

      if (this.onSettingsChange.onEditorFontSizeChange) {
        this.onSettingsChange.onEditorFontSizeChange(size);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save editor font size:', error);
    }
  }

  private async saveEditorKeymap(keymap: string): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setString(PreferenceKeys.EDITOR_KEYMAP, keymap);

      if (this.onSettingsChange.onEditorKeymapChange) {
        this.onSettingsChange.onEditorKeymapChange(keymap);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save editor keymap:', error);
    }
  }

  private async saveSoftWrap(enabled: boolean): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.setBoolean(PreferenceKeys.EDITOR_SOFT_WRAP, enabled);

      if (this.onSettingsChange.onSoftWrapChange) {
        this.onSettingsChange.onSoftWrapChange(enabled);
      }
    } catch (error) {
      console.error('[SettingsDialog] Failed to save soft wrap:', error);
    }
  }
}
