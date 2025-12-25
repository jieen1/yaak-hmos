/**
 * ContinuationService - Cross-device task continuation service
 * Enables seamless request editing across devices
 */

import { distributedDeviceManager } from '@kit.DistributedServiceKit';

/**
 * Device information interface
 */
export interface DeviceInfo {
  deviceId: string;
  deviceName: string;
  deviceType: string;
  networkId: string;
  isOnline: boolean;
}

/**
 * Continuation data for request transfer
 */
export interface ContinuationData {
  requestId: string;
  workspaceId: string;
  url: string;
  method: string;
  headers: string;
  queryParams: string;
  body: string;
  bodyType: string;
  auth: string;
  activeTab: number;
  timestamp: number;
}

/**
 * Continuation result interface
 */
export interface ContinuationResult {
  success: boolean;
  targetDevice: DeviceInfo | null;
  error: string;
}

/**
 * Continuation received callback type
 */
export type ContinuationCallback = (data: ContinuationData) => void;

/**
 * ContinuationService - Manages cross-device continuation
 */
export class ContinuationService {
  private static instance: ContinuationService | null = null;
  private deviceManager: distributedDeviceManager.DeviceManager | null = null;
  private discoveredDevices: DeviceInfo[] = [];
  private continuationCallbacks: ContinuationCallback[] = [];
  private pendingContinuationData: ContinuationData | null = null;
  private isDiscovering: boolean = false;
  private isInitialized: boolean = false;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): ContinuationService {
    if (ContinuationService.instance === null) {
      ContinuationService.instance = new ContinuationService();
    }
    return ContinuationService.instance;
  }

  /**
   * Initialize continuation service
   */
  async initialize(): Promise<void> {
    if (this.isInitialized) {
      return;
    }

    try {
      this.deviceManager = distributedDeviceManager.createDeviceManager('com.jieen.flare');
      this.isInitialized = true;
      console.info('[ContinuationService] Initialized');
    } catch (error) {
      console.error('[ContinuationService] Initialize failed:', error);
      throw Error(error);
    }
  }

  /**
   * Discover available devices
   */
  async discoverDevices(): Promise<DeviceInfo[]> {
    if (this.deviceManager === null) {
      console.error('[ContinuationService] Not initialized');
      return [];
    }

    this.discoveredDevices = [];

    try {
      // Get trusted devices
      const trustedDevices = this.deviceManager.getAvailableDeviceListSync();
      
      trustedDevices.forEach((device: distributedDeviceManager.DeviceBasicInfo) => {
        const deviceInfo: DeviceInfo = {
          deviceId: device.deviceId,
          deviceName: device.deviceName,
          deviceType: device.deviceType,
          networkId: device.networkId || '',
          isOnline: true
        };
        this.discoveredDevices.push(deviceInfo);
      });

      console.info('[ContinuationService] Discovered', this.discoveredDevices.length, 'devices');
    } catch (error) {
      console.error('[ContinuationService] Discovery failed:', error);
    }

    return this.getDiscoveredDevices();
  }

  /**
   * Start device discovery
   */
  async startDiscovery(): Promise<void> {
    if (this.deviceManager === null || this.isDiscovering) {
      return;
    }

    try {
      let discoverParam: Record<string, number> = {
        'discoverTargetType': 1
      };

      this.deviceManager.on('discoverSuccess', (data) => {
        this.handleDeviceFound(data.device);
      });

      this.deviceManager.on('discoverFailure', (data) => {
        console.warn('[ContinuationService] Discovery failure:', data);
      });

      this.deviceManager.startDiscovering(discoverParam);
      this.isDiscovering = true;
      console.info('[ContinuationService] Discovery started');
    } catch (error) {
      console.error('[ContinuationService] Start discovery failed:', error);
    }
  }

  /**
   * Stop device discovery
   */
  stopDiscovery(): void {
    if (this.deviceManager === null || !this.isDiscovering) {
      return;
    }

    try {
      this.deviceManager.stopDiscovering();
      this.deviceManager.off('discoverSuccess');
      this.deviceManager.off('discoverFailure');
      this.isDiscovering = false;
      console.info('[ContinuationService] Discovery stopped');
    } catch (error) {
      console.error('[ContinuationService] Stop discovery failed:', error);
    }
  }

  /**
   * Get discovered devices
   */
  getDiscoveredDevices(): DeviceInfo[] {
    const devices: DeviceInfo[] = [];
    this.discoveredDevices.forEach((device: DeviceInfo) => {
      const copy: DeviceInfo = {
        deviceId: device.deviceId,
        deviceName: device.deviceName,
        deviceType: device.deviceType,
        networkId: device.networkId,
        isOnline: device.isOnline
      };
      devices.push(copy);
    });
    return devices;
  }

  /**
   * Continue to target device
   */
  async continueToDevice(
    targetDeviceId: string,
    data: ContinuationData
  ): Promise<ContinuationResult> {
    const result: ContinuationResult = {
      success: false,
      targetDevice: null,
      error: ''
    };

    // Find target device
    const targetDevice = this.discoveredDevices.find(
      (device: DeviceInfo) => device.deviceId === targetDeviceId
    );

    if (!targetDevice) {
      result.error = '目标设备不在线';
      return result;
    }

    if (!targetDevice.isOnline) {
      result.error = `目标设备 ${targetDevice.deviceName} 不在线`;
      return result;
    }

    try {
      // Store continuation data for transfer
      // The actual transfer happens through Want in EntryAbility
      this.pendingContinuationData = data;
      
      result.success = true;
      result.targetDevice = targetDevice;
      
      console.info('[ContinuationService] Continuation prepared for:', targetDevice.deviceName);
    } catch (error) {
      result.error = error instanceof Error ? error.message : String(error);
      console.error('[ContinuationService] Continue failed:', error);
    }

    return result;
  }

  /**
   * Get pending continuation data (for Want transfer)
   */
  getPendingContinuationData(): ContinuationData | null {
    return this.pendingContinuationData;
  }

  /**
   * Clear pending continuation data
   */
  clearPendingContinuationData(): void {
    this.pendingContinuationData = null;
  }

  /**
   * Receive continuation data from another device
   */
  receiveContinuation(data: ContinuationData): void {
    console.info('[ContinuationService] Received continuation data');
    
    // Notify all registered callbacks
    this.continuationCallbacks.forEach((callback: ContinuationCallback) => {
      try {
        callback(data);
      } catch (error) {
        console.error('[ContinuationService] Callback error:', error);
      }
    });
  }

  /**
   * Register continuation received callback
   */
  onContinuationReceived(callback: ContinuationCallback): void {
    this.continuationCallbacks.push(callback);
  }

  /**
   * Unregister continuation received callback
   */
  offContinuationReceived(callback: ContinuationCallback): void {
    const index = this.continuationCallbacks.indexOf(callback);
    if (index > -1) {
      this.continuationCallbacks.splice(index, 1);
    }
  }

  /**
   * Serialize request data for continuation
   */
  static serializeContinuationData(data: ContinuationData): string {
    return JSON.stringify(data);
  }

  /**
   * Deserialize continuation data
   */
  static deserializeContinuationData(dataStr: string): ContinuationData | null {
    try {
      const parsed: ESObject = JSON.parse(dataStr) as ESObject;
      
      const data: ContinuationData = {
        requestId: String(parsed.requestId || ''),
        workspaceId: String(parsed.workspaceId || ''),
        url: String(parsed.url || ''),
        method: String(parsed.method || 'GET'),
        headers: String(parsed.headers || '[]'),
        queryParams: String(parsed.queryParams || '[]'),
        body: String(parsed.body || ''),
        bodyType: String(parsed.bodyType || 'none'),
        auth: String(parsed.auth || '{}'),
        activeTab: Number(parsed.activeTab || 0),
        timestamp: Number(parsed.timestamp || Date.now())
      };
      
      return data;
    } catch (error) {
      console.error('[ContinuationService] Deserialize failed:', error);
      return null;
    }
  }

  /**
   * Handle device found during discovery
   */
  private handleDeviceFound(device: distributedDeviceManager.DeviceBasicInfo): void {
    const existingIndex = this.discoveredDevices.findIndex(
      (d: DeviceInfo) => d.deviceId === device.deviceId
    );

    const deviceInfo: DeviceInfo = {
      deviceId: device.deviceId,
      deviceName: device.deviceName,
      deviceType: device.deviceType,
      networkId: device.networkId || '',
      isOnline: true
    };

    if (existingIndex >= 0) {
      this.discoveredDevices[existingIndex] = deviceInfo;
    } else {
      this.discoveredDevices.push(deviceInfo);
    }

    console.info('[ContinuationService] Device found:', device.deviceName);
  }
}
