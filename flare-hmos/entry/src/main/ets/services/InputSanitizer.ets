/**
 * Input Sanitizer Service
 * Validates and sanitizes user input to prevent security issues
 * - Validates input length
 * - Prevents dangerous URL protocols
 * - Sanitizes input for database operations
 */

// Dangerous URL protocols that should be blocked
const DANGEROUS_PROTOCOLS: string[] = [
  'javascript:',
  'data:',
  'vbscript:',
  'file:',
  'about:'
];

// Maximum input lengths
const MAX_NAME_LENGTH: number = 255;
const MAX_URL_LENGTH: number = 2048;
const MAX_BODY_LENGTH: number = 10 * 1024 * 1024; // 10MB
const MAX_HEADER_VALUE_LENGTH: number = 8192;

// Sanitization result interface
interface SanitizationResult {
  valid: boolean;
  sanitized: string;
  error: string | null;
}

export class InputSanitizer {
  private static instance: InputSanitizer | null = null;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): InputSanitizer {
    if (!InputSanitizer.instance) {
      InputSanitizer.instance = new InputSanitizer();
    }
    return InputSanitizer.instance;
  }

  /**
   * Sanitize input for database operations
   * - Trims whitespace
   * - Validates length
   * @param input The input string
   * @param maxLength Maximum allowed length
   * @returns Sanitization result
   */
  sanitizeForDatabase(input: string, maxLength: number = MAX_NAME_LENGTH): SanitizationResult {
    if (!input) {
      const result: SanitizationResult = {
        valid: true,
        sanitized: '',
        error: null
      };
      return result;
    }

    // Trim whitespace
    const trimmed: string = input.trim();

    // Check length
    if (trimmed.length > maxLength) {
      const result: SanitizationResult = {
        valid: false,
        sanitized: trimmed.substring(0, maxLength),
        error: `Input exceeds maximum length of ${maxLength} characters`
      };
      return result;
    }

    const result: SanitizationResult = {
      valid: true,
      sanitized: trimmed,
      error: null
    };
    return result;
  }

  /**
   * Sanitize URL to prevent dangerous protocols
   * @param url The URL to sanitize
   * @returns Sanitization result
   */
  sanitizeUrl(url: string): SanitizationResult {
    if (!url) {
      const result: SanitizationResult = {
        valid: true,
        sanitized: '',
        error: null
      };
      return result;
    }

    // Trim whitespace
    const trimmed: string = url.trim();

    // Check length
    if (trimmed.length > MAX_URL_LENGTH) {
      const result: SanitizationResult = {
        valid: false,
        sanitized: trimmed.substring(0, MAX_URL_LENGTH),
        error: `URL exceeds maximum length of ${MAX_URL_LENGTH} characters`
      };
      return result;
    }

    // Check for dangerous protocols
    const lowerUrl: string = trimmed.toLowerCase();
    for (let i = 0; i < DANGEROUS_PROTOCOLS.length; i++) {
      const protocol: string | undefined = DANGEROUS_PROTOCOLS[i];
      if (protocol && lowerUrl.startsWith(protocol)) {
        const result: SanitizationResult = {
          valid: false,
          sanitized: '',
          error: `Dangerous URL protocol detected: ${protocol}`
        };
        return result;
      }
    }

    const result: SanitizationResult = {
      valid: true,
      sanitized: trimmed,
      error: null
    };
    return result;
  }

  /**
   * Sanitize request name
   * @param name The name to sanitize
   * @returns Sanitization result
   */
  sanitizeName(name: string): SanitizationResult {
    return this.sanitizeForDatabase(name, MAX_NAME_LENGTH);
  }

  /**
   * Sanitize request body
   * @param body The body to sanitize
   * @returns Sanitization result
   */
  sanitizeBody(body: string): SanitizationResult {
    if (!body) {
      const result: SanitizationResult = {
        valid: true,
        sanitized: '',
        error: null
      };
      return result;
    }

    // Check length
    if (body.length > MAX_BODY_LENGTH) {
      const result: SanitizationResult = {
        valid: false,
        sanitized: body.substring(0, MAX_BODY_LENGTH),
        error: `Body exceeds maximum length of ${MAX_BODY_LENGTH} bytes`
      };
      return result;
    }

    const result: SanitizationResult = {
      valid: true,
      sanitized: body,
      error: null
    };
    return result;
  }

  /**
   * Sanitize header value
   * @param value The header value to sanitize
   * @returns Sanitization result
   */
  sanitizeHeaderValue(value: string): SanitizationResult {
    if (!value) {
      const result: SanitizationResult = {
        valid: true,
        sanitized: '',
        error: null
      };
      return result;
    }

    // Trim whitespace
    const trimmed: string = value.trim();

    // Check length
    if (trimmed.length > MAX_HEADER_VALUE_LENGTH) {
      const result: SanitizationResult = {
        valid: false,
        sanitized: trimmed.substring(0, MAX_HEADER_VALUE_LENGTH),
        error: `Header value exceeds maximum length of ${MAX_HEADER_VALUE_LENGTH} characters`
      };
      return result;
    }

    // Remove control characters (except tab)
    let sanitized: string = '';
    for (let i = 0; i < trimmed.length; i++) {
      const charCode: number = trimmed.charCodeAt(i);
      // Allow printable ASCII and tab (9), exclude other control characters (0-8, 10-31)
      if (charCode >= 32 || charCode === 9) {
        sanitized += trimmed.charAt(i);
      }
    }

    const result: SanitizationResult = {
      valid: true,
      sanitized: sanitized,
      error: null
    };
    return result;
  }

  /**
   * Validate that a URL uses a safe protocol
   * @param url The URL to validate
   * @returns true if the URL uses a safe protocol
   */
  isUrlSafe(url: string): boolean {
    if (!url) {
      return true;
    }

    const lowerUrl: string = url.toLowerCase().trim();

    // Check for dangerous protocols
    for (let i = 0; i < DANGEROUS_PROTOCOLS.length; i++) {
      const protocol: string | undefined = DANGEROUS_PROTOCOLS[i];
      if (protocol && lowerUrl.startsWith(protocol)) {
        return false;
      }
    }

    return true;
  }

  /**
   * Validate input length
   * @param input The input to validate
   * @param maxLength Maximum allowed length
   * @returns true if the input is within the length limit
   */
  isWithinLength(input: string, maxLength: number): boolean {
    if (!input) {
      return true;
    }
    return input.length <= maxLength;
  }

  /**
   * Get maximum lengths for different input types
   */
  getMaxLengths(): { name: number; url: number; body: number; headerValue: number } {
    return {
      name: MAX_NAME_LENGTH,
      url: MAX_URL_LENGTH,
      body: MAX_BODY_LENGTH,
      headerValue: MAX_HEADER_VALUE_LENGTH
    };
  }

  /**
   * Escape HTML special characters to prevent XSS
   * @param input The input to escape
   * @returns Escaped string
   */
  escapeHtml(input: string): string {
    if (!input) {
      return '';
    }

    let escaped: string = '';
    for (let i = 0; i < input.length; i++) {
      const char: string = input.charAt(i);
      switch (char) {
        case '&':
          escaped += '&amp;';
          break;
        case '<':
          escaped += '&lt;';
          break;
        case '>':
          escaped += '&gt;';
          break;
        case '"':
          escaped += '&quot;';
          break;
        case "'":
          escaped += '&#39;';
          break;
        default:
          escaped += char;
      }
    }
    return escaped;
  }
}

export type { SanitizationResult };
