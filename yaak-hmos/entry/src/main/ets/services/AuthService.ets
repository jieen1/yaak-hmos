/**
 * AuthService - Huawei Account authentication service
 * Provides login, logout, and user state management using Account Kit
 */

import { authentication } from '@kit.AccountKit';
import { util } from '@kit.ArkTS';
import { AuthError } from '../common/FlareError';
import type { AuthConfig } from '../model/HttpRequest';

/**
 * User information interface
 */
export interface UserInfo {
  unionId: string;
  openId: string;
  displayName: string;
  avatarUrl: string;
  email: string;
  isLoggedIn: boolean;
  loginTime: number;
}

/**
 * Authentication result interface
 */
export interface AuthResult {
  success: boolean;
  user: UserInfo | null;
  error: string;
}

/**
 * Auth state change callback type
 */
export type AuthStateCallback = (user: UserInfo | null) => void;

/**
 * 获取匿名手机号结果
 */
export interface AnonymousPhoneResult {
  success: boolean;
  anonymousPhone: string;
  errorCode: number;
  errorMessage: string;
}

/**
 * 业务错误接口
 */
interface BusinessErrorInfo {
  code: number;
  message: string;
}

/**
 * AuthService - Manages Huawei Account authentication
 */
export class AuthService {
  private static currentUser: UserInfo | null = null;
  private static callbacks: AuthStateCallback[] = [];
  private static isInitialized: boolean = false;

  /**
   * Initialize auth service
   */
  static initialize(): void {
    if (AuthService.isInitialized) {
      return;
    }
    AuthService.isInitialized = true;
    console.info('[AuthService] Initialized');
  }

  /**
   * 获取华为账号匿名手机号（用于一键登录页面展示）
   * 根据官方文档：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/account-phone-unionid-login
   */
  static async getQuickLoginAnonymousPhone(): Promise<AnonymousPhoneResult> {
    const result: AnonymousPhoneResult = {
      success: false,
      anonymousPhone: '',
      errorCode: 0,
      errorMessage: ''
    };

    try {
      // 创建授权请求
      const authRequest = new authentication.HuaweiIDProvider().createAuthorizationWithHuaweiIDRequest();
      // 获取匿名手机号需传 quickLoginAnonymousPhone 这个 scope
      authRequest.scopes = ['quickLoginAnonymousPhone'];
      // 用于防跨站点请求伪造
      authRequest.state = util.generateRandomUUID();
      // 一键登录场景该参数必须设置为 false
      authRequest.forceAuthorization = false;

      const controller = new authentication.AuthenticationController();
      const response = await controller.executeRequest(authRequest);

      const authResponse = response as authentication.AuthorizationWithHuaweiIDResponse;

      // 获取匿名手机号
      // 注意：需要在 obfuscation-rules.txt 中配置 quickLoginAnonymousPhone 属性白名单
      const extraInfo = authResponse.data?.extraInfo;
      if (extraInfo) {
        const anonymousPhone = extraInfo?.quickLoginAnonymousPhone as string;
        if (anonymousPhone && anonymousPhone.length > 0) {
          result.success = true;
          result.anonymousPhone = anonymousPhone;
          console.info('[AuthService] Got anonymous phone:', anonymousPhone);
        } else {
          result.errorMessage = '未获取到匿名手机号';
          console.info('[AuthService] Anonymous phone is empty');
        }
      } else {
        result.errorMessage = '响应数据为空';
        console.info('[AuthService] Response extraInfo is empty');
      }
    } catch (error) {
      const bizError = error as BusinessErrorInfo;
      result.errorCode = bizError.code;
      result.errorMessage = bizError.message || '获取匿名手机号失败';
      console.error('[AuthService] Get anonymous phone failed:', result.errorCode, result.errorMessage);
    }

    return result;
  }

