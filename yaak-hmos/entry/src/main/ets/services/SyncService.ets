/**
 * SyncService - Cloud data synchronization service
 * Manages bidirectional sync between local and cloud storage
 */

import { SyncQueue } from './SyncQueue';
import type { SyncQueueItem, SyncEntityType, SyncAction } from './SyncQueue';
import { NetworkService } from './NetworkService';
import type { NetworkStatus } from './NetworkService';
import { SyncError } from '../common/FlareError';
import type common from '@ohos.app.ability.common';

/**
 * Sync status interface
 */
export interface SyncStatus {
  isOnline: boolean;
  isSyncing: boolean;
  lastSyncTime: number;
  pendingChanges: number;
  error: string | null;
}

/**
 * Sync options interface
 */
export interface SyncServiceOptions {
  autoSync: boolean;
  wifiOnly: boolean;
  syncInterval: number;
  syncSensitiveData: boolean;
}

/**
 * Sync status callback type
 */
export type SyncStatusCallback = (status: SyncStatus) => void;

/**
 * Default sync options
 */
const DEFAULT_OPTIONS: SyncServiceOptions = {
  autoSync: true,
  wifiOnly: false,
  syncInterval: 30000,
  syncSensitiveData: true
};

/**
 * SyncService - Manages data synchronization
 */
export class SyncService {
  private static instance: SyncService | null = null;
  private syncQueue: SyncQueue;
  private networkService: NetworkService;
  private options: SyncServiceOptions;
  private status: SyncStatus;
  private callbacks: SyncStatusCallback[] = [];
  private syncTimer: number | null = null;
  private isInitialized: boolean = false;
  private userId: string = '';

  private constructor() {
    this.syncQueue = SyncQueue.getInstance();
    this.networkService = NetworkService.getInstance();
    this.options = DEFAULT_OPTIONS;
    this.status = {
      isOnline: false,
      isSyncing: false,
      lastSyncTime: 0,
      pendingChanges: 0,
      error: null
    };
  }

  /**
   * Get singleton instance
   */
  static getInstance(): SyncService {
    if (SyncService.instance === null) {
      SyncService.instance = new SyncService();
    }
    return SyncService.instance;
  }

  /**
   * Initialize sync service
   */
  async initialize(context: common.UIAbilityContext, userId: string): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    this.userId = userId;

