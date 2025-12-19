# Implementation Plan

## Overview

This implementation plan breaks down the Yaak HarmonyOS application development into incremental, actionable tasks. Each task builds on previous work and focuses on coding activities that can be executed by a development agent.

**Key Principles:**
- Implement core functionality first, then add enhancements
- Test as we build to catch issues early
- Follow HarmonyOS best practices throughout
- Use State Management V2 (@ObservedV2, @Trace, @ComponentV2)
- Apply resource qualifiers for theming

---

## Phase 1: Foundation and Data Layer

- [x] 1. Set up project structure and core data models



  - Create directory structure: model/, database/, services/, components/, pages/, theme/, common/
  - Implement base data models with @ObservedV2 and @Trace decorators
  - Create Workspace, HttpRequest, Folder, Environment, HttpResponse, CookieJar models
  - Add type definitions for HttpMethod, BodyType, AuthType, ResponseState
  - _Requirements: 11.1, 11.2_

- [x] 2. Implement database layer with RDB Store



  - Create DatabaseManager singleton with connection management
  - Implement database initialization with table creation SQL
  - Add database version management and migration strategy
  - Create indexes for workspace_id, folder_id, request_id, sort_priority
  - _Requirements: 9.1, 9.2, 9.3_

- [ ]* 2.1 Write property test for database persistence
  - **Property 10: Database Persistence Round-Trip**
  - **Validates: Requirements 9.1, 9.2**
  - Test that any data model saved to database can be loaded with identical values
  - Use fast-check to generate random model instances
  - Configure 100 iterations minimum

- [ ] 3. Implement repository pattern for data access
  - Create BaseRepository with common CRUD operations
  - Implement WorkspaceRepository with getAllWorkspaces, createWorkspace, updateWorkspace, deleteWorkspace
  - Implement RequestRepository with getRequestsByWorkspaceId, createRequest, updateRequest, deleteRequest
  - Implement FolderRepository with getFoldersByWorkspaceId, createFolder, updateFolder, deleteFolder
  - Implement EnvironmentRepository with getEnvironmentsByWorkspaceId, createEnvironment, updateEnvironment
  - Implement ResponseRepository with getResponsesByRequestId, createResponse, deleteResponse
  - Implement CookieRepository with getAllCookies, upsertCookie, deleteCookie
  - Add transaction support using executeInTransaction helper
  - _Requirements: 1.1, 2.1, 3.1, 5.1, 9.1_

- [ ]* 3.1 Write property test for request ID generation
  - **Property 2: Request ID Uniqueness and Format**
  - **Validates: Requirements 2.1**
  - Test that all generated request IDs are unique and start with "rq" prefix
  - Generate multiple requests and verify ID uniqueness

- [ ]* 3.2 Write property test for cascade deletion
  - **Property 3: Request Deletion Cascade**
  - **Validates: Requirements 2.7**
  - Test that deleting a request removes all associated responses
  - Create request with responses, delete request, verify responses are gone


## Phase 2: Theme System and Resources

- [x] 4. Set up resource qualifiers for theme adaptation



  - Create base/element/color.json with light mode colors
  - Create dark/element/color.json with dark mode colors
  - Create base/element/float.json with spacing, font sizes, border radius, animation durations
  - Create base/element/string.json with text resources
  - Define all color tokens: background, surface, text_primary, text_secondary, primary, border, etc.
  - Define all spacing tokens: spacing_xs through spacing_2xl
  - Define all typography tokens: font_size_xs through font_size_2xl
  - _Requirements: 15.1, 15.2, 15.3_

- [x] 5. Implement ThemeManager with State Management V2



  - Create ThemeManager class with @ObservedV2 decorator
  - Add @Trace properties: isDark, followSystem
  - Implement singleton pattern with getInstance()
  - Add setSystemColorMode() method for system theme changes
  - Add toggleTheme() method for manual theme switching
  - Add setFollowSystem() method to enable/disable auto-theme
  - _Requirements: 15.3, 15.4, 15.5_

- [x] 6. Configure theme monitoring in EntryAbility


  - Update EntryAbility.onCreate() to initialize ThemeManager with system color mode
  - Implement EntryAbility.onConfigurationUpdate() to update ThemeManager on system theme change
  - Test theme switching by changing system settings
  - _Requirements: 15.3_

- [ ]* 6.1 Write property test for theme auto-update
  - **Property 15: Theme Auto-Update**
  - **Validates: Requirements 15.3**
  - Test that system theme changes trigger app theme updates when auto-theme is enabled
  - Simulate system theme changes and verify ThemeManager state


