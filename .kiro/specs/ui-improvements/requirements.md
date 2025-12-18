# Requirements Document - UI Improvements

## Introduction

This document outlines the requirements for three major UI improvements to the Yaak HarmonyOS application, based on comprehensive analysis of the Tauri desktop application's implementation:

1. **Resizable Sidebar with Auto-Hide** - Smooth drag-to-resize with automatic hiding when dragged below minimum width
2. **Enhanced Response Viewer with Content Formatting** - Intelligent content type detection and formatting with multiple viewer modes
3. **Request Management Features** - Complete request lifecycle management including rename, duplicate, delete, and unsaved changes tracking

These improvements follow the Tauri application's proven UX patterns and technical architecture.

## Glossary

- **Sidebar**: The left panel containing workspace, folder, and request navigation tree
- **Response Pane**: The right panel displaying HTTP response data with tabs (Body, Headers, Info)
- **Request Item**: A single HTTP request entry in the sidebar tree
- **Content Formatting**: Automatic syntax highlighting and pretty-printing based on Content-Type header
- **Pretty Mode**: Formatted view with syntax highlighting and structure
- **Raw Mode**: Unformatted plain text view of response body
- **Resize Handle**: The draggable divider between sidebar and main content area
- **Context Menu**: Right-click or long-press menu showing available actions
- **Unsaved Indicator**: Visual marker (dot) showing request has uncommitted changes

## Requirements

### Requirement 1: Resizable Sidebar with Auto-Hide

**User Story:** As a user, I want to resize the sidebar by dragging a handle, so that I can adjust the workspace layout to my preference and maximize screen space for request/response viewing.

#### Acceptance Criteria

1. WHEN a user drags the resize handle to the right THEN the system SHALL increase the sidebar width in real-time with smooth visual feedback
2. WHEN a user drags the resize handle to the left THEN the system SHALL decrease the sidebar width in real-time
3. WHEN a user drags the sidebar width below 50px THEN the system SHALL automatically hide the sidebar and reset width to default (250px)
4. WHEN the sidebar is hidden THEN the system SHALL collapse to 0px width and show only the main content area
5. WHEN a user clicks the sidebar toggle button THEN the system SHALL show/hide the sidebar with smooth transition animation
6. WHEN the sidebar width changes THEN the system SHALL persist the width value to local storage keyed by workspace ID
7. WHEN a user double-clicks the resize handle THEN the system SHALL reset the sidebar width to default (250px)
8. WHEN resizing occurs THEN the system SHALL disable CSS transitions to ensure smooth 60fps dragging performance
9. WHEN resizing ends THEN the system SHALL re-enable CSS transitions for smooth width changes
10. WHEN the sidebar is shown THEN the system SHALL restore the previously saved width for the current workspace

### Requirement 2: Enhanced Response Viewer with Content Formatting

**User Story:** As a user, I want to view response content with intelligent formatting based on content type, so that I can easily read, understand, and analyze API responses.

#### Acceptance Criteria

1. WHEN a response has Content-Type "application/json" or content starts with `{` or `[` THEN the system SHALL display formatted JSON with syntax highlighting in Pretty mode
2. WHEN a response has Content-Type "text/html" or content starts with `<!doctype` or `<html` THEN the system SHALL provide both rendered HTML preview (Pretty) and syntax-highlighted HTML source (Raw)
3. WHEN a response has Content-Type "text/xml" or "application/xml" or content starts with `<` THEN the system SHALL display formatted XML with syntax highlighting
4. WHEN a response has Content-Type "text/plain" THEN the system SHALL display plain text with monospace font
5. WHEN a response has Content-Type starting with "image/" (image/png, image/jpeg, image/svg+xml, etc.) THEN the system SHALL display the image preview
6. WHEN a response has Content-Type starting with "video/" THEN the system SHALL display a video player
7. WHEN a response has Content-Type starting with "audio/" THEN the system SHALL display an audio player
8. WHEN a response has Content-Type "application/pdf" THEN the system SHALL display a PDF viewer
9. WHEN a response has Content-Type "text/csv" or "text/tab-separated-values" THEN the system SHALL display a table view
10. WHEN a response has Content-Type "text/event-stream" THEN the system SHALL display streaming events in real-time
11. WHEN viewing text-based content THEN the system SHALL provide a mode selector with "Pretty" and "Raw" options
12. WHEN "Pretty" mode is selected THEN the system SHALL apply syntax highlighting and formatting
13. WHEN "Raw" mode is selected THEN the system SHALL display unformatted plain text
14. WHEN response body exceeds 1MB THEN the system SHALL show a confirmation dialog with "Show Response" and "Cancel" buttons before rendering
15. WHEN response state is "initialized" or "connected" THEN the system SHALL show a loading indicator with elapsed time
16. WHEN response content length is 0 THEN the system SHALL display "Empty" message
17. WHEN response has an error THEN the system SHALL display the error message in a danger banner
18. WHEN content type detection fails THEN the system SHALL attempt to detect format from first 20 bytes of content
19. WHEN viewing formatted content THEN the system SHALL persist the selected mode (Pretty/Raw) per request ID

