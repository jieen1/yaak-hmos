/**
 * Validator Service
 * Provides input validation with user-friendly error messages
 */

import { ValidationError } from './AppError';

/**
 * Validation result interface
 */
export interface ValidationResult {
  isValid: boolean;
  error: ValidationError | null;
}

/**
 * URL validation options
 */
export interface UrlValidationOptions {
  allowedProtocols: string[];
  requireProtocol: boolean;
}

/**
 * Validator class
 * Provides validation methods for various input types
 */
export class Validator {
  // Dangerous URL protocols that should be blocked
  private static readonly DANGEROUS_PROTOCOLS: string[] = [
    'javascript:',
    'data:',
    'vbscript:',
    'file:'
  ];

  // Allowed URL protocols
  private static readonly ALLOWED_PROTOCOLS: string[] = [
    'http:',
    'https:',
    'ws:',
    'wss:'
  ];

  // Maximum input lengths
  private static readonly MAX_URL_LENGTH: number = 2048;
  private static readonly MAX_NAME_LENGTH: number = 255;
  private static readonly MAX_BODY_LENGTH: number = 10 * 1024 * 1024; // 10MB

  /**
   * Validate URL format and safety
   */
  static validateUrl(url: string): ValidationResult {
    // Check for empty URL
    if (!url || url.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('URL')
      };
      return result;
    }

    const trimmedUrl: string = url.trim();

    // Check URL length
    if (trimmedUrl.length > Validator.MAX_URL_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('URL', 1, Validator.MAX_URL_LENGTH)
      };
      return result;
    }

    // Check for dangerous protocols
    const lowerUrl: string = trimmedUrl.toLowerCase();
    for (let i = 0; i < Validator.DANGEROUS_PROTOCOLS.length; i++) {
      const protocol: string | undefined = Validator.DANGEROUS_PROTOCOLS[i];
      if (protocol && lowerUrl.startsWith(protocol)) {
        const result: ValidationResult = {
          isValid: false,
          error: ValidationError.dangerousProtocol(protocol)
        };
        return result;
      }
    }

    // Check for valid protocol
    let hasValidProtocol: boolean = false;
    for (let i = 0; i < Validator.ALLOWED_PROTOCOLS.length; i++) {
      const protocol: string | undefined = Validator.ALLOWED_PROTOCOLS[i];
      if (protocol && lowerUrl.startsWith(protocol)) {
        hasValidProtocol = true;
        break;
      }
    }

    // If no protocol, check if it looks like a valid URL
    if (!hasValidProtocol) {
      // Allow URLs without protocol (will be prefixed with http://)
      if (!Validator.isValidUrlFormat(trimmedUrl)) {
        const result: ValidationResult = {
          isValid: false,
          error: ValidationError.invalidUrl(trimmedUrl)
        };
        return result;
      }
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Check if string looks like a valid URL format
   */
  private static isValidUrlFormat(url: string): boolean {
    // Simple check for URL-like format
    // Must contain at least one dot and no spaces
    if (url.includes(' ')) {
      return false;
    }

    // Check for basic URL structure
    const urlPattern: RegExp = /^[a-zA-Z0-9][-a-zA-Z0-9]*(\.[a-zA-Z0-9][-a-zA-Z0-9]*)+/;
    return urlPattern.test(url);
  }

  /**
   * Validate request name
   */
  static validateRequestName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Request name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Request name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate folder name
   */
  static validateFolderName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Folder name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Folder name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate workspace name
   */
  static validateWorkspaceName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Workspace name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Workspace name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate environment name
   */
  static validateEnvironmentName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Environment name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Environment name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate variable name
   */
  static validateVariableName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Variable name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Variable name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    // Check for valid variable name format (alphanumeric and underscore)
    const validPattern: RegExp = /^[a-zA-Z_][a-zA-Z0-9_]*$/;
    if (!validPattern.test(trimmedName)) {
      const result: ValidationResult = {
        isValid: false,
        error: new ValidationError(
          'INVALID_FORMAT',
          `Invalid variable name format: ${trimmedName}`,
          'Variable names must start with a letter or underscore and contain only letters, numbers, and underscores.',
          'variableName'
        )
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate header name
   */
  static validateHeaderName(name: string): ValidationResult {
    // Check for empty name
    if (!name || name.trim().length === 0) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.required('Header name')
      };
      return result;
    }

    const trimmedName: string = name.trim();

    // Check name length
    if (trimmedName.length > Validator.MAX_NAME_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: ValidationError.invalidLength('Header name', 1, Validator.MAX_NAME_LENGTH)
      };
      return result;
    }

    // Check for valid header name format (no spaces, colons, or control characters)
    const invalidChars: RegExp = /[\s:]/;
    if (invalidChars.test(trimmedName)) {
      const result: ValidationResult = {
        isValid: false,
        error: new ValidationError(
          'INVALID_FORMAT',
          `Invalid header name format: ${trimmedName}`,
          'Header names cannot contain spaces or colons.',
          'headerName'
        )
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Validate request body size
   */
  static validateBodySize(body: string): ValidationResult {
    if (body.length > Validator.MAX_BODY_LENGTH) {
      const result: ValidationResult = {
        isValid: false,
        error: new ValidationError(
          'BODY_TOO_LARGE',
          `Request body exceeds maximum size of ${Validator.MAX_BODY_LENGTH} bytes`,
          'The request body is too large. Please reduce the size.',
          'body'
        )
      };
      return result;
    }

    const result: ValidationResult = {
      isValid: true,
      error: null
    };
    return result;
  }

  /**
   * Sanitize URL by adding protocol if missing
   */
  static sanitizeUrl(url: string): string {
    const trimmedUrl: string = url.trim();
    
    // Check if URL already has a protocol
    const hasProtocol: boolean = /^[a-zA-Z]+:\/\//.test(trimmedUrl);
    
    if (!hasProtocol) {
      // Default to https
      return `https://${trimmedUrl}`;
    }
    
    return trimmedUrl;
  }

  /**
   * Sanitize string for database storage
   * Removes control characters and limits length
   */
  static sanitizeForDatabase(input: string, maxLength: number = 255): string {
    // Remove control characters except newlines and tabs
    const sanitized: string = input.replace(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/g, '');
    
    // Limit length
    if (sanitized.length > maxLength) {
      return sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }
}