## Phase 3: Core Services

- [x] 7. Implement TemplateEngine service


  - Create TemplateEngine class with resolve() method
  - Implement regex-based template variable substitution for {{ variableName }}
  - Implement function call parsing for {{ functionName(args) }}
  - Add built-in functions: timestamp(), uuid(), random(min, max), base64(str), md5(str)
  - Support nested template resolution
  - Handle undefined variables by leaving placeholders unchanged
  - _Requirements: 5.3, 21.1, 21.2, 21.5, 21.6_

- [ ]* 7.1 Write property test for template substitution
  - **Property 7: Template Variable Substitution**
  - **Validates: Requirements 5.3, 21.1**
  - Test that any variable reference is correctly substituted
  - Generate random variable names and values

- [ ]* 7.2 Write property test for undefined variables
  - **Property 8: Undefined Variable Preservation**
  - **Validates: Requirements 5.5**
  - Test that undefined variables remain as placeholders
  - Generate random template strings with undefined variables

- [ ]* 7.3 Write property test for nested templates
  - **Property 16: Nested Template Resolution**
  - **Validates: Requirements 21.5**
  - Test that nested templates resolve correctly from innermost to outermost
  - Generate random nested template structures

- [x] 8. Implement EnvironmentService


  - Create EnvironmentService class with mergeVariables() method
  - Implement variable merging from multiple environments
  - Add resolveVariable() method for single variable lookup
  - Handle enabled/disabled variables
  - _Requirements: 5.1, 5.2, 5.4_

- [x] 9. Implement AuthService


  - Create AuthService class with getAuthHeaders() method
  - Implement Basic Auth header generation with base64 encoding
  - Implement Bearer Token header generation
  - Implement API Key header generation (header and query parameter locations)
  - Support template variable resolution in auth credentials
  - _Requirements: 6.1, 6.2, 6.3, 6.4_

- [ ]* 9.1 Write property test for Basic Auth encoding
  - **Property 9: Basic Auth Header Generation**
  - **Validates: Requirements 6.2**
  - Test that any username/password generates valid Authorization header
  - Verify base64 encoding correctness

- [x] 10. Implement CookieService



  - Create CookieService class with storeCookies() and getCookiesForRequest() methods
  - Implement cookie parsing from Set-Cookie headers
  - Implement domain matching logic (exact match and wildcard)
  - Implement path matching logic
  - Handle cookie expiration
  - Handle secure flag for HTTPS-only cookies
  - _Requirements: 13.1, 13.2, 13.3, 13.5_

- [ ]* 10.1 Write property test for cookie storage
  - **Property 13: Cookie Storage from Response**
  - **Validates: Requirements 13.1**
  - Test that any Set-Cookie header is correctly parsed and stored
  - Generate random cookie strings

- [ ]* 10.2 Write property test for cookie matching
  - **Property 14: Cookie Inclusion in Requests**
  - **Validates: Requirements 13.2**
  - Test that cookies matching domain/path are included in requests
  - Generate random URLs and cookie jars


## Phase 4: Request Execution

- [x] 11. Implement ResponseStorageService


  - Create ResponseStorageService class with saveResponseBody(), loadResponseBody(), deleteResponseBody()
  - Implement file system operations for response body storage in app_data_dir/responses/
  - Use response ID as filename
  - Handle both string and ArrayBuffer body types
  - Implement cleanupOldResponses() for automatic cleanup
  - _Requirements: 22.1, 22.2, 22.4, 22.6_

- [ ]* 11.1 Write property test for response storage round-trip
  - **Property 17: Response Body Storage Round-Trip**
  - **Validates: Requirements 22.1, 22.4**
  - Test that any response body saved to file can be loaded with identical content
  - Generate random response bodies

- [x] 12. Implement RequestExecutor service


  - Create RequestExecutor class with execute() method
  - Implement URL template resolution using TemplateEngine
  - Implement header template resolution
  - Implement body template resolution based on body_type
  - Apply authentication using AuthService
  - Include cookies using CookieService
  - Build HTTP request using @ohos.net.http module
  - Execute HTTP request and capture response
  - Store response body using ResponseStorageService
  - Create HttpResponse record in database
  - Handle request cancellation
  - _Requirements: 4.1, 4.2, 4.3, 4.7, 4.8_

- [ ]* 12.1 Write property test for request execution
  - **Property 5: HTTP Request Execution**
  - **Validates: Requirements 4.1**
  - Test that any valid HTTP request configuration produces a response
  - Mock HTTP calls for testing

