/**
 * Encryption Service
 * Provides encryption and decryption for sensitive data using HarmonyOS HUKS
 * Uses AES-256-GCM for encryption
 */

import { huks } from '@kit.UniversalKeystoreKit';
import { util } from '@kit.ArkTS';

// Key alias for the encryption key
const KEY_ALIAS: string = 'yaak_encryption_key';

// AES-GCM parameters
const AES_KEY_SIZE: number = 256;
const GCM_TAG_SIZE: number = 128;
const GCM_NONCE_SIZE: number = 12;

// Encryption result interface
interface EncryptionResult {
  ciphertext: string;
  nonce: string;
}

export class EncryptionService {
  private static instance: EncryptionService | null = null;
  private keyExists: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): EncryptionService {
    if (!EncryptionService.instance) {
      EncryptionService.instance = new EncryptionService();
    }
    return EncryptionService.instance;
  }

  /**
   * Initialize the encryption service
   * Creates the encryption key if it doesn't exist
   */
  async init(): Promise<void> {
    try {
      const exists: boolean = await this.checkKeyExists();
      if (!exists) {
        await this.createKey();
      }
      this.keyExists = true;
      console.info('[EncryptionService] Initialized successfully');
    } catch (error) {
      console.error('[EncryptionService] Initialization failed:', JSON.stringify(error));
      throw new Error('Failed to initialize encryption service');
    }
  }

  /**
   * Check if the encryption key exists in HUKS
   */
  private async checkKeyExists(): Promise<boolean> {
    try {
      const options: huks.HuksOptions = {
        properties: []
      };
      return await huks.isKeyItemExist(KEY_ALIAS, options);
    } catch (error) {
      console.info('[EncryptionService] Key does not exist, will create new one');
      return false;
    }
  }

  /**
   * Create a new AES-256 encryption key in HUKS
   */
  private async createKey(): Promise<void> {
    const properties: huks.HuksParam[] = [
      {
        tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
        value: huks.HuksKeyAlg.HUKS_ALG_AES
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PURPOSE,
        value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT | huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
      },
      {
        tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
        value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
      },
      {
        tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
        value: huks.HuksCipherMode.HUKS_MODE_GCM
      },
      {
        tag: huks.HuksTag.HUKS_TAG_PADDING,
        value: huks.HuksKeyPadding.HUKS_PADDING_NONE
      }
    ];

    const options: huks.HuksOptions = {
      properties: properties
    };

    try {
      await huks.generateKeyItem(KEY_ALIAS, options);
      console.info('[EncryptionService] Encryption key created successfully');
    } catch (error) {
      console.error('[EncryptionService] Failed to create encryption key:', JSON.stringify(error));
      throw new Error('Failed to create encryption key');
    }
  }

  /**
   * Get or create the encryption key
   * Returns true if key is available
   */
  async getOrCreateKey(): Promise<boolean> {
    if (this.keyExists) {
      return true;
    }
    await this.init();
    return this.keyExists;
  }

  /**
   * Generate a random nonce for GCM mode
   */
  private generateNonce(): Uint8Array {
    const nonce: Uint8Array = new Uint8Array(GCM_NONCE_SIZE);
    for (let i = 0; i < GCM_NONCE_SIZE; i++) {
      nonce[i] = Math.floor(Math.random() * 256);
    }
    return nonce;
  }

  /**
   * Encrypt sensitive data using AES-256-GCM
   * @param plaintext The data to encrypt
   * @returns Encrypted data with nonce, or null if encryption fails
   */
  async encryptSensitiveData(plaintext: string): Promise<string | null> {
    if (!plaintext || plaintext.length === 0) {
      return null;
    }

    try {
      await this.getOrCreateKey();

      const nonce: Uint8Array = this.generateNonce();
      const textEncoder: util.TextEncoder = new util.TextEncoder();
      const plaintextBytes: Uint8Array = textEncoder.encodeInto(plaintext);

      // Encryption properties
      const encryptProperties: huks.HuksParam[] = [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_ENCRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_GCM
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_NONE
        },
        {
          tag: huks.HuksTag.HUKS_TAG_NONCE,
          value: nonce
        },
        {
          tag: huks.HuksTag.HUKS_TAG_AE_TAG,
          value: new Uint8Array(GCM_TAG_SIZE / 8)
        }
      ];

      const encryptOptions: huks.HuksOptions = {
        properties: encryptProperties,
        inData: plaintextBytes
      };

      // Init encryption session
      const initResult: huks.HuksSessionHandle = await huks.initSession(KEY_ALIAS, encryptOptions);
      const handle: number = initResult.handle;

      // Finish encryption
      const finishOptions: huks.HuksOptions = {
        properties: encryptProperties,
        inData: plaintextBytes
      };
      const finishResult: huks.HuksReturnResult = await huks.finishSession(handle, finishOptions);

      if (!finishResult.outData) {
        throw new Error('Encryption returned no data');
      }

      // Encode result as base64
      const base64Helper: util.Base64Helper = new util.Base64Helper();
      const ciphertextBase64: string = base64Helper.encodeToStringSync(finishResult.outData);
      const nonceBase64: string = base64Helper.encodeToStringSync(nonce);

      // Return combined result: nonce:ciphertext
      const result: EncryptionResult = {
        ciphertext: ciphertextBase64,
        nonce: nonceBase64
      };
      return JSON.stringify(result);

    } catch (error) {
      console.error('[EncryptionService] Encryption failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Decrypt sensitive data using AES-256-GCM
   * @param encryptedData The encrypted data (JSON with ciphertext and nonce)
   * @returns Decrypted plaintext, or null if decryption fails
   */
  async decryptSensitiveData(encryptedData: string): Promise<string | null> {
    if (!encryptedData || encryptedData.length === 0) {
      return null;
    }

    try {
      await this.getOrCreateKey();

      // Parse encrypted data
      const parsed: EncryptionResult = JSON.parse(encryptedData) as EncryptionResult;
      const base64Helper: util.Base64Helper = new util.Base64Helper();
      const ciphertext: Uint8Array = base64Helper.decodeSync(parsed.ciphertext);
      const nonce: Uint8Array = base64Helper.decodeSync(parsed.nonce);

      // Decryption properties
      const decryptProperties: huks.HuksParam[] = [
        {
          tag: huks.HuksTag.HUKS_TAG_ALGORITHM,
          value: huks.HuksKeyAlg.HUKS_ALG_AES
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PURPOSE,
          value: huks.HuksKeyPurpose.HUKS_KEY_PURPOSE_DECRYPT
        },
        {
          tag: huks.HuksTag.HUKS_TAG_KEY_SIZE,
          value: huks.HuksKeySize.HUKS_AES_KEY_SIZE_256
        },
        {
          tag: huks.HuksTag.HUKS_TAG_BLOCK_MODE,
          value: huks.HuksCipherMode.HUKS_MODE_GCM
        },
        {
          tag: huks.HuksTag.HUKS_TAG_PADDING,
          value: huks.HuksKeyPadding.HUKS_PADDING_NONE
        },
        {
          tag: huks.HuksTag.HUKS_TAG_NONCE,
          value: nonce
        },
        {
          tag: huks.HuksTag.HUKS_TAG_AE_TAG,
          value: new Uint8Array(GCM_TAG_SIZE / 8)
        }
      ];

      const decryptOptions: huks.HuksOptions = {
        properties: decryptProperties,
        inData: ciphertext
      };

      // Init decryption session
      const initResult: huks.HuksSessionHandle = await huks.initSession(KEY_ALIAS, decryptOptions);
      const handle: number = initResult.handle;

      // Finish decryption
      const finishOptions: huks.HuksOptions = {
        properties: decryptProperties,
        inData: ciphertext
      };
      const finishResult: huks.HuksReturnResult = await huks.finishSession(handle, finishOptions);

      if (!finishResult.outData) {
        throw new Error('Decryption returned no data');
      }

      // Decode result
      const textDecoder: util.TextDecoder = util.TextDecoder.create('utf-8');
      const plaintext: string = textDecoder.decodeToString(finishResult.outData);
      return plaintext;

    } catch (error) {
      console.error('[EncryptionService] Decryption failed:', JSON.stringify(error));
      return null;
    }
  }

  /**
   * Check if a string is encrypted (has the expected format)
   */
  isEncrypted(data: string): boolean {
    if (!data || data.length === 0) {
      return false;
    }
    try {
      const parsed: ESObject = JSON.parse(data) as ESObject;
      return typeof parsed.ciphertext === 'string' && typeof parsed.nonce === 'string';
    } catch {
      return false;
    }
  }

  /**
   * Delete the encryption key (use with caution - all encrypted data will be unrecoverable)
   */
  async deleteKey(): Promise<void> {
    try {
      const options: huks.HuksOptions = {
        properties: []
      };
      await huks.deleteKeyItem(KEY_ALIAS, options);
      this.keyExists = false;
      console.info('[EncryptionService] Encryption key deleted');
    } catch (error) {
      console.error('[EncryptionService] Failed to delete encryption key:', JSON.stringify(error));
    }
  }
}
