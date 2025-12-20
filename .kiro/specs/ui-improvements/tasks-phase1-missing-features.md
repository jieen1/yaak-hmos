# Implementation Plan - Phase 1 Missing Features

## Overview

This implementation plan covers the Phase 1 high-priority missing features:
1. 数据导入功能 (Data Import)
2. 数据导出功能 (Data Export)
3. 命令面板 (Command Palette)
4. 复制为 cURL (Copy as cURL)

**Estimated Time**: 2 weeks (80 hours)

---

## Phase 1.1: cURL Import/Export (Week 1, Days 1-2)

### 1. Implement CurlImporter Service

- [x] 1.1 Create CurlImporter.ets service file
  - Implement parse() method to convert cURL string to HttpRequest
  - Implement isCurlCommand() detection method
  - Parse URL from cURL command
  - Parse HTTP method (-X flag)
  - Parse headers (-H flag)
  - Parse body data (-d, --data, --data-raw flags)
  - Parse authentication (-u flag for Basic Auth)
  - Handle quoted strings and escape sequences
  - _Requirements: 10.6_

- [ ]* 1.2 Write property test for cURL parsing
  - **Property 1: cURL Round-Trip Consistency**
  - **Validates: Requirements 10.6, 16.1**
  - Test that parsing then generating produces equivalent cURL
  - Generate random valid cURL commands

### 2. Implement CurlGenerator Service

- [x] 2.1 Create CurlGenerator.ets service file
  - Implement generate() method to convert HttpRequest to cURL string
  - Resolve template variables before generation
  - Generate URL with query parameters
  - Generate -X flag for non-GET methods
  - Generate -H flags for headers
  - Generate -d flag for body
  - Generate -u flag for Basic Auth
  - Implement shell escaping for special characters
  - Support multi-line formatting option
  - _Requirements: 16.1, 16.2, 16.3_

- [ ]* 2.2 Write property test for cURL generation
  - **Property 6: cURL Variable Resolution**
  - **Validates: Requirements 16.3**
  - Test that all template variables are resolved
  - Generate random requests with variables

### 3. Integrate Copy as cURL

- [x] 3.1 Add "Copy as cURL" to request context menu
  - Add menu item to RequestContextMenu
  - Wire up click handler
  - Call CurlGenerator.generate()
  - Copy to clipboard using pasteboard API
  - Show success toast notification
  - _Requirements: 16.1, 16.4_

- [x] 3.2 Add "Copy as cURL" button to request editor
  - Add button to RequestEditorComponent toolbar
  - Implement same functionality as context menu
  - _Requirements: 16.1_



---

## Phase 1.2: Data Import (Week 1, Days 3-5)

### 4. Create Import Service Infrastructure

- [x] 4.1 Create ImportService.ets service file
  - Implement detectFormat() method
  - Implement import() dispatcher method
  - Define ImportFormat type
  - Define ImportResult interface
  - Define ImportError interface
  - _Requirements: 10.1_

- [x] 4.2 Create import format detection logic
  - Detect OpenAPI by openapi field
  - Detect Postman by info.schema field
  - Detect Insomnia by _type field
  - Detect Swagger by swagger field
  - Detect cURL by curl prefix
  - _Requirements: 10.1_

### 5. Implement OpenAPI Importer

- [x] 5.1 Create OpenAPIImporter.ets service file
  - Parse OpenAPI 3.0/3.1 JSON/YAML
  - Extract servers for base URL
  - Iterate paths and operations
  - Convert each operation to HttpRequest
  - Extract parameters (query, header, path)
  - Generate request body from schema
  - Create folders for path groups (optional)
  - _Requirements: 10.2_

- [ ]* 5.2 Write property test for OpenAPI import
  - **Property 2: OpenAPI Import Completeness**
  - **Validates: Requirements 10.2**
  - Test that all path+method combinations are imported
  - Generate random valid OpenAPI specs

### 6. Implement Postman Importer

- [x] 6.1 Create PostmanImporter.ets service file
  - Parse Postman Collection v2/v2.1 JSON
  - Recursively process items (requests and folders)
  - Convert Postman request to HttpRequest
  - Preserve folder hierarchy
  - Convert Postman variables to Environment
  - Handle Postman auth configurations
  - _Requirements: 10.3_
  - Handle Postman auth configurations
  - _Requirements: 10.3_

- [ ]* 6.2 Write property test for Postman import
  - **Property 3: Postman Import Structure Preservation**
  - **Validates: Requirements 10.3**
  - Test that folder hierarchy is preserved
  - Generate random Postman collections

