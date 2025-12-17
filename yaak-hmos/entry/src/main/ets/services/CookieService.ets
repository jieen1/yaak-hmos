/**
 * Cookie Service
 * Manages HTTP cookies with domain and path matching
 * Handles cookie parsing, storage, and retrieval
 */

import { Cookie } from '../model/CookieJar';
import { CookieRepository } from '../database/CookieRepository';

export class CookieService {
  private static cookieRepository = new CookieRepository();

  /**
   * Store cookies from response headers
   */
  static async storeCookies(
    workspaceId: string,
    headers: Record<string, string | string[]>,
    url: string
  ): Promise<void> {
    const setCookieHeaders = CookieService.getSetCookieHeaders(headers);
    if (setCookieHeaders.length === 0) return;

    const parsedUrl = CookieService.parseUrl(url);
    if (!parsedUrl) return;

    for (const cookieStr of setCookieHeaders) {
      try {
        const cookie = CookieService.parseCookie(cookieStr, parsedUrl.hostname);
        await CookieService.cookieRepository.upsertCookie(workspaceId, cookie);
      } catch (error) {
        console.error(`Failed to parse cookie: ${error}`);
      }
    }
  }

  /**
   * Get cookies for a request
   */
  static async getCookiesForRequest(workspaceId: string, url: string): Promise<Cookie[]> {
    const parsedUrl = CookieService.parseUrl(url);
    if (!parsedUrl) return [];

    const allCookies = await CookieService.cookieRepository.getAllCookies(workspaceId);
    const now = Date.now();

    return allCookies.filter(cookie => {
      // Check domain match
      if (!CookieService.domainMatches(cookie.domain, parsedUrl.hostname)) {
        return false;
      }

      // Check path match
      if (!parsedUrl.pathname.startsWith(cookie.path)) {
        return false;
      }

      // Check expiration
      if (cookie.expires && cookie.expires < now) {
        return false;
      }

      // Check secure flag
      if (cookie.secure && parsedUrl.protocol !== 'https:') {
        return false;
      }

      return true;
    });
  }

  /**
   * Get Cookie header string for request
   */
  static async getCookieHeader(workspaceId: string, url: string): Promise<string> {
    const cookies = await CookieService.getCookiesForRequest(workspaceId, url);
    return cookies.map(c => `${c.name}=${c.value}`).join('; ');
  }

  /**
   * Parse Set-Cookie header string
   */
  private static parseCookie(cookieStr: string, defaultDomain: string): Cookie {
    const cookie = new Cookie();
    const parts = cookieStr.split(';').map(p => p.trim());

    // First part is name=value
    if (parts.length > 0) {
      const [name, ...valueParts] = parts[0].split('=');
      cookie.name = name.trim();
      cookie.value = valueParts.join('=').trim();
    }

    // Parse attributes
    for (let i = 1; i < parts.length; i++) {
      const part = parts[i];
      const [key, value] = part.split('=').map(p => p.trim());
      const lowerKey = key.toLowerCase();

      switch (lowerKey) {
        case 'domain':
          cookie.domain = value || defaultDomain;
          break;
        case 'path':
          cookie.path = value || '/';
          break;
        case 'expires':
          cookie.expires = CookieService.parseExpires(value);
          break;
        case 'max-age':
          const maxAge = parseInt(value);
          if (!isNaN(maxAge)) {
            cookie.expires = Date.now() + (maxAge * 1000);
          }
          break;
        case 'httponly':
          cookie.http_only = true;
          break;
        case 'secure':
          cookie.secure = true;
          break;
      }
    }

    // Set default domain if not specified
    if (!cookie.domain) {
      cookie.domain = defaultDomain;
    }

    // Set default path if not specified
    if (!cookie.path) {
      cookie.path = '/';
    }

    return cookie;
  }

  /**
   * Parse expires date string
   */
  private static parseExpires(dateStr: string): number | null {
    try {
      const date = new Date(dateStr);
      return date.getTime();
    } catch (error) {
      return null;
    }
  }

  /**
   * Check if cookie domain matches request domain
   */
  private static domainMatches(cookieDomain: string, requestDomain: string): boolean {
    // Exact match
    if (cookieDomain === requestDomain) {
      return true;
    }

    // Wildcard match (e.g., .example.com matches sub.example.com)
    if (cookieDomain.startsWith('.')) {
      return requestDomain.endsWith(cookieDomain.substring(1)) ||
        requestDomain === cookieDomain.substring(1);
    }

    return false;
  }

  /**
   * Get Set-Cookie headers from response headers
   */
  private static getSetCookieHeaders(headers: Record<string, string | string[]>): string[] {
    const setCookie = headers['set-cookie'] || headers['Set-Cookie'];

    if (!setCookie) {
      return [];
    }

    if (Array.isArray(setCookie)) {
      return setCookie;
    }

    return [setCookie];
  }

  /**
   * Parse URL string
   */
  private static parseUrl(url: string): { protocol: string; hostname: string; pathname: string } | null {
    try {
      // Simple URL parsing
      const match = url.match(/^(https?):\/\/([^\/]+)(\/.*)?$/);
      if (!match) return null;

      return {
        protocol: match[1] + ':',
        hostname: match[2],
        pathname: match[3] || '/'
      };
    } catch (error) {
      console.error(`Failed to parse URL: ${error}`);
      return null;
    }
  }

  /**
   * Delete expired cookies for a workspace
   */
  static async deleteExpiredCookies(workspaceId: string): Promise<void> {
    await CookieService.cookieRepository.deleteExpiredCookies(workspaceId);
  }

  /**
   * Clear all cookies for a workspace
   */
  static async clearAllCookies(workspaceId: string): Promise<void> {
    await CookieService.cookieRepository.clearAllCookies(workspaceId);
  }
}
