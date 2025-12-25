/**
 * FlareError - Base error class and error codes for Flare application
 * Provides structured error handling for all modules
 */

/**
 * Error code enumeration for authentication errors
 */
export enum AuthErrorCode {
  AUTH_CANCELLED = 'AUTH_CANCELLED',
  AUTH_NETWORK_ERROR = 'AUTH_NETWORK_ERROR',
  AUTH_ACCOUNT_DISABLED = 'AUTH_ACCOUNT_DISABLED',
  AUTH_TOKEN_EXPIRED = 'AUTH_TOKEN_EXPIRED',
  AUTH_UNKNOWN = 'AUTH_UNKNOWN'
}

/**
 * Error code enumeration for sync errors
 */
export enum SyncErrorCode {
  SYNC_NETWORK_ERROR = 'SYNC_NETWORK_ERROR',
  SYNC_SERVICE_ERROR = 'SYNC_SERVICE_ERROR',
  SYNC_CONFLICT = 'SYNC_CONFLICT',
  SYNC_QUOTA_EXCEEDED = 'SYNC_QUOTA_EXCEEDED',
  SYNC_DATA_ERROR = 'SYNC_DATA_ERROR'
}

/**
 * Error code enumeration for continuation errors
 */
export enum ContinuationErrorCode {
  CONT_DEVICE_OFFLINE = 'CONT_DEVICE_OFFLINE',
  CONT_APP_NOT_FOUND = 'CONT_APP_NOT_FOUND',
  CONT_TIMEOUT = 'CONT_TIMEOUT',
  CONT_TRANSFER_ERROR = 'CONT_TRANSFER_ERROR'
}

/**
 * Error code enumeration for share errors
 */
export enum ShareErrorCode {
  SHARE_INVALID_FORMAT = 'SHARE_INVALID_FORMAT',
  SHARE_VERSION_MISMATCH = 'SHARE_VERSION_MISMATCH',
  SHARE_IMPORT_ERROR = 'SHARE_IMPORT_ERROR'
}

/**
 * Union type for all error codes
 */
export type FlareErrorCode = AuthErrorCode | SyncErrorCode | ContinuationErrorCode | ShareErrorCode;

/**
 * Base error class for Flare application
 */
export class FlareError extends Error {
  readonly code: FlareErrorCode;
  readonly timestamp: number;
  readonly details: string;

  constructor(code: FlareErrorCode, message: string, details: string = '') {
    super(message);
    this.name = 'FlareError';
    this.code = code;
    this.timestamp = Date.now();
    this.details = details;
  }

  /**
   * Get user-friendly error message
   */
  getUserMessage(): string {
    return this.message;
  }
}

/**
 * Authentication error class
 */
export class AuthError extends FlareError {
  constructor(code: AuthErrorCode, message: string, details: string = '') {
    super(code, message, details);
    this.name = 'AuthError';
  }

  static cancelled(): AuthError {
    return new AuthError(AuthErrorCode.AUTH_CANCELLED, '用户取消了登录');
  }

  static networkError(): AuthError {
    return new AuthError(AuthErrorCode.AUTH_NETWORK_ERROR, '网络不可用，请检查网络连接');
  }

  static accountDisabled(): AuthError {
    return new AuthError(AuthErrorCode.AUTH_ACCOUNT_DISABLED, '账号已被禁用，请联系客服');
  }

  static tokenExpired(): AuthError {
    return new AuthError(AuthErrorCode.AUTH_TOKEN_EXPIRED, '登录已过期，请重新登录');
  }

  static unknown(details: string = ''): AuthError {
    return new AuthError(AuthErrorCode.AUTH_UNKNOWN, '登录失败，请重试', details);
  }
}

/**
 * Sync error class
 */
export class SyncError extends FlareError {
  constructor(code: SyncErrorCode, message: string, details: string = '') {
    super(code, message, details);
    this.name = 'SyncError';
  }

  static networkError(): SyncError {
    return new SyncError(SyncErrorCode.SYNC_NETWORK_ERROR, '网络不可用，数据将在网络恢复后同步');
  }

  static serviceError(details: string = ''): SyncError {
    return new SyncError(SyncErrorCode.SYNC_SERVICE_ERROR, '云端服务暂时不可用，请稍后重试', details);
  }

  static conflict(): SyncError {
    return new SyncError(SyncErrorCode.SYNC_CONFLICT, '数据冲突，正在自动解决');
  }

  static quotaExceeded(): SyncError {
    return new SyncError(SyncErrorCode.SYNC_QUOTA_EXCEEDED, '云端存储空间不足');
  }

  static dataError(details: string = ''): SyncError {
    return new SyncError(SyncErrorCode.SYNC_DATA_ERROR, '数据格式错误', details);
  }
}

/**
 * Continuation error class
 */
export class ContinuationError extends FlareError {
  constructor(code: ContinuationErrorCode, message: string, details: string = '') {
    super(code, message, details);
    this.name = 'ContinuationError';
  }

  static deviceOffline(deviceName: string = ''): ContinuationError {
    const msg = deviceName ? `目标设备 ${deviceName} 不在线` : '目标设备不在线';
    return new ContinuationError(ContinuationErrorCode.CONT_DEVICE_OFFLINE, msg);
  }

  static appNotFound(): ContinuationError {
    return new ContinuationError(ContinuationErrorCode.CONT_APP_NOT_FOUND, '请在目标设备上安装 Flare');
  }

  static timeout(): ContinuationError {
    return new ContinuationError(ContinuationErrorCode.CONT_TIMEOUT, '流转超时，请重试');
  }

  static transferError(details: string = ''): ContinuationError {
    return new ContinuationError(ContinuationErrorCode.CONT_TRANSFER_ERROR, '数据传输失败，请重试', details);
  }
}

/**
 * Share error class
 */
export class ShareError extends FlareError {
  constructor(code: ShareErrorCode, message: string, details: string = '') {
    super(code, message, details);
    this.name = 'ShareError';
  }

  static invalidFormat(): ShareError {
    return new ShareError(ShareErrorCode.SHARE_INVALID_FORMAT, '无法识别的数据格式');
  }

  static versionMismatch(version: string = ''): ShareError {
    const msg = version ? `数据版本 ${version} 不兼容，请更新应用` : '数据版本不兼容，请更新应用';
    return new ShareError(ShareErrorCode.SHARE_VERSION_MISMATCH, msg);
  }

  static importError(details: string = ''): ShareError {
    return new ShareError(ShareErrorCode.SHARE_IMPORT_ERROR, '导入失败', details);
  }
}
