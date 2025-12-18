# Implementation Plan - UI Improvements

## Overview

This implementation plan breaks down the UI improvements into manageable tasks, organized by feature area. Each task includes specific implementation details and references to requirements.

**Total Estimated Time**: 4 weeks (160 hours)

**Task Breakdown**:
- Phase 1: Core Infrastructure (40 hours)
- Phase 2: Response Viewer (50 hours)
- Phase 3: Request Management (50 hours)
- Phase 4: Polish and Testing (20 hours)

---

## Phase 1: Core Infrastructure (Week 1)

### 1. Create ResizeHandle Component

- [ ] 1.1 Create ResizeHandle.ets component file
  - Implement PanGesture for drag detection
  - Track start position and calculate delta
  - Emit resize events with coordinates
  - Add visual feedback during drag
  - Support double-tap to reset
  - _Requirements: 1.1, 1.2, 1.7_

- [ ] 1.2 Add ResizeHandle to Index.ets
  - Position handle between sidebar and main content
  - Wire up event handlers
  - Test drag functionality
  - _Requirements: 1.1, 1.2_

### 2. Implement Sidebar Width Management

- [ ] 2.1 Add sidebar width state to Index.ets
  - Add @Local sidebarWidth: number = 250
  - Add @Local sidebarHidden: boolean = false
  - Add @Local isResizing: boolean = false
  - _Requirements: 1.1, 1.4, 1.8_

- [ ] 2.2 Implement resize event handlers
  - handleResizeStart() - Store initial width
  - handleResizeMove() - Calculate and apply new width
  - handleResizeEnd() - Persist to preferences
  - handleResetWidth() - Reset to default 250px
  - _Requirements: 1.1, 1.2, 1.3, 1.7_

- [ ] 2.3 Add auto-hide logic
  - Check if width < 50px during resize
  - Set sidebarHidden = true
  - Reset width to 250px
  - _Requirements: 1.3_

- [ ] 2.4 Implement width persistence
  - Load width from preferences on init
  - Save width to preferences on resize end
  - Key by workspace ID: `sidebar_width_${workspaceId}`
  - _Requirements: 1.6, 1.10_


### 3. Create ContentTypeDetector Service

- [ ] 3.1 Create ContentTypeDetector.ets service file
  - Implement detect() method
  - Parse Content-Type header
  - Implement MIME type mapping
  - Add content-based detection fallback
  - _Requirements: 2.1-2.10, 2.18_

