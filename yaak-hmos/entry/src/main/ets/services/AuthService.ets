/**
 * Auth Service
 * Handles authentication for HTTP requests
 * Supports Basic Auth, Bearer Token, API Key, and OAuth2
 */

import util from '@ohos.util';
import { AuthConfig } from '../model/HttpRequest';
import { TemplateEngine } from './TemplateEngine';

export class AuthService {
  /**
   * Get authentication headers based on auth configuration
   */
  static getAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    switch (auth.type) {
      case 'basic':
        return AuthService.getBasicAuthHeaders(auth, variables);
      case 'bearer':
        return AuthService.getBearerAuthHeaders(auth, variables);
      case 'api-key':
        return AuthService.getApiKeyHeaders(auth, variables);
      case 'oauth2':
        return AuthService.getOAuth2Headers(auth, variables);
      case 'none':
      default:
        const emptyHeaders: Record<string, string> = {};
        return emptyHeaders;
    }
  }

  /**
   * Get Basic Auth headers
   * Format: Authorization: Basic base64(username:password)
   */
  private static getBasicAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const username = TemplateEngine.resolve(auth.basic_username, variables);
    const password = TemplateEngine.resolve(auth.basic_password, variables);

    if (!username) {
      console.warn('Basic Auth: username is empty');
      const emptyHeaders: Record<string, string> = {};
      return emptyHeaders;
    }

    try {
      const credentials = `${username}:${password}`;
      const helper = new util.Base64Helper();
      const uint8Array = new util.TextEncoder().encodeInto(credentials);
      const encoded = helper.encodeToStringSync(uint8Array);

      return {
        'Authorization': `Basic ${encoded}`
      };
    } catch (error) {
      console.error(`Basic Auth encoding error: ${error}`);
      const emptyHeaders: Record<string, string> = {};
      return emptyHeaders;
    }
  }

  /**
   * Get Bearer Token headers
   * Format: Authorization: Bearer <token>
   */
  private static getBearerAuthHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const token = TemplateEngine.resolve(auth.bearer_token, variables);

    if (!token) {
      console.warn('Bearer Auth: token is empty');
      const emptyHeaders: Record<string, string> = {};
      return emptyHeaders;
    }

    return {
      'Authorization': `Bearer ${token}`
    };
  }

  /**
   * Get API Key headers or query parameters
   * Can be added as header or query parameter based on location
   */
  private static getApiKeyHeaders(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const name = TemplateEngine.resolve(auth.api_key_name, variables);
    const value = TemplateEngine.resolve(auth.api_key_value, variables);

    if (!name || !value) {
      console.warn('API Key Auth: name or value is empty');
      return {};
    }

    // Only return headers if location is 'header'
    // Query parameters are handled separately in URL building
    if (auth.api_key_location === 'header') {
      const headers: Record<string, string> = {};
      headers[name] = value;
      return headers;
    }

    const emptyHeaders: Record<string, string> = {};
    return emptyHeaders;
  }

  /**
   * Get OAuth2 headers
   * Format: Authorization: Bearer <access_token>
   */
  private static getOAuth2Headers(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    const accessToken = TemplateEngine.resolve(auth.oauth2_access_token, variables);

    if (!accessToken) {
      console.warn('OAuth2 Auth: access token is empty');
      const emptyHeaders: Record<string, string> = {};
      return emptyHeaders;
    }

    return {
      'Authorization': `Bearer ${accessToken}`
    };
  }

  /**
   * Get API Key query parameters (if location is 'query')
   */
  static getApiKeyQueryParams(
    auth: AuthConfig,
    variables: Map<string, string>
  ): Record<string, string> {
    if (auth.type !== 'api-key' || auth.api_key_location !== 'query') {
      const emptyParams: Record<string, string> = {};
      return emptyParams;
    }

    const name = TemplateEngine.resolve(auth.api_key_name, variables);
    const value = TemplateEngine.resolve(auth.api_key_value, variables);

    if (!name || !value) {
      const emptyParams: Record<string, string> = {};
      return emptyParams;
    }

    const params: Record<string, string> = {};
    params[name] = value;
    return params;
  }

  /**
   * Check if OAuth2 token is expired
   */
  static isOAuth2TokenExpired(auth: AuthConfig): boolean {
    if (auth.type !== 'oauth2' || !auth.oauth2_expires_at) {
      return false;
    }

    return Date.now() >= auth.oauth2_expires_at;
  }

  /**
   * Check if auth configuration is valid
   */
  static isAuthValid(auth: AuthConfig): boolean {
    switch (auth.type) {
      case 'basic':
        return !!auth.basic_username;
      case 'bearer':
        return !!auth.bearer_token;
      case 'api-key':
        return !!auth.api_key_name && !!auth.api_key_value;
      case 'oauth2':
        return !!auth.oauth2_access_token && !AuthService.isOAuth2TokenExpired(auth);
      case 'none':
      default:
        return true;
    }
  }
}
