/**
 * Debounce Utility
 * Provides debouncing functionality for UI event handlers
 * Helps optimize performance by reducing unnecessary updates
 */

// Debounce function type
type DebouncedFunction = () => void;

// Debounce state interface
interface DebounceState {
  timeoutId: number | null;
  lastCallTime: number;
}

/**
 * Creates a debounced version of a function
 * The function will only be called after the specified delay has passed
 * without any new calls
 * 
 * @param func The function to debounce
 * @param delayMs The delay in milliseconds
 * @returns A debounced version of the function
 */
export function debounce(func: () => void, delayMs: number): DebouncedFunction {
  let timeoutId: number | null = null;

  return (): void => {
    // Clear existing timeout
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
    }

    // Set new timeout
    timeoutId = setTimeout(() => {
      func();
      timeoutId = null;
    }, delayMs);
  };
}

/**
 * Creates a debounced version of a function with a value parameter
 * 
 * @param func The function to debounce
 * @param delayMs The delay in milliseconds
 * @returns A debounced version of the function
 */
export function debounceWithValue<T>(func: (value: T) => void, delayMs: number): (value: T) => void {
  let timeoutId: number | null = null;
  let latestValue: T | undefined = undefined;

  return (value: T): void => {
    latestValue = value;

    // Clear existing timeout
    if (timeoutId !== null) {
      clearTimeout(timeoutId);
    }

    // Set new timeout
    timeoutId = setTimeout(() => {
      if (latestValue !== undefined) {
        func(latestValue);
      }
      timeoutId = null;
    }, delayMs);
  };
}

/**
 * Debounce Manager class for managing multiple debounced operations
 */
export class DebounceManager {
  private debounceStates: Map<string, DebounceState> = new Map();

  /**
   * Execute a function with debouncing
   * 
   * @param key Unique key for this debounce operation
   * @param func The function to execute
   * @param delayMs The delay in milliseconds
   */
  execute(key: string, func: () => void, delayMs: number): void {
    let state: DebounceState | undefined = this.debounceStates.get(key);

    if (!state) {
      state = {
        timeoutId: null,
        lastCallTime: 0
      };
      this.debounceStates.set(key, state);
    }

    // Clear existing timeout
    if (state.timeoutId !== null) {
      clearTimeout(state.timeoutId);
    }

    // Update last call time
    state.lastCallTime = Date.now();

    // Set new timeout
    state.timeoutId = setTimeout(() => {
      func();
      const currentState: DebounceState | undefined = this.debounceStates.get(key);
      if (currentState) {
        currentState.timeoutId = null;
      }
    }, delayMs);
  }

  /**
   * Cancel a pending debounced operation
   * 
   * @param key The key of the operation to cancel
   */
  cancel(key: string): void {
    const state: DebounceState | undefined = this.debounceStates.get(key);

    if (state && state.timeoutId !== null) {
      clearTimeout(state.timeoutId);
      state.timeoutId = null;
    }
  }

  /**
   * Cancel all pending debounced operations
   */
  cancelAll(): void {
    this.debounceStates.forEach((state: DebounceState) => {
      if (state.timeoutId !== null) {
        clearTimeout(state.timeoutId);
        state.timeoutId = null;
      }
    });
  }

  /**
   * Clear all debounce states
   */
  clear(): void {
    this.cancelAll();
    this.debounceStates.clear();
  }
}

/**
 * Throttle utility - limits function calls to once per interval
 * Unlike debounce, throttle ensures the function is called at regular intervals
 * 
 * @param func The function to throttle
 * @param intervalMs The minimum interval between calls in milliseconds
 * @returns A throttled version of the function
 */
export function throttle(func: () => void, intervalMs: number): DebouncedFunction {
  let lastCallTime: number = 0;
  let timeoutId: number | null = null;

  return (): void => {
    const now: number = Date.now();
    const timeSinceLastCall: number = now - lastCallTime;

    if (timeSinceLastCall >= intervalMs) {
      // Enough time has passed, call immediately
      lastCallTime = now;
      func();
    } else if (timeoutId === null) {
      // Schedule a call for later
      const remainingTime: number = intervalMs - timeSinceLastCall;
      timeoutId = setTimeout(() => {
        lastCallTime = Date.now();
        func();
        timeoutId = null;
      }, remainingTime);
    }
  };
}

/**
 * Throttle with value parameter
 * 
 * @param func The function to throttle
 * @param intervalMs The minimum interval between calls in milliseconds
 * @returns A throttled version of the function
 */
export function throttleWithValue<T>(func: (value: T) => void, intervalMs: number): (value: T) => void {
  let lastCallTime: number = 0;
  let timeoutId: number | null = null;
  let latestValue: T | undefined = undefined;

  return (value: T): void => {
    latestValue = value;
    const now: number = Date.now();
    const timeSinceLastCall: number = now - lastCallTime;

    if (timeSinceLastCall >= intervalMs) {
      // Enough time has passed, call immediately
      lastCallTime = now;
      func(value);
    } else if (timeoutId === null) {
      // Schedule a call for later
      const remainingTime: number = intervalMs - timeSinceLastCall;
      timeoutId = setTimeout(() => {
        lastCallTime = Date.now();
        if (latestValue !== undefined) {
          func(latestValue);
        }
        timeoutId = null;
      }, remainingTime);
    }
  };
}
