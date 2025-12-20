/**
 * Keyboard Shortcuts Service
 * Manages keyboard shortcuts for the application
 * Provides a centralized way to handle keyboard events
 */

// Shortcut action type
type ShortcutAction = 'sendRequest' | 'newRequest' | 'focusSearch' | 'saveRequest' | 'duplicateRequest' | 'deleteRequest' | 'toggleSidebar' | 'toggleResponseViewer';

// Shortcut definition interface
interface ShortcutDefinition {
  key: string;
  ctrl: boolean;
  alt: boolean;
  shift: boolean;
  action: ShortcutAction;
  description: string;
}

// Shortcut handler type
type ShortcutHandler = () => void;

export class KeyboardShortcuts {
  private static instance: KeyboardShortcuts | null = null;
  
  // Registered handlers for each action
  private handlers: Map<ShortcutAction, ShortcutHandler> = new Map();
  
  // Shortcut definitions
  private shortcuts: ShortcutDefinition[] = [];

  private constructor() {
    this.initDefaultShortcuts();
  }

  /**
   * Get singleton instance
   */
  static getInstance(): KeyboardShortcuts {
    if (!KeyboardShortcuts.instance) {
      KeyboardShortcuts.instance = new KeyboardShortcuts();
    }
    return KeyboardShortcuts.instance;
  }

  /**
   * Initialize default keyboard shortcuts
   */
  private initDefaultShortcuts(): void {
    // Ctrl+Enter - Send current request
    const sendRequest: ShortcutDefinition = {
      key: 'Enter',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'sendRequest',
      description: 'Send current request'
    };
    this.shortcuts.push(sendRequest);

    // Ctrl+N - New request
    const newRequest: ShortcutDefinition = {
      key: 'n',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'newRequest',
      description: 'Create new request'
    };
    this.shortcuts.push(newRequest);

    // Ctrl+F - Focus search
    const focusSearch: ShortcutDefinition = {
      key: 'f',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'focusSearch',
      description: 'Focus sidebar search'
    };
    this.shortcuts.push(focusSearch);

    // Ctrl+S - Save request
    const saveRequest: ShortcutDefinition = {
      key: 's',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'saveRequest',
      description: 'Save current request'
    };
    this.shortcuts.push(saveRequest);

    // Ctrl+D - Duplicate request
    const duplicateRequest: ShortcutDefinition = {
      key: 'd',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'duplicateRequest',
      description: 'Duplicate current request'
    };
    this.shortcuts.push(duplicateRequest);

    // Delete - Delete request
    const deleteRequest: ShortcutDefinition = {
      key: 'Delete',
      ctrl: false,
      alt: false,
      shift: false,
      action: 'deleteRequest',
      description: 'Delete current request'
    };
    this.shortcuts.push(deleteRequest);

    // Ctrl+B - Toggle sidebar
    const toggleSidebar: ShortcutDefinition = {
      key: 'b',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'toggleSidebar',
      description: 'Toggle sidebar visibility'
    };
    this.shortcuts.push(toggleSidebar);

    // Ctrl+R - Toggle response viewer
    const toggleResponseViewer: ShortcutDefinition = {
      key: 'r',
      ctrl: true,
      alt: false,
      shift: false,
      action: 'toggleResponseViewer',
      description: 'Toggle response viewer'
    };
    this.shortcuts.push(toggleResponseViewer);
  }

  /**
   * Register a handler for a shortcut action
   * @param action The action to handle
   * @param handler The handler function
   */
  registerHandler(action: ShortcutAction, handler: ShortcutHandler): void {
    this.handlers.set(action, handler);
    console.info(`[KeyboardShortcuts] Registered handler for: ${action}`);
  }

  /**
   * Unregister a handler for a shortcut action
   * @param action The action to unregister
   */
  unregisterHandler(action: ShortcutAction): void {
    this.handlers.delete(action);
    console.info(`[KeyboardShortcuts] Unregistered handler for: ${action}`);
  }

  /**
   * Handle a keyboard event
   * @param event The keyboard event
   * @returns true if the event was handled
   */
  handleKeyEvent(key: string, ctrlKey: boolean, altKey: boolean, shiftKey: boolean): boolean {
    // Find matching shortcut
    const shortcut: ShortcutDefinition | undefined = this.shortcuts.find((s: ShortcutDefinition) => {
      return s.key.toLowerCase() === key.toLowerCase() &&
             s.ctrl === ctrlKey &&
             s.alt === altKey &&
             s.shift === shiftKey;
    });

    if (!shortcut) {
      return false;
    }

    // Get handler for this action
    const handler: ShortcutHandler | undefined = this.handlers.get(shortcut.action);
    
    if (handler) {
      console.info(`[KeyboardShortcuts] Executing action: ${shortcut.action}`);
      handler();
      return true;
    }

    console.warn(`[KeyboardShortcuts] No handler registered for: ${shortcut.action}`);
    return false;
  }

  /**
   * Get all shortcut definitions
   */
  getShortcuts(): ShortcutDefinition[] {
    return this.shortcuts;
  }

  /**
   * Get shortcut for a specific action
   * @param action The action to get shortcut for
   */
  getShortcutForAction(action: ShortcutAction): ShortcutDefinition | null {
    const shortcut: ShortcutDefinition | undefined = this.shortcuts.find(
      (s: ShortcutDefinition) => s.action === action
    );
    return shortcut || null;
  }

  /**
   * Format shortcut as display string
   * @param shortcut The shortcut to format
   */
  formatShortcut(shortcut: ShortcutDefinition): string {
    const parts: string[] = [];
    
    if (shortcut.ctrl) {
      parts.push('Ctrl');
    }
    if (shortcut.alt) {
      parts.push('Alt');
    }
    if (shortcut.shift) {
      parts.push('Shift');
    }
    
    // Format key name
    let keyName: string = shortcut.key;
    if (keyName === 'Enter') {
      keyName = '↵';
    } else if (keyName === 'Delete') {
      keyName = 'Del';
    } else {
      keyName = keyName.toUpperCase();
    }
    parts.push(keyName);
    
    return parts.join('+');
  }

  /**
   * Get all shortcuts formatted for display
   */
  getFormattedShortcuts(): Array<{ action: string; shortcut: string; description: string }> {
    const result: Array<{ action: string; shortcut: string; description: string }> = [];
    
    this.shortcuts.forEach((s: ShortcutDefinition) => {
      const item: { action: string; shortcut: string; description: string } = {
        action: s.action,
        shortcut: this.formatShortcut(s),
        description: s.description
      };
      result.push(item);
    });
    
    return result;
  }

  /**
   * Check if a key combination is a registered shortcut
   */
  isShortcut(key: string, ctrlKey: boolean, altKey: boolean, shiftKey: boolean): boolean {
    return this.shortcuts.some((s: ShortcutDefinition) => {
      return s.key.toLowerCase() === key.toLowerCase() &&
             s.ctrl === ctrlKey &&
             s.alt === altKey &&
             s.shift === shiftKey;
    });
  }
}

export type { ShortcutAction, ShortcutDefinition };
