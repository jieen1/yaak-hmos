# Design Document - UI Improvements

## Overview

This design document outlines the solution for fixing critical UI issues in the Yaak HarmonyOS application. The fixes will improve usability by implementing proper event handling for the settings button, adding resizable panes with proper constraints, creating dialogs for workspace and environment management, fixing authentication editor input fields, and improving the key-value editors for headers and query parameters.

## Architecture

The solution follows the existing component-based architecture of the HarmonyOS application:

1. **Component Layer**: UI components built with ArkTS @ComponentV2 decorators
2. **Service Layer**: Business logic for managing workspaces, environments, and settings
3. **Storage Layer**: Local storage for persisting user preferences (pane widths, settings)
4. **Event Layer**: Event handlers for user interactions

### Key Architectural Decisions

1. Use HarmonyOS's built-in gesture recognition for drag-to-resize functionality
2. Store pane width preferences in AppStorage for persistence across sessions
3. Create reusable dialog components for workspace and environment management
4. Improve input field sizing using flexible layouts and proper constraints

## Components and Interfaces

### 1. Settings Dialog Component

```typescript
@ComponentV2
export struct SettingsDialog {
  @Param isVisible: boolean = false;
  @Param onClose: () => void = () => {};
  
  // Settings tabs: General, Appearance, Shortcuts, etc.
  @Local selectedTab: string = 'general';
}
```

### 2. Resizable Pane Component

```typescript
interface ResizablePaneProps {
  minWidth: number;
  maxWidth: number;
  defaultWidth: number;
  storageKey: string;
  onWidthChange?: (width: number) => void;
}

@ComponentV2
export struct ResizablePane {
  @Param minWidthValue: number = 200;
  @Param maxWidthValue: number = 800;
  @Param defaultWidthValue: number = 300;
  @Param storageKey: string = '';
  @Param onWidthChange: (width: number) => void = () => {};
  
  @Local currentWidth: number = 300;
  @Local isDragging: boolean = false;
}
```

### 3. Workspace Management Dialog

```typescript
@ComponentV2
export struct WorkspaceManagementDialog {
  @Param isVisible: boolean = false;
  @Param workspaces: Workspace[] = [];
  @Param onClose: () => void = () => {};
  @Param onCreate: (workspace: Workspace) => Promise<void> = async () => {};
  @Param onUpdate: (workspace: Workspace) => Promise<void> = async () => {};
  @Param onDelete: (workspaceId: string) => Promise<void> = async () => {};
}
```

### 4. Environment Management Dialog

```typescript
@ComponentV2
export struct EnvironmentManagementDialog {
  @Param isVisible: boolean = false;
  @Param workspaceId: string = '';
  @Param environments: Environment[] = [];
  @Param onClose: () => void = () => {};
  @Param onCreate: (environment: Environment) => Promise<void> = async () => {};
  @Param onUpdate: (environment: Environment) => Promise<void> = async () => {};
  @Param onDelete: (environmentId: string) => Promise<void> = async () => {};
}
```

### 5. Improved Auth Editor

The existing AuthEditor component will be enhanced with:
- Proper input field heights (minimum 40dp)
- Scrollable container for long content
- Better spacing between fields

### 6. Improved Key-Value Editor

```typescript
interface KeyValuePair {
  id: string;
  enabled: boolean;
  key: string;
  value: string;
}

@ComponentV2
export struct ImprovedKeyValueEditor {
  @Param pairs: KeyValuePair[] = [];
  @Param onChange: (pairs: KeyValuePair[]) => void = () => {};
  @Param keyPlaceholder: string = 'Key';
  @Param valuePlaceholder: string = 'Value';
  
  // Improved layout with proper field sizing
  private readonly minInputHeight: number = 40;
  private readonly inputSpacing: number = 8;
}
```

## Data Models

### Pane Width Preferences

```typescript
interface PaneWidthPreference {
  workspaceId: string;
  paneName: string;
  width: number;
  timestamp: number;
}
```

### Settings Configuration

