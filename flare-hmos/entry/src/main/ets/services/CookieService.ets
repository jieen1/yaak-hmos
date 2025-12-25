/**
 * Cookie Service
 * Manages HTTP cookies with domain and path matching
 * Handles cookie parsing, storage, and retrieval
 */

import { Cookie } from '../model/CookieJar';
import { CookieRepository } from '../database/CookieRepository';

interface ParsedUrl {
  protocol: string;
  hostname: string;
  pathname: string;
}

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
    if (!parsedUrl) {
      console.warn(`[CookieService] Failed to parse URL: ${url}`);
      return [];
    }

    const allCookies = await CookieService.cookieRepository.getAllCookies(workspaceId);
    const now = Date.now();

    return allCookies.filter(cookie => {
      // Check domain match
      if (!CookieService.domainMatches(cookie.domain, parsedUrl.hostname)) {
        return false;
      }

      // Check path match - ensure both pathname and cookie.path exist
      const pathname = parsedUrl.pathname || '/';
      const cookiePath = cookie.path || '/';
      if (!pathname || !cookiePath || typeof pathname !== 'string' || typeof cookiePath !== 'string') {
        console.warn(`[CookieService] Invalid path: pathname=${pathname}, cookiePath=${cookiePath}`);
        return false;
      }
      if (!pathname.startsWith(cookiePath)) {
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
      const firstPart: string | undefined = parts[0];
      if (firstPart) {
        const nameValueParts = firstPart.split('=');
        if (nameValueParts.length > 0) {
          const namePart: string | undefined = nameValueParts[0];
          cookie.name = namePart ? namePart.trim() : '';
          const valueParts: string[] = [];
          for (let i = 1; i < nameValueParts.length; i++) {
            const valuePart: string | undefined = nameValueParts[i];
            if (valuePart) {
              valueParts.push(valuePart);
            }
          }
          cookie.value = valueParts.join('=').trim();
        }
      }
    }

    // Parse attributes
    for (let i = 1; i < parts.length; i++) {
      const part: string | undefined = parts[i];
      if (!part) continue;
      
      const keyValueParts = part.split('=').map((p: string): string => p.trim());
      const key: string = keyValueParts.length > 0 && keyValueParts[0] ? keyValueParts[0] : '';
      const value: string = keyValueParts.length > 1 && keyValueParts[1] ? keyValueParts[1] : '';
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
    if (!cookie.domain || cookie.domain.trim() === '') {
      cookie.domain = defaultDomain || '';
    }

    // Set default path if not specified
    if (!cookie.path || cookie.path.trim() === '') {
      cookie.path = '/';
    }

    // Final validation
    if (!cookie.domain) {
      console.warn(`[CookieService] Cookie has no domain, using empty string`);
      cookie.domain = '';
    }
    if (!cookie.path) {
      console.warn(`[CookieService] Cookie has no path, using /`);
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
    // Validate inputs
    if (!cookieDomain || !requestDomain || typeof cookieDomain !== 'string' || typeof requestDomain !== 'string') {
      console.warn(`[CookieService] Invalid domain parameters: cookieDomain=${cookieDomain}, requestDomain=${requestDomain}`);
      return false;
    }

    // Exact match
    if (cookieDomain === requestDomain) {
      return true;
    }

    // Wildcard match (e.g., .example.com matches sub.example.com)
    if (cookieDomain.startsWith('.')) {
      const domainWithoutDot = cookieDomain.substring(1);
      return requestDomain.endsWith(domainWithoutDot) ||
        requestDomain === domainWithoutDot;
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
  private static parseUrl(url: string): ParsedUrl | null {
    try {
      if (!url || typeof url !== 'string') {
        console.error(`[CookieService] Invalid URL: ${url}`);
        return null;
      }

      // Simple URL parsing
      const match = url.match(/^(https?):\/\/([^\/]+)(\/.*)?$/);
      if (!match) {
        console.error(`[CookieService] URL regex match failed for: ${url}`);
        return null;
      }

      const result: ParsedUrl = {
        protocol: match[1] + ':',
        hostname: match[2] || '',
        pathname: match[3] || '/'
      };
      
      console.info(`[CookieService] Parsed URL: protocol=${result.protocol}, hostname=${result.hostname}, pathname=${result.pathname}`);
      return result;
    } catch (error) {
      console.error(`[CookieService] Failed to parse URL: ${error}`);
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
