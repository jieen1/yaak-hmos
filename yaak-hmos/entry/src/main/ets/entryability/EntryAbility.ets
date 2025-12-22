import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { ThemeManager } from '../theme/ThemeManager';
import { ContinuationService } from '../services/ContinuationService';
import type { ContinuationData } from '../services/ContinuationService';
import { PreferencesService, PreferenceKeys } from '../services/PreferencesService';
import { FontSettings } from '../services/FontService';

const DOMAIN = 0x0000;
const CONTINUATION_DATA_KEY = 'flare_continuation_data';

export default class EntryAbility extends UIAbility {
  private continuationData: ContinuationData | null = null;
  private static instance: EntryAbility | null = null;

  /**
   * Get singleton instance for accessing from other components
   */
  public static getInstance(): EntryAbility | null {
    return EntryAbility.instance;
  }

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    EntryAbility.instance = this;
    
    // Check for continuation data
    this.handleContinuation(want, launchParam);
    
    try {
      // Initialize ThemeManager with system color mode
      const config = this.context.config;
      if (config && config.colorMode !== undefined) {
        ThemeManager.getInstance().init(config.colorMode);
        hilog.info(DOMAIN, 'testTag', 'ThemeManager initialized with color mode: %{public}d', config.colorMode);
      } else {
        // Default to light mode if system color mode is not available
        ThemeManager.getInstance().init(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
        hilog.info(DOMAIN, 'testTag', 'ThemeManager initialized with default light mode');
      }
      
      // Load and apply saved theme preference
      this.loadAndApplySavedTheme();
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize ThemeManager. Cause: %{public}s', JSON.stringify(err));
    }
    
    try {
      // Initialize Database
      DatabaseManager.getInstance().init(this.context);
      hilog.info(DOMAIN, 'testTag', 'DatabaseManager initialized');
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to initialize DatabaseManager. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * Load saved theme preference and apply it
   */
  private async loadAndApplySavedTheme(): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      await prefsService.init(this.context);
      
      const savedTheme: string = await prefsService.getString(PreferenceKeys.THEME_MODE, 'system');
      hilog.info(DOMAIN, 'testTag', 'Loaded saved theme: %{public}s', savedTheme);
      
      this.applyThemeMode(savedTheme);
      
      // Load and apply font settings
      await this.loadAndApplyFontSettings(prefsService);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to load saved theme. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * Load and apply font settings from preferences
   */
  private async loadAndApplyFontSettings(prefsService: PreferencesService): Promise<void> {
    try {
      const interfaceFont: string = await prefsService.getString(PreferenceKeys.INTERFACE_FONT, 'system');
      const interfaceFontSize: number = await prefsService.getNumber(PreferenceKeys.INTERFACE_FONT_SIZE, 14);
      const editorFont: string = await prefsService.getString(PreferenceKeys.EDITOR_FONT, 'system');
      const editorFontSize: number = await prefsService.getNumber(PreferenceKeys.EDITOR_FONT_SIZE, 14);
      
      // 使用 FontSettings 单例
      const fontSettings = FontSettings.getInstance();
      fontSettings.init(interfaceFont, interfaceFontSize, editorFont, editorFontSize);
      
      hilog.info(DOMAIN, 'testTag', 'Font settings loaded: interface=%{public}s/%{public}d, editor=%{public}s/%{public}d',
        interfaceFont, interfaceFontSize, editorFont, editorFontSize);
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to load font settings. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * Apply theme mode to the application
   * @param themeMode - 'light', 'dark', or 'system'
   */
  public applyThemeMode(themeMode: string): void {
    try {
      const appContext = this.context.getApplicationContext();
      const themeManager = ThemeManager.getInstance();
      
      if (themeMode === 'dark') {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_DARK);
        themeManager.setThemeMode('dark');
        hilog.info(DOMAIN, 'testTag', 'Applied dark theme');
      } else if (themeMode === 'light') {
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT);
        themeManager.setThemeMode('light');
        hilog.info(DOMAIN, 'testTag', 'Applied light theme');
      } else {
        // system / auto - follow system color mode
        appContext.setColorMode(ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET);
        themeManager.setThemeMode('auto');
        hilog.info(DOMAIN, 'testTag', 'Applied system theme (follow system)');
      }
    } catch (err) {
      hilog.error(DOMAIN, 'testTag', 'Failed to apply theme mode. Cause: %{public}s', JSON.stringify(err));
    }
  }

  /**
   * Handle continuation from another device
   */
  private handleContinuation(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    // Check if this is a continuation launch
    if (launchParam.launchReason === AbilityConstant.LaunchReason.CONTINUATION) {
      hilog.info(DOMAIN, 'testTag', 'Launched via continuation');
      
      // Extract continuation data from want
      if (want.parameters && want.parameters[CONTINUATION_DATA_KEY]) {
        const dataStr = want.parameters[CONTINUATION_DATA_KEY] as string;
        this.continuationData = ContinuationService.deserializeContinuationData(dataStr);
        
        if (this.continuationData !== null) {
          hilog.info(DOMAIN, 'testTag', 'Continuation data received for request: %{public}s', 
            this.continuationData.requestId);
          
          // Notify ContinuationService
          ContinuationService.getInstance().receiveContinuation(this.continuationData);
        }
      }
    }
  }

  /**
   * Called when continuation is requested
   */
  onContinue(wantParam: Record<string, Object>): AbilityConstant.OnContinueResult {
    hilog.info(DOMAIN, 'testTag', 'onContinue called');
    
    // Get pending continuation data
    const continuationService = ContinuationService.getInstance();
    const data = continuationService.getPendingContinuationData();
    
    if (data !== null) {
      // Serialize and store in want parameters
      wantParam[CONTINUATION_DATA_KEY] = ContinuationService.serializeContinuationData(data);
      continuationService.clearPendingContinuationData();
      
      hilog.info(DOMAIN, 'testTag', 'Continuation data prepared for transfer');
      return AbilityConstant.OnContinueResult.AGREE;
    }
    
    return AbilityConstant.OnContinueResult.REJECT;
  }

  onNewWant(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', 'onNewWant called');
    
    // Handle continuation when app is already running
    this.handleContinuation(want, launchParam);
  }

  onConfigurationUpdate(newConfig: Configuration): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onConfigurationUpdate');
    
    // Listen to system theme changes and update ThemeManager
    if (newConfig.colorMode !== undefined) {
      ThemeManager.getInstance().setSystemColorMode(newConfig.colorMode);
      hilog.info(DOMAIN, 'testTag', 'System color mode updated to: %{public}d', newConfig.colorMode);
    }
  }

  onDestroy(): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage): void {
    // Main window is created, set main page for this ability
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageCreate');

    windowStage.loadContent('pages/Index', (err) => {
      if (err.code) {
        hilog.error(DOMAIN, 'testTag', 'Failed to load the content. Cause: %{public}s', JSON.stringify(err));
        return;
      }
      hilog.info(DOMAIN, 'testTag', 'Succeeded in loading the content.');
    });
  }

  onWindowStageDestroy(): void {
    // Main window is destroyed, release UI related resources
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onWindowStageDestroy');
  }

  onForeground(): void {
    // Ability has brought to foreground
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onForeground');
  }

  onBackground(): void {
    // Ability has back to background
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onBackground');
  }
}
