/**
 * CurlGenerator - Generate cURL commands from HttpRequest
 *
 * Supports:
 * - URL with query parameters
 * - HTTP method (-X)
 * - Headers (-H)
 * - Body data (-d)
 * - Basic authentication (-u)
 * - Multi-line formatting
 * - Shell escaping
 */

import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { TemplateEngine } from './TemplateEngine';

/**
 * Options for cURL generation
 */
interface CurlGeneratorOptions {
  multiLine: boolean;
  includeComments: boolean;
  shellType: 'bash' | 'cmd' | 'powershell';
}

/**
 * Resolved request with all variables substituted
 */
interface ResolvedRequest {
  url: string;
  method: string;
  headers: Map<string, string>;
  body: string | null;
  bodyType: string;
  authHeader: string | null;
}

export class CurlGenerator {
  private static readonly DEFAULT_OPTIONS: CurlGeneratorOptions = {
    multiLine: true,
    includeComments: false,
    shellType: 'bash'
  };

  /**
   * Generate cURL command from HttpRequest
   */
  static generate(
    request: HttpRequest,
    variables: Map<string, string>,
    options?: CurlGeneratorOptions
  ): string {
    let opts: CurlGeneratorOptions;
    if (options) {
      opts = {
        multiLine: options.multiLine !== undefined ? options.multiLine : CurlGenerator.DEFAULT_OPTIONS.multiLine,
        includeComments: options.includeComments !== undefined ? options.includeComments : CurlGenerator.DEFAULT_OPTIONS.includeComments,
        shellType: options.shellType !== undefined ? options.shellType : CurlGenerator.DEFAULT_OPTIONS.shellType
      };
    } else {
      opts = {
        multiLine: CurlGenerator.DEFAULT_OPTIONS.multiLine,
        includeComments: CurlGenerator.DEFAULT_OPTIONS.includeComments,
        shellType: CurlGenerator.DEFAULT_OPTIONS.shellType
      };
    }
    const resolved = CurlGenerator.resolveVariables(request, variables);
    const parts = CurlGenerator.buildCommandParts(resolved, opts);

    if (opts.multiLine) {
      return CurlGenerator.formatMultiLine(parts, opts.shellType);
    }
    return parts.join(' ');
  }

  /**
   * Resolve template variables in request
   */
  private static resolveVariables(
    request: HttpRequest,
    variables: Map<string, string>
  ): ResolvedRequest {
    // Resolve URL
    let url = TemplateEngine.resolve(request.url, variables);

    // Add query parameters to URL
    const enabledParams = request.query_params.filter((p: QueryParam) => p.enabled);
    if (enabledParams.length > 0) {
      const queryParts: string[] = [];
      enabledParams.forEach((param: QueryParam) => {
        const name = TemplateEngine.resolve(param.name, variables);
        const value = TemplateEngine.resolve(param.value, variables);
        queryParts.push(`${encodeURIComponent(name)}=${encodeURIComponent(value)}`);
      });
      const separator = url.includes('?') ? '&' : '?';
      url = url + separator + queryParts.join('&');
    }

    // Resolve headers
    const headers = new Map<string, string>();
    const enabledHeaders = request.headers.filter((h: HttpHeader) => h.enabled);
    enabledHeaders.forEach((header: HttpHeader) => {
      const name = TemplateEngine.resolve(header.name, variables);
      const value = TemplateEngine.resolve(header.value, variables);
      headers.set(name, value);
    });

    // Resolve body
    let body: string | null = null;
    if (request.body && request.body_type !== 'none') {
      body = TemplateEngine.resolve(request.body, variables);
    }

    // Generate auth header
    let authHeader: string | null = null;
    if (request.auth && request.auth.type !== 'none') {
      authHeader = CurlGenerator.generateAuthHeader(request.auth, variables);
    }

    const result: ResolvedRequest = {
      url: url,
      method: request.method,
      headers: headers,
      body: body,
      bodyType: request.body_type,
      authHeader: authHeader
    };
    return result;
  }


