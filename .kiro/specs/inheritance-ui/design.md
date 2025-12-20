# Design Document: Inheritance UI Features

## Overview

This design document describes the implementation of inheritance UI features for the yaak-hmos HarmonyOS application. The feature enables users to visualize and understand inherited authentication and headers from parent folders and workspaces, providing a clear indication of where settings come from and allowing easy navigation to modify them.

## Architecture

The inheritance UI feature builds upon the existing `InheritanceService` and extends the UI components to display inheritance information. The architecture follows a layered approach:

```
┌─────────────────────────────────────────────────────────────┐
│                      UI Components                          │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │  HeadersEditor  │  │   AuthEditor    │  │  Settings   │ │
│  │  (with inherit) │  │  (with inherit) │  │   Dialogs   │ │
│  └────────┬────────┘  └────────┬────────┘  └──────┬──────┘ │
└───────────┼────────────────────┼─────────────────┼─────────┘
            │                    │                 │
┌───────────┴────────────────────┴─────────────────┴─────────┐
│                   InheritanceService                        │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │ resolveHeaders  │  │  resolveAuth    │  │ getSource   │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└────────────────────────────────────────────────────────────┘
            │                    │                 │
┌───────────┴────────────────────┴─────────────────┴─────────┐
│                      Data Layer                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌─────────────┐ │
│  │    Requests     │  │    Folders      │  │  Workspace  │ │
│  └─────────────────┘  └─────────────────┘  └─────────────┘ │
└────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Enhanced HeadersEditor Component

The HeadersEditor will be extended to accept and display inherited headers.

```typescript
// New props for HeadersEditor
interface HeadersEditorProps {
  headers: HttpHeader[];                    // Editable headers
  inheritedHeaders?: HttpHeader[];          // Read-only inherited headers
  inheritedSources?: InheritedHeaderSource[]; // Source info for each inherited header
  onChange: (headers: HttpHeader[]) => void;
  onNavigateToSource?: (sourceType: string, sourceId: string) => void;
}

interface InheritedHeaderSource {
  headerId: string;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}
```

### 2. Enhanced AuthEditor Component

The AuthEditor will be extended to show inheritance information.

```typescript
// New props for AuthEditor
interface AuthEditorProps {
  auth: AuthConfig;
  inheritedAuth?: InheritedAuthInfo | null;
  onChange: (auth: AuthConfig) => void;
  onNavigateToSource?: (sourceType: string, sourceId: string) => void;
}

interface InheritedAuthInfo {
  auth: AuthConfig;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}
```

### 3. FolderSettingsDialog Component

New dialog for editing folder settings including headers and auth.

```typescript
interface FolderSettingsDialogProps {
  visible: boolean;
  folder: Folder;
  folders: Folder[];           // For inheritance resolution
  workspace: Workspace | null;
  onClose: () => void;
  onSave: (folder: Folder) => void;
}
```

### 4. WorkspaceSettingsDialog Enhancement

Extend existing WorkspaceSettingsDialog to include headers and auth tabs.

### 5. InheritanceService Extensions

Add new methods to support UI requirements:

```typescript
// New method to get inherited headers with source info
static getInheritedHeadersWithSource(
  request: HttpRequest | Folder,
  folders: Folder[],
  workspace: Workspace | null
): InheritedHeaderWithSource[];

// New method to get inherited auth with source info
static getInheritedAuthWithSource(
  request: HttpRequest | Folder,
  folders: Folder[],
  workspace: Workspace | null
): InheritedAuthInfo | null;
```

## Data Models

### InheritedHeaderWithSource

```typescript
interface InheritedHeaderWithSource {
  header: HttpHeader;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}
```

### InheritedAuthInfo

```typescript
interface InheritedAuthInfo {
  auth: AuthConfig;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}
