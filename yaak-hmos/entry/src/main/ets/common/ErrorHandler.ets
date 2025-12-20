/**
 * Error Handler Service
 * Centralized error handling with user-friendly messages and logging
 */

import promptAction from '@ohos.promptAction';
import { 
  AppError, 
  ErrorCategory, 
  NetworkError, 
  DatabaseError, 
  FileSystemError,
} from './AppError';

/**
 * Error handler result interface
 */
export interface ErrorHandlerResult {
  handled: boolean;
  userMessage: string;
  shouldRetry: boolean;
}

/**
 * Error Handler class
 * Provides centralized error handling with logging and user notifications
 */
export class ErrorHandler {
  private static instance: ErrorHandler | null = null;
  
  // Error log for debugging
  private errorLog: AppError[] = [];
  private maxLogSize: number = 100;

  private constructor() {
    // Private constructor for singleton
  }

  /**
   * Get singleton instance
   */
  static getInstance(): ErrorHandler {
    if (!ErrorHandler.instance) {
      ErrorHandler.instance = new ErrorHandler();
    }
    return ErrorHandler.instance;
  }

  /**
   * Handle an error with appropriate user feedback
   */
  handle(error: Error | AppError, showToast: boolean = true): ErrorHandlerResult {
    // Convert to AppError if needed
    const appError: AppError = this.toAppError(error);
    
    // Log the error
    this.logError(appError);
    
    // Determine if retry is appropriate
    const shouldRetry: boolean = this.shouldRetry(appError);
    
    // Show user notification if requested
    if (showToast) {
      this.showErrorToast(appError.userMessage);
    }
    
    const result: ErrorHandlerResult = {
      handled: true,
      userMessage: appError.userMessage,
      shouldRetry: shouldRetry
    };
    
    return result;
  }

  /**
   * Handle error silently (log only, no user notification)
   */
  handleSilent(error: Error | AppError): void {
    const appError: AppError = this.toAppError(error);
    this.logError(appError);
  }

  /**
   * Convert any error to AppError
   */
  private toAppError(error: Error | AppError): AppError {
    // Already an AppError
    if (error instanceof AppError) {
      return error;
    }

    // Try to detect error type from message
    const message: string = error.message || 'Unknown error';
    
    // Network errors
    if (this.isNetworkError(message)) {
      return this.createNetworkError(message, error);
    }
    
    // Database errors
    if (this.isDatabaseError(message)) {
      return DatabaseError.queryFailed(message, error);
    }
    
    // File system errors
    if (this.isFileSystemError(message)) {
      return this.createFileSystemError(message, error);
    }
    
    // Default to unknown error
    return new AppError(
      'UNKNOWN_ERROR',
      message,
      ErrorCategory.UNKNOWN,
      'An unexpected error occurred. Please try again.',
      { originalError: error }
    );
  }

  /**
   * Check if error is network-related
   */
  private isNetworkError(message: string): boolean {
    const networkPatterns: string[] = [
      'ECONNREFUSED',
      'ENOTFOUND',
      'ETIMEDOUT',
      'ENETUNREACH',
      'ECONNRESET',
      'socket',
      'network',
      'connection',
      'timeout'
    ];
    
    const lowerMessage: string = message.toLowerCase();
    return networkPatterns.some((pattern: string) => lowerMessage.includes(pattern.toLowerCase()));
  }

  /**
   * Check if error is database-related
   */
  private isDatabaseError(message: string): boolean {
    const dbPatterns: string[] = [
      'database',
      'sqlite',
      'rdb',
      'query',
      'transaction'
    ];
    
    const lowerMessage: string = message.toLowerCase();
    return dbPatterns.some((pattern: string) => lowerMessage.includes(pattern.toLowerCase()));
  }

  /**
   * Check if error is file system-related
   */
  private isFileSystemError(message: string): boolean {
    const fsPatterns: string[] = [
      'ENOENT',
      'EACCES',
      'ENOSPC',
      'file',
      'directory',
      'permission'
    ];
    
    const lowerMessage: string = message.toLowerCase();
    return fsPatterns.some((pattern: string) => lowerMessage.includes(pattern.toLowerCase()));
  }