- [ ]* 12.2 Write property test for request cancellation
  - **Property 6: Request Cancellation**
  - **Validates: Requirements 4.8**
  - Test that cancelling an in-flight request aborts the operation
  - Verify response state is set to "cancelled"

- [x] 13. Implement body type handlers



  - Implement JSON body handler (pass-through with template resolution)
  - Implement XML body handler (pass-through with template resolution)
  - Implement form-urlencoded body handler with URL encoding
  - Implement form-data (multipart) body handler with boundary generation
  - Implement binary file body handler with file reading
  - Implement GraphQL body handler (JSON format)
  - _Requirements: 2.6, 27.1, 27.4, 28.1, 28.4, 29.1, 29.3_

- [ ]* 13.1 Write property test for URL encoding
  - **Property 23: URL Encoding Correctness**
  - **Validates: Requirements 28.4**
  - Test that any string with special characters encodes/decodes correctly
  - Generate random strings with special characters

- [ ]* 13.2 Write property test for multipart boundary
  - **Property 22: Multi-Part Boundary Generation**
  - **Validates: Requirements 27.4**
  - Test that boundary string is unique and doesn't appear in form data
  - Generate random form data


## Phase 5: UI Components - Sidebar

- [x] 14. Create reusable styled components


  - Create ThemedButton component with @ComponentV2, @Param, resource references
  - Create ThemedTextInput component with @ComponentV2, @Param, resource references
  - Create ThemedSelect component with @ComponentV2, @Param, resource references
  - Create ThemedDivider component with resource references
  - Apply design tokens (spacing, colors, border radius) from resources
  - _Requirements: 10.1, 15.1, 15.2_

- [x] 15. Implement SidebarItem view model


  - Create SidebarItem class to represent tree nodes
  - Add type field ('folder' or 'request')
  - Add data field (Folder or HttpRequest)
  - Add level field for indentation
  - _Requirements: 8.1_

- [x] 16. Implement FolderItemComponent


  - Create FolderItemComponent with @ComponentV2
  - Add @Param for folder, level, isExpanded, onToggle
  - Display folder icon and name
  - Show expand/collapse indicator
  - Apply indentation based on level
  - Use resource colors and spacing
  - _Requirements: 8.1, 8.3_

- [x] 17. Implement RequestItemComponent


  - Create RequestItemComponent with @ComponentV2
  - Add @Param for request, level, isSelected, onSelect
  - Display HTTP method badge with color coding
  - Display request name
  - Apply indentation based on level
  - Highlight selected request
  - Use resource colors and spacing
  - _Requirements: 8.1, 8.2_

- [x] 18. Implement SidebarComponent



  - Create SidebarComponent with @ComponentV2
  - Add @Param for items, selectedRequest, onRequestCreate, onFolderCreate, onRequestSelect
  - Add @Local for filterText, expandedFolders
  - Implement search/filter TextInput with debouncing
  - Implement action buttons (New Request, New Folder)
  - Implement tree view using List and ForEach
  - Implement folder expand/collapse logic
  - Implement request filtering by name and URL
  - Apply sidebar background color from resources
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 38.1, 38.2_

- [ ]* 18.1 Write unit tests for sidebar filtering
  - Test that filter correctly matches request names
  - Test that filter correctly matches URLs
  - Test that clearing filter restores full tree


## Phase 6: UI Components - Request Editor

- [x] 19. Implement QueryParamsEditor component


  - Create QueryParamsEditor with @ComponentV2
  - Add @Param for params array
  - Display list of query parameters with name, value, enabled checkbox
  - Implement add parameter button
  - Implement delete parameter button
  - Support enable/disable toggle for each parameter
  - Use ThemedTextInput for name and value fields
  - _Requirements: 2.4_

- [x] 20. Implement HeadersEditor component


  - Create HeadersEditor with @ComponentV2
  - Add @Param for headers array
  - Display list of headers with name, value, enabled checkbox
  - Implement add header button
  - Implement delete header button
  - Support enable/disable toggle for each header
  - Use ThemedTextInput for name and value fields
  - _Requirements: 2.5_

- [x] 21. Implement BodyEditor component


  - Create BodyEditor with @ComponentV2
  - Add @Param for body, bodyType, onBodyChange, onBodyTypeChange
  - Implement body type selector (None, JSON, XML, Form-Data, Form-Urlencoded, Binary, GraphQL, Text)
  - Implement JSON editor with syntax highlighting
  - Implement XML editor with syntax highlighting
  - Implement Form-Data editor with file picker support
  - Implement Form-Urlencoded editor with key-value pairs
  - Implement Binary file picker
  - Implement GraphQL editor with query and variables sections
  - Implement plain text editor
  - _Requirements: 2.6, 16.1, 27.1, 28.1, 29.1, 30.5_

