/**
 * Proxy Service
 * Handles proxy configuration and application for HTTP requests
 * Supports HTTP and HTTPS proxies with authentication
 */

import { WorkspaceSettings } from '../model/Workspace';

// Proxy configuration interface
interface ProxyConfig {
  enabled: boolean;
  host: string;
  port: number;
  username: string;
  password: string;
  protocol: 'http' | 'https';
}

// Bypass pattern interface
interface BypassPattern {
  pattern: string;
  isRegex: boolean;
}

export class ProxyService {
  private static instance: ProxyService | null = null;
  
  // Bypass patterns for hosts that should not use proxy
  private bypassPatterns: BypassPattern[] = [];

  private constructor() {
    this.initDefaultBypassPatterns();
  }

  /**
   * Get singleton instance
   */
  static getInstance(): ProxyService {
    if (!ProxyService.instance) {
      ProxyService.instance = new ProxyService();
    }
    return ProxyService.instance;
  }

  /**
   * Initialize default bypass patterns
   */
  private initDefaultBypassPatterns(): void {
    // Localhost patterns
    const localhost: BypassPattern = { pattern: 'localhost', isRegex: false };
    this.bypassPatterns.push(localhost);
    
    const loopback: BypassPattern = { pattern: '127.0.0.1', isRegex: false };
    this.bypassPatterns.push(loopback);
    
    const loopbackV6: BypassPattern = { pattern: '::1', isRegex: false };
    this.bypassPatterns.push(loopbackV6);
  }

  /**
   * Get proxy configuration from workspace settings
   * @param settings The workspace settings
   * @returns Proxy configuration or null if disabled
   */
  getProxyConfig(settings: WorkspaceSettings): ProxyConfig | null {
    if (!settings.proxy_enabled) {
      return null;
    }

    if (!settings.proxy_host || settings.proxy_port <= 0) {
      console.warn('[ProxyService] Proxy enabled but host/port not configured');
      return null;
    }

    const config: ProxyConfig = {
      enabled: true,
      host: settings.proxy_host,
      port: settings.proxy_port,
      username: settings.proxy_username,
      password: settings.proxy_password,
      protocol: 'http' // Default to HTTP proxy
    };

    return config;
  }

  /**
   * Check if a host should bypass the proxy
   * @param host The host to check
   * @returns true if the host should bypass the proxy
   */
  shouldBypassProxy(host: string): boolean {
    if (!host) {
      return false;
    }

    const lowerHost: string = host.toLowerCase();

    for (let i = 0; i < this.bypassPatterns.length; i++) {
      const pattern: BypassPattern | undefined = this.bypassPatterns[i];
      if (pattern) {
        if (pattern.isRegex) {
          try {
            const regex: RegExp = new RegExp(pattern.pattern, 'i');
            if (regex.test(lowerHost)) {
              return true;
            }
          } catch (error) {
            console.error('[ProxyService] Invalid regex pattern:', pattern.pattern);
          }
        } else {
          if (lowerHost === pattern.pattern.toLowerCase()) {
            return true;
          }
          // Check for wildcard patterns like *.example.com
          if (pattern.pattern.startsWith('*.')) {
            const suffix: string = pattern.pattern.substring(1).toLowerCase();
            if (lowerHost.endsWith(suffix)) {
              return true;
            }
          }
        }
      }
    }

    return false;
  }

  /**
   * Add a bypass pattern
   * @param pattern The pattern to add
   * @param isRegex Whether the pattern is a regex
   */
  addBypassPattern(pattern: string, isRegex: boolean = false): void {
    const bypassPattern: BypassPattern = { pattern, isRegex };
    this.bypassPatterns.push(bypassPattern);
    console.info(`[ProxyService] Added bypass pattern: ${pattern}`);
  }

  /**
   * Remove a bypass pattern
   * @param pattern The pattern to remove
   */
  removeBypassPattern(pattern: string): void {
    this.bypassPatterns = this.bypassPatterns.filter(
      (p: BypassPattern) => p.pattern !== pattern
    );
    console.info(`[ProxyService] Removed bypass pattern: ${pattern}`);
  }

  /**
   * Get all bypass patterns
   */
  getBypassPatterns(): BypassPattern[] {
    return this.bypassPatterns;
  }

  /**
   * Clear all bypass patterns
   */
  clearBypassPatterns(): void {
    this.bypassPatterns = [];
    this.initDefaultBypassPatterns();
    console.info('[ProxyService] Bypass patterns reset to defaults');
  }

  /**
   * Build proxy URL from configuration
   * @param config The proxy configuration
   * @returns The proxy URL
   */
  buildProxyUrl(config: ProxyConfig): string {
    let url: string = `${config.protocol}://`;

    // Add authentication if provided
    if (config.username && config.password) {
      url += `${encodeURIComponent(config.username)}:${encodeURIComponent(config.password)}@`;
    }

    url += `${config.host}:${config.port}`;

    return url;
  }

  /**
   * Parse host from URL
   * @param url The URL to parse
   * @returns The host
   */
  parseHostFromUrl(url: string): string {
    try {
      // Remove protocol
      let urlWithoutProtocol: string = url;
      if (url.startsWith('https://')) {
        urlWithoutProtocol = url.substring(8);
      } else if (url.startsWith('http://')) {
        urlWithoutProtocol = url.substring(7);
      }

      // Extract host
      const pathIndex: number = urlWithoutProtocol.indexOf('/');
      const hostPart: string = pathIndex >= 0 ? urlWithoutProtocol.substring(0, pathIndex) : urlWithoutProtocol;

      // Remove port if present
      const portIndex: number = hostPart.indexOf(':');
      if (portIndex >= 0) {
        return hostPart.substring(0, portIndex);
      }

      return hostPart;
    } catch (error) {
      console.error('[ProxyService] Failed to parse host from URL:', JSON.stringify(error));
      return '';
    }
  }

  /**
   * Check if proxy should be used for a URL
   * @param url The URL to check
   * @param settings The workspace settings
   * @returns true if proxy should be used
   */
  shouldUseProxy(url: string, settings: WorkspaceSettings): boolean {
    if (!settings.proxy_enabled) {
      return false;
    }

    const host: string = this.parseHostFromUrl(url);
    if (this.shouldBypassProxy(host)) {
      console.info(`[ProxyService] Bypassing proxy for host: ${host}`);
      return false;
    }

    return true;
  }

  /**
   * Get proxy error message for display
   * @param error The error
   * @returns User-friendly error message
   */
  getProxyErrorMessage(error: Error): string {
    const message: string = error.message.toLowerCase();

    if (message.includes('econnrefused')) {
      return 'Proxy connection refused. Please check if the proxy server is running.';
    }
    if (message.includes('etimedout')) {
      return 'Proxy connection timed out. Please check the proxy host and port.';
    }
    if (message.includes('enotfound')) {
      return 'Proxy host not found. Please check the proxy hostname.';
    }
    if (message.includes('407') || message.includes('proxy authentication')) {
      return 'Proxy authentication failed. Please check your proxy credentials.';
    }

    return `Proxy error: ${error.message}`;
  }
}

export type { ProxyConfig, BypassPattern };
