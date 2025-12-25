/**
 * Response Cache Service
 * Implements LRU caching for response bodies to improve performance
 */

// Cache entry interface
interface CacheEntry {
  responseId: string;
  body: string;
  accessTime: number;
  size: number;
}

export class ResponseCache {
  private static instance: ResponseCache | null = null;
  
  // LRU cache storage
  private cache: Map<string, CacheEntry> = new Map();
  
  // Maximum number of responses to cache
  private maxCacheSize: number = 50;
  
  // Maximum total cache size in bytes (50MB)
  private maxCacheSizeBytes: number = 50 * 1024 * 1024;
  
  // Current total cache size
  private currentSizeBytes: number = 0;

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * Get singleton instance
   */
  static getInstance(): ResponseCache {
    if (!ResponseCache.instance) {
      ResponseCache.instance = new ResponseCache();
    }
    return ResponseCache.instance;
  }

  /**
   * Get response body from cache
   * Returns null if not in cache
   */
  get(responseId: string): string | null {
    const entry: CacheEntry | undefined = this.cache.get(responseId);
    
    if (!entry) {
      return null;
    }

    // Update access time for LRU
    entry.accessTime = Date.now();
    
    console.info(`[ResponseCache] Cache hit for response: ${responseId}`);
    return entry.body;
  }

  /**
   * Put response body into cache
   */
  put(responseId: string, body: string): void {
    const bodySize: number = body.length;

    // Check if body is too large to cache
    if (bodySize > this.maxCacheSizeBytes / 2) {
      console.info(`[ResponseCache] Response too large to cache: ${responseId} (${bodySize} bytes)`);
      return;
    }

    // Remove existing entry if present
    if (this.cache.has(responseId)) {
      this.remove(responseId);
    }

    // Evict entries if necessary
    while (this.cache.size >= this.maxCacheSize || 
           this.currentSizeBytes + bodySize > this.maxCacheSizeBytes) {
      this.evictLRU();
      
      // Safety check to prevent infinite loop
      if (this.cache.size === 0) {
        break;
      }
    }

    // Create cache entry
    const entry: CacheEntry = {
      responseId: responseId,
      body: body,
      accessTime: Date.now(),
      size: bodySize
    };

    this.cache.set(responseId, entry);
    this.currentSizeBytes += bodySize;

    console.info(`[ResponseCache] Cached response: ${responseId} (${bodySize} bytes, total: ${this.currentSizeBytes} bytes)`);
  }

  /**
   * Remove response from cache
   */
  remove(responseId: string): void {
    const entry: CacheEntry | undefined = this.cache.get(responseId);
    
    if (entry) {
      this.currentSizeBytes -= entry.size;
      this.cache.delete(responseId);
      console.info(`[ResponseCache] Removed from cache: ${responseId}`);
    }
  }

  /**
   * Clear all cached responses
   */
  clear(): void {
    this.cache.clear();
    this.currentSizeBytes = 0;
    console.info('[ResponseCache] Cache cleared');
  }

  /**
   * Evict least recently used entry
   */
  private evictLRU(): void {
    let oldestKey: string | null = null;
    let oldestTime: number = Date.now();

    this.cache.forEach((entry: CacheEntry, key: string) => {
      if (entry.accessTime < oldestTime) {
        oldestTime = entry.accessTime;
        oldestKey = key;
      }
    });

    if (oldestKey !== null) {
      this.remove(oldestKey);
      console.info(`[ResponseCache] Evicted LRU entry: ${oldestKey}`);
    }
  }

  /**
   * Get cache statistics
   */
  getStats(): CacheStats {
    const stats: CacheStats = {
      entryCount: this.cache.size,
      totalSizeBytes: this.currentSizeBytes,
      maxEntries: this.maxCacheSize,
      maxSizeBytes: this.maxCacheSizeBytes
    };
    return stats;
  }

  /**
   * Set maximum cache size (number of entries)
   */
  setMaxCacheSize(size: number): void {
    this.maxCacheSize = size;
    
    // Evict if necessary
    while (this.cache.size > this.maxCacheSize) {
      this.evictLRU();
    }
  }

  /**
   * Set maximum cache size in bytes
   */
  setMaxCacheSizeBytes(bytes: number): void {
    this.maxCacheSizeBytes = bytes;
    
    // Evict if necessary
    while (this.currentSizeBytes > this.maxCacheSizeBytes && this.cache.size > 0) {
      this.evictLRU();
    }
  }
}

// Cache statistics interface
export interface CacheStats {
  entryCount: number;
  totalSizeBytes: number;
  maxEntries: number;
  maxSizeBytes: number;
}