- [x] 22. Implement AuthEditor component


  - Create AuthEditor with @ComponentV2
  - Add @Param for auth configuration
  - Implement auth type selector (None, Basic, Bearer, API Key, OAuth2)
  - Implement Basic Auth fields (username, password)
  - Implement Bearer Token field
  - Implement API Key fields (name, value, location)
  - Implement OAuth2 fields (access token, refresh token, expires at)
  - Use ThemedTextInput for all fields
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 23. Implement RequestEditorComponent



  - Create RequestEditorComponent with @ComponentV2
  - Add @Param for request, onExecute, isLoading
  - Add @Local for activeTab
  - Implement request line with method selector, URL input, Send button
  - Implement tabs for Params, Headers, Body, Auth
  - Integrate QueryParamsEditor, HeadersEditor, BodyEditor, AuthEditor
  - Show loading indicator when isLoading is true
  - Show Cancel button when request is executing
  - Apply background color from resources
  - _Requirements: 2.2, 2.3, 4.1, 4.2, 20.1_

- [ ]* 23.1 Write unit tests for request editor
  - Test that method selector updates request.method
  - Test that URL input updates request.url
  - Test that tab switching works correctly


## Phase 7: UI Components - Response Viewer

- [x] 24. Implement ResponseViewerComponent



  - Create ResponseViewerComponent with @ComponentV2
  - Add @Param for response, status, time, bodySize
  - Add @Local for activeTab, viewMode
  - Implement status bar showing status code, time, size
  - Color-code status (green for 2xx, red for 4xx/5xx)
  - Implement view mode toggle (Pretty, Raw)
  - Implement Pretty mode with JSON formatting and syntax highlighting
  - Implement Raw mode showing unformatted response
  - Implement tabs for Body, Headers, Info
  - Use monospace font for response body
  - Apply background and text colors from resources
  - _Requirements: 4.3, 4.4, 4.5, 7.1, 7.2, 26.1_

- [x] 25. Implement ResponseHeadersTab component



  - Create ResponseHeadersTab with @ComponentV2
  - Add @Param for headers array
  - Display headers as name-value pairs in a list
  - Show Set-Cookie headers separately if present
  - Use resource colors for text
  - _Requirements: 7.4, 26.1, 26.3_

- [x] 26. Implement ResponseInfoTab component



  - Create ResponseInfoTab with @ComponentV2
  - Add @Param for response metadata
  - Display HTTP version, remote address, final URL
  - Display timing information (elapsed time for headers, total)
  - Show redirect information if applicable
  - Use resource colors and spacing
  - _Requirements: 26.2, 26.4, 26.5_

- [ ]* 26.1 Write unit tests for response formatting
  - Test that JSON responses are correctly formatted in Pretty mode
  - Test that invalid JSON falls back to Raw mode
  - Test that status color coding works correctly


## Phase 8: UI Components - Header and Dialogs

- [x] 27. Implement WorkspaceHeader component

  - Create WorkspaceHeader with @ComponentV2
  - Add @Param for workspaces, activeWorkspace, environments, activeEnvironment
  - Add @Param for onWorkspaceSelect, onEnvironmentSelect, onOpenSettings
  - Implement workspace selector using Select component
  - Implement environment selector using Select component
  - Implement settings button with icon
  - Apply header background color from resources
  - Add bottom border using divider color
  - _Requirements: 1.3, 1.5, 5.4, 33.1_


- [x] 28. Implement SettingsDialog component

  - Create SettingsDialog with @ComponentV2
  - Add @Local for settings state
  - Implement appearance selector (Light, Dark, Auto)
  - Implement editor font size slider
  - Implement interface font size slider
  - Implement editor keymap selector (Default, Vim, VSCode, Emacs)
  - Implement soft wrap toggle
  - Save settings to database on change
  - Use CustomDialog or openCustomDialog API
  - _Requirements: 33.1, 33.2, 33.3, 33.4, 33.5, 33.6, 33.7_


- [x] 29. Implement WorkspaceDialog component

  - Create WorkspaceDialog for creating/editing workspaces
  - Add fields for name, description
  - Add workspace settings fields (follow redirects, validate certificates, timeout, proxy)
  - Implement save and cancel buttons
  - Validate workspace name is not empty

  - _Requirements: 1.4, 23.1, 23.2, 23.3, 23.4_