### Requirement 3: Request Management Features

**User Story:** As a user, I want comprehensive request management capabilities including rename, duplicate, delete, and move operations, so that I can efficiently organize and maintain my API workspace.

#### Acceptance Criteria - Context Menu

1. WHEN a user long-presses a request item in the sidebar THEN the system SHALL display a context menu with available actions
2. WHEN a user long-presses a folder item THEN the system SHALL display a context menu with folder-specific actions
3. WHEN multiple items are selected THEN the system SHALL display a context menu with bulk actions
4. WHEN the context menu is displayed for a single HTTP request THEN the system SHALL show: Send, Rename, Duplicate, Move, Delete options
5. WHEN the context menu is displayed for a folder THEN the system SHALL show: Folder Settings, Send All, Rename, Duplicate, Delete, and Create New options
6. WHEN "Send" is selected THEN the system SHALL execute the HTTP request immediately
7. WHEN "Send All" is selected on a folder THEN the system SHALL execute all requests in the folder sequentially

#### Acceptance Criteria - Rename Operation

8. WHEN a user selects "Rename" from context menu THEN the system SHALL show an inline text input with current name pre-filled
9. WHEN a user types a new name and presses Enter THEN the system SHALL update the request name in database and UI
10. WHEN a user presses Escape during rename THEN the system SHALL cancel the rename operation
11. WHEN rename is in progress THEN the system SHALL focus the text input and select all text
12. WHEN rename completes THEN the system SHALL update the sidebar item immediately without page refresh

#### Acceptance Criteria - Duplicate Operation

13. WHEN a user selects "Duplicate" from context menu THEN the system SHALL create a copy of the request with " (Copy)" suffix
14. WHEN a request is duplicated THEN the system SHALL copy all properties: URL, method, headers, body, authentication, parameters
15. WHEN a request is duplicated THEN the system SHALL generate a new unique ID for the copy
16. WHEN a request is duplicated THEN the system SHALL place the copy immediately after the original in sort order
17. WHEN duplication completes THEN the system SHALL navigate to the newly created request

#### Acceptance Criteria - Delete Operation

18. WHEN a user selects "Delete" from context menu THEN the system SHALL show a confirmation dialog with request name
19. WHEN user confirms deletion THEN the system SHALL remove the request from database and UI
20. WHEN a request is deleted THEN the system SHALL select the next available request in the list
21. WHEN the last request is deleted THEN the system SHALL show an empty state
22. WHEN multiple requests are selected for deletion THEN the system SHALL show count in confirmation dialog

#### Acceptance Criteria - Move Operation

23. WHEN a user selects "Move" from context menu THEN the system SHALL show a dialog with available workspaces
24. WHEN a workspace is selected THEN the system SHALL move the request to the target workspace
25. WHEN a request is moved THEN the system SHALL update the workspaceId in database
26. WHEN a request is moved THEN the system SHALL remove it from current workspace sidebar

#### Acceptance Criteria - Drag and Drop

27. WHEN a user drags a request item THEN the system SHALL show a drag preview
28. WHEN a request is dragged over a folder THEN the system SHALL highlight the folder as drop target
29. WHEN a request is dropped on a folder THEN the system SHALL move the request into that folder
30. WHEN a request is dropped between items THEN the system SHALL reorder the request to that position
31. WHEN drag and drop completes THEN the system SHALL update sortPriority values in database
32. WHEN multiple items need reordering THEN the system SHALL batch update all affected items

#### Acceptance Criteria - Keyboard Shortcuts

33. WHEN a request is focused and user presses F2 THEN the system SHALL start rename operation
34. WHEN a request is focused and user presses Delete THEN the system SHALL show delete confirmation
35. WHEN a request is focused and user presses Ctrl+D THEN the system SHALL duplicate the request
36. WHEN a request is focused and user presses Enter THEN the system SHALL send the request

### Requirement 4: Response Viewer Tabs and Navigation

**User Story:** As a user, I want to view different aspects of the HTTP response in organized tabs, so that I can quickly access headers, body, and metadata.

#### Acceptance Criteria

