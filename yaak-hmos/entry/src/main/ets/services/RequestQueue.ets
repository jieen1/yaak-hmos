/**
 * Request Queue Service
 * Limits concurrent HTTP requests to prevent overwhelming the system
 * Queues requests when the limit is reached and processes them as slots become available
 */

// Queued request interface
interface QueuedRequest {
  id: string;
  execute: () => Promise<void>;
  resolve: () => void;
  reject: (error: Error) => void;
  addedAt: number;
}

// Queue statistics interface
interface QueueStats {
  activeCount: number;
  queuedCount: number;
  maxConcurrent: number;
  totalProcessed: number;
}

export class RequestQueue {
  private static instance: RequestQueue | null = null;
  
  // Maximum concurrent requests
  private maxConcurrent: number = 6;
  
  // Currently active requests
  private activeCount: number = 0;
  
  // Queue of pending requests
  private queue: QueuedRequest[] = [];
  
  // Total requests processed
  private totalProcessed: number = 0;

  private constructor() {}

  /**
   * Get singleton instance
   */
  static getInstance(): RequestQueue {
    if (!RequestQueue.instance) {
      RequestQueue.instance = new RequestQueue();
    }
    return RequestQueue.instance;
  }

  /**
   * Set maximum concurrent requests
   * @param max Maximum number of concurrent requests
   */
  setMaxConcurrent(max: number): void {
    this.maxConcurrent = Math.max(1, max);
    console.info(`[RequestQueue] Max concurrent requests set to ${this.maxConcurrent}`);
    
    // Process queue in case we increased the limit
    this.processQueue();
  }

  /**
   * Get maximum concurrent requests
   */
  getMaxConcurrent(): number {
    return this.maxConcurrent;
  }

  /**
   * Enqueue a request for execution
   * Returns a promise that resolves when the request completes
   * 
   * @param requestId Unique identifier for the request
   * @param execute Function that executes the request
   * @returns Promise that resolves when the request completes
   */
  async enqueue(requestId: string, execute: () => Promise<void>): Promise<void> {
    // Check if we can execute immediately
    if (this.activeCount < this.maxConcurrent) {
      await this.executeRequest(requestId, execute);
      return;
    }

    // Queue the request
    return new Promise<void>((resolve, reject) => {
      const queuedRequest: QueuedRequest = {
        id: requestId,
        execute: execute,
        resolve: resolve,
        reject: reject,
        addedAt: Date.now()
      };

      this.queue.push(queuedRequest);
      console.info(`[RequestQueue] Request queued: ${requestId} (queue size: ${this.queue.length})`);
    });
  }

  /**
   * Execute a request and manage the active count
   */
  private async executeRequest(requestId: string, execute: () => Promise<void>): Promise<void> {
    this.activeCount++;
    console.info(`[RequestQueue] Executing request: ${requestId} (active: ${this.activeCount})`);

    try {
      await execute();
      this.totalProcessed++;
    } finally {
      this.activeCount--;
      console.info(`[RequestQueue] Request completed: ${requestId} (active: ${this.activeCount})`);
      
      // Process next queued request
      this.processQueue();
    }
  }

  /**
   * Process the next request in the queue
   */
  private processQueue(): void {
    while (this.activeCount < this.maxConcurrent && this.queue.length > 0) {
      const queuedRequest: QueuedRequest | undefined = this.queue.shift();
      
      if (queuedRequest) {
        const waitTime: number = Date.now() - queuedRequest.addedAt;
        console.info(`[RequestQueue] Processing queued request: ${queuedRequest.id} (waited: ${waitTime}ms)`);

        // Execute the request
        this.activeCount++;
        
        queuedRequest.execute()
          .then(() => {
            this.totalProcessed++;
            queuedRequest.resolve();
          })
          .catch((error: Error) => {
            queuedRequest.reject(error);
          })
          .finally(() => {
            this.activeCount--;
            this.processQueue();
          });
      }
    }
  }

  /**
   * Cancel a queued request
   * @param requestId The ID of the request to cancel
   * @returns true if the request was found and cancelled
   */
  cancel(requestId: string): boolean {
    const index: number = this.queue.findIndex((r: QueuedRequest) => r.id === requestId);
    
    if (index >= 0) {
      const removed: QueuedRequest | undefined = this.queue.splice(index, 1)[0];
      if (removed) {
        removed.reject(new Error('Request cancelled'));
        console.info(`[RequestQueue] Request cancelled: ${requestId}`);
        return true;
      }
    }
    
    return false;
  }

  /**
   * Cancel all queued requests
   */
  cancelAll(): void {
    const cancelledCount: number = this.queue.length;
    
    this.queue.forEach((request: QueuedRequest) => {
      request.reject(new Error('Request cancelled'));
    });
    
    this.queue = [];
    console.info(`[RequestQueue] Cancelled ${cancelledCount} queued requests`);
  }

  /**
   * Get queue statistics
   */
  getStats(): QueueStats {
    const stats: QueueStats = {
      activeCount: this.activeCount,
      queuedCount: this.queue.length,
      maxConcurrent: this.maxConcurrent,
      totalProcessed: this.totalProcessed
    };
    return stats;
  }

  /**
   * Check if a request is queued
   * @param requestId The ID of the request to check
   */
  isQueued(requestId: string): boolean {
    return this.queue.some((r: QueuedRequest) => r.id === requestId);
  }

  /**
   * Get the position of a request in the queue
   * @param requestId The ID of the request
   * @returns The position (0-based) or -1 if not found
   */
  getQueuePosition(requestId: string): number {
    return this.queue.findIndex((r: QueuedRequest) => r.id === requestId);
  }

  /**
   * Check if the queue is at capacity
   */
  isAtCapacity(): boolean {
    return this.activeCount >= this.maxConcurrent;
  }

  /**
   * Get the number of available slots
   */
  getAvailableSlots(): number {
    return Math.max(0, this.maxConcurrent - this.activeCount);
  }
}

export type { QueueStats };
