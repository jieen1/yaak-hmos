/**
 * NetworkService - Network status monitoring service
 * Provides network connectivity status and change notifications
 */

import { connection } from '@kit.NetworkKit';

/**
 * Network status information
 */
export interface NetworkStatus {
  isOnline: boolean;
  isWifi: boolean;
  isCellular: boolean;
  networkType: string;
}

/**
 * Network status change callback type
 */
export type NetworkStatusCallback = (status: NetworkStatus) => void;

/**
 * NetworkService - Monitors network connectivity status
 */
export class NetworkService {
  private static instance: NetworkService | null = null;
  private netConnection: connection.NetConnection | null = null;
  private currentStatus: NetworkStatus;
  private callbacks: NetworkStatusCallback[] = [];
  private isInitialized: boolean = false;

  private constructor() {
    this.currentStatus = {
      isOnline: false,
      isWifi: false,
      isCellular: false,
      networkType: 'none'
    };
  }

  /**
   * Get singleton instance
   */
  static getInstance(): NetworkService {
    if (NetworkService.instance === null) {
      NetworkService.instance = new NetworkService();
    }
    return NetworkService.instance;
  }

  /**
   * Initialize network monitoring
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      // Get initial network status
      await this.updateNetworkStatus();

      // Create network connection for monitoring
      this.netConnection = connection.createNetConnection();

      // Register network available callback
      this.netConnection.on('netAvailable', () => {
        console.info('[NetworkService] Network available');
        this.handleNetworkChange(true);
      });

      // Register network unavailable callback
      this.netConnection.on('netUnavailable', () => {
        console.info('[NetworkService] Network unavailable');
        this.handleNetworkChange(false);
      });

      // Register the connection
      this.netConnection.register(() => {
        console.info('[NetworkService] Network connection registered');
      });

      this.isInitialized = true;
      console.info('[NetworkService] Initialized successfully');
    } catch (error) {
      console.error('[NetworkService] Initialize failed:', error);
    }
  }

  /**
   * Update current network status
   */
  private async updateNetworkStatus(): Promise<void> {
    try {
      const hasNet = await connection.hasDefaultNet();
      
      if (hasNet) {
        const netHandle = await connection.getDefaultNet();
        const netCapabilities = await connection.getNetCapabilities(netHandle);
        
        const isWifi = netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_WIFI);
        const isCellular = netCapabilities.bearerTypes.includes(connection.NetBearType.BEARER_CELLULAR);
        
        let networkType = 'unknown';
        if (isWifi) {
          networkType = 'wifi';
        } else if (isCellular) {
          networkType = 'cellular';
        }

        this.currentStatus = {
          isOnline: true,
          isWifi: isWifi,
          isCellular: isCellular,
          networkType: networkType
        };
      } else {
        this.currentStatus = {
          isOnline: false,
          isWifi: false,
          isCellular: false,
          networkType: 'none'
        };
      }
    } catch (error) {
      console.error('[NetworkService] Update status failed:', error);
      this.currentStatus = {
        isOnline: false,
        isWifi: false,
        isCellular: false,
        networkType: 'none'
      };
    }
  }

  /**
   * Handle network change event
   */
  private handleNetworkChange(isAvailable: boolean): void {
    if (isAvailable) {
      this.updateNetworkStatus().then(() => {
        this.notifyCallbacks();
      });
    } else {
      this.currentStatus = {
        isOnline: false,
        isWifi: false,
        isCellular: false,
        networkType: 'none'
      };
      this.notifyCallbacks();
    }
  }

  /**
   * Notify all registered callbacks
   */
  private notifyCallbacks(): void {
    this.callbacks.forEach((callback: NetworkStatusCallback) => {
      try {
        callback(this.currentStatus);
      } catch (error) {
        console.error('[NetworkService] Callback error:', error);
      }
    });
  }

  /**
   * Check if network is online
   */
  isOnline(): boolean {
    return this.currentStatus.isOnline;
  }

  /**
   * Check if connected via WiFi
   */
  isWifi(): boolean {
    return this.currentStatus.isWifi;
  }

  /**
   * Check if connected via cellular
   */
  isCellular(): boolean {
    return this.currentStatus.isCellular;
  }

  /**
   * Get current network status
   */
  getStatus(): NetworkStatus {
    const status: NetworkStatus = {
      isOnline: this.currentStatus.isOnline,
      isWifi: this.currentStatus.isWifi,
      isCellular: this.currentStatus.isCellular,
      networkType: this.currentStatus.networkType
    };
    return status;
  }

  /**
   * Register network status change callback
   */
  onStatusChanged(callback: NetworkStatusCallback): void {
    this.callbacks.push(callback);
  }

  /**
   * Unregister network status change callback
   */
  offStatusChanged(callback: NetworkStatusCallback): void {
    const index = this.callbacks.indexOf(callback);
    if (index > -1) {
      this.callbacks.splice(index, 1);
    }
  }

  /**
   * Refresh network status manually
   */
  async refresh(): Promise<NetworkStatus> {
    await this.updateNetworkStatus();
    return this.getStatus();
  }

  /**
   * Cleanup resources
   */
  destroy(): void {
    if (this.netConnection !== null) {
      this.netConnection.unregister(() => {
        console.info('[NetworkService] Network connection unregistered');
      });
      this.netConnection = null;
    }
    this.callbacks = [];
    this.isInitialized = false;
    NetworkService.instance = null;
  }
}
