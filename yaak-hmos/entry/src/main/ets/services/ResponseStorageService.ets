/**
 * Response Storage Service
 * Manages response body storage to filesystem
 * Handles both string and ArrayBuffer body types
 */

import fs from '@ohos.file.fs';
import common from '@ohos.app.ability.common';
import util from '@ohos.util';
import { ResponseRepository } from '../database/ResponseRepository';

export class ResponseStorageService {
  private static readonly RESPONSE_DIR = 'responses';
  private static context: common.UIAbilityContext | null = null;

  /**
   * Initialize service with context
   */
  static init(context: common.UIAbilityContext): void {
    this.context = context;
  }

  /**
   * Save response body to file
   */
  static async saveResponseBody(
    responseId: string,
    body: string | ArrayBuffer
  ): Promise<string> {
    if (!this.context) {
      throw new Error('ResponseStorageService not initialized');
    }

    const filesDir = this.context.filesDir;
    const responseDir = `${filesDir}/${this.RESPONSE_DIR}`;

    // Ensure directory exists
    try {
      await fs.access(responseDir);
    } catch (error) {
      // Directory doesn't exist, create it
      await fs.mkdir(responseDir);
    }

    const filePath = `${responseDir}/${responseId}.dat`;

    try {
      // Write body to file
      if (typeof body === 'string') {
        const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
        await fs.write(file.fd, body);
        await fs.close(file.fd);
      } else {
        // ArrayBuffer
        const file = await fs.open(filePath, fs.OpenMode.CREATE | fs.OpenMode.WRITE_ONLY | fs.OpenMode.TRUNC);
        await fs.write(file.fd, body);
        await fs.close(file.fd);
      }

      console.info(`Response body saved to: ${filePath}`);
      return filePath;
    } catch (error) {
      console.error(`Failed to save response body: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * Load response body from file
   */
  static async loadResponseBody(bodyPath: string): Promise<string> {
    try {
      // Check if file exists
      await fs.access(bodyPath);

      // Read file content
      const file = await fs.open(bodyPath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(bodyPath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);

      // Convert ArrayBuffer to string
      const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
      return decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });
    } catch (error) {
      console.error(`Failed to load response body from ${bodyPath}: ${JSON.stringify(error)}`);
      return '';
    }
  }

  /**
   * Delete response body file
   */
  static async deleteResponseBody(bodyPath: string): Promise<void> {
    try {
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
          await this.deleteResponseBody(response.body_path);
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
    if (!this.context) {
      throw new Error('ResponseStorageService not initialized');
    }
    return `${this.context.filesDir}/${this.RESPONSE_DIR}`;
  }

  /**
   * Get total size of all response files
   */
  static async getTotalResponseSize(): Promise<number> {
    try {
      const responseDir = this.getResponseDir();
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
      const responseDir = this.getResponseDir();
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
}
