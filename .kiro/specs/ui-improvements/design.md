# Design Document - UI Improvements

## Overview

This document outlines the technical design for implementing three major UI improvements to the Yaak HarmonyOS application:

1. **Resizable Sidebar with Auto-Hide** - Implements smooth drag-to-resize functionality with automatic hiding
2. **Enhanced Response Viewer** - Adds intelligent content formatting based on Content-Type detection
3. **Request Management** - Provides comprehensive request lifecycle management features

The design is based on the proven patterns from the Tauri desktop application, adapted for HarmonyOS's component model and interaction patterns.

## Architecture

### High-Level Component Structure

```
Index.ets (Main Page)
├── Sidebar (Left Panel)
│   ├── WorkspaceHeader
│   ├── FilterInput
│   ├── RequestTree
│   │   ├── FolderItem (collapsible)
│   │   └── RequestItem (draggable)
│   └── GitDropdown
├── ResizeHandle (Draggable Divider)
└── MainContent (Right Panel)
    ├── RequestPane (Top)
    │   ├── UrlBar
    │   ├── RequestTabs
    │   └── RequestEditors
    └── ResponsePane (Bottom)
        ├── ResponseHeader (Status, Time, Size)
        ├── ResponseTabs (Body, Headers, Info)
        └── ResponseViewers
            ├── TextViewer (JSON, XML, HTML, Plain)
            ├── ImageViewer
            ├── VideoViewer
            ├── AudioViewer
            └── PdfViewer
```

### State Management

The application uses HarmonyOS State Management V2 with the following state atoms:

- `@Local sidebarWidth: number` - Current sidebar width in pixels
- `@Local sidebarHidden: boolean` - Sidebar visibility state
- `@Local isResizing: boolean` - Active resize operation flag
- `@Local activeTab: string` - Active response tab (body/headers/info)
- `@Local viewMode: string` - Response view mode (pretty/raw)
- `@Local selectedRequestIds: string[]` - Selected items in tree
- `@Local filterText: string` - Sidebar filter query

### Data Flow

1. **User Interaction** → Component Event Handler
2. **Event Handler** → State Update (@Local/@Param)
3. **State Update** → UI Re-render (automatic)
4. **Database Operation** → Repository Method
5. **Repository Method** → Database Transaction
6. **Success** → State Sync + UI Update


## Components and Interfaces

### 1. ResizeHandle Component

**Purpose**: Draggable handle for resizing the sidebar

**Interface**:
```typescript
@ComponentV2
export struct ResizeHandle {
  @Param onResizeStart: () => void = () => {};
  @Param onResizeMove: (event: ResizeEvent) => void = () => {};
  @Param onResizeEnd: () => void = () => {};
  @Param onReset: () => void = () => {};
  @Param side: 'left' | 'right' = 'right';
}

interface ResizeEvent {
  x: number;
  y: number;
  xStart: number;
  yStart: number;
}
```

**Behavior**:
- Captures pan gesture events
- Calculates delta from start position
- Emits resize events with coordinates
- Shows visual feedback during drag
- Supports double-tap to reset

**Implementation Notes**:
- Use `PanGesture()` for drag detection
- Track start position in component state
- Emit events at 60fps for smooth resizing
- Apply cursor style changes (not supported in HarmonyOS, use visual feedback instead)

### 2. SidebarComponent

**Purpose**: Left panel containing request tree and navigation

**Interface**:
```typescript
@ComponentV2
export struct SidebarComponent {
  @Param width: number = 250;
  @Param hidden: boolean = false;
  @Param onWidthChange: (width: number) => void = () => {};
  @Param onHiddenChange: (hidden: boolean) => void = () => {};
}
```

**State**:
- `@Local filterText: string` - Search/filter query
- `@Local expandedFolders: Set<string>` - Expanded folder IDs
- `@Local selectedIds: string[]` - Selected request/folder IDs

**Key Methods**:
- `handleFilterChange(text: string)` - Updates filter and hides non-matching items
- `handleItemClick(id: string)` - Selects and navigates to request
- `handleItemLongPress(id: string)` - Shows context menu
- `handleDragStart(id: string)` - Initiates drag operation
- `handleDrop(targetId: string, position: 'before' | 'after' | 'inside')` - Handles drop


### 3. ResponseViewerComponent

**Purpose**: Displays HTTP response with intelligent formatting

**Interface**:
```typescript
@ComponentV2
export struct ResponseViewerComponent {
  @Param response: HttpResponse;
  @Param viewMode: 'pretty' | 'raw' = 'pretty';
  @Param onViewModeChange: (mode: string) => void = () => {};
}
```

**Sub-Components**:

#### TextViewer
```typescript
@ComponentV2
export struct TextViewer {
  @Param text: string;
  @Param language: 'json' | 'xml' | 'html' | 'text';
  @Param pretty: boolean = true;
}
```
- Uses syntax highlighting for JSON, XML, HTML
- Applies formatting/indentation in pretty mode
- Shows line numbers
- Supports text selection and copy

#### ImageViewer
```typescript
@ComponentV2
export struct ImageViewer {
  @Param imagePath: string;
}
```
- Displays image from file path
- Supports zoom and pan gestures
- Shows image dimensions and size

