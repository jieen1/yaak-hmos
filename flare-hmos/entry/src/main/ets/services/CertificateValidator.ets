/**
 * Certificate Validator Service
 * Handles SSL/TLS certificate validation for HTTP requests
 * Supports disabling validation for self-signed certificates (with warning)
 */

// Certificate exception interface
interface CertificateException {
  host: string;
  port: number;
  fingerprint: string;
  addedAt: number;
  reason: string;
}

// Validation result interface
interface ValidationResult {
  valid: boolean;
  error: string | null;
  isException: boolean;
}

export class CertificateValidator {
  private static instance: CertificateValidator | null = null;
  
  // Certificate exceptions stored per workspace
  private exceptions: Map<string, CertificateException[]> = new Map();

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): CertificateValidator {
    if (!CertificateValidator.instance) {
      CertificateValidator.instance = new CertificateValidator();
    }
    return CertificateValidator.instance;
  }

  /**
   * Validate a certificate for a given host
   * @param host The hostname
   * @param port The port number
   * @param workspaceId The workspace ID for exception lookup
   * @param validateCertificates Whether to validate certificates (from workspace settings)
   * @returns Validation result
   */
  validateCertificate(
    host: string,
    port: number,
    workspaceId: string,
    validateCertificates: boolean
  ): ValidationResult {
    // If validation is disabled, return valid with warning
    if (!validateCertificates) {
      console.warn(`[CertificateValidator] Certificate validation disabled for ${host}:${port}`);
      const result: ValidationResult = {
        valid: true,
        error: null,
        isException: true
      };
      return result;
    }

    // Check if there's an exception for this host
    const exception: CertificateException | null = this.getException(workspaceId, host, port);
    if (exception) {
      console.info(`[CertificateValidator] Using certificate exception for ${host}:${port}`);
      const result: ValidationResult = {
        valid: true,
        error: null,
        isException: true
      };
      return result;
    }

    // Default: certificate is valid (actual validation happens in HTTP layer)
    const result: ValidationResult = {
      valid: true,
      error: null,
      isException: false
    };
    return result;
  }

  /**
   * Add a certificate exception for a host
   * @param workspaceId The workspace ID
   * @param host The hostname
   * @param port The port number
   * @param fingerprint The certificate fingerprint
   * @param reason The reason for adding the exception
   */
  addException(
    workspaceId: string,
    host: string,
    port: number,
    fingerprint: string,
    reason: string
  ): void {
    let workspaceExceptions: CertificateException[] | undefined = this.exceptions.get(workspaceId);
    if (!workspaceExceptions) {
      workspaceExceptions = [];
      this.exceptions.set(workspaceId, workspaceExceptions);
    }

    // Check if exception already exists
    const existingIndex: number = workspaceExceptions.findIndex(
      (e: CertificateException) => e.host === host && e.port === port
    );

    const exception: CertificateException = {
      host: host,
      port: port,
      fingerprint: fingerprint,
      addedAt: Date.now(),
      reason: reason
    };

    if (existingIndex >= 0) {
      // Update existing exception
      workspaceExceptions[existingIndex] = exception;
    } else {
      // Add new exception
      workspaceExceptions.push(exception);
    }

    console.info(`[CertificateValidator] Added certificate exception for ${host}:${port}`);
  }

  /**
   * Remove a certificate exception
   * @param workspaceId The workspace ID
   * @param host The hostname
   * @param port The port number
   */
  removeException(workspaceId: string, host: string, port: number): void {
    const workspaceExceptions: CertificateException[] | undefined = this.exceptions.get(workspaceId);
    if (!workspaceExceptions) {
      return;
    }

    const filteredExceptions: CertificateException[] = workspaceExceptions.filter(
      (e: CertificateException) => !(e.host === host && e.port === port)
    );
    this.exceptions.set(workspaceId, filteredExceptions);

    console.info(`[CertificateValidator] Removed certificate exception for ${host}:${port}`);
  }

  /**
   * Get a certificate exception for a host
   * @param workspaceId The workspace ID
   * @param host The hostname
   * @param port The port number
   * @returns The exception if found, null otherwise
   */
  getException(workspaceId: string, host: string, port: number): CertificateException | null {
    const workspaceExceptions: CertificateException[] | undefined = this.exceptions.get(workspaceId);
    if (!workspaceExceptions) {
      return null;
    }

    const exception: CertificateException | undefined = workspaceExceptions.find(
      (e: CertificateException) => e.host === host && e.port === port
    );
    return exception || null;
  }

  /**
   * Get all certificate exceptions for a workspace
   * @param workspaceId The workspace ID
   * @returns Array of certificate exceptions
   */
  getExceptions(workspaceId: string): CertificateException[] {
    return this.exceptions.get(workspaceId) || [];
  }

  /**
   * Clear all certificate exceptions for a workspace
   * @param workspaceId The workspace ID
   */
  clearExceptions(workspaceId: string): void {
    this.exceptions.delete(workspaceId);
    console.info(`[CertificateValidator] Cleared all certificate exceptions for workspace ${workspaceId}`);
  }

  /**
   * Check if validation is disabled (returns warning message)
   * @param validateCertificates Whether validation is enabled
   * @returns Warning message if validation is disabled, null otherwise
   */
  getValidationWarning(validateCertificates: boolean): string | null {
    if (!validateCertificates) {
      return 'Certificate validation is disabled. This may expose you to security risks.';
    }
    return null;
  }
}

export type { CertificateException, ValidationResult };
