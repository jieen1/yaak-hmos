/**
 * SyncDataFilter - Filters and encrypts sensitive data for sync
 * Handles sensitive field detection and encryption
 */

import { EncryptionService } from './EncryptionService';

/**
 * Sensitive field names that should be encrypted or filtered
 */
const SENSITIVE_FIELDS: string[] = [
  'password',
  'token',
  'apiKey',
  'api_key',
  'secret',
  'secretKey',
  'secret_key',
  'accessToken',
  'access_token',
  'refreshToken',
  'refresh_token',
  'bearerToken',
  'bearer_token',
  'privateKey',
  'private_key',
  'clientSecret',
  'client_secret'
];

/**
 * Filtered data result
 */
export interface FilteredData {
  data: object;
  hasSensitiveData: boolean;
  sensitiveFieldCount: number;
}

/**
 * SyncDataFilter - Handles sensitive data for sync
 */
export class SyncDataFilter {
  
  /**
   * Check if a field name is sensitive
   */
  static isSensitiveField(fieldName: string): boolean {
    const lowerName = fieldName.toLowerCase();
    return SENSITIVE_FIELDS.some((sensitive: string) => 
      lowerName.includes(sensitive.toLowerCase())
    );
  }

  /**
   * Filter sensitive data from object (remove sensitive fields)
   */
  static filterSensitiveData(data: object): FilteredData {
    const result: FilteredData = {
      data: {},
      hasSensitiveData: false,
      sensitiveFieldCount: 0
    };

    const filtered = SyncDataFilter.filterObject(data as Record<string, Object>, result);
    result.data = filtered;
    
    return result;
  }

  /**
   * Encrypt sensitive data in object
   */
  static async encryptSensitiveData(data: object): Promise<object> {
    return SyncDataFilter.processObject(
      data as Record<string, Object>,
      async (value: string) => {
        return await EncryptionService.encrypt(value);
      }
    );
  }

  /**
   * Decrypt sensitive data in object
   */
  static async decryptSensitiveData(data: object): Promise<object> {
    return SyncDataFilter.processObject(
      data as Record<string, Object>,
      async (value: string) => {
        return await EncryptionService.decrypt(value);
      }
    );
  }

  /**
   * Filter object recursively
   */
  private static filterObject(
    obj: Record<string, Object>,
    result: FilteredData
  ): Record<string, Object> {
    const filtered: Record<string, Object> = {};

    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = obj[key];

      if (SyncDataFilter.isSensitiveField(key)) {
        result.hasSensitiveData = true;
        result.sensitiveFieldCount += 1;
        // Skip sensitive field
        continue;
      }

      if (value !== null && typeof value === 'object') {
        if (Array.isArray(value)) {
          filtered[key] = SyncDataFilter.filterArray(value as Object[], result);
        } else {
          filtered[key] = SyncDataFilter.filterObject(value as Record<string, Object>, result);
        }
      } else {
        filtered[key] = value;
      }
    }

    return filtered;
  }

  /**
   * Filter array recursively
   */
  private static filterArray(arr: Object[], result: FilteredData): Object[] {
    const filtered: Object[] = [];

    for (let i = 0; i < arr.length; i++) {
      const item = arr[i];
      if (item !== null && typeof item === 'object') {
        if (Array.isArray(item)) {
          filtered.push(SyncDataFilter.filterArray(item as Object[], result));
        } else {
          filtered.push(SyncDataFilter.filterObject(item as Record<string, Object>, result));
        }
      } else {
        filtered.push(item);
      }
    }

    return filtered;
  }

  /**
   * Process object with transformer for sensitive fields
   */
  private static async processObject(
    obj: Record<string, Object>,
    transformer: (value: string) => Promise<string>
  ): Promise<Record<string, Object>> {
    const processed: Record<string, Object> = {};

    const keys = Object.keys(obj);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const value = obj[key];

      if (SyncDataFilter.isSensitiveField(key) && typeof value === 'string') {
        // Transform sensitive string value
        processed[key] = await transformer(value);
      } else if (value !== null && typeof value === 'object') {
        if (Array.isArray(value)) {
          processed[key] = await SyncDataFilter.processArray(value as Object[], transformer);
        } else {
          processed[key] = await SyncDataFilter.processObject(
            value as Record<string, Object>,
            transformer
          );
        }
      } else {
        processed[key] = value;
      }
    }

    return processed;
  }

  /**
   * Process array with transformer
   */
  private static async processArray(
    arr: Object[],
    transformer: (value: string) => Promise<string>
  ): Promise<Object[]> {
    const processed: Object[] = [];

    for (let i = 0; i < arr.length; i++) {
      const item = arr[i];
      if (item !== null && typeof item === 'object') {
        if (Array.isArray(item)) {
          processed.push(await SyncDataFilter.processArray(item as Object[], transformer));
        } else {
          processed.push(await SyncDataFilter.processObject(
            item as Record<string, Object>,
            transformer
          ));
        }
      } else {
        processed.push(item);
      }
    }

    return processed;
  }

  /**
   * Mask sensitive value for display
   */
  static maskSensitiveValue(value: string): string {
    if (value.length <= 4) {
      return '****';
    }
    const visibleChars = Math.min(4, Math.floor(value.length / 4));
    const masked = value.substring(0, visibleChars) + '****' + value.substring(value.length - visibleChars);
    return masked;
  }

  /**
   * Check if object contains any sensitive data
   */
  static containsSensitiveData(data: object): boolean {
    const result = SyncDataFilter.filterSensitiveData(data);
    return result.hasSensitiveData;
  }
}