#### MediaViewer (Video/Audio)
```typescript
@ComponentV2
export struct MediaViewer {
  @Param mediaPath: string;
  @Param mediaType: 'video' | 'audio';
}
```
- Uses HarmonyOS Video/Audio component
- Provides playback controls
- Shows duration and progress

### 4. ContextMenuComponent

**Purpose**: Shows available actions for selected items

**Interface**:
```typescript
@ComponentV2
export struct ContextMenuComponent {
  @Param items: ContextMenuItem[];
  @Param onItemSelect: (action: string) => void = () => {};
  @Param position: { x: number; y: number };
}

interface ContextMenuItem {
  id: string;
  label: string;
  icon?: string;
  disabled?: boolean;
  danger?: boolean;
  separator?: boolean;
}
```

**Actions**:
- Send Request
- Rename
- Duplicate
- Move to Workspace
- Delete
- Folder Settings (folders only)
- Send All (folders only)


## Data Models

### SidebarPreferences
```typescript
interface SidebarPreferences {
  workspaceId: string;
  width: number;
  hidden: boolean;
}
```
Stored in: `preferences` API with key `sidebar_${workspaceId}`

### ResponseViewPreferences
```typescript
interface ResponseViewPreferences {
  requestId: string;
  viewMode: 'pretty' | 'raw';
  activeTab: 'body' | 'headers' | 'info';
}
```
Stored in: `preferences` API with key `response_view_${requestId}`

### TreeNodeState
```typescript
interface TreeNodeState {
  id: string;
  expanded: boolean;
  selected: boolean;
  hidden: boolean; // Based on filter
}
```
Stored in: Component @Local state

### ContentTypeMapping
```typescript
interface ContentTypeMapping {
  mimeType: string;
  viewer: 'text' | 'image' | 'video' | 'audio' | 'pdf';
  language?: 'json' | 'xml' | 'html' | 'text';
  supportsRaw: boolean;
}
```

