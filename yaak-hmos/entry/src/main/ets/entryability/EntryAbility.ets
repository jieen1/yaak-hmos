import { AbilityConstant, ConfigurationConstant, UIAbility, Want, Configuration } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';
import { DatabaseManager } from '../database/DatabaseManager';
import { ThemeManager } from '../theme/ThemeManager';

const DOMAIN = 0x0000;

export default class EntryAbility extends UIAbility {
  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(DOMAIN, 'testTag', '%{public}s', 'Ability onCreate');
    
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
