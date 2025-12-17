# Implementation Plan - UI Improvements

- [x] 1. Fix Settings Button Click Handler


  - Update WorkspaceHeader component to properly handle settings button click
  - Create state variable for settings dialog visibility in Index page
  - Wire up the onOpenSettings callback to show the settings dialog
  - _Requirements: 1.1_

- [ ] 2. Create Settings Dialog Component
  - [x] 2.1 Create SettingsDialog.ets component file


    - Define component structure with tabs for different settings categories
    - Implement General, Appearance, and About tabs
    - Add close button and backdrop click handling
    - _Requirements: 1.2, 1.3_

  - [ ]* 2.2 Write property test for settings dialog visibility
    - **Property 1: Settings button click triggers dialog**
    - **Validates: Requirements 1.1**

- [ ] 3. Implement Resizable Panes
  - [x] 3.1 Create ResizablePane component


    - Implement PanGesture for drag-to-resize
    - Add min/max width constraints
    - Create visual resize handle
    - _Requirements: 2.1, 2.5_

  - [x] 3.2 Add pane width persistence

    - Use AppStorage to save pane widths
    - Load saved widths on component initialization
    - Key storage by workspace ID
    - _Requirements: 2.4_

  - [x] 3.3 Update Index page layout to use ResizablePane


    - Replace fixed-width columns with ResizablePane components
    - Set appropriate default widths (sidebar: 250dp, request: 50%, response: 30%)
    - Add horizontal scroll support for narrow panes
    - _Requirements: 2.2, 2.3_

  - [ ]* 3.4 Write property test for pane width constraints
    - **Property 2: Pane width constraints are enforced**
    - **Validates: Requirements 2.1, 2.5**

  - [ ]* 3.5 Write property test for pane width persistence
    - **Property 3: Pane width persistence**
    - **Validates: Requirements 2.4**

- [ ] 4. Create Workspace Management Dialog
  - [x] 4.1 Create WorkspaceManagementDialog component


    - Implement list view of existing workspaces
    - Add create workspace form
    - Add edit and delete actions
    - _Requirements: 3.1, 3.2_

  - [x] 4.2 Wire up workspace management in Index page


    - Add button to open workspace management dialog
    - Connect create/update/delete callbacks to repository methods
    - Refresh workspace list after operations
    - _Requirements: 3.2_

  - [ ]* 4.3 Write property test for workspace creation
    - **Property 4: Workspace creation round trip**
    - **Validates: Requirements 3.2**

- [ ] 5. Create Environment Management Dialog
  - [x] 5.1 Create EnvironmentManagementDialog component


    - Implement list view of environments for selected workspace
    - Add create environment form with variable editor
    - Add edit and delete actions
    - _Requirements: 3.3, 3.4, 3.5_

  - [x] 5.2 Wire up environment management in Index page


    - Add button to open environment management dialog
    - Connect create/update/delete callbacks to repository methods
    - Refresh environment list after operations
    - _Requirements: 3.4_

  - [ ]* 5.3 Write property test for environment creation
    - **Property 5: Environment creation round trip**
    - **Validates: Requirements 3.4**

- [ ] 6. Fix Auth Editor Input Fields
  - [x] 6.1 Update AuthEditor component layout


    - Set minimum height for all input fields (40dp)
    - Add proper spacing between fields (12dp)
    - Wrap content in Scroll component for overflow
    - _Requirements: 4.3, 4.4, 4.5, 4.6_

  - [x] 6.2 Ensure auth type switching works correctly

    - Verify all auth types display appropriate fields
    - Test field visibility when switching between types
    - Ensure saved values persist when switching back
    - _Requirements: 4.1, 4.2_

  - [ ]* 6.3 Write property test for auth field visibility
    - **Property 6: Auth field visibility**
    - **Validates: Requirements 4.1, 4.3, 4.4, 4.5, 4.6**

  - [ ]* 6.4 Write property test for input field minimum height
    - **Property 7: Input field minimum height**
    - **Validates: Requirements 4.3, 4.4, 4.5, 4.6, 5.1, 5.2**

- [ ] 7. Fix Headers and Query Parameters Editors
  - [x] 7.1 Update HeadersEditor component


    - Increase input field heights to minimum 40dp
    - Adjust row layout to show both key and value fields
    - Use flexible layout with proper flex weights
    - Add horizontal scroll for narrow containers
    - _Requirements: 5.1, 5.3, 5.4_

  - [x] 7.2 Create QueryParamsEditor component


    - Copy improved layout from HeadersEditor
    - Adapt for query parameter editing
    - Ensure consistent styling with HeadersEditor
    - _Requirements: 5.2, 5.3, 5.4_

  - [x] 7.3 Update RequestEditorComponent to use new editors



    - Replace existing headers editor with improved version
    - Add query parameters editor tab
    - Ensure proper tab switching
    - _Requirements: 5.1, 5.2_

  - [ ]* 7.4 Write property test for value field visibility
    - **Property 8: Value field visibility**
    - **Validates: Requirements 5.3**

- [ ] 8. Final Integration and Testing
  - [ ] 8.1 Test all components together
    - Verify settings dialog opens from header button
    - Test pane resizing with all three panes
    - Create and manage workspaces and environments
    - Test auth editor with all auth types
    - Test headers and query params editors with long content
    - _Requirements: All_

  - [ ] 8.2 Fix any integration issues
    - Address any bugs found during integration testing
    - Ensure smooth user experience
    - Verify all requirements are met
    - _Requirements: All_

  - [ ]* 8.3 Write integration tests
    - Test settings persistence across app restarts
    - Test pane width persistence across app restarts
    - Test workspace/environment management workflows
    - Test auth configuration save/load

- [ ] 9. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.