**Mapping Table**:
| Content-Type | Viewer | Language | Supports Raw |
|--------------|--------|----------|--------------|
| application/json | text | json | yes |
| text/html | text | html | yes |
| text/xml, application/xml | text | xml | yes |
| text/plain | text | text | yes |
| image/* | image | - | no |
| video/* | video | - | no |
| audio/* | audio | - | no |
| application/pdf | pdf | - | no |
| text/csv | text | text | yes |
| text/event-stream | text | text | yes |


## Error Handling

### Resize Operation Errors

**Scenario**: Sidebar width becomes invalid
- **Detection**: Width < 0 or width > screen width
- **Recovery**: Reset to default width (250px)
- **User Feedback**: None (silent recovery)

**Scenario**: Preferences save fails
- **Detection**: Exception from preferences API
- **Recovery**: Continue with in-memory state
- **User Feedback**: Log error, no toast (non-critical)

### Response Viewer Errors

**Scenario**: Response body file not found
- **Detection**: File access error when loading body
- **Recovery**: Show "Response body not available" message
- **User Feedback**: Error message in viewer area

**Scenario**: Invalid JSON/XML format
- **Detection**: Parse error when formatting
- **Recovery**: Fall back to raw text view
- **User Feedback**: Show "Invalid format, displaying raw" banner

**Scenario**: Large response (>1MB)
- **Detection**: Check content length before rendering
- **Recovery**: Show confirmation dialog
- **User Feedback**: "Large response detected. Show anyway?" with Yes/No buttons

### Request Management Errors

**Scenario**: Delete operation fails
- **Detection**: Database error during deletion
- **Recovery**: Rollback transaction, keep item in UI
- **User Feedback**: Toast: "Failed to delete request: [error]"

**Scenario**: Duplicate operation fails
- **Detection**: Database error during insertion
- **Recovery**: No changes to database
- **User Feedback**: Toast: "Failed to duplicate request: [error]"

**Scenario**: Rename with empty name
- **Detection**: Validation before save
- **Recovery**: Reject change, keep original name
- **User Feedback**: Toast: "Request name cannot be empty"


## Testing Strategy

### Unit Tests

**ResizeHandle Component**:
- Test gesture detection and event emission
- Test coordinate calculation accuracy
- Test reset functionality
- Test boundary conditions (min/max width)

**ContentType Detection**:
- Test MIME type parsing
- Test content-based detection (first 20 bytes)
- Test fallback to text viewer
- Test all supported content types

**Request Management**:
- Test rename validation
- Test duplicate ID generation
- Test delete confirmation logic
- Test move operation workspace validation

### Integration Tests

**Sidebar Resize Flow**:
1. Start drag on resize handle
2. Move mouse/touch to new position
3. Verify sidebar width updates in real-time
4. Release drag
5. Verify width persisted to preferences
6. Reload app
7. Verify width restored correctly

**Response Viewer Flow**:
1. Send HTTP request
2. Receive response with JSON content-type
3. Verify JSON viewer displayed
4. Switch to Raw mode
5. Verify plain text displayed
6. Switch back to Pretty mode
7. Verify formatted JSON displayed

**Request Context Menu Flow**:
1. Long-press request item
2. Verify context menu appears
3. Select "Duplicate"
4. Verify new request created
5. Verify new request has "(Copy)" suffix
6. Verify new request selected

### Property-Based Tests

Not applicable for UI components. Focus on unit and integration tests.


## Implementation Details

### 1. Sidebar Resize Implementation

**File**: `yaak-hmos/entry/src/main/ets/components/ResizeHandle.ets`

```typescript
@ComponentV2
export struct ResizeHandle {
  @Param onResizeMove: (event: ResizeEvent) => void = () => {};
  @Param onResizeStart: () => void = () => {};
  @Param onResizeEnd: () => void = () => {};
  @Param onReset: () => void = () => {};
  
  @Local private isDragging: boolean = false;
  @Local private startX: number = 0;
  @Local private startY: number = 0;

  build() {
    Column()
      .width(8)
      .height('100%')
      .backgroundColor(this.isDragging ? '#1890ff' : 'transparent')
      .gesture(
        PanGesture()
          .onActionStart((event: GestureEvent) => {
            this.isDragging = true;
            this.startX = event.fingerList[0].globalX;
            this.startY = event.fingerList[0].globalY;
            this.onResizeStart();
          })
          .onActionUpdate((event: GestureEvent) => {
            const currentX = event.fingerList[0].globalX;
            const currentY = event.fingerList[0].globalY;
            this.onResizeMove({
              x: currentX,
              y: currentY,
              xStart: this.startX,
              yStart: this.startY
            });
          })
          .onActionEnd(() => {
            this.isDragging = false;
            this.onResizeEnd();
          })
      )
      .gesture(
        TapGesture({ count: 2 })
          .onAction(() => {
            this.onReset();
          })
      );
  }
}
```

**File**: `yaak-hmos/entry/src/main/ets/pages/Index.ets` (modifications)

```typescript
@Local sidebarWidth: number = 250;
@Local sidebarHidden: boolean = false;
@Local isResizing: boolean = false;
private startWidth: number = 0;

// Load preferences on init
async aboutToAppear() {
  const prefs = await preferences.getPreferences(this.context, 'yaak_prefs');
  this.sidebarWidth = await prefs.get(`sidebar_width_${this.selectedWorkspace?.id}`, 250) as number;
  this.sidebarHidden = await prefs.get(`sidebar_hidden_${this.selectedWorkspace?.id}`, false) as boolean;
}

handleResizeStart = (): void => {
  this.startWidth = this.sidebarWidth;
  this.isResizing = true;
}

handleResizeMove = (event: ResizeEvent): void => {
  const delta = event.x - event.xStart;
  const newWidth = this.startWidth + delta;
  
  if (newWidth < 50) {
    this.sidebarHidden = true;
    this.sidebarWidth = 250; // Reset to default
  } else {
    this.sidebarHidden = false;
    this.sidebarWidth = Math.min(Math.max(newWidth, 200), 600);
  }
}

handleResizeEnd = async (): Promise<void> => {
  this.isResizing = false;
  
  // Persist to preferences
  const prefs = await preferences.getPreferences(this.context, 'yaak_prefs');
  await prefs.put(`sidebar_width_${this.selectedWorkspace?.id}`, this.sidebarWidth);
  await prefs.put(`sidebar_hidden_${this.selectedWorkspace?.id}`, this.sidebarHidden);
  await prefs.flush();
}

handleResetWidth = async (): Promise<void> => {
  this.sidebarWidth = 250;
  this.sidebarHidden = false;
  
  const prefs = await preferences.getPreferences(this.context, 'yaak_prefs');
  await prefs.put(`sidebar_width_${this.selectedWorkspace?.id}`, 250);
  await prefs.put(`sidebar_hidden_${this.selectedWorkspace?.id}`, false);
  await prefs.flush();
}
```


### 2. Response Viewer Implementation

**File**: `yaak-hmos/entry/src/main/ets/services/ContentTypeDetector.ets`

```typescript
export class ContentTypeDetector {
  /**
   * Detect content type from headers and content
   */
  static detect(headers: HttpResponseHeader[], content: string | null): ContentTypeInfo {
    // First try Content-Type header
    const contentTypeHeader = headers.find(h => 
      h.name.toLowerCase() === 'content-type'
    );
    
    if (contentTypeHeader) {
      const mimeType = this.parseMimeType(contentTypeHeader.value);
      const info = this.getInfoFromMimeType(mimeType);
      if (info) return info;
    }
    
    // Fall back to content detection
    if (content) {
      return this.detectFromContent(content);
    }
    
    // Default to text
    return {
      viewer: 'text',
      language: 'text',
      supportsRaw: true
    };
  }
  
  private static parseMimeType(contentType: string): string {
    return contentType.split(';')[0].trim().toLowerCase();
  }
  
  private static getInfoFromMimeType(mimeType: string): ContentTypeInfo | null {
    const mappings: Record<string, ContentTypeInfo> = {
      'application/json': { viewer: 'text', language: 'json', supportsRaw: true },
      'text/html': { viewer: 'text', language: 'html', supportsRaw: true },
      'text/xml': { viewer: 'text', language: 'xml', supportsRaw: true },
      'application/xml': { viewer: 'text', language: 'xml', supportsRaw: true },
      'text/plain': { viewer: 'text', language: 'text', supportsRaw: true },
      'application/pdf': { viewer: 'pdf', language: null, supportsRaw: false },
      'text/csv': { viewer: 'text', language: 'text', supportsRaw: true },
    };
    
    // Check exact match
    if (mappings[mimeType]) {
      return mappings[mimeType];
    }
    
    // Check prefix match
    if (mimeType.startsWith('image/')) {
      return { viewer: 'image', language: null, supportsRaw: false };
    }
    if (mimeType.startsWith('video/')) {
      return { viewer: 'video', language: null, supportsRaw: false };
    }
    if (mimeType.startsWith('audio/')) {
      return { viewer: 'audio', language: null, supportsRaw: false };
    }
    
    return null;
  }
  
  private static detectFromContent(content: string): ContentTypeInfo {
    const firstBytes = content.slice(0, 20).trim();
    
    if (firstBytes.startsWith('{') || firstBytes.startsWith('[')) {
      return { viewer: 'text', language: 'json', supportsRaw: true };
    }
    if (firstBytes.toLowerCase().startsWith('<!doctype') || 
        firstBytes.toLowerCase().startsWith('<html')) {
      return { viewer: 'text', language: 'html', supportsRaw: true };
    }
    if (firstBytes.startsWith('<')) {
      return { viewer: 'text', language: 'xml', supportsRaw: true };
    }
    
    return { viewer: 'text', language: 'text', supportsRaw: true };
  }
}