### 7. Implement Insomnia Importer

- [x] 7.1 Create InsomniaImporter.ets service file
  - Parse Insomnia v4+ export JSON
  - Process resources by type
  - Convert request resources to HttpRequest
  - Convert folder resources to Folder
  - Convert environment resources to Environment
  - Handle Insomnia auth configurations
  - _Requirements: 10.4_

### 8. Implement Swagger Importer

- [x] 8.1 Create SwaggerImporter.ets service file
  - Parse Swagger 2.0 JSON
  - Extract host and basePath for base URL
  - Iterate paths and operations
  - Convert each operation to HttpRequest
  - Handle Swagger parameters
  - Generate request body from definitions
  - _Requirements: 10.5_

### 9. Create Import Dialog UI

- [x] 9.1 Create ImportDialog.ets component
  - Create modal dialog structure
  - Add format selector (dropdown)
  - Add file picker button
  - Add paste area for cURL/content
  - Show format auto-detection result
  - _Requirements: 10.1_

- [x] 9.2 Implement import preview
  - Parse file content on selection
  - Display preview of items to import
  - Show request count, folder count
  - Allow user to confirm or cancel
  - _Requirements: 10.8_

- [x] 9.3 Implement import execution
  - Call ImportService.import() on confirm
  - Show progress indicator
  - Display import summary on completion
  - Show error details if import fails
  - Refresh sidebar after successful import
  - _Requirements: 10.8, 10.9_

### 10. Implement cURL Auto-Detection in URL Field

- [x] 10.1 Add cURL detection to URL input
  - Detect paste event in URL TextInput
  - Check if pasted content is cURL command
  - Show confirmation dialog if cURL detected
  - Import cURL and populate request fields
  - _Requirements: 10.7_



---

## Phase 1.3: Data Export (Week 2, Days 1-2)

### 11. Implement Export Service

- [x] 11.1 Create ExportService.ets service file
  - Implement exportWorkspace() method
  - Implement exportWorkspaces() method
  - Build YaakExportData structure
  - Include workspace, folders, requests, environments
  - Handle includePrivateEnvironments option
  - Generate JSON output
  - _Requirements: 11.1, 11.4, 11.5, 11.6_

- [ ]* 11.2 Write property test for export-import round-trip
  - **Property 4: Export-Import Round-Trip**
  - **Validates: Requirements 11.4, 11.5, 11.6**
  - Test that export then import produces identical data
  - Generate random workspaces with requests

### 12. Create Export Dialog UI

- [x] 12.1 Create ExportDialog.ets component
  - Create modal dialog structure
  - Add workspace selector (checkboxes)
  - Add "Select All" / "Deselect All" buttons
  - Add includePrivateEnvironments toggle
  - Add export button
  - _Requirements: 11.1, 11.2, 11.3_

- [x] 12.2 Implement export execution
  - Validate at least one workspace selected
  - Call ExportService.exportWorkspaces()
  - Show file save dialog
  - Write JSON to selected location
  - Show success/error toast
  - _Requirements: 11.4_

### 13. Add Export Menu Items

- [x] 13.1 Add Export to workspace context menu
  - Add "Export Workspace" menu item
  - Open ExportDialog with workspace pre-selected
  - _Requirements: 11.1_

- [x] 13.2 Add Export to main menu/header
  - Add "Export..." button or menu item
  - Open ExportDialog
  - _Requirements: 11.1_

---

## Phase 1.4: Command Palette (Week 2, Days 3-5)

### 14. Implement Command Service

- [x] 14.1 Create CommandService.ets service file
  - Define Command interface
  - Define CommandResult interface
  - Implement getCommands() to return built-in commands
  - Implement search() method
  - Implement fuzzy matching algorithm
  - Sort results by relevance score
  - Group results by category
  - _Requirements: 12.3, 12.4_

- [ ]* 14.2 Write property test for fuzzy search
  - **Property 5: Fuzzy Search Relevance**
  - **Validates: Requirements 12.3, 12.4**
  - Test that exact matches score higher than partial
  - Generate random queries and items

- [x] 14.3 Define built-in commands
  - New HTTP Request (Ctrl+N)
  - New Folder
  - New Workspace
  - Import... (Ctrl+I)
  - Export... (Ctrl+E)
  - Settings (Ctrl+,)
  - Send Request (Ctrl+Enter)
  - Duplicate Request (Ctrl+D)
  - Toggle Sidebar (Ctrl+B)
  - Focus URL Bar (Ctrl+L)
  - _Requirements: 12.8_

