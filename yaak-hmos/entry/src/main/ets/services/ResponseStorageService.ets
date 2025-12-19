/**
 * Response Storage Service
 * Manages response body storage to filesystem
 * Handles both string and ArrayBuffer body types
 * Includes LRU caching for improved performance
 */

import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { ResponseRepository } from '../database/ResponseRepository';
import { ResponseCache, CacheStats } from './ResponseCache';

export class ResponseStorageService {
  private static readonly RESPONSE_DIR = 'responses';
  private static context: common.UIAbilityContext | null = null;
  private static cache: ResponseCache = ResponseCache.getInstance();

  /**
   * Initialize service with context
   */
  static init(context: common.UIAbilityContext): void {
    ResponseStorageService.context = context;
  }

  /**
   * Save response body to file
   * Based on HarmonyOS documentation - using SYNC APIs consistently
   */
  static async saveResponseBody(
    responseId: string,
    body: string | ArrayBuffer
  ): Promise<string> {
    if (!ResponseStorageService.context) {
      console.error('[ResponseStorageService] Service not initialized');
      throw new Error('ResponseStorageService not initialized');
    }

    const filesDir = ResponseStorageService.context.filesDir;
    const responseDir = `${filesDir}/${ResponseStorageService.RESPONSE_DIR}`;
    
    console.info(`[ResponseStorageService] filesDir: ${filesDir}`);
    console.info(`[ResponseStorageService] responseDir: ${responseDir}`);
    console.info(`[ResponseStorageService] responseId: ${responseId}`);

    // Ensure directory exists using SYNC API (matching HarmonyOS documentation pattern)
    try {
      if (!fs.accessSync(responseDir)) {
        console.info(`[ResponseStorageService] Directory does not exist, creating: ${responseDir}`);
        fs.mkdirSync(responseDir);
        console.info(`[ResponseStorageService] Directory created successfully`);
      } else {
        console.info(`[ResponseStorageService] Directory exists: ${responseDir}`);
      }
    } catch (error) {
      console.error(`[ResponseStorageService] Failed to check/create directory: ${JSON.stringify(error)}`);
      throw new Error(`Failed to check/create directory: ${JSON.stringify(error)}`);
    }

    // File path: use responseId directly without extension (matching Tauri)
    const filePath = `${responseDir}/${responseId}`;
    console.info(`[ResponseStorageService] Attempting to save to: ${filePath}`);

    // Use correct OpenMode based on HarmonyOS documentation
    // READ_WRITE | CREATE | TRUNC
    let file: fs.File | null = null;
    try {
      console.info(`[ResponseStorageService] Opening file with READ_WRITE | CREATE | TRUNC mode`);
      file = fs.openSync(filePath, fs.OpenMode.READ_WRITE | fs.OpenMode.CREATE | fs.OpenMode.TRUNC);
      console.info(`[ResponseStorageService] File opened successfully, fd: ${file.fd}`);
      
      // Write body to file
      if (typeof body === 'string') {
        console.info(`[ResponseStorageService] Writing string body (${body.length} chars)`);
        fs.writeSync(file.fd, body);
      } else {
        console.info(`[ResponseStorageService] Writing ArrayBuffer body (${body.byteLength} bytes)`);
        fs.writeSync(file.fd, body);
      }
      
      console.info(`[ResponseStorageService] Data written successfully`);
      return filePath;
    } catch (error) {
      const errorMsg = `Failed to save response body: ${JSON.stringify(error)}`;
      console.error(`[ResponseStorageService] ${errorMsg}`);
      console.error(`[ResponseStorageService] Error details - filePath: ${filePath}, body type: ${typeof body}`);
      throw new Error(errorMsg);
    } finally {
      // Always close file descriptor, even if error occurs
      if (file !== null) {
        try {
          fs.closeSync(file.fd);
          console.info(`[ResponseStorageService] File closed successfully`);
        } catch (closeError) {
          console.error(`[ResponseStorageService] Failed to close file: ${JSON.stringify(closeError)}`);
        }
      }
    }
  }