interface ContentTypeInfo {
  viewer: 'text' | 'image' | 'video' | 'audio' | 'pdf';
  language: 'json' | 'xml' | 'html' | 'text' | null;
  supportsRaw: boolean;
}
```


**File**: `yaak-hmos/entry/src/main/ets/components/ResponseViewer.ets`

```typescript
@ComponentV2
export struct ResponseViewer {
  @Param response: HttpResponse;
  @Local viewMode: 'pretty' | 'raw' = 'pretty';
  @Local activeTab: 'body' | 'headers' | 'info' = 'body';
  
  private contentTypeInfo: ContentTypeInfo | null = null;
  private responseBody: string = '';
  
  async aboutToAppear() {
    // Load preferences
    const prefs = await preferences.getPreferences(getContext(), 'yaak_prefs');
    this.viewMode = await prefs.get(`view_mode_${this.response.request_id}`, 'pretty') as string;
    this.activeTab = await prefs.get(`active_tab_${this.response.request_id}`, 'body') as string;
    
    // Load response body
    if (this.response.body_path) {
      this.responseBody = await ResponseStorageService.loadResponseBody(this.response.body_path);
    }
    
    // Detect content type
    this.contentTypeInfo = ContentTypeDetector.detect(this.response.headers, this.responseBody);
  }
  
  build() {
    Column() {
      // Response header with status, time, size
      this.buildResponseHeader();
      
      // Tabs
      Tabs({ index: this.getTabIndex() }) {
        TabContent() {
          this.buildBodyTab();
        }.tabBar('Body')
        
        TabContent() {
          this.buildHeadersTab();
        }.tabBar(`Headers (${this.response.headers.length})`)
        
        TabContent() {
          this.buildInfoTab();
        }.tabBar('Info')
      }
      .onChange((index: number) => {
        this.activeTab = ['body', 'headers', 'info'][index];
        this.savePreferences();
      })
    }
  }
  
  @Builder
  buildBodyTab() {
    Column() {
      // Mode selector for text content
      if (this.contentTypeInfo?.supportsRaw) {
        Row() {
          Text('Pretty')
            .onClick(() => {
              this.viewMode = 'pretty';
              this.savePreferences();
            })
          Text('Raw')
            .onClick(() => {
              this.viewMode = 'raw';
              this.savePreferences();
            })
        }
      }
      
      // Content viewer based on type
      if (this.contentTypeInfo?.viewer === 'text') {
        TextViewer({
          text: this.responseBody,
          language: this.contentTypeInfo.language,
          pretty: this.viewMode === 'pretty'
        })
      } else if (this.contentTypeInfo?.viewer === 'image') {
        ImageViewer({ imagePath: this.response.body_path })
      } else if (this.contentTypeInfo?.viewer === 'video') {
        VideoViewer({ videoPath: this.response.body_path })
      } else if (this.contentTypeInfo?.viewer === 'audio') {
        AudioViewer({ audioPath: this.response.body_path })
      }
    }
  }
  
  private async savePreferences() {
    const prefs = await preferences.getPreferences(getContext(), 'yaak_prefs');
    await prefs.put(`view_mode_${this.response.request_id}`, this.viewMode);
    await prefs.put(`active_tab_${this.response.request_id}`, this.activeTab);
    await prefs.flush();
  }
}
```


### 3. Request Management Implementation

**File**: `yaak-hmos/entry/src/main/ets/components/RequestContextMenu.ets`

```typescript
@ComponentV2
export struct RequestContextMenu {
  @Param request: HttpRequest;
  @Param onAction: (action: string) => void = () => {};
  @Param visible: boolean = false;
  @Param position: { x: number; y: number } = { x: 0, y: 0 };
  