- [x] 30. Implement EnvironmentDialog component

  - Create EnvironmentDialog for creating/editing environments
  - Add field for environment name
  - Implement variable list editor with name, value, enabled, is_secret
  - Implement add variable button
  - Implement delete variable button
  - Support secret variables with password input


  - Implement save and cancel buttons
  - _Requirements: 5.1, 5.2_

- [x] 31. Implement EmptyState component

  - Create EmptyState component for when no request is selected
  - Display welcome message and instructions
  - Show "New Request" button
  - Show "Import" button
  - Use resource colors and spacing

  - _Requirements: 10.1_


## Phase 9: Main Page Integration

- [x] 32. Implement main page with Navigation

  - Create Index.ets as entry point with @Entry and @ComponentV2
  - Add @Local for workspaces, requests, folders, environments, sidebarItems
  - Add @Local for selectedWorkspace, selectedRequest, selectedEnvironment
  - Add @Local for responseBody, responseStatus, responseTime, responseSize
  - Add @Local for isLoading, isRequestLoading, sidebarHidden, workspaceLayout
  - Implement aboutToAppear() to initialize DatabaseManager and load data
  - Implement loadWorkspaces(), loadRequests(), loadFolders(), loadEnvironments()
  - Implement rebuildSidebar() to build tree structure
  - Implement createDefaultWorkspace() for first-time setup
  - Implement createRequest() and createFolder() methods
  - Implement executeRequest() method using RequestExecutor
  - _Requirements: 1.1, 1.2, 1.3, 4.1, 9.2_


- [ ]* 32.1 Write property test for workspace loading
  - **Property 1: Workspace Loading Completeness**
  - **Validates: Requirements 1.1**
  - Test that loading workspaces returns all records without loss
  - Generate random database states with workspaces

- [x] 33. Implement main page layout

  - Create three-pane layout: Sidebar, RequestEditor, ResponseViewer
  - Integrate WorkspaceHeader at the top
  - Integrate SidebarComponent (20% width, collapsible)
  - Integrate RequestEditorComponent (50% width)

  - Integrate ResponseViewerComponent (30% width)
  - Show EmptyState when no request is selected
  - Support horizontal and vertical layout modes
  - Add dividers between panes
  - Apply background colors from resources
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_


- [x] 34. Implement workspace switching

  - Handle workspace selection from WorkspaceHeader
  - Load associated requests, folders, environments when workspace changes
  - Clear selected request when switching workspaces

  - Update UI to reflect new workspace
  - _Requirements: 1.3, 1.5_

- [x] 35. Implement environment switching

  - Handle environment selection from WorkspaceHeader
  - Update selectedEnvironment state


  - Merge variables from selected environment for request execution
  - _Requirements: 5.4_

- [x] 36. Implement request selection

  - Handle request selection from SidebarComponent
  - Load request details into RequestEditorComponent
  - Load recent responses for the request
  - Update selectedRequest state
  - _Requirements: 8.2_

- [x] 37. Implement request execution flow


  - Handle Send button click from RequestEditorComponent
  - Show loading indicator during execution
  - Merge environment variables
  - Execute request using RequestExecutor
  - Store response body to file
  - Create response record in database
  - Update ResponseViewerComponent with results

  - Handle execution errors with user-friendly messages
  - _Requirements: 4.1, 4.2, 4.3, 4.7_

- [ ]* 37.1 Write integration test for request execution flow
  - Test complete flow from request creation to response display
  - Mock HTTP calls
  - Verify database records are created
  - Verify response files are created


## Phase 10: Advanced Features

- [x] 38. Implement folder hierarchy and inheritance
  - Add support for nested folders in rebuildSidebar()
  - Implement folder expand/collapse in SidebarComponent
  - Implement auth inheritance from parent folders
  - Implement header inheritance from parent folders
  - Resolve inheritance chain from request → folder → parent folder → workspace
  - Display inherited values with visual distinction in UI
  - _Requirements: 3.2, 3.3, 24.1, 24.2, 24.3, 24.4, 24.5_

- [ ]* 38.1 Write property test for folder assignment
  - **Property 4: Folder Assignment Consistency**
  - **Validates: Requirements 3.2**
  - Test that moving request to folder updates folder_id correctly
  - Generate random requests and folders


- [ ]* 38.2 Write property test for auth inheritance
  - **Property 18: Folder Auth Inheritance**
  - **Validates: Requirements 24.1**
  - Test that requests without auth inherit from parent folder
  - Generate random folder hierarchies with auth

- [ ]* 38.3 Write property test for explicit auth override
  - **Property 19: Explicit Auth Override**
  - **Validates: Requirements 24.3**
  - Test that explicit request auth overrides folder auth
  - Generate random auth configurations