- [ ] 3.2 Add content type mapping table
  - Map application/json → text viewer, json language
  - Map text/html → text viewer, html language
  - Map text/xml, application/xml → text viewer, xml language
  - Map image/* → image viewer
  - Map video/* → video viewer
  - Map audio/* → audio viewer
  - Map application/pdf → pdf viewer
  - _Requirements: 2.1-2.10_

- [ ] 3.3 Implement content-based detection
  - Check first 20 bytes of content
  - Detect JSON by { or [ prefix
  - Detect HTML by <!doctype or <html prefix
  - Detect XML by < prefix
  - Fall back to text viewer
  - _Requirements: 2.18_

### 4. Set Up Preferences API Integration

- [ ] 4.1 Create PreferencesService.ets utility
  - Wrap preferences API for easier use
  - Implement get/set/flush methods
  - Add type-safe getters
  - Handle errors gracefully
  - _Requirements: 1.6, 2.19_

- [ ] 4.2 Add preference keys constants
  - SIDEBAR_WIDTH_PREFIX = 'sidebar_width_'
  - SIDEBAR_HIDDEN_PREFIX = 'sidebar_hidden_'
  - VIEW_MODE_PREFIX = 'view_mode_'
  - ACTIVE_TAB_PREFIX = 'active_tab_'
  - _Requirements: 1.6, 2.19_

---

## Phase 2: Response Viewer (Week 2)

### 5. Create Base Response Viewer Components

- [ ] 5.1 Create ResponseViewer.ets component
  - Add @Param response: HttpResponse
  - Add @Local viewMode: 'pretty' | 'raw'
  - Add @Local activeTab: 'body' | 'headers' | 'info'
  - Load preferences on init
  - Detect content type
  - Load response body from file
  - _Requirements: 2.1-2.19, 4.1-4.10_

- [ ] 5.2 Implement response header display
  - Show HTTP status code with color coding
  - Show elapsed time (headers + total)
  - Show response size
  - Add loading indicator for in-progress requests
  - _Requirements: 4.1-4.6, 7.1-7.3_

- [ ] 5.3 Implement tab navigation
  - Create Tabs component with Body/Headers/Info
  - Persist active tab per request ID
  - Show count badge on Headers tab
  - _Requirements: 4.1-4.8_


### 6. Implement Text Viewer with Syntax Highlighting

- [ ] 6.1 Create TextViewer.ets component
  - Add @Param text: string
  - Add @Param language: 'json' | 'xml' | 'html' | 'text'
  - Add @Param pretty: boolean
  - Implement syntax highlighting for JSON
  - Implement syntax highlighting for XML
  - Implement syntax highlighting for HTML
  - _Requirements: 2.1, 2.3, 2.4, 2.11, 2.12_

- [ ] 6.2 Add formatting logic
  - Format JSON with indentation in pretty mode
  - Format XML with indentation in pretty mode
  - Format HTML with indentation in pretty mode
  - Show raw text in raw mode
  - _Requirements: 2.12, 2.13_

- [ ] 6.3 Add view mode toggle
  - Create mode selector UI (Pretty/Raw buttons)
  - Wire up mode change handler
  - Persist mode to preferences
  - Hide toggle for non-text content
  - _Requirements: 2.11, 2.12, 2.13, 2.19_

- [ ] 6.4 Add large response confirmation
  - Check content length before rendering
  - Show dialog if > 1MB
  - Provide "Show Response" and "Cancel" buttons
  - _Requirements: 2.14_

### 7. Implement Media Viewers

- [ ] 7.1 Create ImageViewer.ets component
  - Add @Param imagePath: string
  - Load image from file path
  - Display image with proper scaling
  - Show image dimensions and size
  - Support pinch-to-zoom gesture
  - _Requirements: 2.5_

- [ ] 7.2 Create VideoViewer.ets component
  - Add @Param videoPath: string
  - Use HarmonyOS Video component
  - Add playback controls
  - Show duration and progress
  - _Requirements: 2.6_

- [ ] 7.3 Create AudioViewer.ets component
  - Add @Param audioPath: string
  - Use HarmonyOS Audio component
  - Add playback controls
  - Show duration and progress
  - _Requirements: 2.7_

### 8. Implement Special Content Viewers

- [ ] 8.1 Create PdfViewer.ets component (optional)
  - Add @Param pdfPath: string
  - Use HarmonyOS PDF rendering API
  - Add page navigation
  - Show page count
  - _Requirements: 2.8_

- [ ] 8.2 Implement CSV table viewer (optional)
  - Parse CSV content
  - Display in table format
  - Add column headers
  - _Requirements: 2.9_

- [ ] 8.3 Implement event stream viewer (optional)
  - Display streaming events
  - Show events in real-time
  - Add auto-scroll option
  - _Requirements: 2.10_


### 9. Integrate Response Viewer into Index.ets

- [ ] 9.1 Replace existing response display with ResponseViewer
  - Import ResponseViewer component
  - Pass current response as prop
  - Remove old response display code
  - Test with different content types
  - _Requirements: 2.1-2.19_

- [ ] 9.2 Add response state handling
  - Show loading indicator when state = 'initialized'
  - Show "Empty" message when content_length = 0
  - Show error banner when response has error
  - _Requirements: 2.15, 2.16, 2.17, 4.10_

- [ ] 9.3 Test response viewer with various content types
  - Test JSON response
  - Test XML response
  - Test HTML response
  - Test image response
  - Test plain text response
  - Test error response
  - _Requirements: 2.1-2.17_

---

## Phase 3: Request Management (Week 3)

### 10. Create Context Menu Component

- [ ] 10.1 Create ContextMenu.ets component
  - Add @Param items: ContextMenuItem[]
  - Add @Param visible: boolean
  - Add @Param position: { x, y }
  - Add @Param onItemSelect callback
  - Implement menu item rendering
  - Add separator support
  - Add icon support
  - Add danger styling for delete
  - _Requirements: 3.1-3.7_

- [ ] 10.2 Create RequestContextMenu.ets component
  - Extend ContextMenu with request-specific items
  - Add "Send" action
  - Add "Rename" action
  - Add "Duplicate" action
  - Add "Move" action
  - Add "Delete" action
  - _Requirements: 3.1-3.7_

- [ ] 10.3 Create FolderContextMenu.ets component
  - Extend ContextMenu with folder-specific items
  - Add "Folder Settings" action
  - Add "Send All" action
  - Add "Rename" action
  - Add "Duplicate" action
  - Add "Delete" action
  - Add "Create New" submenu
  - _Requirements: 3.5, 3.6, 3.7_


### 11. Implement Rename Functionality

- [ ] 11.1 Add rename state to RequestTreeItem
  - Add @Local isRenaming: boolean = false
  - Add @Local editingName: string = ''
  - Show text input when isRenaming = true
  - _Requirements: 3.8-3.12_

- [ ] 11.2 Implement rename UI
  - Show inline text input with current name
  - Focus input and select all text
  - Handle Enter key to confirm
  - Handle Escape key to cancel
  - _Requirements: 3.9, 3.10, 3.11_

- [ ] 11.3 Implement rename save logic
  - Validate name is not empty
  - Update request in database
  - Update UI immediately
  - Show error toast if save fails
  - _Requirements: 3.9, 3.12_

### 12. Implement Duplicate Functionality

- [ ] 12.1 Create duplicateRequest method
  - Copy all request properties
  - Generate new unique ID
  - Add " (Copy)" suffix to name
  - Set created_at and updated_at to now
  - _Requirements: 3.13, 3.14, 3.15_

- [ ] 12.2 Implement duplicate save logic
  - Insert new request into database
  - Calculate sort priority (after original)
  - Navigate to new request
  - Show error toast if save fails
  - _Requirements: 3.16, 3.17_

### 13. Implement Delete Functionality

- [ ] 13.1 Create delete confirmation dialog
  - Show AlertDialog with request name
  - Add "Cancel" button
  - Add "Delete" button (danger style)
  - _Requirements: 3.18_

- [ ] 13.2 Implement delete logic
  - Delete request from database
  - Remove from UI
  - Select next available request
  - Show empty state if no requests left
  - Show error toast if delete fails
  - _Requirements: 3.19, 3.20, 3.21_

- [ ] 13.3 Support bulk delete
  - Show count in confirmation dialog
  - Delete all selected requests
  - Update UI after all deletions
  - _Requirements: 3.22_


### 14. Implement Move Functionality

- [ ] 14.1 Create move dialog
  - Show list of available workspaces
  - Highlight current workspace
  - Add "Cancel" and "Move" buttons
  - _Requirements: 3.23_

- [ ] 14.2 Implement move logic
  - Update workspaceId in database
  - Remove from current workspace UI
  - Show success toast
  - Show error toast if move fails
  - _Requirements: 3.24, 3.25, 3.26_

### 15. Implement Drag and Drop

- [ ] 15.1 Add drag gesture to RequestTreeItem
  - Detect PanGesture start
  - Show drag preview
  - Track drag position
  - _Requirements: 3.27_

- [ ] 15.2 Implement drop target highlighting
  - Highlight folder when dragged over
  - Show drop indicator between items
  - Calculate drop position (before/after/inside)
  - _Requirements: 3.28_

- [ ] 15.3 Implement drop logic
  - Move request to folder if dropped on folder
  - Reorder request if dropped between items
  - Update sortPriority values
  - Batch update all affected items
  - _Requirements: 3.29, 3.30, 3.31, 3.32_

### 16. Add Keyboard Shortcuts

- [ ] 16.1 Implement F2 for rename
  - Detect F2 key press when request focused
  - Start rename operation
  - _Requirements: 3.33_

- [ ] 16.2 Implement Delete key for delete
  - Detect Delete key press when request focused
  - Show delete confirmation
  - _Requirements: 3.34_

- [ ] 16.3 Implement Ctrl+D for duplicate
  - Detect Ctrl+D key press when request focused
  - Duplicate request
  - _Requirements: 3.35_

- [ ] 16.4 Implement Enter for send
  - Detect Enter key press when request focused
  - Send HTTP request
  - _Requirements: 3.36_


### 17. Implement Request Status Indicators

- [ ] 17.1 Add loading indicator to RequestTreeItem
  - Show spinner when request is executing
  - Position next to request name
  - _Requirements: 7.1, 7.6_

- [ ] 17.2 Add status code badge
  - Show HTTP status code after request completes
  - Color code by status range (2xx=green, 4xx=orange, 5xx=red)
  - _Requirements: 7.2, 7.3_

- [ ] 17.3 Add HTTP method tag
  - Show method badge (GET, POST, etc.)
  - Color code by method (GET=blue, POST=green, DELETE=red)
  - _Requirements: 7.4_

- [ ] 17.4 Add unsaved changes indicator (optional)
  - Show dot next to request name when modified
  - Hide dot after save
  - _Requirements: 7.5_

---

## Phase 4: Polish and Testing (Week 4)

### 18. Implement Sidebar Tree Navigation

- [ ] 18.1 Add keyboard navigation
  - Implement Up/Down arrow navigation
  - Implement Right arrow to expand folder
  - Implement Left arrow to collapse folder
  - Implement Enter to activate request
  - Implement Space to send request
  - _Requirements: 6.2, 6.3, 6.4, 6.5, 6.6_

- [ ] 18.2 Implement filter functionality
  - Add filter input at top of sidebar
  - Filter requests by name/URL in real-time
  - Show folders if any child matches
  - Hide non-matching items
  - Clear filter on Escape
  - _Requirements: 6.7, 6.8, 6.9, 6.10_

- [ ] 18.3 Add focus management
  - Highlight active request
  - Show focus indicator
  - Support tab navigation
  - _Requirements: 6.1, 6.11_

### 19. Add Response History Support

- [ ] 19.1 Create response history dropdown
  - Show list of recent responses
  - Display timestamp for each
  - Limit to 10 most recent
  - _Requirements: 5.1, 5.2, 5.6_

- [ ] 19.2 Implement response selection
  - Allow selecting historical response
  - Display selected response
  - Show indicator that it's not latest
  - Auto-switch to new response when sent
  - _Requirements: 5.3, 5.4, 5.5_


### 20. Performance Optimization

- [ ] 20.1 Optimize sidebar resize performance
  - Disable transitions during drag
  - Use @Local for immediate updates
  - Throttle preference saves
  - _Requirements: Performance - 60fps_

- [ ] 20.2 Optimize response viewer performance
  - Implement large response confirmation
  - Lazy load syntax highlighting
  - Cache formatted content
  - _Requirements: Performance - <500ms formatting_

- [ ] 20.3 Optimize tree rendering
  - Use LazyForEach for tree items
  - Implement viewport culling
  - Cache tree node calculations
  - _Requirements: Performance - <100ms rendering_

- [ ] 20.4 Optimize database operations
  - Batch update operations
  - Use transactions for multiple updates
  - Add indexes on commonly queried fields
  - _Requirements: Performance - <200ms operations_

### 21. Accessibility Implementation

- [ ] 21.1 Add keyboard accessibility
  - Ensure all elements are focusable
  - Add focus indicators
  - Support tab navigation
  - _Requirements: Accessibility - Keyboard Navigation_

- [ ] 21.2 Add screen reader support
  - Add accessibility labels
  - Add accessibility descriptions
  - Announce state changes
  - _Requirements: Accessibility - Screen Reader_

- [ ] 21.3 Ensure visual accessibility
  - Maintain 4.5:1 contrast ratio
  - Use multiple indicators (not just color)
  - Ensure 44x44dp touch targets
  - _Requirements: Accessibility - Visual Feedback, Touch Targets_

### 22. Testing and Bug Fixes

- [ ] 22.1 Write unit tests
  - Test ResizeHandle gesture detection
  - Test ContentTypeDetector logic
  - Test request management operations
  - _Requirements: Testing Strategy_

- [ ] 22.2 Perform integration testing
  - Test sidebar resize flow end-to-end
  - Test response viewer with various content types
  - Test request context menu flow
  - _Requirements: Testing Strategy_

- [ ] 22.3 Fix identified bugs
  - Address any crashes or errors
  - Fix UI glitches
  - Resolve performance issues
  - _Requirements: Quality Metrics_

- [ ] 22.4 User acceptance testing
  - Deploy to test users
  - Collect feedback
  - Make refinements
  - _Requirements: Deployment Strategy_


### 23. Documentation and Deployment

- [ ] 23.1 Create user documentation
  - Document sidebar resize feature
  - Document response viewer modes
  - Document context menu actions
  - Document keyboard shortcuts
  - _Requirements: Deployment Strategy_

- [ ] 23.2 Add inline help
  - Add tooltips for UI elements
  - Add empty state messages
  - Add error recovery instructions
  - _Requirements: Usability_

- [ ] 23.3 Prepare for deployment
  - Create feature flags
  - Set up monitoring
  - Prepare rollback plan
  - _Requirements: Deployment Strategy_

- [ ] 23.4 Deploy to production
  - Alpha release (internal)
  - Beta release (10% users)
  - General availability (all users)
  - Monitor metrics and errors
  - _Requirements: Deployment Strategy_

---

## Summary

**Total Tasks**: 23 major tasks with 80+ sub-tasks

**Estimated Timeline**:
- Week 1: Tasks 1-4 (Core Infrastructure)
- Week 2: Tasks 5-9 (Response Viewer)
- Week 3: Tasks 10-17 (Request Management)
- Week 4: Tasks 18-23 (Polish, Testing, Deployment)

**Key Milestones**:
- End of Week 1: Resizable sidebar working
- End of Week 2: Response viewer with all content types
- End of Week 3: Full request management features
- End of Week 4: Production-ready release

**Dependencies**:
- Tasks 5-9 depend on Task 3 (ContentTypeDetector)
- Tasks 10-17 depend on Task 10 (ContextMenu)
- Task 23 depends on all previous tasks

**Optional Tasks** (marked with "optional"):
- Task 8.1: PdfViewer
- Task 8.2: CSV table viewer
- Task 8.3: Event stream viewer
- Task 17.4: Unsaved changes indicator

These optional tasks can be implemented in future iterations if time permits.
