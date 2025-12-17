/**
 * Theme Manager
 * Manages application theme with State Management V2
 * Supports light, dark, and auto (system) theme modes
 */

import ConfigurationConstant from '@ohos.app.ability.ConfigurationConstant';

export type ThemeMode = 'light' | 'dark' | 'auto';

@ObservedV2
export class ThemeManager {
  private static instance: ThemeManager;

  @Trace isDark: boolean = false;
  @Trace followSystem: boolean = true;
  @Trace themeMode: ThemeMode = 'auto';

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  /**
   * Initialize theme with system color mode
   */
  public init(systemColorMode: ConfigurationConstant.ColorMode): void {
    if (this.followSystem) {
      this.setSystemColorMode(systemColorMode);
    }
  }

  /**
   * Set system color mode (called when system theme changes)
   */
  public setSystemColorMode(colorMode: ConfigurationConstant.ColorMode): void {
    if (this.followSystem) {
      this.isDark = colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
      console.info(`ThemeManager: System color mode changed to ${this.isDark ? 'dark' : 'light'}`);
    }
  }

  /**
   * Toggle between light and dark theme
   */
  public toggleTheme(): void {
    this.isDark = !this.isDark;
    this.followSystem = false;
    this.themeMode = this.isDark ? 'dark' : 'light';
    console.info(`ThemeManager: Theme toggled to ${this.themeMode}`);
  }

  /**
   * Set theme mode explicitly
   */
  public setThemeMode(mode: ThemeMode): void {
    this.themeMode = mode;

    if (mode === 'auto') {
      this.followSystem = true;
      // Will be updated by system color mode
    } else {
      this.followSystem = false;
      this.isDark = mode === 'dark';
    }

    console.info(`ThemeManager: Theme mode set to ${mode}`);
  }

  /**
   * Enable or disable auto-theme (follow system)
   */
  public setFollowSystem(follow: boolean, systemColorMode?: ConfigurationConstant.ColorMode): void {
    this.followSystem = follow;

    if (follow && systemColorMode !== undefined) {
      this.setSystemColorMode(systemColorMode);
      this.themeMode = 'auto';
    }

    console.info(`ThemeManager: Follow system set to ${follow}`);
  }

  /**
   * Get current theme mode
   */
  public getThemeMode(): ThemeMode {
    return this.themeMode;
  }

  /**
   * Check if current theme is dark
   */
  public isDarkMode(): boolean {
    return this.isDark;
  }

  /**
   * Check if following system theme
   */
  public isFollowingSystem(): boolean {
    return this.followSystem;
  }
}