- [x] 39. Implement request duplication


  - Add duplicate action to request context menu
  - Implement duplicateRequest() method
  - Generate new unique ID for duplicated request
  - Copy all configuration (headers, body, auth, etc.)
  - Append " Copy" to request name
  - Insert duplicated request into database
  - Select duplicated request in sidebar
  - _Requirements: 19.1, 19.2, 19.3, 25.1, 25.2, 25.5_

- [ ]* 39.1 Write property test for request duplication
  - **Property 20: Request Duplication Uniqueness**
  - **Validates: Requirements 25.1**
  - Test that duplicated request has different ID but same configuration
  - Generate random requests and duplicate them

- [x] 40. Implement folder duplication


  - Add duplicate action to folder context menu
  - Implement duplicateFolder() method with recursion
  - Generate new unique IDs for folder and all children
  - Preserve folder tree structure
  - Append " Copy" to folder name
  - Insert duplicated folder and children into database
  - _Requirements: 19.4, 25.3_

- [ ]* 40.1 Write property test for recursive folder duplication
  - **Property 21: Recursive Folder Duplication**
  - **Validates: Requirements 25.3**
  - Test that folder duplication preserves tree structure
  - Generate random folder hierarchies

- [x] 41. Implement drag and drop reordering


  - Add drag gesture support to SidebarItemComponent
  - Implement drop zones between items and into folders
  - Calculate new sort_priority based on drop position
  - Update folder_id when dropping into folder
  - Update database with new folder_id and sort_priority
  - Refresh sidebar to reflect changes
  - _Requirements: 39.1, 39.2, 39.3, 39.4, 39.5_

- [ ]* 41.1 Write property test for drag-drop update
  - **Property 24: Drag-Drop Database Update**
  - **Validates: Requirements 39.2**
  - Test that drag-drop correctly updates database
  - Generate random drag-drop scenarios

- [x] 42. Implement context menu actions



  - Add long-press gesture support to sidebar items
  - Implement context menu with Rename, Duplicate, Delete, Send actions for requests
  - Implement context menu with Rename, Duplicate, Delete, Settings actions for folders
  - Implement rename dialog with validation
  - Implement delete confirmation dialog
  - Handle delete with cascade for folders (with user preference)
  - _Requirements: 8.5, 40.1, 40.2, 40.3, 40.5_


## Phase 11: Request History and Response Management

- [x] 43. Implement response history
  - Add response history list to ResponseViewerComponent
  - Load recent responses for selected request from database
  - Display responses in reverse chronological order
  - Show timestamp, status code, and duration for each response
  - Allow selecting previous responses to view
  - Implement clear history action
  - Implement automatic cleanup of old responses (configurable age)
  - _Requirements: 12.1, 12.2, 12.3, 12.4, 12.5, 37.1, 37.2, 37.3, 37.4, 37.5_

- [ ]* 43.1 Write unit tests for response history
  - Test that responses are displayed in reverse chronological order
  - Test that selecting a response loads its body
  - Test that clear history removes all responses

- [x] 44. Implement response cancellation
  - Add Cancel button to RequestEditorComponent when request is executing
  - Implement request cancellation using http.destroy()
  - Update response state to "cancelled"
  - Record elapsed time up to cancellation
  - Save partial response if any data was received
  - _Requirements: 4.8, 36.1, 36.2, 36.3, 36.4, 36.5_

- [x] 45. Implement response body file management
  - Ensure response bodies are written to files immediately upon receipt
  - Implement lazy loading of response bodies (load from file when viewing)
  - Implement response body caching with LRU eviction
  - Implement cleanup of orphaned response files
  - Handle file system errors gracefully
  - _Requirements: 22.1, 22.2, 22.3, 22.4, 22.5, 22.6_


## Phase 12: Error Handling and Validation

- [x] 46. Implement error handling framework
  - Create AppError class with code, message, category, details
  - Create ErrorCategory enum (NETWORK, DATABASE, VALIDATION, FILE_SYSTEM, AUTHENTICATION)
  - Create ErrorHandler class with handle() method
  - Implement user-friendly error messages for each category
  - Integrate error handling into all services
  - Show error toasts using promptAction.showToast()
  - Log errors for debugging
  - _Requirements: 4.7, 9.3_

- [x] 47. Implement validation
  - Create Validator class with validation methods
  - Implement validateUrl() to check URL format
  - Implement validateRequestName() to check name length and emptiness
  - Implement validateEnvironmentName() to check name requirements
  - Implement validateWorkspaceName() to check name requirements
  - Throw AppError with VALIDATION category for validation failures
  - Display validation errors in UI near input fields
  - _Requirements: 2.8_

