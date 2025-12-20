/**
 * Secure Data Service
 * Handles encryption and decryption of sensitive data in models
 * Encrypts: secret environment variables, auth credentials (passwords, tokens)
 */

import { EncryptionService } from './EncryptionService';
import { Environment, EnvironmentVariable } from '../model/Environment';
import { AuthConfig } from '../model/HttpRequest';

// Prefix to identify encrypted values
const ENCRYPTED_PREFIX: string = 'ENC:';

export class SecureDataService {
  private static instance: SecureDataService | null = null;
  private encryptionService: EncryptionService;
  private initialized: boolean = false;

  private constructor() {
    this.encryptionService = EncryptionService.getInstance();
  }

  /**
   * Get singleton instance
   */
  static getInstance(): SecureDataService {
    if (!SecureDataService.instance) {
      SecureDataService.instance = new SecureDataService();
    }
    return SecureDataService.instance;
  }

  /**
   * Initialize the service
   */
  async init(): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      await this.encryptionService.init();
      this.initialized = true;
      console.info('[SecureDataService] Initialized successfully');
    } catch (error) {
      console.error('[SecureDataService] Initialization failed:', JSON.stringify(error));
      // Continue without encryption - data will be stored in plain text
      this.initialized = true;
    }
  }

  /**
   * Check if a value is encrypted
   */
  private isEncrypted(value: string): boolean {
    return value.startsWith(ENCRYPTED_PREFIX);
  }

  /**
   * Encrypt a single value
   */
  private async encryptValue(value: string): Promise<string> {
    if (!value || value.length === 0) {
      return value;
    }
    if (this.isEncrypted(value)) {
      return value; // Already encrypted
    }
    try {
      const encrypted: string | null = await this.encryptionService.encryptSensitiveData(value);
      if (encrypted) {
        return ENCRYPTED_PREFIX + encrypted;
      }
      return value; // Return plain text if encryption fails
    } catch (error) {
      console.error('[SecureDataService] Encryption failed:', JSON.stringify(error));
      return value;
    }
  }

  /**
   * Decrypt a single value
   */
  private async decryptValue(value: string): Promise<string> {
    if (!value || value.length === 0) {
      return value;
    }
    if (!this.isEncrypted(value)) {
      return value; // Not encrypted
    }
    try {
      const encryptedData: string = value.substring(ENCRYPTED_PREFIX.length);
      const decrypted: string | null = await this.encryptionService.decryptSensitiveData(encryptedData);
      if (decrypted) {
        return decrypted;
      }
      return ''; // Return empty string if decryption fails
    } catch (error) {
      console.error('[SecureDataService] Decryption failed:', JSON.stringify(error));
      return '';
    }
  }

  /**
   * Encrypt sensitive environment variables before saving
   * Only encrypts variables marked as is_secret
   */
  async encryptEnvironmentVariables(variables: EnvironmentVariable[]): Promise<EnvironmentVariable[]> {
    await this.init();
    const result: EnvironmentVariable[] = [];
    
    for (let i = 0; i < variables.length; i++) {
      const variable: EnvironmentVariable | undefined = variables[i];
      if (variable) {
        const encryptedVar: EnvironmentVariable = new EnvironmentVariable();
        encryptedVar.id = variable.id;
        encryptedVar.name = variable.name;
        encryptedVar.enabled = variable.enabled;
        encryptedVar.is_secret = variable.is_secret;
        
        if (variable.is_secret && variable.value) {
          encryptedVar.value = await this.encryptValue(variable.value);
        } else {
          encryptedVar.value = variable.value;
        }
        result.push(encryptedVar);
      }
    }
    
    return result;
  }

  /**
   * Decrypt sensitive environment variables after loading
   */
  async decryptEnvironmentVariables(variables: EnvironmentVariable[]): Promise<EnvironmentVariable[]> {
    await this.init();
    const result: EnvironmentVariable[] = [];
    
    for (let i = 0; i < variables.length; i++) {
      const variable: EnvironmentVariable | undefined = variables[i];
      if (variable) {
        const decryptedVar: EnvironmentVariable = new EnvironmentVariable();
        decryptedVar.id = variable.id;
        decryptedVar.name = variable.name;
        decryptedVar.enabled = variable.enabled;
        decryptedVar.is_secret = variable.is_secret;
        
        if (variable.is_secret && variable.value && this.isEncrypted(variable.value)) {
          decryptedVar.value = await this.decryptValue(variable.value);
        } else {
          decryptedVar.value = variable.value;
        }
        result.push(decryptedVar);
      }
    }
    
    return result;
  }

  /**
   * Encrypt auth credentials before saving
   * Encrypts: basic_password, bearer_token, api_key_value, oauth2 tokens
   */
  async encryptAuthConfig(auth: AuthConfig): Promise<AuthConfig> {
    await this.init();
    
    const encryptedAuth: AuthConfig = new AuthConfig();
    encryptedAuth.type = auth.type;
    encryptedAuth.basic_username = auth.basic_username;
    encryptedAuth.api_key_name = auth.api_key_name;
    encryptedAuth.api_key_location = auth.api_key_location;
    encryptedAuth.oauth2_expires_at = auth.oauth2_expires_at;
    
    // Encrypt sensitive fields
    encryptedAuth.basic_password = await this.encryptValue(auth.basic_password);
    encryptedAuth.bearer_token = await this.encryptValue(auth.bearer_token);
    encryptedAuth.api_key_value = await this.encryptValue(auth.api_key_value);
    encryptedAuth.oauth2_access_token = await this.encryptValue(auth.oauth2_access_token);
    encryptedAuth.oauth2_refresh_token = await this.encryptValue(auth.oauth2_refresh_token);
    
    return encryptedAuth;
  }

  /**
   * Decrypt auth credentials after loading
   */
  async decryptAuthConfig(auth: AuthConfig): Promise<AuthConfig> {
    await this.init();
    
    const decryptedAuth: AuthConfig = new AuthConfig();
    decryptedAuth.type = auth.type;
    decryptedAuth.basic_username = auth.basic_username;
    decryptedAuth.api_key_name = auth.api_key_name;
    decryptedAuth.api_key_location = auth.api_key_location;
    decryptedAuth.oauth2_expires_at = auth.oauth2_expires_at;
    
    // Decrypt sensitive fields
    decryptedAuth.basic_password = await this.decryptValue(auth.basic_password);
    decryptedAuth.bearer_token = await this.decryptValue(auth.bearer_token);
    decryptedAuth.api_key_value = await this.decryptValue(auth.api_key_value);
    decryptedAuth.oauth2_access_token = await this.decryptValue(auth.oauth2_access_token);
    decryptedAuth.oauth2_refresh_token = await this.decryptValue(auth.oauth2_refresh_token);
    
    return decryptedAuth;
  }

  /**
   * Encrypt entire environment before saving
   */
  async encryptEnvironment(environment: Environment): Promise<Environment> {
    const encryptedEnv: Environment = new Environment();
    encryptedEnv.id = environment.id;
    encryptedEnv.model = environment.model;
    encryptedEnv.workspace_id = environment.workspace_id;
    encryptedEnv.created_at = environment.created_at;
    encryptedEnv.updated_at = environment.updated_at;
    encryptedEnv.deleted_at = environment.deleted_at;
    encryptedEnv.name = environment.name;
    encryptedEnv.variables = await this.encryptEnvironmentVariables(environment.variables);
    return encryptedEnv;
  }

  /**
   * Decrypt entire environment after loading
   */
  async decryptEnvironment(environment: Environment): Promise<Environment> {
    const decryptedEnv: Environment = new Environment();
    decryptedEnv.id = environment.id;
    decryptedEnv.model = environment.model;
    decryptedEnv.workspace_id = environment.workspace_id;
    decryptedEnv.created_at = environment.created_at;
    decryptedEnv.updated_at = environment.updated_at;
    decryptedEnv.deleted_at = environment.deleted_at;
    decryptedEnv.name = environment.name;
    decryptedEnv.variables = await this.decryptEnvironmentVariables(environment.variables);
    return decryptedEnv;
  }
}
