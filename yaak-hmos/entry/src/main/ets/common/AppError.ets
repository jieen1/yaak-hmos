/**
 * Application Error Classes
 * Provides structured error handling with categories and user-friendly messages
 */

/**
 * Error categories for classification
 */
export enum ErrorCategory {
  NETWORK = 'NETWORK',
  DATABASE = 'DATABASE',
  VALIDATION = 'VALIDATION',
  FILE_SYSTEM = 'FILE_SYSTEM',
  AUTHENTICATION = 'AUTHENTICATION',
  UNKNOWN = 'UNKNOWN'
}

/**
 * Error details interface
 */
export interface ErrorDetails {
  originalError: Error | null;
  context: string;
  timestamp: number;
  requestId: string | null;
}

/**
 * Application Error class
 * Extends Error with additional metadata for better error handling
 */
export class AppError extends Error {
  code: string;
  category: ErrorCategory;
  details: ErrorDetails;
  userMessage: string;

  constructor(
    code: string,
    message: string,
    category: ErrorCategory,
    userMessage: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(message);
    this.name = 'AppError';
    this.code = code;
    this.category = category;
    this.userMessage = userMessage;
    
    // Build details with defaults
    this.details = {
      originalError: details.originalError || null,
      context: details.context || '',
      timestamp: details.timestamp || Date.now(),
      requestId: details.requestId || null
    };
  }

  /**
   * Create a string representation for logging
   */
  toLogString(): string {
    return `[${this.category}] ${this.code}: ${this.message} (context: ${this.details.context})`;
  }
}

/**
 * Network Error - for HTTP and connection issues
 */
export class NetworkError extends AppError {
  constructor(
    code: string,
    message: string,
    userMessage: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(code, message, ErrorCategory.NETWORK, userMessage, details);
    this.name = 'NetworkError';
  }

  /**
   * Create from connection refused error
   */
  static connectionRefused(url: string, originalError: Error | null = null): NetworkError {
    return new NetworkError(
      'ECONNREFUSED',
      `Connection refused to ${url}`,
      'Unable to connect to the server. Please check if the server is running.',
      { originalError: originalError, context: url }
    );
  }

  /**
   * Create from host not found error
   */
  static hostNotFound(host: string, originalError: Error | null = null): NetworkError {
    return new NetworkError(
      'ENOTFOUND',
      `Host not found: ${host}`,
      'The server address could not be found. Please check the URL.',
      { originalError: originalError, context: host }
    );
  }

  /**
   * Create from timeout error
   */
  static timeout(url: string, timeoutMs: number, originalError: Error | null = null): NetworkError {
    return new NetworkError(
      'ETIMEDOUT',
      `Request timed out after ${timeoutMs}ms to ${url}`,
      `The request timed out. The server may be slow or unreachable.`,
      { originalError: originalError, context: url }
    );
  }

  /**
   * Create from network unreachable error
   */
  static networkUnreachable(originalError: Error | null = null): NetworkError {
    return new NetworkError(
      'ENETUNREACH',
      'Network is unreachable',
      'Unable to reach the network. Please check your internet connection.',
      { originalError: originalError }
    );
  }

  /**
   * Create from SSL/TLS error
   */
  static sslError(message: string, originalError: Error | null = null): NetworkError {
    return new NetworkError(
      'SSL_ERROR',
      `SSL/TLS error: ${message}`,
      'There was a security certificate issue. The connection may not be secure.',
      { originalError: originalError, context: message }
    );
  }
}

/**
 * Database Error - for data persistence issues
 */
export class DatabaseError extends AppError {
  constructor(
    code: string,
    message: string,
    userMessage: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(code, message, ErrorCategory.DATABASE, userMessage, details);
    this.name = 'DatabaseError';
  }

  /**
   * Create from query error
   */
  static queryFailed(operation: string, originalError: Error | null = null): DatabaseError {
    return new DatabaseError(
      'DB_QUERY_FAILED',
      `Database query failed: ${operation}`,
      'Failed to access data. Please try again.',
      { originalError: originalError, context: operation }
    );
  }