- [x] 48. Implement database error recovery
  - Add executeWithRetry() method to DatabaseManager
  - Implement exponential backoff for retries
  - Handle database corruption with user notification
  - Implement database backup before risky operations
  - _Requirements: 9.3_

- [x] 49. Implement network error handling
  - Add executeWithErrorHandling() wrapper to RequestExecutor
  - Detect network errors (ECONNREFUSED, ENOTFOUND, ENETUNREACH)
  - Detect timeout errors (ETIMEDOUT, ESOCKETTIMEDOUT)
  - Throw appropriate AppError for each error type
  - Display network errors with retry option
  - _Requirements: 4.7_

- [ ]* 49.1 Write unit tests for error handling
  - Test that network errors are correctly categorized
  - Test that validation errors have user-friendly messages
  - Test that database retries work with exponential backoff


## Phase 13: Security and Encryption

- [ ] 50. Implement encryption service
  - Create EncryptionService class using HarmonyOS HUKS
  - Implement getOrCreateKey() to manage encryption key in HUKS
  - Implement encryptSensitiveData() using AES-256-GCM
  - Implement decryptSensitiveData() using AES-256-GCM
  - Use HUKS for secure key storage
  - _Requirements: 32.2_

- [ ] 51. Implement sensitive data encryption
  - Encrypt environment variables marked as is_secret before saving to database
  - Encrypt authentication credentials (passwords, tokens) before saving
  - Decrypt sensitive data when loading from database
  - Update EnvironmentRepository to handle encryption
  - Update AuthConfig to handle encryption
  - _Requirements: 32.2_

- [ ] 52. Implement certificate validation
  - Create CertificateValidator class
  - Implement validateCertificate() method
  - Support disabling validation for self-signed certificates (with warning)
  - Store certificate exceptions per workspace
  - Display warning when validation is disabled
  - _Requirements: 23.2, 35.1, 35.2_

- [ ] 53. Implement input sanitization
  - Create InputSanitizer class
  - Implement sanitizeForDatabase() to validate input length
  - Implement sanitizeUrl() to prevent dangerous protocols (javascript:, data:, vbscript:)
  - Apply sanitization before all database operations
  - Apply sanitization before all HTTP requests
  - _Requirements: 2.8_

- [ ]* 53.1 Write unit tests for input sanitization
  - Test that dangerous URL protocols are rejected
  - Test that excessively long inputs are rejected
  - Test that valid inputs pass through unchanged


## Phase 14: Performance Optimization

- [ ] 54. Implement database query optimization
  - Add batch operations to repositories (batchCreateRequests, batchUpdateRequests)
  - Implement pagination for large result sets (getRequestsByWorkspaceIdPaginated)
  - Use transactions for related operations
  - Verify indexes are created for foreign keys and sort_priority
  - Profile query performance and optimize slow queries
  - _Requirements: 9.1_

- [ ] 55. Implement response caching
  - Create ResponseCache class with LRU eviction
  - Implement getResponseBody() with cache lookup
  - Set maximum cache size (e.g., 50 responses)
  - Track access order for LRU eviction
  - Evict oldest responses when cache is full
  - _Requirements: 22.4_

- [ ] 56. Implement UI rendering optimization
  - Use LazyForEach for sidebar request list
  - Implement virtual scrolling for response history
  - Debounce text input onChange handlers (500ms)
  - Use @Trace decorator precisely to minimize re-renders
  - Profile UI performance and optimize slow components
  - _Requirements: 11.4_

- [ ] 57. Implement request queuing
  - Create RequestQueue class to limit concurrent requests
  - Set maximum concurrent requests (e.g., 6)
  - Queue requests when limit is reached
  - Process queue as requests complete
  - _Requirements: 4.1_

- [ ]* 57.1 Write performance tests
  - Test that database queries complete within 50ms
  - Test that UI renders at 60 FPS during interactions
  - Test that memory usage stays under 200MB


## Phase 15: Additional Features

- [ ] 58. Implement keyboard shortcuts
  - Add keyboard event listeners to main page
  - Implement Ctrl+Enter to send current request
  - Implement Ctrl+N to create new request
  - Implement Ctrl+F to focus sidebar search
  - Implement Ctrl+S to save current request (auto-save already implemented)
  - Implement Ctrl+D to duplicate current request
  - Display keyboard shortcuts in help dialog
  - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5_

