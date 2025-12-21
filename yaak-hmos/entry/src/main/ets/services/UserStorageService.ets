/**
 * UserStorageService - Secure storage for user information
 * Handles persistence and encryption of user data
 */

import { preferences } from '@kit.ArkData';
import type { UserInfo } from './AuthService';
import type common from '@ohos.app.ability.common';

const USER_PREFERENCES_NAME = 'flare_user_storage';
const USER_INFO_KEY = 'user_info';
const SYNC_OPTIONS_KEY = 'sync_options';

/**
 * Sync options interface
 */
export interface SyncOptions {
  autoSync: boolean;
  wifiOnly: boolean;
  syncInterval: number;
  syncSensitiveData: boolean;
  lastSyncTime: number;
}

/**
 * Default sync options
 */
const DEFAULT_SYNC_OPTIONS: SyncOptions = {
  autoSync: true,
  wifiOnly: false,
  syncInterval: 30000,
  syncSensitiveData: true,
  lastSyncTime: 0
};

/**
 * UserStorageService - Manages user data persistence
 */
export class UserStorageService {
  private static instance: UserStorageService | null = null;
  private dataPreferences: preferences.Preferences | null = null;
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): UserStorageService {
    if (UserStorageService.instance === null) {
      UserStorageService.instance = new UserStorageService();
    }
    return UserStorageService.instance;
  }

  /**
   * Initialize storage service
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      this.dataPreferences = await preferences.getPreferences(context, USER_PREFERENCES_NAME);
      this.isInitialized = true;
      console.info('[UserStorageService] Initialized successfully');
    } catch (error) {
      console.error('[UserStorageService] Initialize failed:', error);
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }

  /**
   * Save user info to storage
   */
  async saveUserInfo(userInfo: UserInfo): Promise<void> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return;
    }

    try {
      const userJson = JSON.stringify(userInfo);
      await this.dataPreferences.put(USER_INFO_KEY, userJson);
      await this.dataPreferences.flush();
      console.info('[UserStorageService] User info saved');
    } catch (error) {
      console.error('[UserStorageService] Save user info failed:', error);
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }

  /**
   * Load user info from storage
   */
  async loadUserInfo(): Promise<UserInfo | null> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return null;
    }

    try {
      const userJson = await this.dataPreferences.get(USER_INFO_KEY, '') as string;
      
      if (userJson === '' || userJson.length === 0) {
        return null;
      }

      const parsed: ESObject = JSON.parse(userJson) as ESObject;
      
      const userInfo: UserInfo = {
        unionId: String(parsed.unionId || ''),
        openId: String(parsed.openId || ''),
        displayName: String(parsed.displayName || ''),
        avatarUrl: String(parsed.avatarUrl || ''),
        email: String(parsed.email || ''),
        isLoggedIn: Boolean(parsed.isLoggedIn),
        loginTime: Number(parsed.loginTime || 0)
      };

      console.info('[UserStorageService] User info loaded');
      return userInfo;
    } catch (error) {
      console.error('[UserStorageService] Load user info failed:', error);
      return null;
    }
  }

  /**
   * Clear user info from storage
   */
  async clearUserInfo(): Promise<void> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return;
    }

    try {
      await this.dataPreferences.delete(USER_INFO_KEY);
      await this.dataPreferences.flush();
      console.info('[UserStorageService] User info cleared');
    } catch (error) {
      console.error('[UserStorageService] Clear user info failed:', error);
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }

  /**
   * Save sync options to storage
   */
  async saveSyncOptions(options: SyncOptions): Promise<void> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return;
    }

    try {
      const optionsJson = JSON.stringify(options);
      await this.dataPreferences.put(SYNC_OPTIONS_KEY, optionsJson);
      await this.dataPreferences.flush();
      console.info('[UserStorageService] Sync options saved');
    } catch (error) {
      console.error('[UserStorageService] Save sync options failed:', error);
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }

  /**
   * Load sync options from storage
   */
  async loadSyncOptions(): Promise<SyncOptions> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return DEFAULT_SYNC_OPTIONS;
    }

    try {
      const optionsJson = await this.dataPreferences.get(SYNC_OPTIONS_KEY, '') as string;
      
      if (optionsJson === '' || optionsJson.length === 0) {
        return DEFAULT_SYNC_OPTIONS;
      }

      const parsed: ESObject = JSON.parse(optionsJson) as ESObject;
      
      const options: SyncOptions = {
        autoSync: parsed.autoSync !== undefined ? Boolean(parsed.autoSync) : DEFAULT_SYNC_OPTIONS.autoSync,
        wifiOnly: parsed.wifiOnly !== undefined ? Boolean(parsed.wifiOnly) : DEFAULT_SYNC_OPTIONS.wifiOnly,
        syncInterval: parsed.syncInterval !== undefined ? Number(parsed.syncInterval) : DEFAULT_SYNC_OPTIONS.syncInterval,
        syncSensitiveData: parsed.syncSensitiveData !== undefined ? Boolean(parsed.syncSensitiveData) : DEFAULT_SYNC_OPTIONS.syncSensitiveData,
        lastSyncTime: parsed.lastSyncTime !== undefined ? Number(parsed.lastSyncTime) : DEFAULT_SYNC_OPTIONS.lastSyncTime
      };

      console.info('[UserStorageService] Sync options loaded');
      return options;
    } catch (error) {
      console.error('[UserStorageService] Load sync options failed:', error);
      return DEFAULT_SYNC_OPTIONS;
    }
  }

  /**
   * Update last sync time
   */
  async updateLastSyncTime(): Promise<void> {
    const options = await this.loadSyncOptions();
    options.lastSyncTime = Date.now();
    await this.saveSyncOptions(options);
  }

  /**
   * Clear all user data
   */
  async clearAll(): Promise<void> {
    if (this.dataPreferences === null) {
      console.error('[UserStorageService] Not initialized');
      return;
    }

    try {
      await this.dataPreferences.clear();
      await this.dataPreferences.flush();
      console.info('[UserStorageService] All data cleared');
    } catch (error) {
      console.error('[UserStorageService] Clear all failed:', error);
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }

  /**
   * Check if user is stored
   */
  async hasStoredUser(): Promise<boolean> {
    const userInfo = await this.loadUserInfo();
    return userInfo !== null && userInfo.isLoggedIn;
  }
}