```typescript
interface AppSettings {
  theme: 'light' | 'dark' | 'auto';
  fontSize: 'small' | 'medium' | 'large';
  autoSave: boolean;
  requestTimeout: number;
  followRedirects: boolean;
}
```

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Settings button click triggers dialog

*For any* settings button click event, the settings dialog should become visible
**Validates: Requirements 1.1**

### Property 2: Pane width constraints are enforced

*For any* drag operation on a resize handle, the resulting pane width should be between the minimum and maximum allowed widths
**Validates: Requirements 2.1, 2.5**

### Property 3: Pane width persistence

*For any* pane width adjustment, when the application restarts, the pane width should be restored to the last saved value
**Validates: Requirements 2.4**

### Property 4: Workspace creation round trip

*For any* valid workspace data, creating a workspace and then querying the workspace list should include the newly created workspace
**Validates: Requirements 3.2**

### Property 5: Environment creation round trip

*For any* valid environment data, creating an environment and then querying the environment list should include the newly created environment
**Validates: Requirements 3.4**

### Property 6: Auth field visibility

*For any* auth type selection, the displayed input fields should match the requirements of that auth type
**Validates: Requirements 4.1, 4.3, 4.4, 4.5, 4.6**

### Property 7: Input field minimum height

*For any* input field in the auth editor or key-value editor, the field height should be at least 40dp
**Validates: Requirements 4.3, 4.4, 4.5, 4.6, 5.1, 5.2**

### Property 8: Value field visibility

*For any* key-value pair row, both the key input field and value input field should be visible without horizontal scrolling when the pane width is at default
**Validates: Requirements 5.3**

## Error Handling

### Settings Dialog Errors

- If settings fail to load, display default settings and show a warning toast
- If settings fail to save, show an error toast and retain previous values

### Pane Resize Errors

- If width preference fails to save, continue with in-memory value
- If width preference fails to load, use default width

### Workspace/Environment Management Errors

- If creation fails, show error dialog with details
- If update fails, revert to previous state and show error
- If deletion fails, show error and do not remove from list
- Validate input before attempting database operations

### Auth Editor Errors

- If auth configuration is invalid, show validation errors inline
- If auth type change fails, revert to previous type

## Testing Strategy

### Unit Testing

Unit tests will verify:
- Settings dialog opens and closes correctly
- Pane width calculations respect min/max constraints
- Workspace and environment CRUD operations work correctly
- Auth editor displays correct fields for each auth type
- Key-value editor properly handles add/remove operations

### Property-Based Testing

Property-based tests will use the HarmonyOS testing framework to verify:
- Pane width constraints across random drag operations
- Workspace/environment creation with random valid data
- Auth field visibility across all auth types
- Input field heights across different content sizes

### Integration Testing

Integration tests will verify:
- Settings changes persist across app restarts
- Pane widths persist across app restarts
- Workspace selection loads correct environments
- Auth configuration saves and loads correctly

### Manual Testing

Manual testing will verify:
- Smooth drag-to-resize experience
- Settings dialog usability
- Workspace/environment management workflows
- Auth editor usability across all auth types
- Key-value editor usability with long content

## Implementation Notes

### HarmonyOS-Specific Considerations

1. **Gesture Recognition**: Use PanGesture for drag-to-resize functionality
2. **AppStorage**: Use AppStorage.setOrCreate() for persisting preferences
3. **Dialog Management**: Use CustomDialog for modal dialogs
4. **Input Fields**: Use TextInput with proper height constraints
5. **Scrolling**: Use Scroll component for scrollable content areas

### Performance Considerations

1. Debounce pane width updates during drag operations
2. Batch database operations for workspace/environment management
3. Use lazy loading for large environment variable lists
4. Optimize re-renders by using @Local and @Param decorators appropriately

### Accessibility Considerations

1. Ensure resize handles have sufficient touch target size (minimum 44x44dp)
2. Provide keyboard shortcuts for common operations
3. Use proper ARIA labels for screen readers
4. Ensure sufficient color contrast for all UI elements
5. Support system font size preferences