  private menuItems: ContextMenuItem[] = [];
  
  aboutToAppear() {
    this.menuItems = [
      { id: 'send', label: 'Send', icon: 'send' },
      { id: 'rename', label: 'Rename', icon: 'edit' },
      { id: 'duplicate', label: 'Duplicate', icon: 'copy' },
      { id: 'move', label: 'Move to Workspace', icon: 'folder' },
      { id: 'separator', separator: true },
      { id: 'delete', label: 'Delete', icon: 'delete', danger: true }
    ];
  }
  
  build() {
    if (this.visible) {
      Column() {
        ForEach(this.menuItems, (item: ContextMenuItem) => {
          if (item.separator) {
            Divider();
          } else {
            Row() {
              Image($r(`app.media.${item.icon}`))
                .width(20)
                .height(20);
              Text(item.label)
                .fontColor(item.danger ? '#ff4d4f' : '#000000');
            }
            .onClick(() => {
              this.onAction(item.id);
            })
          }
        })
      }
      .position({ x: this.position.x, y: this.position.y })
      .backgroundColor('#ffffff')
      .borderRadius(8)
      .shadow({ radius: 10, color: '#00000020' })
    }
  }
}
```

**File**: `yaak-hmos/entry/src/main/ets/components/RequestTreeItem.ets`

```typescript
@ComponentV2
export struct RequestTreeItem {
  @Param request: HttpRequest;
  @Param selected: boolean = false;
  @Param onSelect: () => void = () => {};
  @Param onLongPress: () => void = () => {};
  @Param onDragStart: () => void = () => {};
  
  @Local showContextMenu: boolean = false;
  @Local contextMenuPosition: { x: number; y: number } = { x: 0, y: 0 };
  
  build() {
    Row() {
      // HTTP Method badge
      Text(this.request.method)
        .fontSize(12)
        .fontColor('#ffffff')
        .backgroundColor(this.getMethodColor())
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(4);
      
      // Request name
      Text(this.request.name || this.request.url)
        .fontSize(14)
        .fontColor(this.selected ? '#1890ff' : '#000000')
        .layoutWeight(1);
      
      // Status indicator
      if (this.request.lastResponse) {
        Text(this.request.lastResponse.status.toString())
          .fontSize(12)
          .fontColor(this.getStatusColor(this.request.lastResponse.status));
      }
    }
    .width('100%')
    .padding(12)
    .backgroundColor(this.selected ? '#e6f7ff' : 'transparent')
    .onClick(this.onSelect)
    .gesture(
      LongPressGesture()
        .onAction((event: GestureEvent) => {
          this.contextMenuPosition = {
            x: event.fingerList[0].globalX,
            y: event.fingerList[0].globalY
          };
          this.showContextMenu = true;
          this.onLongPress();
        })
    )
    .gesture(
      PanGesture()
        .onActionStart(() => {
          this.onDragStart();
        })
    );
    
    // Context menu overlay
    RequestContextMenu({
      request: this.request,
      visible: this.showContextMenu,
      position: this.contextMenuPosition,
      onAction: (action: string) => {
        this.handleContextAction(action);
        this.showContextMenu = false;
      }
    });
  }
  
  private handleContextAction(action: string) {
    switch (action) {
      case 'send':
        this.sendRequest();
        break;
      case 'rename':
        this.startRename();
        break;
      case 'duplicate':
        this.duplicateRequest();
        break;
      case 'delete':
        this.deleteRequest();
        break;
    }
  }
  
  private async duplicateRequest() {
    const newRequest: HttpRequest = {
      ...this.request,
      id: `req_${Date.now()}_${Math.floor(Math.random() * 10000)}`,
      name: `${this.request.name} (Copy)`,
      created_at: Date.now(),
      updated_at: Date.now()
    };
    
    const requestRepo = new RequestRepository();
    await requestRepo.createRequest(newRequest);
    
    console.info(`[RequestTreeItem] Request duplicated: ${newRequest.id}`);
  }
  
  private async deleteRequest() {
    // Show confirmation dialog
    AlertDialog.show({
      title: 'Delete Request',
      message: `Are you sure you want to delete "${this.request.name}"?`,
      primaryButton: {
        value: 'Cancel',
        action: () => {}
      },
      secondaryButton: {
        value: 'Delete',
        fontColor: '#ff4d4f',
        action: async () => {
          const requestRepo = new RequestRepository();
          await requestRepo.deleteRequest(this.request.id);
          console.info(`[RequestTreeItem] Request deleted: ${this.request.id}`);
        }
      }
    });
  }
  
  private getMethodColor(): string {
    const colors: Record<string, string> = {
      'GET': '#1890ff',
      'POST': '#52c41a',
      'PUT': '#faad14',
      'DELETE': '#ff4d4f',
      'PATCH': '#722ed1'
    };
    return colors[this.request.method] || '#8c8c8c';
  }
  
