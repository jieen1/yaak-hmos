/**
 * CurlImporter - Parse cURL commands and convert to HttpRequest
 *
 * Supports:
 * - URL extraction
 * - HTTP method (-X, --request)
 * - Headers (-H, --header)
 * - Body data (-d, --data, --data-raw, --data-binary)
 * - Basic authentication (-u, --user)
 * - Insecure flag (-k, --insecure)
 * - Compressed flag (--compressed)
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { UUID } from '../common/UUID';
import { HttpMethod } from '../model';

/**
 * Parsed cURL flags and values
 */
interface CurlFlags {
  url: string;
  method: string;
  headers: Map<string, string>;
  data: string | null;
  user: string | null;
  insecure: boolean;
  compressed: boolean;
}

/**
 * Result of cURL parsing
 */
interface CurlParseResult {
  success: boolean;
  request: HttpRequest | null;
  error: string | null;
}

interface ParseUrlResult {
  baseUrl: string;
  queryParams: QueryParam[];
}

export class CurlImporter {
  /**
   * Check if a string is a cURL command
   */
  static isCurlCommand(text: string): boolean {
    if (!text || typeof text !== 'string') {
      return false;
    }
    const trimmed = text.trim().toLowerCase();
    return trimmed.startsWith('curl ') || trimmed === 'curl';
  }

  /**
   * Parse a cURL command string and return an HttpRequest
   */
  static parse(curlCommand: string, workspaceId: string = ''): CurlParseResult {
    if (!curlCommand || typeof curlCommand !== 'string') {
      const result: CurlParseResult = {
        success: false,
        request: null,
        error: 'Invalid cURL command: empty or not a string'
      };
      return result;
    }

    const trimmed = curlCommand.trim();
    if (!CurlImporter.isCurlCommand(trimmed)) {
      const result: CurlParseResult = {
        success: false,
        request: null,
        error: 'Invalid cURL command: must start with "curl"'
      };
      return result;
    }

    try {
      const flags = CurlImporter.parseFlags(trimmed);
      const request = CurlImporter.flagsToRequest(flags, workspaceId);
      const result: CurlParseResult = {
        success: true,
        request: request,
        error: null
      };
      return result;
    } catch (e) {
      const errorMessage = e instanceof Error ? e.message : String(e);
      const result: CurlParseResult = {
        success: false,
        request: null,
        error: `Failed to parse cURL command: ${errorMessage}`
      };
      return result;
    }
  }