  /**
   * Create from connection error
   */
  static connectionFailed(originalError: Error | null = null): DatabaseError {
    return new DatabaseError(
      'DB_CONNECTION_FAILED',
      'Failed to connect to database',
      'Unable to access local storage. Please restart the app.',
      { originalError: originalError }
    );
  }

  /**
   * Create from corruption error
   */
  static corrupted(originalError: Error | null = null): DatabaseError {
    return new DatabaseError(
      'DB_CORRUPTED',
      'Database appears to be corrupted',
      'Local data may be corrupted. You may need to reset the app data.',
      { originalError: originalError }
    );
  }
}

/**
 * Validation Error - for input validation issues
 */
export class ValidationError extends AppError {
  fieldName: string;

  constructor(
    code: string,
    message: string,
    userMessage: string,
    fieldName: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(code, message, ErrorCategory.VALIDATION, userMessage, details);
    this.name = 'ValidationError';
    this.fieldName = fieldName;
  }

  /**
   * Create for required field
   */
  static required(fieldName: string): ValidationError {
    return new ValidationError(
      'REQUIRED_FIELD',
      `${fieldName} is required`,
      `Please enter a ${fieldName.toLowerCase()}.`,
      fieldName
    );
  }

  /**
   * Create for invalid URL
   */
  static invalidUrl(url: string): ValidationError {
    return new ValidationError(
      'INVALID_URL',
      `Invalid URL: ${url}`,
      'Please enter a valid URL (e.g., https://api.example.com).',
      'url',
      { context: url }
    );
  }

  /**
   * Create for invalid length
   */
  static invalidLength(fieldName: string, minLength: number, maxLength: number): ValidationError {
    return new ValidationError(
      'INVALID_LENGTH',
      `${fieldName} must be between ${minLength} and ${maxLength} characters`,
      `${fieldName} must be between ${minLength} and ${maxLength} characters.`,
      fieldName
    );
  }

  /**
   * Create for dangerous URL protocol
   */
  static dangerousProtocol(protocol: string): ValidationError {
    return new ValidationError(
      'DANGEROUS_PROTOCOL',
      `Dangerous URL protocol: ${protocol}`,
      'This URL protocol is not allowed for security reasons.',
      'url',
      { context: protocol }
    );
  }
}

/**
 * File System Error - for file operations
 */
export class FileSystemError extends AppError {
  constructor(
    code: string,
    message: string,
    userMessage: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(code, message, ErrorCategory.FILE_SYSTEM, userMessage, details);
    this.name = 'FileSystemError';
  }

  /**
   * Create for file not found
   */
  static fileNotFound(path: string): FileSystemError {
    return new FileSystemError(
      'FILE_NOT_FOUND',
      `File not found: ${path}`,
      'The requested file could not be found.',
      { context: path }
    );
  }

  /**
   * Create for permission denied
   */
  static permissionDenied(path: string): FileSystemError {
    return new FileSystemError(
      'PERMISSION_DENIED',
      `Permission denied: ${path}`,
      'Unable to access the file. Permission denied.',
      { context: path }
    );
  }

  /**
   * Create for disk full
   */
  static diskFull(): FileSystemError {
    return new FileSystemError(
      'DISK_FULL',
      'Disk is full',
      'Unable to save data. Please free up some storage space.',
      {}
    );
  }
}

/**
 * Authentication Error - for auth-related issues
 */
export class AuthenticationError extends AppError {
  constructor(
    code: string,
    message: string,
    userMessage: string,
    details: Partial<ErrorDetails> = {}
  ) {
    super(code, message, ErrorCategory.AUTHENTICATION, userMessage, details);
    this.name = 'AuthenticationError';
  }

  /**
   * Create for invalid credentials
   */
  static invalidCredentials(): AuthenticationError {
    return new AuthenticationError(
      'INVALID_CREDENTIALS',
      'Invalid authentication credentials',
      'The provided credentials are invalid. Please check and try again.',
      {}
    );
  }

  /**
   * Create for expired token
   */
  static tokenExpired(): AuthenticationError {
    return new AuthenticationError(
      'TOKEN_EXPIRED',
      'Authentication token has expired',
      'Your session has expired. Please re-authenticate.',
      {}
    );
  }
}
