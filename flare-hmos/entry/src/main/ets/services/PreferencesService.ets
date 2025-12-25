/**
 * PreferencesService
 * Utility service for managing application preferences
 * Provides type-safe access to persistent storage
 */

import preferences from '@ohos.data.preferences';
import type common from '@ohos.app.ability.common';

const PREFERENCES_NAME = 'flare_preferences';

export class PreferencesService {
  private static instance: PreferencesService | null = null;
  private store: preferences.Preferences | null = null;
  private context: common.UIAbilityContext | null = null;

  private constructor() {}

  static getInstance(): PreferencesService {
    if (PreferencesService.instance === null) {
      PreferencesService.instance = new PreferencesService();
    }
    return PreferencesService.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.context = context;
    try {
      this.store = await preferences.getPreferences(context, PREFERENCES_NAME);
      console.info('[PreferencesService] Initialized successfully');
    } catch (error) {
      console.error('[PreferencesService] Failed to initialize:', JSON.stringify(error));
      throw new Error('Failed to initialize preferences');
    }
  }

  async getString(key: string, defaultValue: string): Promise<string> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return defaultValue;
    }

    try {
      const value: preferences.ValueType = await this.store.get(key, defaultValue);
      return value as string;
    } catch (error) {
      console.error(`[PreferencesService] Failed to get string for key ${key}:`, JSON.stringify(error));
      return defaultValue;
    }
  }

  async getNumber(key: string, defaultValue: number): Promise<number> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return defaultValue;
    }

    try {
      const value: preferences.ValueType = await this.store.get(key, defaultValue);
      return value as number;
    } catch (error) {
      console.error(`[PreferencesService] Failed to get number for key ${key}:`, JSON.stringify(error));
      return defaultValue;
    }
  }

  async getBoolean(key: string, defaultValue: boolean): Promise<boolean> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return defaultValue;
    }

    try {
      const value: preferences.ValueType = await this.store.get(key, defaultValue);
      return value as boolean;
    } catch (error) {
      console.error(`[PreferencesService] Failed to get boolean for key ${key}:`, JSON.stringify(error));
      return defaultValue;
    }
  }

  async setString(key: string, value: string): Promise<void> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return;
    }

    try {
      await this.store.put(key, value);
      await this.store.flush();
      console.info(`[PreferencesService] Set string: ${key} = ${value}`);
    } catch (error) {
      console.error(`[PreferencesService] Failed to set string for key ${key}:`, JSON.stringify(error));
    }
  }

  async setNumber(key: string, value: number): Promise<void> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return;
    }

    try {
      await this.store.put(key, value);
      await this.store.flush();
      console.info(`[PreferencesService] Set number: ${key} = ${value}`);
    } catch (error) {
      console.error(`[PreferencesService] Failed to set number for key ${key}:`, JSON.stringify(error));
    }
  }

  async setBoolean(key: string, value: boolean): Promise<void> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return;
    }

    try {
      await this.store.put(key, value);
      await this.store.flush();
      console.info(`[PreferencesService] Set boolean: ${key} = ${value}`);
    } catch (error) {
      console.error(`[PreferencesService] Failed to set boolean for key ${key}:`, JSON.stringify(error));
    }
  }

  async remove(key: string): Promise<void> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return;
    }

    try {
      await this.store.delete(key);
      await this.store.flush();
      console.info(`[PreferencesService] Removed key: ${key}`);
    } catch (error) {
      console.error(`[PreferencesService] Failed to remove key ${key}:`, JSON.stringify(error));
    }
  }

  async clear(): Promise<void> {
    if (!this.store) {
      console.warn('[PreferencesService] Store not initialized');
      return;
    }

    try {
      await this.store.clear();
      await this.store.flush();
      console.info('[PreferencesService] Cleared all preferences');
    } catch (error) {
      console.error('[PreferencesService] Failed to clear preferences:', JSON.stringify(error));
    }
  }
}

// Preference key constants
export class PreferenceKeys {
  static readonly SIDEBAR_WIDTH_PREFIX: string = 'sidebar_width_';
  static readonly SIDEBAR_HIDDEN_PREFIX: string = 'sidebar_hidden_';
  static readonly RESPONSE_WIDTH_PREFIX: string = 'response_width_';
  static readonly RESPONSE_VIEWER_HIDDEN: string = 'response_viewer_hidden';
  static readonly VIEW_MODE_PREFIX: string = 'view_mode_';
  static readonly ACTIVE_TAB_PREFIX: string = 'active_tab_';
  static readonly PRIVACY_POLICY_ACCEPTED: string = 'privacy_policy_accepted';
  static readonly SYNC_AUTO_ENABLED: string = 'sync_auto_enabled';
  static readonly SYNC_WIFI_ONLY: string = 'sync_wifi_only';
  static readonly SYNC_SENSITIVE_DATA: string = 'sync_sensitive_data';
  
  // Appearance settings
  static readonly THEME_MODE: string = 'theme_mode';
  
  // Font settings
  static readonly INTERFACE_FONT: string = 'interface_font';
  static readonly INTERFACE_FONT_SIZE: string = 'interface_font_size';
  static readonly EDITOR_FONT: string = 'editor_font';
  static readonly EDITOR_FONT_SIZE: string = 'editor_font_size';
  
  // Editor settings
  static readonly EDITOR_KEYMAP: string = 'editor_keymap';
  static readonly EDITOR_SOFT_WRAP: string = 'editor_soft_wrap';

  static getSidebarWidthKey(workspaceId: string): string {
    return `${PreferenceKeys.SIDEBAR_WIDTH_PREFIX}${workspaceId}`;
  }

  static getSidebarHiddenKey(workspaceId: string): string {
    return `${PreferenceKeys.SIDEBAR_HIDDEN_PREFIX}${workspaceId}`;
  }

  static getResponseWidthKey(workspaceId: string): string {
    return `${PreferenceKeys.RESPONSE_WIDTH_PREFIX}${workspaceId}`;
  }

  static getViewModeKey(requestId: string): string {
    return `${PreferenceKeys.VIEW_MODE_PREFIX}${requestId}`;
  }

  static getActiveTabKey(requestId: string): string {
    return `${PreferenceKeys.ACTIVE_TAB_PREFIX}${requestId}`;
  }
}