  /**
   * Parse cURL command into flags structure
   */
  private static parseFlags(curlCommand: string): CurlFlags {
    const flags: CurlFlags = {
      url: '',
      method: 'GET',
      headers: new Map<string, string>(),
      data: null,
      user: null,
      insecure: false,
      compressed: false
    };

    // Tokenize the command, handling quoted strings
    const tokens = CurlImporter.tokenize(curlCommand);

    let i = 0;
    while (i < tokens.length) {
      const token = tokens[i];

      if (token === 'curl') {
        i++;
        continue;
      }

      // Method flag
      if (token === '-X' || token === '--request') {
        i++;
        if (i < tokens.length) {
          flags.method = tokens[i].toUpperCase();
        }
        i++;
        continue;
      }

      // Header flag
      if (token === '-H' || token === '--header') {
        i++;
        if (i < tokens.length) {
          const headerValue = tokens[i];
          const colonIndex = headerValue.indexOf(':');
          if (colonIndex > 0) {
            const name = headerValue.substring(0, colonIndex).trim();
            const value = headerValue.substring(colonIndex + 1).trim();
            flags.headers.set(name, value);
          }
        }
        i++;
        continue;
      }

      // Data flags
      if (token === '-d' || token === '--data' || token === '--data-raw' || token === '--data-binary') {
        i++;
        if (i < tokens.length) {
          flags.data = tokens[i];
          // If data is provided, default to POST if method not explicitly set
          if (flags.method === 'GET') {
            flags.method = 'POST';
          }
        }
        i++;
        continue;
      }

      // User flag (Basic Auth)
      if (token === '-u' || token === '--user') {
        i++;
        if (i < tokens.length) {
          flags.user = tokens[i];
        }
        i++;
        continue;
      }

      // Insecure flag
      if (token === '-k' || token === '--insecure') {
        flags.insecure = true;
        i++;
        continue;
      }

      // Compressed flag
      if (token === '--compressed') {
        flags.compressed = true;
        i++;
        continue;
      }

      // Location flag (follow redirects)
      if (token === '-L' || token === '--location') {
        i++;
        continue;
      }

      // Silent/quiet flags (ignore)
      if (token === '-s' || token === '--silent' || token === '-S' || token === '--show-error') {
        i++;
        continue;
      }

      // Output flag (ignore)
      if (token === '-o' || token === '--output') {
        i += 2; // Skip flag and value
        continue;
      }

      // If it looks like a URL, capture it
      if (token.startsWith('http://') || token.startsWith('https://') || token.startsWith('ws://') || token.startsWith('wss://')) {
        flags.url = token;
        i++;
        continue;
      }

      // Unknown flag or positional argument
      // If no URL yet and doesn't start with -, treat as URL
      if (!flags.url && !token.startsWith('-')) {
        flags.url = token;
      }

      i++;
    }

    return flags;
  }


  /**
   * Tokenize cURL command, handling quoted strings
   */
  private static tokenize(command: string): string[] {
    const tokens: string[] = [];
    let current = '';
    let inSingleQuote = false;
    let inDoubleQuote = false;
    let escapeNext = false;

    for (let i = 0; i < command.length; i++) {
      const char = command[i];

      if (escapeNext) {
        current += char;
        escapeNext = false;
        continue;
      }

      if (char === '\\' && !inSingleQuote) {
        escapeNext = true;
        continue;
      }

      if (char === "'" && !inDoubleQuote) {
        inSingleQuote = !inSingleQuote;
        continue;
      }

      if (char === '"' && !inSingleQuote) {
        inDoubleQuote = !inDoubleQuote;
        continue;
      }

      if ((char === ' ' || char === '\t' || char === '\n' || char === '\r') && !inSingleQuote && !inDoubleQuote) {
        if (current.length > 0) {
          tokens.push(current);
          current = '';
        }
        continue;
      }

      current += char;
    }

    if (current.length > 0) {
      tokens.push(current);
    }

    return tokens;
  }

  /**
   * Convert parsed flags to HttpRequest
   */
  private static flagsToRequest(flags: CurlFlags, workspaceId: string): HttpRequest {
    const request = new HttpRequest();
    request.id = UUID.randomUUID();
    request.workspace_id = workspaceId;
    request.created_at = Date.now();
    request.updated_at = Date.now();

    // Set URL and extract query parameters
    const urlParts = CurlImporter.parseUrl(flags.url);
    request.url = urlParts.baseUrl;
    request.query_params = urlParts.queryParams;

    // Set method
    request.method = flags.method as HttpMethod;

    // Set name from URL path
    request.name = CurlImporter.generateNameFromUrl(flags.url);

    // Set headers
    const headers: HttpHeader[] = [];
    flags.headers.forEach((value: string, name: string) => {
      const header: HttpHeader = new HttpHeader();
      header.id = UUID.randomUUID();
      header.name = name;
      header.value = value;
      header.enabled = true;
      headers.push(header);
    });
    request.headers = headers;

    // Set body
    if (flags.data) {
      request.body = flags.data;
      // Detect body type from Content-Type header or content
      request.body_type = CurlImporter.detectBodyType(flags.data, flags.headers);
    }

    // Set authentication
    if (flags.user) {
      const authConfig = new AuthConfig();
      const colonIndex = flags.user.indexOf(':');
      if (colonIndex > 0) {
        authConfig.type = 'basic';
        authConfig.basic_username = flags.user.substring(0, colonIndex);
        authConfig.basic_password = flags.user.substring(colonIndex + 1);
      } else {
        authConfig.type = 'basic';
        authConfig.basic_username = flags.user;
        authConfig.basic_password = '';
      }
      request.auth = authConfig;
    }

    return request;
  }


