/**
 * ResponseCacheService - Persistent response caching for offline support
 * Extends response storage with caching capabilities
 */

import { HttpResponse } from '../model/HttpResponse';
import { ResponseStorageService } from './ResponseStorageService';
import { PreferencesService } from './PreferencesService';

/**
 * Cache entry interface
 */
interface CacheEntry {
  requestId: string;
  responseId: string;
  url: string;
  method: string;
  statusCode: number;
  bodyPath: string;
  cachedAt: number;
  expiresAt: number;
}

/**
 * Cache statistics interface
 */
export interface CacheStats {
  entryCount: number;
  totalSizeBytes: number;
  oldestEntry: number;
  newestEntry: number;
}

const CACHE_PREFIX = 'response_cache_';
const CACHE_INDEX_KEY = 'response_cache_index';
const DEFAULT_CACHE_TTL = 7 * 24 * 60 * 60 * 1000; // 7 days
const MAX_CACHE_ENTRIES = 100;

/**
 * ResponseCacheService - Manages response caching for offline access
 */
export class ResponseCacheService {
  private static instance: ResponseCacheService | null = null;
  private cacheIndex: Map<string, CacheEntry> = new Map();
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): ResponseCacheService {
    if (ResponseCacheService.instance === null) {
      ResponseCacheService.instance = new ResponseCacheService();
    }
    return ResponseCacheService.instance;
  }

  /**
   * Initialize cache service
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      await this.loadCacheIndex();
      await this.cleanExpiredEntries();
      this.isInitialized = true;
      console.info('[ResponseCacheService] Initialized with', this.cacheIndex.size, 'entries');
    } catch (error) {
      console.error('[ResponseCacheService] Initialize failed:', error);
    }
  }

  /**
   * Cache a response
   */
  async cacheResponse(
    requestId: string,
    response: HttpResponse,
    ttl: number = DEFAULT_CACHE_TTL
  ): Promise<void> {
    try {
      const cacheKey = this.getCacheKey(requestId, response.request_url, response.request_method);
      
      const entry: CacheEntry = {
        requestId: requestId,
        responseId: response.id,
        url: response.request_url,
        method: response.request_method,
        statusCode: response.status_code,
        bodyPath: response.body_path,
        cachedAt: Date.now(),
        expiresAt: Date.now() + ttl
      };

      this.cacheIndex.set(cacheKey, entry);
      
      // Enforce max cache size
      await this.enforceMaxCacheSize();
      
      // Save index
      await this.saveCacheIndex();
      
      console.info('[ResponseCacheService] Cached response for:', requestId);
    } catch (error) {
      console.error('[ResponseCacheService] Cache failed:', error);
    }
  }

  /**
   * Get cached response
   */
  async getCachedResponse(
    requestId: string,
    url: string,
    method: string
  ): Promise<HttpResponse | null> {
    const cacheKey = this.getCacheKey(requestId, url, method);
    const entry = this.cacheIndex.get(cacheKey);

    if (!entry) {
      return null;
    }

    // Check if expired
    if (Date.now() > entry.expiresAt) {
      await this.removeCacheEntry(cacheKey);
      return null;
    }

    try {
      // Load response body
      const bodyContent = await ResponseStorageService.loadResponseBody(entry.bodyPath);
      
      // Create response object
      const response = new HttpResponse();
      response.id = entry.responseId;
      response.request_id = entry.requestId;
      response.request_url = entry.url;
      response.request_method = entry.method;
      response.status_code = entry.statusCode;
      response.body_path = entry.bodyPath;
      response.created_at = entry.cachedAt;

      console.info('[ResponseCacheService] Cache hit for:', requestId);
      return response;
    } catch (error) {
      console.error('[ResponseCacheService] Failed to load cached response:', error);
      return null;
    }
  }

  /**
   * Check if response is cached
   */
  isCached(requestId: string, url: string, method: string): boolean {
    const cacheKey = this.getCacheKey(requestId, url, method);
    const entry = this.cacheIndex.get(cacheKey);
    
    if (!entry) {
      return false;
    }

    return Date.now() <= entry.expiresAt;
  }

  /**
   * Invalidate cache for a request
   */
  async invalidateCache(requestId: string): Promise<void> {
    const keysToRemove: string[] = [];
    
    this.cacheIndex.forEach((entry: CacheEntry, key: string) => {
      if (entry.requestId === requestId) {
        keysToRemove.push(key);
      }
    });

    for (const key of keysToRemove) {
      await this.removeCacheEntry(key);
    }

    console.info('[ResponseCacheService] Invalidated cache for:', requestId);
  }

  /**
   * Clear all cache
   */
  async clearCache(): Promise<void> {
    const keys: string[] = [];
    this.cacheIndex.forEach((entry: CacheEntry, key: string) => {
      keys.push(key);
    });

    for (const key of keys) {
      await this.removeCacheEntry(key);
    }

    this.cacheIndex.clear();
    await this.saveCacheIndex();
    
    console.info('[ResponseCacheService] Cache cleared');
  }

  /**
   * Get cache statistics
   */
  getCacheStats(): CacheStats {
    let oldestEntry = Date.now();
    let newestEntry = 0;
    let totalSize = 0;

    this.cacheIndex.forEach((entry: CacheEntry) => {
      if (entry.cachedAt < oldestEntry) {
        oldestEntry = entry.cachedAt;
      }
      if (entry.cachedAt > newestEntry) {
        newestEntry = entry.cachedAt;
      }
    });

    const stats: CacheStats = {
      entryCount: this.cacheIndex.size,
      totalSizeBytes: totalSize,
      oldestEntry: this.cacheIndex.size > 0 ? oldestEntry : 0,
      newestEntry: newestEntry
    };

    return stats;
  }

  /**
   * Generate cache key
   */
  private getCacheKey(requestId: string, url: string, method: string): string {
    return `${CACHE_PREFIX}${requestId}_${method}_${this.hashUrl(url)}`;
  }

  /**
   * Simple URL hash
   */
  private hashUrl(url: string): string {
    let hash = 0;
    for (let i = 0; i < url.length; i++) {
      const char = url.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash;
    }
    return Math.abs(hash).toString(16);
  }

  /**
   * Load cache index from preferences
   */
  private async loadCacheIndex(): Promise<void> {
    try {
      const prefsService = PreferencesService.getInstance();
      const indexJson = await prefsService.getString(CACHE_INDEX_KEY, '{}');
      const parsed: ESObject = JSON.parse(indexJson) as ESObject;
      
      this.cacheIndex.clear();
      
      if (parsed && typeof parsed === 'object') {
        const keys = Object.keys(parsed);
        keys.forEach((key: string) => {
          const entryData: ESObject = parsed[key] as ESObject;
          if (entryData) {
            const entry: CacheEntry = {
              requestId: String(entryData.requestId || ''),
              responseId: String(entryData.responseId || ''),
              url: String(entryData.url || ''),
              method: String(entryData.method || ''),
              statusCode: Number(entryData.statusCode || 0),
              bodyPath: String(entryData.bodyPath || ''),
              cachedAt: Number(entryData.cachedAt || 0),
              expiresAt: Number(entryData.expiresAt || 0)
            };
            this.cacheIndex.set(key, entry);
          }
        });
      }
    } catch (error) {
      console.error('[ResponseCacheService] Failed to load cache index:', error);
      this.cacheIndex.clear();
    }
  }

  /**
   * Save cache index to preferences
   */
  private async saveCacheIndex(): Promise<void> {
    try {
      const indexObj: Record<string, CacheEntry> = {};
      this.cacheIndex.forEach((entry: CacheEntry, key: string) => {
        indexObj[key] = entry;
      });

      const prefsService = PreferencesService.getInstance();
      await prefsService.setString(CACHE_INDEX_KEY, JSON.stringify(indexObj));
    } catch (error) {
      console.error('[ResponseCacheService] Failed to save cache index:', error);
    }
  }

  /**
   * Remove a cache entry
   */
  private async removeCacheEntry(key: string): Promise<void> {
    const entry = this.cacheIndex.get(key);
    if (entry) {
      // Delete body file
      try {
        await ResponseStorageService.deleteResponseBody(entry.bodyPath);
      } catch (error) {
        console.warn('[ResponseCacheService] Failed to delete body file:', error);
      }
      
      this.cacheIndex.delete(key);
    }
  }

  /**
   * Clean expired entries
   */
  private async cleanExpiredEntries(): Promise<void> {
    const now = Date.now();
    const expiredKeys: string[] = [];

    this.cacheIndex.forEach((entry: CacheEntry, key: string) => {
      if (now > entry.expiresAt) {
        expiredKeys.push(key);
      }
    });

    for (const key of expiredKeys) {
      await this.removeCacheEntry(key);
    }

    if (expiredKeys.length > 0) {
      await this.saveCacheIndex();
      console.info('[ResponseCacheService] Cleaned', expiredKeys.length, 'expired entries');
    }
  }

  /**
   * Enforce maximum cache size
   */
  private async enforceMaxCacheSize(): Promise<void> {
    if (this.cacheIndex.size <= MAX_CACHE_ENTRIES) {
      return;
    }

    // Sort entries by cachedAt (oldest first)
    const entries: Array<[string, CacheEntry]> = [];
    this.cacheIndex.forEach((entry: CacheEntry, key: string) => {
      entries.push([key, entry]);
    });

    entries.sort((a: [string, CacheEntry], b: [string, CacheEntry]) => 
      a[1].cachedAt - b[1].cachedAt
    );

    // Remove oldest entries until under limit
    const toRemove = entries.length - MAX_CACHE_ENTRIES;
    for (let i = 0; i < toRemove; i++) {
      const entry = entries[i];
      if (entry) {
        await this.removeCacheEntry(entry[0]);
      }
    }

    console.info('[ResponseCacheService] Removed', toRemove, 'oldest entries');
  }
}