1. WHEN a response is loaded THEN the system SHALL display three tabs: Body, Headers, Info
2. WHEN the Body tab is active THEN the system SHALL display the response content with appropriate viewer
3. WHEN the Headers tab is active THEN the system SHALL display all response headers in a table format
4. WHEN the Info tab is active THEN the system SHALL display response metadata (URL, status, timing, size, version, remote address)
5. WHEN switching tabs THEN the system SHALL persist the active tab per request ID
6. WHEN the Body tab is displayed THEN the system SHALL show a mode selector (Pretty/Raw) in the tab label
7. WHEN the Headers tab is displayed THEN the system SHALL show a count badge with number of headers
8. WHEN no response exists THEN the system SHALL display hotkey hints for common actions
9. WHEN response is loading THEN the system SHALL show loading indicator with elapsed time
10. WHEN response has error THEN the system SHALL display error banner above tabs

### Requirement 5: Response History and Pinning

**User Story:** As a user, I want to view previous responses for a request, so that I can compare results across multiple executions.

#### Acceptance Criteria

1. WHEN a request has multiple responses THEN the system SHALL show a dropdown to select response history
2. WHEN the response dropdown is clicked THEN the system SHALL display a list of recent responses with timestamps
3. WHEN a historical response is selected THEN the system SHALL display that response while keeping the request editable
4. WHEN viewing a historical response THEN the system SHALL show a visual indicator that it's not the latest
5. WHEN a new request is sent THEN the system SHALL automatically switch to the new response
6. WHEN response history exceeds 10 items THEN the system SHALL show only the 10 most recent
7. WHEN a response is pinned THEN the system SHALL keep it visible even when new responses arrive

### Requirement 6: Sidebar Tree Navigation

**User Story:** As a user, I want to navigate the request tree with keyboard and mouse, so that I can quickly access any request or folder.

#### Acceptance Criteria

1. WHEN the sidebar is focused THEN the system SHALL highlight the active request
2. WHEN user presses Up/Down arrow keys THEN the system SHALL navigate to previous/next item
3. WHEN user presses Right arrow on folder THEN the system SHALL expand the folder
4. WHEN user presses Left arrow on folder THEN the system SHALL collapse the folder
5. WHEN user presses Enter on request THEN the system SHALL activate that request
6. WHEN user presses Space on request THEN the system SHALL send the request
7. WHEN user types in sidebar THEN the system SHALL focus the filter input
8. WHEN filter text is entered THEN the system SHALL hide non-matching items in real-time
9. WHEN filter matches folder contents THEN the system SHALL show the folder even if name doesn't match
10. WHEN filter is cleared THEN the system SHALL restore all items to visible state
11. WHEN sidebar has focus and user presses Escape THEN the system SHALL hide the sidebar

### Requirement 7: Request Status Indicators

**User Story:** As a user, I want to see the status of requests at a glance, so that I can quickly identify which requests succeeded or failed.

#### Acceptance Criteria

1. WHEN a request is executing THEN the system SHALL show a loading spinner next to the request name
2. WHEN a request completes successfully THEN the system SHALL show the HTTP status code badge (e.g., 200, 201)
3. WHEN a request fails THEN the system SHALL show the error status code badge (e.g., 404, 500)
4. WHEN viewing the sidebar THEN the system SHALL display HTTP method tags with color coding (GET=blue, POST=green, DELETE=red, etc.)
5. WHEN a request has unsaved changes THEN the system SHALL show a dot indicator next to the request name
6. WHEN multiple requests are executing THEN the system SHALL show loading indicators for all active requests

## Non-Functional Requirements

### Performance
- Sidebar resize operations SHALL complete within 16ms (60fps) for smooth dragging
- Response formatting SHALL complete within 500ms for responses up to 1MB
- Syntax highlighting SHALL use web workers to avoid blocking the UI thread
- Request save operations SHALL complete within 200ms
- Tree rendering SHALL support virtualization for workspaces with 1000+ requests
- Filter operations SHALL complete within 100ms for instant feedback

### Usability
- All interactive elements SHALL provide visual feedback within 100ms
- Error messages SHALL be clear, actionable, and include recovery suggestions
- The UI SHALL follow HarmonyOS design guidelines and component patterns
- Touch targets SHALL be minimum 44x44 dp for accessibility
- Keyboard shortcuts SHALL be discoverable through tooltips and help menu
- Context menus SHALL adapt based on selection context (single vs multiple items)

### Compatibility
- The system SHALL work on HarmonyOS API 11+
- The system SHALL support both phone and tablet form factors
- The system SHALL adapt layout for different screen sizes (responsive design)
- The system SHALL support both light and dark themes
- The system SHALL persist user preferences across app restarts

### Data Integrity
- All database operations SHALL use transactions to ensure consistency
- Request changes SHALL be persisted immediately to prevent data loss
- The system SHALL handle concurrent modifications gracefully
- The system SHALL validate all user input before persisting to database

### Accessibility
- All interactive elements SHALL be keyboard accessible
- The system SHALL provide appropriate ARIA labels for screen readers
- Color coding SHALL not be the only means of conveying information
- Text SHALL maintain minimum 4.5:1 contrast ratio for readability