  /**
   * Load response body from file with caching
   * Uses LRU cache for improved performance
   */
  static async loadResponseBody(bodyPath: string): Promise<string> {
    // Extract response ID from path for cache key
    const responseId: string = ResponseStorageService.extractResponseId(bodyPath);
    
    // Check cache first
    const cachedBody: string | null = ResponseStorageService.cache.get(responseId);
    if (cachedBody !== null) {
      return cachedBody;
    }

    // Load from file
    let file: fs.File | null = null;
    try {
      // Check if file exists
      await fs.access(bodyPath);

      // Read file content
      file = await fs.open(bodyPath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(bodyPath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);

      // Convert ArrayBuffer to string using TextDecoder
      const textDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const body: string = textDecoder.decodeToString(new Uint8Array(buffer));
      
      // Cache the loaded body
      ResponseStorageService.cache.put(responseId, body);
      
      return body;
    } catch (error) {
      console.error(`[ResponseStorageService] Failed to load response body from ${bodyPath}: ${JSON.stringify(error)}`);
      return '';
    } finally {
      // Always close file descriptor
      if (file !== null) {
        try {
          await fs.close(file.fd);
        } catch (closeError) {
          console.error(`[ResponseStorageService] Failed to close file: ${JSON.stringify(closeError)}`);
        }
      }
    }
  }

  /**
   * Extract response ID from file path
   */
  private static extractResponseId(bodyPath: string): string {
    const parts: string[] = bodyPath.split('/');
    const lastPart: string | undefined = parts[parts.length - 1];
    return lastPart || bodyPath;
  }

  /**
   * Delete response body file and remove from cache
   */
  static async deleteResponseBody(bodyPath: string): Promise<void> {
    try {
      // Remove from cache
      const responseId: string = ResponseStorageService.extractResponseId(bodyPath);
      ResponseStorageService.cache.remove(responseId);
      
      // Delete file
      await fs.access(bodyPath);
      await fs.unlink(bodyPath);
      console.info(`Response body deleted: ${bodyPath}`);
    } catch (error) {
      console.error(`Failed to delete response body: ${JSON.stringify(error)}`);
    }
  }

  /**
   * Cleanup old responses (older than maxAge milliseconds)
   */
  static async cleanupOldResponses(maxAge: number = 7 * 24 * 60 * 60 * 1000): Promise<void> {
    const responseRepository = new ResponseRepository();
    const responses = await responseRepository.getAllResponses();
    const now = Date.now();
    let deletedCount = 0;

    for (const response of responses) {
      if (now - response.created_at > maxAge) {
        try {
          // Delete response body file
          await ResponseStorageService.deleteResponseBody(response.body_path);
          // Delete response record from database
          await responseRepository.deleteResponse(response.id);
          deletedCount++;
        } catch (error) {
          console.error(`Failed to cleanup response ${response.id}: ${JSON.stringify(error)}`);
        }
      }
    }

    console.info(`Cleaned up ${deletedCount} old responses`);
  }

  /**
   * Get response directory path
   */
  static getResponseDir(): string {
    if (!ResponseStorageService.context) {
      throw new Error('ResponseStorageService not initialized');
    }
    return `${ResponseStorageService.context.filesDir}/${ResponseStorageService.RESPONSE_DIR}`;
  }

  /**
   * Get total size of all response files
   */
  static async getTotalResponseSize(): Promise<number> {
    try {
      const responseDir = ResponseStorageService.getResponseDir();
      await fs.access(responseDir);

      const files = await fs.listFile(responseDir);
      let totalSize = 0;

      for (const file of files) {
        try {
          const filePath = `${responseDir}/${file}`;
          const stat = await fs.stat(filePath);
          totalSize += stat.size;
        } catch (error) {
          console.error(`Failed to get file size: ${JSON.stringify(error)}`);
        }
      }

      return totalSize;
    } catch (error) {
      console.error(`Failed to get total response size: ${JSON.stringify(error)}`);
      return 0;
    }
  }

  /**
   * Delete all response files
   */
  static async clearAllResponses(): Promise<void> {
    try {
      // Clear cache
      ResponseStorageService.cache.clear();
      
      const responseDir = ResponseStorageService.getResponseDir();
      await fs.access(responseDir);

      const files = await fs.listFile(responseDir);
      let deletedCount = 0;

      for (const file of files) {
        try {
          const filePath = `${responseDir}/${file}`;
          await fs.unlink(filePath);
          deletedCount++;
        } catch (error) {
          console.error(`Failed to delete file: ${JSON.stringify(error)}`);
        }
      }

      console.info(`Cleared ${deletedCount} response files`);
    } catch (error) {
      console.error(`Failed to clear all responses: ${JSON.stringify(error)}`);
    }
  }

  /**
   * Clean up orphaned response files
   * Removes files that don't have corresponding database records
   */
  static async cleanupOrphanedFiles(): Promise<void> {
    try {
      const responseDir = ResponseStorageService.getResponseDir();
      await fs.access(responseDir);

      const files = await fs.listFile(responseDir);
      const responseRepository = new ResponseRepository();
      const allResponses = await responseRepository.getAllResponses();
      
      // Create a set of valid response IDs
      const validIds: Set<string> = new Set();
      allResponses.forEach((response) => {
        validIds.add(response.id);
      });

      let deletedCount = 0;

      for (const file of files) {
        // Check if file corresponds to a valid response
        if (!validIds.has(file)) {
          try {
            const filePath = `${responseDir}/${file}`;
            await fs.unlink(filePath);
            deletedCount++;
            console.info(`Deleted orphaned response file: ${file}`);
          } catch (error) {
            console.error(`Failed to delete orphaned file: ${JSON.stringify(error)}`);
          }
        }
      }

      console.info(`Cleaned up ${deletedCount} orphaned response files`);
    } catch (error) {
      console.error(`Failed to cleanup orphaned files: ${JSON.stringify(error)}`);
    }
  }

  /**
   * Get cache statistics
   */
  static getCacheStats(): CacheStats {
    return ResponseStorageService.cache.getStats();
  }

  /**
   * Clear the response cache
   */
  static clearCache(): void {
    ResponseStorageService.cache.clear();
  }
}
