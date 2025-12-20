/**
 * Client Certificate Service
 * Manages client certificates for mutual TLS authentication
 * Supports PFX and PEM certificate formats
 */

// Client certificate configuration interface
interface ClientCertificate {
  id: string;
  name: string;
  host: string;
  port: number;
  enabled: boolean;
  certType: 'pfx' | 'pem';
  pfxPath: string | null;
  crtPath: string | null;
  keyPath: string | null;
  passphrase: string;
  createdAt: number;
  updatedAt: number;
}

// Certificate match result interface
interface CertificateMatchResult {
  found: boolean;
  certificate: ClientCertificate | null;
}

export class ClientCertificateService {
  private static instance: ClientCertificateService | null = null;
  
  // Certificates stored per workspace
  private certificates: Map<string, ClientCertificate[]> = new Map();

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): ClientCertificateService {
    if (!ClientCertificateService.instance) {
      ClientCertificateService.instance = new ClientCertificateService();
    }
    return ClientCertificateService.instance;
  }

  /**
   * Add a client certificate
   * @param workspaceId The workspace ID
   * @param certificate The certificate configuration
   */
  addCertificate(workspaceId: string, certificate: ClientCertificate): void {
    let workspaceCerts: ClientCertificate[] | undefined = this.certificates.get(workspaceId);
    if (!workspaceCerts) {
      workspaceCerts = [];
      this.certificates.set(workspaceId, workspaceCerts);
    }

    // Check if certificate already exists
    const existingIndex: number = workspaceCerts.findIndex(
      (c: ClientCertificate) => c.id === certificate.id
    );

    if (existingIndex >= 0) {
      // Update existing certificate
      workspaceCerts[existingIndex] = certificate;
    } else {
      // Add new certificate
      workspaceCerts.push(certificate);
    }

    console.info(`[ClientCertificateService] Added certificate for ${certificate.host}:${certificate.port}`);
  }

  /**
   * Remove a client certificate
   * @param workspaceId The workspace ID
   * @param certificateId The certificate ID
   */
  removeCertificate(workspaceId: string, certificateId: string): void {
    const workspaceCerts: ClientCertificate[] | undefined = this.certificates.get(workspaceId);
    if (!workspaceCerts) {
      return;
    }

    const filteredCerts: ClientCertificate[] = workspaceCerts.filter(
      (c: ClientCertificate) => c.id !== certificateId
    );
    this.certificates.set(workspaceId, filteredCerts);

    console.info(`[ClientCertificateService] Removed certificate: ${certificateId}`);
  }

  /**
   * Get certificate for a host and port
   * @param workspaceId The workspace ID
   * @param host The host
   * @param port The port
   * @returns The matching certificate or null
   */
  getCertificateForHost(workspaceId: string, host: string, port: number): CertificateMatchResult {
    const workspaceCerts: ClientCertificate[] | undefined = this.certificates.get(workspaceId);
    if (!workspaceCerts) {
      const result: CertificateMatchResult = { found: false, certificate: null };
      return result;
    }

    // Find matching enabled certificate
    const certificate: ClientCertificate | undefined = workspaceCerts.find(
      (c: ClientCertificate) => {
        if (!c.enabled) {
          return false;
        }
        // Match host (case-insensitive)
        if (c.host.toLowerCase() !== host.toLowerCase()) {
          return false;
        }
        // Match port (0 means any port)
        if (c.port !== 0 && c.port !== port) {
          return false;
        }
        return true;
      }
    );

    if (certificate) {
      const result: CertificateMatchResult = { found: true, certificate: certificate };
      return result;
    }

    const result: CertificateMatchResult = { found: false, certificate: null };
    return result;
  }

  /**
   * Get all certificates for a workspace
   * @param workspaceId The workspace ID
   */
  getCertificates(workspaceId: string): ClientCertificate[] {
    return this.certificates.get(workspaceId) || [];
  }

  /**
   * Enable or disable a certificate
   * @param workspaceId The workspace ID
   * @param certificateId The certificate ID
   * @param enabled Whether to enable or disable
   */
  setCertificateEnabled(workspaceId: string, certificateId: string, enabled: boolean): void {
    const workspaceCerts: ClientCertificate[] | undefined = this.certificates.get(workspaceId);
    if (!workspaceCerts) {
      return;
    }

    const certificate: ClientCertificate | undefined = workspaceCerts.find(
      (c: ClientCertificate) => c.id === certificateId
    );

    if (certificate) {
      certificate.enabled = enabled;
      certificate.updatedAt = Date.now();
      console.info(`[ClientCertificateService] Certificate ${certificateId} ${enabled ? 'enabled' : 'disabled'}`);
    }
  }

  /**
   * Clear all certificates for a workspace
   * @param workspaceId The workspace ID
   */
  clearCertificates(workspaceId: string): void {
    this.certificates.delete(workspaceId);
    console.info(`[ClientCertificateService] Cleared all certificates for workspace ${workspaceId}`);
  }

  /**
   * Create a new certificate configuration
   * @param host The host
   * @param port The port
   * @param certType The certificate type
   * @returns A new certificate configuration
   */
  createCertificate(host: string, port: number, certType: 'pfx' | 'pem'): ClientCertificate {
    const now: number = Date.now();
    const certificate: ClientCertificate = {
      id: `cert_${now}_${Math.floor(Math.random() * 10000)}`,
      name: `${host}:${port}`,
      host: host,
      port: port,
      enabled: true,
      certType: certType,
      pfxPath: null,
      crtPath: null,
      keyPath: null,
      passphrase: '',
      createdAt: now,
      updatedAt: now
    };
    return certificate;
  }

  /**
   * Validate certificate configuration
   * @param certificate The certificate to validate
   * @returns Validation error message or null if valid
   */
  validateCertificate(certificate: ClientCertificate): string | null {
    if (!certificate.host) {
      return 'Host is required';
    }

    if (certificate.certType === 'pfx') {
      if (!certificate.pfxPath) {
        return 'PFX file path is required';
      }
    } else if (certificate.certType === 'pem') {
      if (!certificate.crtPath) {
        return 'Certificate file path is required';
      }
      if (!certificate.keyPath) {
        return 'Key file path is required';
      }
    }

    return null;
  }

  /**
   * Parse host and port from URL
   * @param url The URL to parse
   * @returns Object with host and port
   */
  parseHostPort(url: string): { host: string; port: number } {
    try {
      let host: string = '';
      let port: number = 443; // Default HTTPS port

      // Remove protocol
      let urlWithoutProtocol: string = url;
      if (url.startsWith('https://')) {
        urlWithoutProtocol = url.substring(8);
        port = 443;
      } else if (url.startsWith('http://')) {
        urlWithoutProtocol = url.substring(7);
        port = 80;
      }

      // Extract host and port
      const pathIndex: number = urlWithoutProtocol.indexOf('/');
      const hostPart: string = pathIndex >= 0 ? urlWithoutProtocol.substring(0, pathIndex) : urlWithoutProtocol;

      const portIndex: number = hostPart.indexOf(':');
      if (portIndex >= 0) {
        host = hostPart.substring(0, portIndex);
        const portStr: string = hostPart.substring(portIndex + 1);
        const parsedPort: number = parseInt(portStr, 10);
        if (!isNaN(parsedPort)) {
          port = parsedPort;
        }
      } else {
        host = hostPart;
      }

      return { host, port };
    } catch (error) {
      console.error('[ClientCertificateService] Failed to parse URL:', JSON.stringify(error));
      return { host: '', port: 443 };
    }
  }
}

export type { ClientCertificate, CertificateMatchResult };