```



## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Inherited Headers Display Completeness

*For any* request with inherited headers from parent folders or workspace, the HeadersEditor SHALL display all enabled inherited headers in a collapsible section with the correct count badge, and each inherited header SHALL be rendered as read-only (disabled).

**Validates: Requirements 1.1, 1.2, 1.3, 1.5**

### Property 2: Inherited Auth Source Display

*For any* request with inherited authentication, the AuthEditor SHALL display "Inherited from [source name]" where source name is the folder name when inherited from a folder, or "Workspace" when inherited from workspace.

**Validates: Requirements 2.1, 2.2, 5.2**

### Property 3: Auth Form Display When Not Inherited

*For any* request with authentication directly set (not inherited), the AuthEditor SHALL display the authentication configuration form instead of the inheritance message.

**Validates: Requirements 2.6**

### Property 4: Folder Inheritance Resolution

*For any* folder with parent folders or workspace, the InheritanceService SHALL correctly resolve inherited headers and auth from the parent hierarchy, and the FolderSettingsDialog SHALL display these inherited settings.

**Validates: Requirements 3.2, 3.3, 3.4**

### Property 5: Workspace Inheritance Resolution

*For any* workspace with auth configured, all requests in the workspace without explicit auth SHALL inherit the workspace auth.

**Validates: Requirements 4.4**

### Property 6: Header Source Indication

*For any* inherited header displayed in the HeadersEditor, the source (folder name or "Workspace") SHALL be indicated for each header.

**Validates: Requirements 5.1**

## Error Handling

### Invalid Inheritance Chain

- IF a folder references a non-existent parent folder THEN THE InheritanceService SHALL stop traversal and return results up to that point
- IF workspace is null THEN THE InheritanceService SHALL only resolve from folder hierarchy

### Missing Data

- IF inherited headers array is undefined THEN THE HeadersEditor SHALL treat it as empty array
- IF inherited auth info is null THEN THE AuthEditor SHALL display the auth form or "No authentication" message

### Navigation Errors

- IF navigation to source settings fails THEN THE System SHALL show an error toast and remain on current screen

## Testing Strategy

### Unit Tests

Unit tests will verify specific examples and edge cases:

1. **HeadersEditor with empty inherited headers** - Verify inherited section is not displayed
2. **HeadersEditor with mixed enabled/disabled inherited headers** - Verify only enabled headers shown
3. **AuthEditor with no auth anywhere** - Verify "No authentication" message
4. **AuthEditor with workspace auth** - Verify "Inherited from Workspace" message
5. **FolderSettingsDialog tabs** - Verify Headers and Auth tabs exist
6. **WorkspaceSettingsDialog tabs** - Verify Headers and Auth tabs exist

### Property-Based Tests

Property-based tests will use fast-check or similar library to verify universal properties:

1. **Property 1 Test**: Generate random lists of inherited headers with mixed enabled states, verify count badge matches enabled count and all enabled headers are displayed as disabled
2. **Property 2 Test**: Generate random inheritance chains with auth at different levels, verify correct source is displayed
3. **Property 3 Test**: Generate random requests with direct auth, verify form is displayed
4. **Property 4 Test**: Generate random folder hierarchies with headers/auth, verify correct resolution
5. **Property 5 Test**: Generate random workspaces with auth and requests without auth, verify inheritance
6. **Property 6 Test**: Generate random inherited headers with source info, verify source is displayed

### Integration Tests

1. **End-to-end inheritance flow** - Create workspace → folder → request, set auth on workspace, verify request shows inherited auth
2. **Header inheritance chain** - Create nested folders with headers, verify all headers are inherited correctly
3. **Override inheritance** - Set auth on request, verify it overrides inherited auth

## UI Mockups

### HeadersEditor with Inherited Headers

```
┌─────────────────────────────────────────────────────────────┐
│ Headers                                              [Add]  │
├─────────────────────────────────────────────────────────────┤
│ ▼ Inherited (3)                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ ☑ Authorization  Bearer ***  (from: API Folder)        │ │
│ │ ☑ X-API-Version  v2          (from: Workspace)         │ │
│ │ ☑ Accept         application/json (from: Workspace)    │ │
│ └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│ ☑ Content-Type    application/json                    [×]  │
│ ☑ X-Custom        value                               [×]  │
│ ☐ X-Debug         true                                [×]  │
└─────────────────────────────────────────────────────────────┘
```

### AuthEditor with Inherited Auth

```
┌─────────────────────────────────────────────────────────────┐
│ Auth Type: [Inherit from Parent ▼]                          │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│     Inherited from API Folder                               │
│     [Click to edit]                                         │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### FolderSettingsDialog

```
┌─────────────────────────────────────────────────────────────┐
│ Folder Settings: API Folder                           [×]   │
├─────────────────────────────────────────────────────────────┤
│ [General] [Headers] [Auth]                                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│ (Tab content based on selection)                            │
│                                                             │
├─────────────────────────────────────────────────────────────┤
│                                    [Cancel]  [Save]         │
└─────────────────────────────────────────────────────────────┘
```