### 15. Create Command Palette UI

- [x] 15.1 Create CommandPalette.ets component
  - Create modal overlay structure
  - Add search input with auto-focus
  - Add results list with categories
  - Style with semi-transparent backdrop
  - Position at top-center of screen
  - _Requirements: 12.2_

- [x] 15.2 Implement search functionality
  - Debounce input (150ms)
  - Call CommandService.search() on input
  - Update results list
  - Highlight matching characters
  - _Requirements: 12.3_

- [x] 15.3 Implement keyboard navigation
  - Up/Down arrows to navigate results
  - Enter to execute selected command
  - Escape to close palette
  - Track selectedIndex state
  - Scroll selected item into view
  - _Requirements: 12.6, 12.7_

- [x] 15.4 Implement command execution
  - Execute command action on selection
  - Close palette after execution
  - Handle execution errors gracefully
  - _Requirements: 12.5_

### 16. Integrate Command Palette

- [x] 16.1 Add Ctrl+K keyboard shortcut
  - Register global keyboard listener in Index.ets
  - Toggle commandPaletteVisible on Ctrl+K
  - _Requirements: 12.1_

- [x] 16.2 Add dynamic request/workspace results
  - Include current workspace requests in search
  - Include all workspaces in search
  - Include environments in search
  - Navigate to item on selection
  - _Requirements: 12.3, 12.4_

- [x] 16.3 Display keyboard shortcuts in results
  - Show shortcut badge for commands with shortcuts
  - Right-align shortcut text
  - _Requirements: 12.8_



---

## Phase 1.5: Integration and Testing (Week 2, Day 5)

### 17. Integration Testing

- [ ] 17.1 Test import flow end-to-end
  - Test OpenAPI import with sample file
  - Test Postman import with sample collection
  - Test cURL import with various commands
  - Verify items appear in sidebar
  - Verify request details are correct
  - _Requirements: 10.1-10.9_

- [ ] 17.2 Test export flow end-to-end
  - Export workspace with requests and folders
  - Verify JSON file is valid
  - Import exported file to new workspace
  - Verify data matches original
  - _Requirements: 11.1-11.6_

- [ ] 17.3 Test command palette flow
  - Open with Ctrl+K
  - Search for commands
  - Search for requests
  - Execute commands
  - Navigate with keyboard
  - _Requirements: 12.1-12.8_

- [ ] 17.4 Test copy as cURL flow
  - Copy simple GET request
  - Copy POST request with body
  - Copy request with headers
  - Copy request with auth
  - Verify cURL is valid
  - _Requirements: 16.1-16.4_

### 18. Bug Fixes and Polish

- [ ] 18.1 Fix identified issues
  - Address any bugs found during testing
  - Fix UI glitches
  - Improve error messages
  - _Requirements: All_

- [ ] 18.2 Performance optimization
  - Optimize large file imports
  - Optimize command palette search
  - Add loading indicators where needed
  - _Requirements: Performance_

- [ ] 18.3 Accessibility improvements
  - Ensure dialogs are keyboard accessible
  - Add proper focus management
  - Add screen reader labels
  - _Requirements: Accessibility_

---

## Summary

**Total Tasks**: 18 major tasks with 45+ sub-tasks

**Estimated Timeline**:
- Week 1, Days 1-2: cURL Import/Export (Tasks 1-3)
- Week 1, Days 3-5: Data Import (Tasks 4-10)
- Week 2, Days 1-2: Data Export (Tasks 11-13)
- Week 2, Days 3-5: Command Palette (Tasks 14-16)
- Week 2, Day 5: Integration and Testing (Tasks 17-18)

**Key Milestones**:
- End of Day 2: Copy as cURL working
- End of Week 1: All import formats working
- End of Day 7: Export working
- End of Week 2: Command palette working, all features tested

**Dependencies**:
- Task 1 (CurlImporter) is needed for Task 10 (cURL auto-detection)
- Task 4 (ImportService) is needed for Tasks 5-9 (individual importers)
- Task 14 (CommandService) is needed for Tasks 15-16 (Command Palette UI)

**Optional Tasks** (marked with *):
- Property-based tests (1.2, 2.2, 5.2, 6.2, 11.2, 14.2)

These property tests are recommended for ensuring correctness but can be deferred if time is limited.