    try {
      // Initialize dependencies
      await this.networkService.initialize();
      await this.syncQueue.initialize(context);

      // Listen for network changes
      this.networkService.onStatusChanged((netStatus: NetworkStatus) => {
        this.handleNetworkChange(netStatus);
      });

      // Update initial status
      this.status.isOnline = this.networkService.isOnline();
      this.status.pendingChanges = this.syncQueue.getPendingCount();

      this.isInitialized = true;
      console.info('[SyncService] Initialized for user:', userId);

      // Start auto sync if enabled
      if (this.options.autoSync) {
        this.startAutoSync();
      }
    } catch (error) {
      console.error('[SyncService] Initialize failed:', error);
      throw new Error(error);
    }
  }

  /**
   * Start synchronization
   */
  async startSync(): Promise<void> {
    if (!this.canSync()) {
      console.info('[SyncService] Cannot sync - offline or wifi-only restriction');
      return;
    }

    if (this.status.isSyncing) {
      console.info('[SyncService] Sync already in progress');
      return;
    }

    this.status.isSyncing = true;
    this.status.error = null;
    this.notifyCallbacks();

    try {
      // Process pending queue
      await this.processSyncQueue();

      // Pull remote changes
      await this.pullRemoteChanges();

      this.status.lastSyncTime = Date.now();
      console.info('[SyncService] Sync completed');
    } catch (error) {
      const errorMsg = error instanceof Error ? error.message : String(error);
      this.status.error = errorMsg;
      console.error('[SyncService] Sync failed:', error);
    } finally {
      this.status.isSyncing = false;
      this.status.pendingChanges = this.syncQueue.getPendingCount();
      this.notifyCallbacks();
    }
  }

  /**
   * Stop synchronization
   */
  stopSync(): void {
    this.stopAutoSync();
    console.info('[SyncService] Sync stopped');
  }

  /**
   * Force full sync
   */
  async forceSync(): Promise<void> {
    console.info('[SyncService] Force sync triggered');
    await this.startSync();
  }

  /**
   * Record local change for sync
   */
  async recordChange(
    entityType: SyncEntityType,
    entityId: string,
    action: SyncAction,
    data: object
  ): Promise<void> {
    await this.syncQueue.enqueue(entityType, entityId, action, data);
    this.status.pendingChanges = this.syncQueue.getPendingCount();
    this.notifyCallbacks();

    // Trigger sync if auto-sync enabled and online
    if (this.options.autoSync && this.canSync()) {
      // Debounce sync - wait 5 seconds before syncing
      this.scheduleDebouncedSync();
    }
  }

  /**
   * Get current sync status
   */
  getSyncStatus(): SyncStatus {
    const status: SyncStatus = {
      isOnline: this.status.isOnline,
      isSyncing: this.status.isSyncing,
      lastSyncTime: this.status.lastSyncTime,
      pendingChanges: this.status.pendingChanges,
      error: this.status.error
    };
    return status;
  }

  /**
   * Update sync options
   */
  updateOptions(options: Partial<SyncServiceOptions>): void {
    if (options.autoSync !== undefined) {
      this.options.autoSync = options.autoSync;
    }
    if (options.wifiOnly !== undefined) {
      this.options.wifiOnly = options.wifiOnly;
    }
    if (options.syncInterval !== undefined) {
      this.options.syncInterval = options.syncInterval;
    }
    if (options.syncSensitiveData !== undefined) {
      this.options.syncSensitiveData = options.syncSensitiveData;
    }

    // Restart auto sync with new interval
    if (this.options.autoSync) {
      this.stopAutoSync();
      this.startAutoSync();
    } else {
      this.stopAutoSync();
    }

    console.info('[SyncService] Options updated:', this.options);
  }

  /**
   * Get current options
   */
  getOptions(): SyncServiceOptions {
    const opts: SyncServiceOptions = {
      autoSync: this.options.autoSync,
      wifiOnly: this.options.wifiOnly,
      syncInterval: this.options.syncInterval,
      syncSensitiveData: this.options.syncSensitiveData
    };
    return opts;
  }

  /**
   * Register sync status callback
   */
  onSyncStatusChanged(callback: SyncStatusCallback): void {
    this.callbacks.push(callback);
  }

  /**
   * Unregister sync status callback
   */
  offSyncStatusChanged(callback: SyncStatusCallback): void {
    const index = this.callbacks.indexOf(callback);
    if (index > -1) {
      this.callbacks.splice(index, 1);
    }
  }

  /**
   * Resolve conflict between local and cloud data
   */
  resolveConflict(localData: object, cloudData: object): object {
    const local = localData as Record<string, Object>;
    const cloud = cloudData as Record<string, Object>;
    
    const localTime = Number(local['updatedAt'] || local['updated_at'] || 0);
    const cloudTime = Number(cloud['updatedAt'] || cloud['updated_at'] || 0);

    // Last write wins
    if (localTime >= cloudTime) {
      console.info('[SyncService] Conflict resolved: local wins');
      return localData;
    } else {
      console.info('[SyncService] Conflict resolved: cloud wins');
      return cloudData;
    }
  }

  /**
   * Check if sync is possible
   */
  private canSync(): boolean {
    if (!this.status.isOnline) {
      return false;
    }
    if (this.options.wifiOnly && !this.networkService.isWifi()) {
      return false;
    }
    return true;
  }

  /**
   * Handle network status change
   */
  private handleNetworkChange(netStatus: NetworkStatus): void {
    this.status.isOnline = netStatus.isOnline;
    this.notifyCallbacks();

    // Sync pending changes when coming online
    if (netStatus.isOnline && this.syncQueue.getPendingCount() > 0) {
      console.info('[SyncService] Network restored, syncing pending changes');
      this.startSync();
    }
  }

  /**
   * Process sync queue
   */
  private async processSyncQueue(): Promise<void> {
    while (!this.syncQueue.isEmpty()) {
      const item = this.syncQueue.peek();
      if (item === null) {
        break;
      }

      try {
        await this.syncItem(item);
        await this.syncQueue.dequeue(item.id);
      } catch (error) {
        const errorMsg = error instanceof Error ? error.message : String(error);
        const shouldRetry = await this.syncQueue.markFailed(item.id, errorMsg);
        if (!shouldRetry) {
          console.error('[SyncService] Item sync failed permanently:', item.id);
        }
        break; // Stop processing on error
      }
    }
  }

  /**
   * Sync single item to cloud
   */
  private async syncItem(item: SyncQueueItem): Promise<void> {
    console.info('[SyncService] Syncing item:', item.entityType, item.entityId, item.action);
    
    // TODO: Implement actual cloud sync when Cloud DB is configured
    // For now, simulate sync delay
    await this.delay(100);
    
    // In real implementation:
    // - Parse item.data
    // - Filter sensitive data if !syncSensitiveData
    // - Call Cloud DB API based on action (create/update/delete)
    // - Handle conflicts
  }

  /**
   * Pull remote changes from cloud
   */
  private async pullRemoteChanges(): Promise<void> {
    console.info('[SyncService] Pulling remote changes');
    
    // TODO: Implement actual cloud pull when Cloud DB is configured
    // For now, simulate pull delay
    await this.delay(100);
    
    // In real implementation:
    // - Query Cloud DB for changes since lastSyncTime
    // - Merge with local data
    // - Handle conflicts using resolveConflict()
  }

  /**
   * Start auto sync timer
   */
  private startAutoSync(): void {
    if (this.syncTimer !== null) {
      return;
    }

    this.syncTimer = setInterval(() => {
      if (this.canSync() && !this.status.isSyncing) {
        this.startSync();
      }
    }, this.options.syncInterval);

    console.info('[SyncService] Auto sync started, interval:', this.options.syncInterval);
  }

  /**
   * Stop auto sync timer
   */
  private stopAutoSync(): void {
    if (this.syncTimer !== null) {
      clearInterval(this.syncTimer);
      this.syncTimer = null;
      console.info('[SyncService] Auto sync stopped');
    }
  }

  private debouncedSyncTimer: number | null = null;

  /**
   * Schedule debounced sync
   */
  private scheduleDebouncedSync(): void {
    if (this.debouncedSyncTimer !== null) {
      clearTimeout(this.debouncedSyncTimer);
    }

    this.debouncedSyncTimer = setTimeout(() => {
      this.debouncedSyncTimer = null;
      if (this.canSync() && !this.status.isSyncing) {
        this.startSync();
      }
    }, 5000);
  }

  /**
   * Notify all callbacks
   */
  private notifyCallbacks(): void {
    const status = this.getSyncStatus();
    this.callbacks.forEach((callback: SyncStatusCallback) => {
      try {
        callback(status);
      } catch (error) {
        console.error('[SyncService] Callback error:', error);
      }
    });
  }

  /**
   * Delay helper
   */
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
  }

  /**
   * Cleanup resources
   */
  destroy(): void {
    this.stopAutoSync();
    if (this.debouncedSyncTimer !== null) {
      clearTimeout(this.debouncedSyncTimer);
    }
    this.callbacks = [];
    SyncService.instance = null;
  }
}
