/**
 * SyncQueue - Manages pending sync changes
 * Provides queue persistence and retry mechanism
 */

import { preferences } from '@kit.ArkData';
import type common from '@ohos.app.ability.common';

const SYNC_QUEUE_PREFERENCES = 'flare_sync_queue';
const QUEUE_KEY = 'pending_changes';
const MAX_RETRY_COUNT = 3;

/**
 * Sync change entity types
 */
export type SyncEntityType = 'workspace' | 'request' | 'folder' | 'environment';

/**
 * Sync change action types
 */
export type SyncAction = 'create' | 'update' | 'delete';

/**
 * Sync queue item interface
 */
export interface SyncQueueItem {
  id: string;
  entityType: SyncEntityType;
  entityId: string;
  action: SyncAction;
  data: string;
  timestamp: number;
  retryCount: number;
  lastError: string;
}

/**
 * SyncQueue - Manages offline sync queue
 */
export class SyncQueue {
  private static instance: SyncQueue | null = null;
  private dataPreferences: preferences.Preferences | null = null;
  private queue: SyncQueueItem[] = [];
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): SyncQueue {
    if (SyncQueue.instance === null) {
      SyncQueue.instance = new SyncQueue();
    }
    return SyncQueue.instance;
  }

  /**
   * Initialize sync queue
   */
  async initialize(context: common.UIAbilityContext): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      this.dataPreferences = await preferences.getPreferences(context, SYNC_QUEUE_PREFERENCES);
      await this.loadQueue();
      this.isInitialized = true;
      console.info('[SyncQueue] Initialized with', this.queue.length, 'pending items');
    } catch (error) {
      console.error('[SyncQueue] Initialize failed:', error);
      throw new Error(error);
    }
  }

  /**
   * Add item to queue
   */
  async enqueue(
    entityType: SyncEntityType,
    entityId: string,
    action: SyncAction,
    data: object
  ): Promise<void> {
    const item: SyncQueueItem = {
      id: this.generateId(),
      entityType: entityType,
      entityId: entityId,
      action: action,
      data: JSON.stringify(data),
      timestamp: Date.now(),
      retryCount: 0,
      lastError: ''
    };

    // Check for existing item with same entity
    const existingIndex = this.findExistingItemIndex(entityType, entityId);
    
    if (existingIndex >= 0) {
      // Merge with existing item
      const existing = this.queue[existingIndex];
      
      if (action === 'delete') {
        // Delete supersedes create/update
        if (existing.action === 'create') {
          // Remove from queue entirely - never synced
          this.queue.splice(existingIndex, 1);
        } else {
          // Replace with delete
          this.queue[existingIndex] = item;
        }
      } else if (action === 'update') {
        // Update replaces previous update, but not create
        if (existing.action !== 'create') {
          this.queue[existingIndex] = item;
        } else {
          // Keep as create with new data
          existing.data = item.data;
          existing.timestamp = item.timestamp;
        }
      }
    } else {
      this.queue.push(item);
    }

    await this.saveQueue();
    console.info('[SyncQueue] Enqueued:', entityType, entityId, action);
  }

  /**
   * Get next item from queue
   */
  peek(): SyncQueueItem | null {
    if (this.queue.length === 0) {
      return null;
    }
    return this.queue[0];
  }

  /**
   * Remove item from queue after successful sync
   */
  async dequeue(itemId: string): Promise<void> {
    const index = this.queue.findIndex((item: SyncQueueItem) => item.id === itemId);
    if (index >= 0) {
      this.queue.splice(index, 1);
      await this.saveQueue();
      console.info('[SyncQueue] Dequeued:', itemId);
    }
  }

  /**
   * Mark item as failed and increment retry count
   */
  async markFailed(itemId: string, error: string): Promise<boolean> {
    const index = this.queue.findIndex((item: SyncQueueItem) => item.id === itemId);
    if (index >= 0) {
      this.queue[index].retryCount += 1;
      this.queue[index].lastError = error;

      if (this.queue[index].retryCount >= MAX_RETRY_COUNT) {
        // Move to end of queue or remove
        console.warn('[SyncQueue] Max retries reached for:', itemId);
        this.queue.splice(index, 1);
        await this.saveQueue();
        return false;
      }

      // Move to end of queue for retry later
      const item = this.queue.splice(index, 1)[0];
      this.queue.push(item);
      await this.saveQueue();
      return true;
    }
    return false;
  }

  /**
   * Get all pending items
   */
  getAll(): SyncQueueItem[] {
    const result: SyncQueueItem[] = [];
    this.queue.forEach((item: SyncQueueItem) => {
      const copy: SyncQueueItem = {
        id: item.id,
        entityType: item.entityType,
        entityId: item.entityId,
        action: item.action,
        data: item.data,
        timestamp: item.timestamp,
        retryCount: item.retryCount,
        lastError: item.lastError
      };
      result.push(copy);
    });
    return result;
  }

  /**
   * Get pending count
   */
  getPendingCount(): number {
    return this.queue.length;
  }

  /**
   * Check if queue is empty
   */
  isEmpty(): boolean {
    return this.queue.length === 0;
  }

  /**
   * Clear all items from queue
   */
  async clear(): Promise<void> {
    this.queue = [];
    await this.saveQueue();
    console.info('[SyncQueue] Cleared');
  }

  /**
   * Load queue from storage
   */
  private async loadQueue(): Promise<void> {
    if (this.dataPreferences === null) {
      return;
    }

    try {
      const queueJson = await this.dataPreferences.get(QUEUE_KEY, '[]') as string;
      const parsed: ESObject = JSON.parse(queueJson) as ESObject;
      
      if (Array.isArray(parsed)) {
        this.queue = [];
        parsed.forEach((item: ESObject) => {
          const queueItem: SyncQueueItem = {
            id: String(item.id || ''),
            entityType: String(item.entityType || 'request') as SyncEntityType,
            entityId: String(item.entityId || ''),
            action: String(item.action || 'update') as SyncAction,
            data: String(item.data || '{}'),
            timestamp: Number(item.timestamp || 0),
            retryCount: Number(item.retryCount || 0),
            lastError: String(item.lastError || '')
          };
          this.queue.push(queueItem);
        });
      }
    } catch (error) {
      console.error('[SyncQueue] Load failed:', error);
      this.queue = [];
    }
  }

  /**
   * Save queue to storage
   */
  private async saveQueue(): Promise<void> {
    if (this.dataPreferences === null) {
      return;
    }

    try {
      const queueJson = JSON.stringify(this.queue);
      await this.dataPreferences.put(QUEUE_KEY, queueJson);
      await this.dataPreferences.flush();
    } catch (error) {
      console.error('[SyncQueue] Save failed:', error);
    }
  }

  /**
   * Find existing item index for same entity
   */
  private findExistingItemIndex(entityType: SyncEntityType, entityId: string): number {
    return this.queue.findIndex((item: SyncQueueItem) => 
      item.entityType === entityType && item.entityId === entityId
    );
  }

  /**
   * Generate unique ID
   */
  private generateId(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2, 8);
    return `sq_${timestamp}_${random}`;
  }
}