  private getStatusColor(status: number): string {
    if (status >= 200 && status < 300) return '#52c41a';
    if (status >= 300 && status < 400) return '#faad14';
    if (status >= 400 && status < 500) return '#ff4d4f';
    if (status >= 500) return '#cf1322';
    return '#8c8c8c';
  }
}
```


## Performance Optimizations

### 1. Sidebar Resize Performance

**Problem**: Dragging can cause frame drops if UI updates are too heavy

**Solutions**:
- Disable CSS transitions during drag (`isResizing` flag)
- Use `@Local` state for immediate updates without re-rendering entire tree
- Throttle preference saves to only occur on drag end
- Use hardware-accelerated transforms where possible

**Implementation**:
```typescript
// Disable transitions during resize
.animation(this.isResizing ? null : { duration: 200 })
```

### 2. Response Viewer Performance

**Problem**: Large responses can freeze UI during formatting

**Solutions**:
- Check content length before rendering
- Show confirmation dialog for responses > 1MB
- Lazy load syntax highlighting (only when visible)
- Use virtual scrolling for very long content
- Cache formatted content to avoid re-formatting

**Implementation**:
```typescript
if (this.responseBody.length > 1024 * 1024) {
  // Show confirmation dialog
  AlertDialog.show({
    title: 'Large Response',
    message: `Response is ${(this.responseBody.length / 1024 / 1024).toFixed(2)}MB. Display anyway?`,
    primaryButton: { value: 'Cancel' },
    secondaryButton: { 
      value: 'Show', 
      action: () => this.renderResponse() 
    }
  });
} else {
  this.renderResponse();
}
```

### 3. Tree Rendering Performance

**Problem**: Large workspaces with 1000+ requests can be slow

**Solutions**:
- Use `LazyForEach` for tree items
- Implement virtual scrolling
- Only render visible items (viewport culling)
- Cache tree node calculations
- Debounce filter operations

**Implementation**:
```typescript
List() {
  LazyForEach(this.visibleRequests, (request: HttpRequest) => {
    ListItem() {
      RequestTreeItem({ request: request })
    }
  })
}
.cachedCount(20) // Cache 20 items above/below viewport
```

### 4. Database Query Optimization

**Problem**: Frequent database queries can slow down UI

**Solutions**:
- Batch database operations
- Use transactions for multiple updates
- Cache frequently accessed data
- Use indexes on commonly queried fields
- Debounce save operations

**Implementation**:
```typescript
// Batch update sort priorities
async updateSortPriorities(items: Array<{ id: string; priority: number }>) {
  await this.db.executeInTransaction(async () => {
    for (const item of items) {
      await this.db.execute(
        'UPDATE http_requests SET sort_priority = ? WHERE id = ?',
        [item.priority, item.id]
      );
    }
  });
}
```


## Security Considerations

### 1. File Path Validation

**Risk**: Malicious response body paths could access unauthorized files

**Mitigation**:
- Validate all file paths are within app sandbox
- Use `context.filesDir` as base path
- Reject paths with `..` or absolute paths
- Sanitize file names before storage

**Implementation**:
```typescript
private validateFilePath(path: string): boolean {
  const filesDir = this.context.filesDir;
  const resolvedPath = path.startsWith(filesDir);
  const hasTraversal = path.includes('..');
  return resolvedPath && !hasTraversal;
}
```

### 2. Content Type Injection

**Risk**: Malicious Content-Type headers could trigger incorrect viewers

**Mitigation**:
- Validate Content-Type format
- Whitelist allowed MIME types
- Fall back to text viewer for unknown types
- Sanitize HTML content before rendering

**Implementation**:
```typescript
private sanitizeContentType(contentType: string): string {
  const allowedTypes = [
    'application/json',
    'text/html',
    'text/xml',
    'text/plain',
    'image/*',
    'video/*',
    'audio/*'
  ];
  
  const mimeType = contentType.split(';')[0].trim();
  const isAllowed = allowedTypes.some(allowed => {
    if (allowed.endsWith('/*')) {
      return mimeType.startsWith(allowed.slice(0, -2));
    }
    return mimeType === allowed;
  });
  
  return isAllowed ? contentType : 'text/plain';
}
```

### 3. XSS Prevention in HTML Viewer

**Risk**: Malicious HTML responses could execute scripts

**Mitigation**:
- Use Web component with sandbox mode
- Disable JavaScript execution
- Strip `<script>` tags from HTML
- Use Content Security Policy

**Implementation**:
```typescript
Web({ 
  src: `data:text/html;charset=utf-8,${encodeURIComponent(sanitizedHtml)}`,
  controller: this.webController 
})
.javaScriptAccess(false) // Disable JavaScript
.domStorageAccess(false) // Disable storage
```

### 4. SQL Injection Prevention

**Risk**: User input in request names could inject SQL

**Mitigation**:
- Use parameterized queries
- Validate and sanitize all user input
- Use ORM/Repository pattern
- Escape special characters

**Implementation**:
```typescript
// Always use parameterized queries
async updateRequestName(id: string, name: string): Promise<void> {
  await this.db.execute(
    'UPDATE http_requests SET name = ? WHERE id = ?',
    [name, id] // Parameters prevent injection
  );
}
```


## Accessibility

### 1. Keyboard Navigation

**Requirements**:
- All interactive elements must be keyboard accessible
- Provide keyboard shortcuts for common actions
- Support tab navigation through UI
- Show focus indicators

**Implementation**:
```typescript
// Focus management
.focusable(true)
.onFocus(() => {
  this.isFocused = true;
})
.onBlur(() => {
  this.isFocused = false;
})
.border({
  width: this.isFocused ? 2 : 0,
  color: '#1890ff'
})
```

**Keyboard Shortcuts**:
| Action | Shortcut | Scope |
|--------|----------|-------|
| Toggle Sidebar | Ctrl+B | Global |
| Focus Filter | Ctrl+F | Sidebar |
| Send Request | Ctrl+Enter | Request |
| Rename | F2 | Tree Item |
| Delete | Delete | Tree Item |
| Duplicate | Ctrl+D | Tree Item |
| Navigate Up | ↑ | Tree |
| Navigate Down | ↓ | Tree |
| Expand Folder | → | Folder |
| Collapse Folder | ← | Folder |

### 2. Screen Reader Support

**Requirements**:
- Provide meaningful labels for all UI elements
- Announce state changes
- Support ARIA attributes

**Implementation**:
```typescript
Text(this.request.name)
  .accessibilityText(`HTTP ${this.request.method} request to ${this.request.url}`)
  .accessibilityLevel('h3')
  .accessibilityDescription(
    this.selected ? 'Selected' : 'Not selected'
  );