  /**
   * Create appropriate network error
   */
  private createNetworkError(message: string, originalError: Error): NetworkError {
    const lowerMessage: string = message.toLowerCase();
    
    if (lowerMessage.includes('econnrefused')) {
      return NetworkError.connectionRefused('', originalError);
    }
    if (lowerMessage.includes('enotfound')) {
      return NetworkError.hostNotFound('', originalError);
    }
    if (lowerMessage.includes('etimedout') || lowerMessage.includes('timeout')) {
      return NetworkError.timeout('', 30000, originalError);
    }
    if (lowerMessage.includes('enetunreach')) {
      return NetworkError.networkUnreachable(originalError);
    }
    
    // Generic network error
    return new NetworkError(
      'NETWORK_ERROR',
      message,
      'A network error occurred. Please check your connection.',
      { originalError: originalError }
    );
  }

  /**
   * Create appropriate file system error
   */
  private createFileSystemError(message: string, originalError: Error): FileSystemError {
    const lowerMessage: string = message.toLowerCase();
    
    if (lowerMessage.includes('enoent')) {
      return FileSystemError.fileNotFound('');
    }
    if (lowerMessage.includes('eacces') || lowerMessage.includes('permission')) {
      return FileSystemError.permissionDenied('');
    }
    if (lowerMessage.includes('enospc')) {
      return FileSystemError.diskFull();
    }
    
    // Generic file system error
    return new FileSystemError(
      'FILE_SYSTEM_ERROR',
      message,
      'A file system error occurred.',
      { originalError: originalError }
    );
  }

  /**
   * Determine if error is retryable
   */
  private shouldRetry(error: AppError): boolean {
    // Network errors are often retryable
    if (error.category === ErrorCategory.NETWORK) {
      // Timeout and connection errors are retryable
      const retryableCodes: string[] = ['ETIMEDOUT', 'ECONNREFUSED', 'ENETUNREACH', 'ECONNRESET'];
      return retryableCodes.includes(error.code);
    }
    
    // Database errors may be retryable
    if (error.category === ErrorCategory.DATABASE) {
      return error.code === 'DB_QUERY_FAILED';
    }
    
    // Validation and auth errors are not retryable
    return false;
  }

  /**
   * Log error for debugging
   */
  private logError(error: AppError): void {
    console.error(`[ErrorHandler] ${error.toLogString()}`);
    
    // Add to error log
    this.errorLog.push(error);
    
    // Trim log if too large
    if (this.errorLog.length > this.maxLogSize) {
      this.errorLog.shift();
    }
  }

  /**
   * Show error toast to user
   */
  private showErrorToast(message: string): void {
    try {
      promptAction.showToast({
        message: message,
        duration: 3000
      });
    } catch (error) {
      console.error('[ErrorHandler] Failed to show toast:', error);
    }
  }

  /**
   * Show error dialog for critical errors
   */
  showErrorDialog(title: string, message: string, onRetry: (() => void) | null = null): void {
    try {
      interface DialogButton {
        text: string;
        color: string;
      }
      
      const buttons: DialogButton[] = [{ text: 'OK', color: '#000000' }];
      
      if (onRetry !== null) {
        buttons.push({ text: 'Retry', color: '#007AFF' });
      }
      
      promptAction.showDialog({
        title: title,
        message: message,
        buttons: buttons
      }).then((result: promptAction.ShowDialogSuccessResponse) => {
        if (result.index === 1 && onRetry !== null) {
          onRetry();
        }
      }).catch((error: Error) => {
        console.error('[ErrorHandler] Dialog error:', error);
      });
    } catch (error) {
      console.error('[ErrorHandler] Failed to show dialog:', error);
    }
  }

  /**
   * Get recent errors for debugging
   */
  getRecentErrors(): AppError[] {
    return [...this.errorLog];
  }

  /**
   * Clear error log
   */
  clearErrorLog(): void {
    this.errorLog = [];
  }

  /**
   * Get user-friendly message for error category
   */
  static getCategoryMessage(category: ErrorCategory): string {
    switch (category) {
      case ErrorCategory.NETWORK:
        return 'Network Error';
      case ErrorCategory.DATABASE:
        return 'Data Error';
      case ErrorCategory.VALIDATION:
        return 'Validation Error';
      case ErrorCategory.FILE_SYSTEM:
        return 'File Error';
      case ErrorCategory.AUTHENTICATION:
        return 'Authentication Error';
      default:
        return 'Error';
    }
  }
}