  /**
   * Login with Huawei ID
   */
  static async loginWithHuaweiID(): Promise<AuthResult> {
    const result: AuthResult = {
      success: false,
      user: null,
      error: ''
    };

    try {
      // Create login request
      const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
      loginRequest.forceLogin = false;
      loginRequest.state = util.generateRandomUUID();

      // Execute authentication
      const controller = new authentication.AuthenticationController();
      const response = await controller.executeRequest(loginRequest);

      // Handle response
      const loginResponse = response as authentication.AuthorizationWithHuaweiIDResponse;

      if (loginResponse.state !== loginRequest.state) {
        result.error = 'State mismatch, possible security issue';
        return result;
      }

      // Extract user info from response
      const userInfo: UserInfo = {
        unionId: loginResponse.data?.unionID || '',
        openId: loginResponse.data?.openID || '',
        displayName: loginResponse.data?.nickName || '',
        avatarUrl: loginResponse.data?.avatarUri || '',
        email: loginResponse.data?.email || '',
        isLoggedIn: true,
        loginTime: Date.now()
      };

      AuthService.currentUser = userInfo;
      AuthService.notifyCallbacks(userInfo);

      result.success = true;
      result.user = userInfo;

      console.info('[AuthService] Login successful:', userInfo.displayName);
    } catch (error) {
      const authError = AuthService.handleAuthError(error);
      result.error = authError.message;
      console.error('[AuthService] Login failed:', error);
    }

    return result;
  }

  /**
   * Silent login for already authorized users
   */
  static async silentLogin(): Promise<AuthResult> {
    const result: AuthResult = {
      success: false,
      user: null,
      error: ''
    };

    try {
      // Create silent login request
      const loginRequest = new authentication.HuaweiIDProvider().createLoginWithHuaweiIDRequest();
      loginRequest.forceLogin = false;
      loginRequest.state = util.generateRandomUUID();

      // Execute authentication
      const controller = new authentication.AuthenticationController();
      const response = await controller.executeRequest(loginRequest);

      // Handle response
      const loginResponse = response as authentication.AuthorizationWithHuaweiIDResponse;

      if (loginResponse.data?.unionID) {
        const userInfo: UserInfo = {
          unionId: loginResponse.data.unionID || '',
          openId: loginResponse.data.openID || '',
          displayName: loginResponse.data.nickName || '',
          avatarUrl: loginResponse.data.avatarUri || '',
          email: loginResponse.data.email || '',
          isLoggedIn: true,
          loginTime: Date.now()
        };

        AuthService.currentUser = userInfo;
        AuthService.notifyCallbacks(userInfo);

        result.success = true;
        result.user = userInfo;

        console.info('[AuthService] Silent login successful');
      } else {
        result.error = 'No valid session found';
      }
    } catch (error) {
      result.error = 'Silent login failed';
      console.info('[AuthService] Silent login failed, user needs to login manually');
    }

    return result;
  }

  /**
   * Logout current user
   */
  static async logout(clearLocalData: boolean = false): Promise<void> {
    try {
      // Cancel authorization
      const cancelRequest = new authentication.HuaweiIDProvider().createCancelAuthorizationRequest();
      const controller = new authentication.AuthenticationController();
      
      await controller.executeRequest(cancelRequest);
      
      console.info('[AuthService] Authorization cancelled');
    } catch (error) {
      console.warn('[AuthService] Cancel authorization failed:', error);
    }

    // Clear local user state
    AuthService.currentUser = null;
    AuthService.notifyCallbacks(null);

    console.info('[AuthService] Logout completed, clearLocalData:', clearLocalData);
  }

  /**
   * Get current user info
   */
  static getCurrentUser(): UserInfo | null {
    return AuthService.currentUser;
  }

  /**
   * Check if user is logged in
   */
  static isLoggedIn(): boolean {
    return AuthService.currentUser !== null && AuthService.currentUser.isLoggedIn;
  }

  /**
   * Set current user (for restoring from storage)
   */
  static setCurrentUser(user: UserInfo | null): void {
    AuthService.currentUser = user;
    AuthService.notifyCallbacks(user);
  }

  /**
   * Register auth state change callback
   */
  static onAuthStateChanged(callback: AuthStateCallback): void {
    AuthService.callbacks.push(callback);
  }