```

### 3. Visual Feedback

**Requirements**:
- Provide visual feedback for all interactions
- Use multiple indicators (not just color)
- Maintain sufficient contrast ratios
- Support high contrast mode

**Implementation**:
```typescript
// Multiple indicators for status
Row() {
  // Color indicator
  Circle()
    .width(8)
    .height(8)
    .fill(this.getStatusColor());
  
  // Text indicator
  Text(this.getStatusText())
    .fontSize(12);
  
  // Icon indicator
  Image(this.getStatusIcon())
    .width(16)
    .height(16);
}
```

### 4. Touch Target Sizes

**Requirements**:
- Minimum touch target: 44x44 dp
- Adequate spacing between targets
- Support for different input methods

**Implementation**:
```typescript
Button('Delete')
  .width(44)
  .height(44)
  .padding(12) // Ensures minimum touch area
```


## Migration and Compatibility

### 1. Existing Data Migration

**Scenario**: Users upgrading from version without these features

**Migration Steps**:
1. No database schema changes required
2. Preferences will be created on first use with defaults
3. Existing requests continue to work without modification
4. Response viewer will detect content types for existing responses

**Implementation**:
```typescript
async migratePreferences() {
  const prefs = await preferences.getPreferences(this.context, 'yaak_prefs');
  
  // Check if migration needed
  const migrated = await prefs.get('ui_improvements_migrated', false);
  if (migrated) return;
  
  // Set default preferences for all workspaces
  const workspaces = await this.workspaceRepo.getAllWorkspaces();
  for (const workspace of workspaces) {
    await prefs.put(`sidebar_width_${workspace.id}`, 250);
    await prefs.put(`sidebar_hidden_${workspace.id}`, false);
  }
  
  await prefs.put('ui_improvements_migrated', true);
  await prefs.flush();
}
```

### 2. Backward Compatibility

**Requirements**:
- New features must not break existing functionality
- Graceful degradation for missing data
- Support for old response format

**Implementation**:
```typescript
// Handle responses without body_path
if (this.response.body_path) {
  this.responseBody = await ResponseStorageService.loadResponseBody(
    this.response.body_path
  );
} else {
  // Fall back to inline body (old format)
  this.responseBody = this.response.body || '';
}
```

### 3. Feature Flags

**Purpose**: Enable gradual rollout and easy rollback

**Implementation**:
```typescript
interface FeatureFlags {
  enableResizableSidebar: boolean;
  enableEnhancedResponseViewer: boolean;
  enableRequestManagement: boolean;
}

class FeatureFlagService {
  private static flags: FeatureFlags = {
    enableResizableSidebar: true,
    enableEnhancedResponseViewer: true,
    enableRequestManagement: true
  };
  
  static isEnabled(feature: keyof FeatureFlags): boolean {
    return this.flags[feature];
  }
}