  /**
   * Parse URL and extract query parameters
   */
  private static parseUrl(url: string): ParseUrlResult {
    const queryParams: QueryParam[] = [];

    if (!url) {
      const result: ParseUrlResult = {
        baseUrl: '',
        queryParams: queryParams
      };
      return result;
    }

    const questionIndex = url.indexOf('?');
    if (questionIndex === -1) {
      const result: ParseUrlResult = {
        baseUrl: url,
        queryParams: queryParams
      };
      return result;
    }

    const baseUrl = url.substring(0, questionIndex);
    const queryString = url.substring(questionIndex + 1);

    const pairs = queryString.split('&');
    for (const pair of pairs) {
      const equalsIndex = pair.indexOf('=');
      if (equalsIndex > 0) {
        const param: QueryParam = new QueryParam();
        param.id = UUID.randomUUID();
        param.name = decodeURIComponent(pair.substring(0, equalsIndex));
        param.value = decodeURIComponent(pair.substring(equalsIndex + 1));
        param.enabled = true;
        queryParams.push(param);
      } else if (pair.length > 0) {
        const param: QueryParam = new QueryParam();
        param.id = UUID.randomUUID();
        param.name = decodeURIComponent(pair);
        param.value = '';
        param.enabled = true;
        queryParams.push(param);
      }
    }

    const result: ParseUrlResult = {
      baseUrl: baseUrl,
      queryParams: queryParams
    };
    return result;
  }

  /**
   * Generate a request name from URL
   */
  private static generateNameFromUrl(url: string): string {
    if (!url) {
      return '导入的请求';
    }

    try {
      // Remove protocol
      let path = url.replace(/^https?:\/\//, '');

      // Remove query string
      const questionIndex = path.indexOf('?');
      if (questionIndex > 0) {
        path = path.substring(0, questionIndex);
      }

      // Get last path segment
      const segments = path.split('/').filter((s: string) => s.length > 0);
      if (segments.length > 1) {
        const lastSegment = segments[segments.length - 1];
        if (lastSegment) {
          return lastSegment;
        }
      }

      // Use hostname if no path
      if (segments.length > 0) {
        const firstSegment = segments[0];
        if (firstSegment) {
          return firstSegment;
        }
      }

      return '导入的请求';
    } catch (e) {
      return '导入的请求';
    }
  }

  /**
   * Detect body type from content and headers
   */
  private static detectBodyType(
    data: string,
    headers: Map<string, string>
  ): 'none' | 'json' | 'xml' | 'form-data' | 'form-urlencoded' | 'binary' | 'graphql' | 'text' {
    // Check Content-Type header
    let contentType = '';
    headers.forEach((value: string, name: string) => {
      if (name.toLowerCase() === 'content-type') {
        contentType = value.toLowerCase();
      }
    });

    if (contentType.includes('application/json')) {
      return 'json';
    }
    if (contentType.includes('application/xml') || contentType.includes('text/xml')) {
      return 'xml';
    }
    if (contentType.includes('application/x-www-form-urlencoded')) {
      return 'form-urlencoded';
    }
    if (contentType.includes('multipart/form-data')) {
      return 'form-data';
    }

    // Try to detect from content
    const trimmed = data.trim();
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      return 'json';
    }
    if (trimmed.startsWith('<')) {
      return 'xml';
    }
    if (trimmed.includes('=') && !trimmed.includes(' ')) {
      return 'form-urlencoded';
    }

    return 'text';
  }
}