- [ ] 59. Implement workspace settings
  - Add workspace settings to WorkspaceDialog
  - Implement follow_redirects toggle
  - Implement validate_certificates toggle
  - Implement request_timeout input (milliseconds)
  - Implement proxy configuration (enabled, host, port, username, password)
  - Apply workspace settings during request execution
  - _Requirements: 23.1, 23.2, 23.3, 23.4_

- [ ] 60. Implement proxy support
  - Add proxy configuration to workspace settings
  - Apply proxy settings to HTTP requests
  - Support HTTP and HTTPS proxies
  - Support proxy authentication
  - Support bypass patterns for specific hosts
  - Display proxy errors clearly
  - _Requirements: 34.1, 34.2, 34.3, 34.4, 34.5_

- [ ] 61. Implement client certificate authentication
  - Add client certificate configuration to workspace settings
  - Store certificate paths (pfx_file or crt_file + key_file)
  - Match certificates by host and port
  - Support passphrase for encrypted certificates
  - Apply certificates during request execution
  - Support enable/disable toggle for certificates
  - _Requirements: 35.1, 35.2, 35.3, 35.4, 35.5, 35.6_

- [ ]* 61.1 Write integration tests for advanced features
  - Test that keyboard shortcuts trigger correct actions
  - Test that workspace settings are applied to requests
  - Test that proxy configuration routes requests correctly


## Phase 16: Final Integration and Testing

- [ ] 62. Checkpoint - Ensure all tests pass
  - Run all unit tests and verify they pass
  - Run all property-based tests and verify they pass
  - Run all integration tests and verify they pass
  - Fix any failing tests
  - Ask the user if questions arise

- [ ] 63. Implement State Management V2 reactivity verification
  - Verify all data models use @ObservedV2 and @Trace
  - Verify all components use @ComponentV2
  - Verify component inputs use @Param
  - Verify component outputs use @Event
  - Verify component local state uses @Local
  - Test that property changes trigger minimal UI updates
  - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5_

- [ ]* 63.1 Write property test for State Management V2 reactivity
  - **Property 11: State Management V2 Reactivity**
  - **Validates: Requirements 11.4**
  - Test that only affected components re-render on property change
  - Monitor render counts during property updates

- [ ]* 63.2 Write property test for array mutation observation
  - **Property 12: Array Mutation Observation**
  - **Validates: Requirements 11.5**
  - Test that array mutations trigger UI updates
  - Test push, pop, splice, and other array operations

- [ ] 64. Implement theme adaptation verification
  - Verify all colors use resource references ($r('app.color.xxx'))
  - Verify all spacing uses resource references ($r('app.float.xxx'))
  - Verify all font sizes use resource references ($r('app.float.xxx'))
  - Test theme switching between light and dark modes
  - Verify no hardcoded colors remain in components
  - Test auto-theme follows system changes
  - _Requirements: 15.1, 15.2, 15.3_

- [ ] 65. Implement end-to-end testing
  - Test complete workflow: create workspace → create request → execute → view response
  - Test folder organization: create folder → move request → verify hierarchy
  - Test environment variables: create environment → add variables → use in request
  - Test authentication: configure auth → execute request → verify headers
  - Test theme switching: toggle theme → verify UI updates
  - Test request history: execute multiple times → view history → select previous response
  - _Requirements: All_

- [ ]* 65.1 Write integration tests for end-to-end workflows
  - Test workspace creation and switching
  - Test request execution with variables and auth
  - Test folder hierarchy with inheritance
  - Test theme switching with UI updates

- [ ] 66. Final checkpoint - Ensure all tests pass
  - Run complete test suite
  - Verify all property-based tests pass with 100+ iterations
  - Verify all unit tests pass
  - Verify all integration tests pass
  - Fix any remaining issues
  - Ask the user if questions arise

---

## Summary

This implementation plan provides a structured approach to building the Yaak HarmonyOS application:

- **16 phases** covering foundation, UI, services, and advanced features
- **66 main tasks** with clear objectives and requirements references
- **30+ property-based tests** to verify correctness properties
- **Multiple unit and integration tests** for comprehensive coverage
- **Focus on HarmonyOS best practices**: State Management V2, resource qualifiers, Navigation component
- **Incremental development**: Each phase builds on previous work
- **Testing integrated throughout**: Tests are written alongside implementation

**Optional tasks** (marked with *) include property-based tests, unit tests, and integration tests. These can be skipped for faster MVP development, but are recommended for production quality.

**To begin implementation:**
1. Open this tasks.md file
2. Click "Start task" next to the first task
3. Complete tasks sequentially, building incrementally
4. Run tests at checkpoints to verify correctness
5. Ask for help if any issues arise