  /**
   * Unregister auth state change callback
   */
  static offAuthStateChanged(callback: AuthStateCallback): void {
    const index = AuthService.callbacks.indexOf(callback);
    if (index > -1) {
      AuthService.callbacks.splice(index, 1);
    }
  }

  /**
   * Notify all registered callbacks
   */
  private static notifyCallbacks(user: UserInfo | null): void {
    AuthService.callbacks.forEach((callback: AuthStateCallback) => {
      try {
        callback(user);
      } catch (error) {
        console.error('[AuthService] Callback error:', error);
      }
    });
  }

  /**
   * Get authentication headers based on auth config
   * Used by RequestExecutor to apply authentication to requests
   */
  static getAuthHeaders(auth: AuthConfig, variables: Map<string, string>): Record<string, string> {
    const headers: Record<string, string> = {};

    if (!auth || auth.type === 'none' || auth.type === 'inherit') {
      return headers;
    }

    switch (auth.type) {
      case 'basic': {
        const username = AuthService.resolveVariable(auth.basic_username || '', variables);
        const password = AuthService.resolveVariable(auth.basic_password || '', variables);
        const credentials = `${username}:${password}`;
        // Base64 encode credentials
        const encoded = AuthService.base64Encode(credentials);
        headers['Authorization'] = `Basic ${encoded}`;
        break;
      }
      case 'bearer': {
        const token = AuthService.resolveVariable(auth.bearer_token || '', variables);
        headers['Authorization'] = `Bearer ${token}`;
        break;
      }
      case 'api-key': {
        // Only add to headers if location is 'header'
        if (auth.api_key_location === 'header') {
          const name = AuthService.resolveVariable(auth.api_key_name || 'X-API-Key', variables);
          const value = AuthService.resolveVariable(auth.api_key_value || '', variables);
          headers[name] = value;
        }
        break;
      }
      default:
        break;
    }

    return headers;
  }

  /**
   * Get API key query parameters if auth type is api-key with query location
   */
  static getApiKeyQueryParams(auth: AuthConfig | null, variables: Map<string, string>): Record<string, string> {
    const params: Record<string, string> = {};

    if (!auth || auth.type !== 'api-key' || auth.api_key_location !== 'query') {
      return params;
    }

    const name = AuthService.resolveVariable(auth.api_key_name || 'api_key', variables);
    const value = AuthService.resolveVariable(auth.api_key_value || '', variables);
    params[name] = value;

    return params;
  }

  /**
   * Resolve template variable in string
   */
  private static resolveVariable(value: string, variables: Map<string, string>): string {
    if (!value) {
      return value;
    }
    
    let result = value;
    variables.forEach((varValue: string, varName: string) => {
      const pattern = `{{${varName}}}`;
      while (result.includes(pattern)) {
        result = result.replace(pattern, varValue);
      }
    });
    
    return result;
  }

  /**
   * Base64 encode string
   */
  private static base64Encode(str: string): string {
    try {
      const textEncoder = new util.TextEncoder();
      const uint8Array = textEncoder.encodeInto(str);
      const base64Helper = new util.Base64Helper();
      return base64Helper.encodeToStringSync(uint8Array);
    } catch (error) {
      console.error('[AuthService] Base64 encode failed:', error);
      return '';
    }
  }

  /**
   * Handle authentication errors
   */
  private static handleAuthError(error: Object): AuthError {
    const errorStr = String(error);
    
    if (errorStr.includes('cancel') || errorStr.includes('Cancel')) {
      return AuthError.cancelled();
    }
    
    if (errorStr.includes('network') || errorStr.includes('Network')) {
      return AuthError.networkError();
    }
    
    if (errorStr.includes('disabled') || errorStr.includes('Disabled')) {
      return AuthError.accountDisabled();
    }
    
    if (errorStr.includes('expired') || errorStr.includes('Expired')) {
      return AuthError.tokenExpired();
    }
    
    return AuthError.unknown(errorStr);
  }
}
