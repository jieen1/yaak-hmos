# Implementation Plan: Inheritance UI Features

## Overview

This implementation plan covers the inheritance UI features for yaak-hmos, enabling users to see and understand inherited authentication and headers from parent folders and workspaces.

## Tasks

- [x] 1. Extend InheritanceService with source tracking
  - [x] 1.1 Add InheritedHeaderWithSource interface
    - Define interface with header, sourceType, sourceId, sourceName fields
    - Export from InheritanceService.ets
    - _Requirements: 5.1_

  - [x] 1.2 Add InheritedAuthInfo interface
    - Define interface with auth, sourceType, sourceId, sourceName fields
    - Export from InheritanceService.ets
    - _Requirements: 5.2_

  - [x] 1.3 Implement getInheritedHeadersWithSource method
    - Traverse folder hierarchy collecting headers with source info
    - Include workspace headers with source info
    - Return array of InheritedHeaderWithSource
    - _Requirements: 1.1, 5.1_

  - [x] 1.4 Implement getInheritedAuthWithSource method
    - Traverse folder hierarchy to find first auth
    - Return InheritedAuthInfo with source details or null
    - _Requirements: 2.1, 2.2, 2.3, 5.2_

- [x] 2. Enhance HeadersEditor component
  - [x] 2.1 Add inheritedHeaders and inheritedSources props
    - Add @Param for inheritedHeaders: HttpHeader[]
    - Add @Param for inheritedSources: InheritedHeaderWithSource[]
    - Add @Param for onNavigateToSource callback
    - _Requirements: 1.1_

  - [x] 2.2 Implement collapsible inherited headers section
    - Add @Local showInheritedHeaders state
    - Build collapsible section with toggle button
    - Show count badge with inherited header count
    - Only show section when inherited headers exist
    - _Requirements: 1.1, 1.2, 1.4_

  - [x] 2.3 Render inherited headers as read-only
    - Filter to only enabled inherited headers
    - Display each header with disabled inputs
    - Show source indicator for each header
    - _Requirements: 1.3, 1.5, 5.1_

  - [ ]* 2.4 Write property test for inherited headers display
    - **Property 1: Inherited Headers Display Completeness**
    - **Validates: Requirements 1.1, 1.2, 1.3, 1.5**

- [x] 3. Enhance AuthEditor component
  - [x] 3.1 Add inheritedAuth and onNavigateToSource props
    - Add @Param for inheritedAuth: InheritedAuthInfo | null
    - Add @Param for onNavigateToSource callback
    - _Requirements: 2.1_

  - [x] 3.2 Implement inherited auth display
    - Check if auth is inherited (type is 'none' and inheritedAuth exists)
    - Display "Inherited from [source name]" message
    - Make source name tappable for navigation
    - _Requirements: 2.1, 2.2, 2.3, 5.2_

  - [x] 3.3 Update auth type selector with "Inherit from Parent" option
    - Add new option to auth type dropdown
    - Handle selection to clear local auth and use inherited
    - _Requirements: 2.1_

  - [x] 3.4 Handle no authentication state
    - Display "No authentication" when no auth anywhere
    - _Requirements: 2.5_

  - [ ]* 3.5 Write property test for inherited auth display
    - **Property 2: Inherited Auth Source Display**
    - **Validates: Requirements 2.1, 2.2, 5.2**

- [x] 4. Create FolderSettingsDialog component
  - [x] 4.1 Create FolderSettingsDialog.ets file
    - Create modal dialog structure
    - Add visible, folder, folders, workspace, onClose, onSave props
    - _Requirements: 3.1_

  - [x] 4.2 Implement tabs for General, Headers, Auth
    - Use Tabs component for consistency
    - Add General tab with folder name editing
    - Add Headers tab with HeadersEditor
    - Add Auth tab with AuthEditor
    - _Requirements: 3.1_

  - [x] 4.3 Wire up inheritance resolution for folder
    - Call InheritanceService.getInheritedHeadersWithSource for headers
    - Call InheritanceService.getInheritedAuthWithSource for auth
    - Pass inherited data to editors
    - _Requirements: 3.2, 3.3_

  - [x] 4.4 Implement save functionality
    - Update folder headers on save
    - Update folder auth on save
    - Call onSave callback
    - _Requirements: 3.4_

  - [ ]* 4.5 Write property test for folder inheritance resolution
    - **Property 4: Folder Inheritance Resolution**
    - **Validates: Requirements 3.2, 3.3, 3.4**

- [x] 5. Enhance WorkspaceSettingsDialog component
  - [x] 5.1 Add Headers tab to WorkspaceSettingsDialog
    - Add TAB_HEADERS constant
    - Add HeadersEditor in TabContent
    - Wire up onChange to update workspace headers
    - _Requirements: 4.1, 4.2_

  - [x] 5.2 Add Auth tab to WorkspaceSettingsDialog
    - Add TAB_AUTH constant
    - Add AuthEditor in TabContent
    - Wire up onChange to update workspace auth
    - _Requirements: 4.1, 4.3_

  - [ ]* 5.3 Write property test for workspace inheritance
    - **Property 5: Workspace Inheritance Resolution**
    - **Validates: Requirements 4.4**

- [x] 6. Integrate with RequestEditorComponent
  - [x] 6.1 Pass inherited headers to HeadersEditor
    - Get inherited headers using InheritanceService
    - Pass to HeadersEditor component
    - _Requirements: 1.1_

  - [x] 6.2 Pass inherited auth to AuthEditor
    - Get inherited auth using InheritanceService
    - Pass to AuthEditor component
    - _Requirements: 2.1_

  - [x] 6.3 Implement navigation to source settings
    - Handle onNavigateToSource callback
    - Open FolderSettingsDialog or WorkspaceSettingsDialog
    - _Requirements: 5.3_

- [x] 7. Integrate with Index.ets
  - [x] 7.1 Add FolderSettingsDialog state and handlers
    - Add showFolderSettingsDialog state
    - Add selectedFolderForSettings state
    - Add handler to open folder settings
    - Add handler to save folder settings
    - _Requirements: 3.1_

  - [x] 7.2 Add folder settings to sidebar context menu
    - Add "Settings" option to folder context menu
    - Wire up to open FolderSettingsDialog
    - _Requirements: 3.1_

  - [x] 7.3 Update workspace settings integration
    - Ensure WorkspaceSettingsDialog has headers and auth tabs
    - Wire up save handlers for headers and auth
    - _Requirements: 4.1_

- [ ] 8. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Final integration and polish
  - [x] 9.1 Update component exports
    - Export FolderSettingsDialog from components/index.ets
    - Export new interfaces from services/index.ets
    - _Requirements: All_

  - [ ] 9.2 Add visual polish
    - Ensure consistent styling with rest of app
    - Add appropriate spacing and colors
    - _Requirements: All_

  - [ ] 9.3 Test end-to-end inheritance flow
    - Create workspace with auth
    - Create folder with headers
    - Create request and verify inheritance
    - _Requirements: All_

## Notes

- Tasks marked with `*` are optional property-based tests
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties
- Unit tests validate specific examples and edge cases