  /**
   * Generate authentication header or flag
   */
  private static generateAuthHeader(
    auth: AuthConfig,
    variables: Map<string, string>
  ): string | null {
    switch (auth.type) {
      case 'basic': {
        const username = TemplateEngine.resolve(auth.basic_username, variables);
        const password = TemplateEngine.resolve(auth.basic_password, variables);
        return `${username}:${password}`;
      }
      case 'bearer': {
        const token = TemplateEngine.resolve(auth.bearer_token, variables);
        return `Bearer ${token}`;
      }
      case 'api-key': {
        // API key is handled as a header, not a special auth flag
        return null;
      }
      default:
        return null;
    }
  }

  /**
   * Build cURL command parts
   */
  private static buildCommandParts(
    resolved: ResolvedRequest,
    options: CurlGeneratorOptions
  ): string[] {
    const parts: string[] = ['curl'];

    // Add method if not GET
    if (resolved.method !== 'GET') {
      parts.push('-X');
      parts.push(resolved.method);
    }

    // Add URL
    parts.push(CurlGenerator.escapeShell(resolved.url, options.shellType));

    // Add headers
    resolved.headers.forEach((value: string, name: string) => {
      parts.push('-H');
      parts.push(CurlGenerator.escapeShell(`${name}: ${value}`, options.shellType));
    });

    // Add auth
    if (resolved.authHeader) {
      // Check if it's Basic auth (contains colon) or Bearer token
      if (resolved.authHeader.startsWith('Bearer ')) {
        parts.push('-H');
        parts.push(CurlGenerator.escapeShell(`Authorization: ${resolved.authHeader}`, options.shellType));
      } else {
        parts.push('-u');
        parts.push(CurlGenerator.escapeShell(resolved.authHeader, options.shellType));
      }
    }

    // Add body
    if (resolved.body) {
      parts.push('-d');
      parts.push(CurlGenerator.escapeShell(resolved.body, options.shellType));
    }

    return parts;
  }

  /**
   * Escape shell special characters
   */
  private static escapeShell(value: string, shellType: string): string {
    if (shellType === 'cmd') {
      // Windows CMD escaping
      return `"${value.replace(/"/g, '\\"')}"`;
    } else if (shellType === 'powershell') {
      // PowerShell escaping
      return `'${value.replace(/'/g, "''")}'`;
    } else {
      // Bash escaping (default)
      // Use single quotes for most cases, escape single quotes
      if (value.includes("'")) {
        return `'${value.replace(/'/g, "'\\''")}'`;
      }
      return `'${value}'`;
    }
  }

  /**
   * Format command as multi-line for readability
   */
  private static formatMultiLine(parts: string[], shellType: string): string {
    if (parts.length <= 2) {
      return parts.join(' ');
    }

    const continuation = shellType === 'cmd' ? ' ^' : ' \\';
    const lines: string[] = [];

    // First line: curl and method
    let firstLine = parts[0];
    let i = 1;

    // Add method to first line if present
    if (i < parts.length && parts[i] === '-X') {
      firstLine += ` ${parts[i]} ${parts[i + 1]}`;
      i += 2;
    }

    // Add URL to first line
    if (i < parts.length && !parts[i].startsWith('-')) {
      firstLine += ` ${parts[i]}`;
      i++;
    }

    lines.push(firstLine + continuation);

    // Add remaining flags, one per line
    while (i < parts.length) {
      const flag = parts[i];
      i++;
      if (i < parts.length && !parts[i].startsWith('-')) {
        const value = parts[i];
        i++;
        const isLast = i >= parts.length;
        lines.push(`  ${flag} ${value}${isLast ? '' : continuation}`);
      } else {
        const isLast = i >= parts.length;
        lines.push(`  ${flag}${isLast ? '' : continuation}`);
      }
    }

    return lines.join('\n');
  }
}