// Usage in components
if (FeatureFlagService.isEnabled('enableResizableSidebar')) {
  ResizeHandle({ ... });
}
```


## Deployment Strategy

### Phase 1: Core Infrastructure (Week 1)
- Implement ResizeHandle component
- Add sidebar width persistence
- Create ContentTypeDetector service
- Set up preferences API integration

### Phase 2: Response Viewer (Week 2)
- Implement TextViewer with syntax highlighting
- Add ImageViewer component
- Add VideoViewer and AudioViewer components
- Implement view mode toggle (Pretty/Raw)
- Add large response confirmation

### Phase 3: Request Management (Week 3)
- Implement context menu component
- Add rename functionality
- Add duplicate functionality
- Add delete with confirmation
- Implement drag and drop reordering

### Phase 4: Polish and Testing (Week 4)
- Add keyboard shortcuts
- Implement accessibility features
- Performance optimization
- Integration testing
- Bug fixes and refinements

### Rollout Plan

**Alpha Release** (Internal Testing):
- Deploy to development team
- Collect feedback on usability
- Fix critical bugs
- Performance profiling

**Beta Release** (Limited Users):
- Deploy to 10% of users
- Monitor error rates
- Collect user feedback
- A/B testing for UX improvements

**General Availability**:
- Deploy to all users
- Monitor performance metrics
- Provide user documentation
- Support channels ready

### Rollback Plan

If critical issues are discovered:

1. **Immediate**: Disable feature flags
2. **Short-term**: Revert to previous version
3. **Long-term**: Fix issues and re-deploy

**Rollback Triggers**:
- Crash rate > 1%
- Performance degradation > 20%
- Data loss incidents
- Critical security vulnerabilities


## Monitoring and Metrics

### Key Performance Indicators (KPIs)

**User Engagement**:
- Sidebar resize usage frequency
- Response viewer mode switches (Pretty vs Raw)
- Context menu action usage
- Keyboard shortcut adoption rate

**Performance Metrics**:
- Sidebar resize frame rate (target: 60fps)
- Response formatting time (target: <500ms)
- Tree rendering time (target: <100ms)
- Database operation latency (target: <200ms)

**Quality Metrics**:
- Crash-free rate (target: >99.9%)
- Error rate (target: <0.1%)
- User-reported bugs (target: <5 per week)
- Response time for user feedback (target: <24 hours)

### Logging Strategy

**Log Levels**:
- **ERROR**: Critical failures requiring immediate attention
- **WARN**: Potential issues that don't block functionality
- **INFO**: Important state changes and user actions
- **DEBUG**: Detailed diagnostic information

**Log Examples**:
```typescript
// Sidebar resize
console.info(`[ResizeHandle] Sidebar width changed: ${oldWidth}px -> ${newWidth}px`);

// Response viewer
console.info(`[ResponseViewer] Content type detected: ${contentType}, viewer: ${viewer}`);

// Request management
console.info(`[RequestManagement] Request duplicated: ${originalId} -> ${newId}`);

// Performance
console.warn(`[Performance] Response formatting took ${duration}ms (threshold: 500ms)`);

// Errors
console.error(`[Database] Failed to save request: ${error.message}`, error);
```

### Analytics Events

**User Actions**:
- `sidebar_resized`: { width: number, workspace_id: string }
- `sidebar_hidden`: { workspace_id: string }
- `response_view_mode_changed`: { mode: 'pretty' | 'raw', content_type: string }
- `request_renamed`: { request_id: string }
- `request_duplicated`: { request_id: string }
- `request_deleted`: { request_id: string }
- `context_menu_opened`: { item_type: 'request' | 'folder' }

**Performance Events**:
- `response_formatted`: { duration_ms: number, size_bytes: number, content_type: string }
- `tree_rendered`: { duration_ms: number, item_count: number }
- `database_operation`: { operation: string, duration_ms: number }

**Error Events**:
- `error_occurred`: { component: string, error_type: string, message: string }
- `large_response_shown`: { size_mb: number, user_confirmed: boolean }


## Future Enhancements

### 1. Advanced Response Viewers

**CSV Table Viewer**:
- Parse CSV content into table format
- Support column sorting and filtering
- Export to Excel format

**GraphQL Viewer**:
- Syntax highlighting for GraphQL responses
- Schema introspection display
- Query/mutation documentation

**Protocol Buffer Viewer**:
- Decode protobuf messages
- Display message structure
- Support for .proto file imports

### 2. Sidebar Enhancements

**Multiple Sidebar Panels**:
- Collections panel
- History panel
- Environments panel
- Switchable via tabs

**Advanced Filtering**:
- Filter by HTTP method
- Filter by status code
- Filter by response time
- Save filter presets

**Workspace Switcher**:
- Quick workspace switching
- Recent workspaces list
- Workspace search

### 3. Request Management Enhancements

**Bulk Operations**:
- Multi-select requests
- Bulk delete
- Bulk move to folder
- Bulk tag assignment

**Request Templates**:
- Save request as template
- Template library
- Template variables
- Quick create from template

**Request History**:
- View all historical responses
- Compare responses
- Export response history
- Response diff viewer

### 4. Collaboration Features

**Request Sharing**:
- Generate shareable links
- Export request as cURL
- Export collection as Postman format
- QR code for mobile sharing

**Team Workspaces**:
- Shared workspaces
- Real-time collaboration
- Change notifications
- Conflict resolution

### 5. Performance Improvements

**Virtual Scrolling**:
- Render only visible items
- Support for 10,000+ requests
- Smooth scrolling performance

**Web Workers**:
- Offload syntax highlighting
- Background response parsing
- Async content formatting

**Caching Strategy**:
- Cache formatted responses
- Cache syntax highlighting
- Intelligent cache invalidation

