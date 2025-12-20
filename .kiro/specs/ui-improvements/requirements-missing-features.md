# 遗漏功能需求文档 - Yaak HarmonyOS

## 概述

本文档基于对 Tauri 桌面应用源代码的全面分析，列出了 HarmonyOS 版本中尚未实现的功能。这些功能按优先级和复杂度分类。

---

## 一、高优先级功能（核心功能）

### Requirement 8: WebSocket 请求支持

**User Story:** As a user, I want to create and manage WebSocket connections, so that I can test real-time communication APIs.

#### Acceptance Criteria

1. WHEN a user creates a new request THEN the system SHALL provide "WebSocket Request" as an option
2. WHEN a WebSocket request is selected THEN the system SHALL display a WebSocket-specific request pane
3. WHEN a user enters a WebSocket URL and clicks Connect THEN the system SHALL establish a WebSocket connection
4. WHEN connected THEN the system SHALL display connection status (connected/disconnected)
5. WHEN connected THEN the system SHALL allow sending text messages
6. WHEN messages are received THEN the system SHALL display them in real-time in the response pane
7. WHEN a user clicks Disconnect THEN the system SHALL close the WebSocket connection
8. WHEN connection errors occur THEN the system SHALL display error messages clearly
9. WHEN viewing WebSocket history THEN the system SHALL show all sent and received messages with timestamps

### Requirement 9: gRPC 请求支持

**User Story:** As a user, I want to create and execute gRPC requests, so that I can test gRPC-based APIs.

#### Acceptance Criteria

1. WHEN a user creates a new request THEN the system SHALL provide "gRPC Request" as an option
2. WHEN a gRPC request is selected THEN the system SHALL display a gRPC-specific request pane
3. WHEN a user provides a proto file THEN the system SHALL parse and display available services and methods
4. WHEN reflection is enabled THEN the system SHALL auto-discover services from the server
5. WHEN a service/method is selected THEN the system SHALL display the message editor with schema hints
6. WHEN a user sends a unary request THEN the system SHALL execute and display the response
7. WHEN streaming is used THEN the system SHALL handle client/server/bidirectional streaming
8. WHEN metadata is provided THEN the system SHALL include it in the gRPC call
9. WHEN errors occur THEN the system SHALL display gRPC status codes and error details

### Requirement 10: 数据导入功能

**User Story:** As a user, I want to import API collections from other tools, so that I can migrate my existing work to Yaak.

#### Acceptance Criteria

1. WHEN a user selects Import THEN the system SHALL display supported import formats
2. WHEN importing OpenAPI 3.0/3.1 THEN the system SHALL create requests from all endpoints
3. WHEN importing Postman Collection v2/v2.1 THEN the system SHALL preserve folder structure and variables
4. WHEN importing Insomnia v4+ THEN the system SHALL convert requests and environments
5. WHEN importing Swagger 2.0 THEN the system SHALL create requests from all operations
6. WHEN importing cURL commands THEN the system SHALL parse and create equivalent HTTP requests
7. WHEN pasting cURL into URL field THEN the system SHALL auto-detect and import the command
8. WHEN import completes THEN the system SHALL show summary of imported items
9. WHEN import fails THEN the system SHALL display detailed error messages

### Requirement 11: 数据导出功能

**User Story:** As a user, I want to export my workspaces and requests, so that I can backup or share my API collections.

#### Acceptance Criteria

1. WHEN a user selects Export THEN the system SHALL display export options
2. WHEN exporting THEN the system SHALL allow selecting specific workspaces
3. WHEN exporting THEN the system SHALL provide option to include/exclude private environments
4. WHEN export completes THEN the system SHALL save to a JSON file
5. WHEN exporting THEN the system SHALL preserve all request configurations
6. WHEN exporting THEN the system SHALL include folder hierarchy

### Requirement 12: 命令面板 (Command Palette)

**User Story:** As a user, I want a quick command palette, so that I can rapidly access any feature or request without using the mouse.

#### Acceptance Criteria

1. WHEN a user presses Ctrl+K or Cmd+K THEN the system SHALL open the command palette
2. WHEN the palette is open THEN the system SHALL display a search input
3. WHEN typing THEN the system SHALL fuzzy-search across all commands, requests, and workspaces
4. WHEN results are shown THEN the system SHALL group them by category (Actions, Requests, Environments, Workspaces)
5. WHEN a result is selected THEN the system SHALL execute the corresponding action
6. WHEN navigating results THEN the system SHALL support arrow keys and Enter to select
7. WHEN pressing Escape THEN the system SHALL close the palette
8. WHEN showing actions THEN the system SHALL display associated keyboard shortcuts

---

## 二、中优先级功能（增强功能）

### Requirement 13: Cookie 管理

**User Story:** As a user, I want to view and manage cookies, so that I can debug authentication and session issues.

#### Acceptance Criteria

1. WHEN a user opens Cookie Manager THEN the system SHALL display all stored cookies
2. WHEN viewing cookies THEN the system SHALL show domain, name, value, expiration, and flags
3. WHEN a user edits a cookie THEN the system SHALL update the stored value
4. WHEN a user deletes a cookie THEN the system SHALL remove it from storage
5. WHEN a user creates a cookie THEN the system SHALL add it to the cookie jar
6. WHEN cookies are received from responses THEN the system SHALL automatically store them
7. WHEN sending requests THEN the system SHALL include matching cookies automatically

### Requirement 14: 环境颜色标识

**User Story:** As a user, I want to assign colors to environments, so that I can quickly identify which environment is active.

#### Acceptance Criteria

1. WHEN editing an environment THEN the system SHALL provide a color picker
2. WHEN a color is selected THEN the system SHALL display a color indicator in the environment selector
3. WHEN an environment is active THEN the system SHALL show the color prominently in the header
4. WHEN switching environments THEN the system SHALL update the color indicator immediately

### Requirement 15: 请求描述和文档

**User Story:** As a user, I want to add descriptions to requests and folders, so that I can document my API collection.

#### Acceptance Criteria

1. WHEN editing a request THEN the system SHALL provide a description/info tab
2. WHEN editing description THEN the system SHALL support Markdown formatting
3. WHEN viewing a request THEN the system SHALL display the description if present
4. WHEN a request has a description THEN the system SHALL show an indicator in the sidebar
5. WHEN editing a folder THEN the system SHALL allow adding folder-level documentation

### Requirement 16: 复制为 cURL

**User Story:** As a user, I want to copy requests as cURL commands, so that I can share or debug them in terminal.

#### Acceptance Criteria

1. WHEN a user selects "Copy as cURL" THEN the system SHALL generate a valid cURL command
2. WHEN generating cURL THEN the system SHALL include all headers, body, and authentication
3. WHEN generating cURL THEN the system SHALL resolve template variables
4. WHEN copied THEN the system SHALL show a success toast notification

### Requirement 17: 保存响应到文件

**User Story:** As a user, I want to save response bodies to files, so that I can use them for further analysis.

#### Acceptance Criteria

1. WHEN viewing a response THEN the system SHALL provide a "Save Response" option
2. WHEN saving THEN the system SHALL allow choosing file location and name
3. WHEN saving THEN the system SHALL preserve the original content type
4. WHEN saving binary content THEN the system SHALL write raw bytes

### Requirement 18: 复制响应

**User Story:** As a user, I want to copy response content, so that I can use it in other applications.

#### Acceptance Criteria

1. WHEN viewing a response THEN the system SHALL provide a "Copy Response" button
2. WHEN copying THEN the system SHALL copy the formatted or raw content based on current view mode
3. WHEN copied THEN the system SHALL show a success toast notification

---

## 三、低优先级功能（高级功能）

### Requirement 19: Git 同步

**User Story:** As a user, I want to sync my workspaces with Git, so that I can version control and collaborate on API collections.

#### Acceptance Criteria

1. WHEN configuring a workspace THEN the system SHALL allow setting a sync directory
2. WHEN sync is enabled THEN the system SHALL export workspace data to the directory
3. WHEN changes are made THEN the system SHALL update the sync files
4. WHEN viewing Git status THEN the system SHALL show uncommitted changes
5. WHEN pulling changes THEN the system SHALL import updated data

### Requirement 20: 工作区加密

**User Story:** As a user, I want to encrypt sensitive data in my workspace, so that I can protect credentials and secrets.

#### Acceptance Criteria

1. WHEN configuring a workspace THEN the system SHALL allow enabling encryption
2. WHEN encryption is enabled THEN the system SHALL prompt for a password
3. WHEN saving sensitive data THEN the system SHALL encrypt it before storage
4. WHEN loading encrypted data THEN the system SHALL decrypt it with the password
5. WHEN exporting THEN the system SHALL maintain encryption for sensitive fields

### Requirement 21: 插件系统

**User Story:** As a user, I want to extend Yaak with plugins, so that I can add custom functionality.

#### Acceptance Criteria

1. WHEN viewing settings THEN the system SHALL show installed plugins
2. WHEN a plugin is installed THEN the system SHALL load its functionality
3. WHEN a plugin provides template functions THEN the system SHALL make them available
4. WHEN a plugin provides importers THEN the system SHALL add them to import options
5. WHEN a plugin provides auth handlers THEN the system SHALL add them to auth options

### Requirement 22: 自动更新

**User Story:** As a user, I want the app to check for updates, so that I can stay on the latest version.

#### Acceptance Criteria

1. WHEN the app starts THEN the system SHALL check for updates (if enabled)
2. WHEN an update is available THEN the system SHALL notify the user
3. WHEN the user accepts THEN the system SHALL download and install the update
4. WHEN viewing settings THEN the system SHALL allow configuring update preferences

### Requirement 23: 发送历史记录

**User Story:** As a user, I want to view my recent request history, so that I can quickly re-send previous requests.

#### Acceptance Criteria

1. WHEN viewing the sidebar THEN the system SHALL provide access to recent requests
2. WHEN viewing history THEN the system SHALL show recently sent requests with timestamps
3. WHEN selecting a history item THEN the system SHALL navigate to that request
4. WHEN clearing history THEN the system SHALL remove all history entries

---

## 四、响应查看器增强

### Requirement 24: SVG 查看器

**User Story:** As a user, I want to view SVG responses as rendered images, so that I can preview vector graphics.

#### Acceptance Criteria

1. WHEN a response has Content-Type "image/svg+xml" THEN the system SHALL render the SVG
2. WHEN viewing SVG THEN the system SHALL provide zoom and pan controls
3. WHEN switching to Raw mode THEN the system SHALL show the SVG source code

### Requirement 25: 网页预览

**User Story:** As a user, I want to preview HTML responses as rendered web pages, so that I can see the actual output.

#### Acceptance Criteria

1. WHEN a response has Content-Type "text/html" THEN the system SHALL provide a "Preview" option
2. WHEN previewing THEN the system SHALL render the HTML in a sandboxed web view
3. WHEN previewing THEN the system SHALL disable JavaScript execution for security

### Requirement 26: 二进制查看器

**User Story:** As a user, I want to view binary response data, so that I can inspect non-text content.

#### Acceptance Criteria

1. WHEN a response has binary content THEN the system SHALL display a hex dump view
2. WHEN viewing binary THEN the system SHALL show file size and content type
3. WHEN viewing binary THEN the system SHALL provide option to save to file

---

## 五、设置增强

### Requirement 27: 编辑器设置

**User Story:** As a user, I want to customize the code editor, so that I can work more comfortably.

#### Acceptance Criteria

1. WHEN viewing settings THEN the system SHALL provide editor font selection
2. WHEN viewing settings THEN the system SHALL provide editor font size slider
3. WHEN viewing settings THEN the system SHALL provide keymap selection (Default, Vim, VSCode, Emacs)
4. WHEN viewing settings THEN the system SHALL provide soft wrap toggle
5. WHEN settings change THEN the system SHALL apply them immediately to all editors

### Requirement 28: 界面设置

**User Story:** As a user, I want to customize the interface, so that I can personalize my experience.

#### Acceptance Criteria

1. WHEN viewing settings THEN the system SHALL provide interface font selection
2. WHEN viewing settings THEN the system SHALL provide interface font size slider
3. WHEN viewing settings THEN the system SHALL provide interface scale slider
4. WHEN viewing settings THEN the system SHALL provide colored methods toggle
5. WHEN settings change THEN the system SHALL apply them immediately

---

## 实现优先级建议

### Phase 1 (高优先级 - 核心功能)
1. Requirement 10: 数据导入功能
2. Requirement 11: 数据导出功能
3. Requirement 12: 命令面板
4. Requirement 16: 复制为 cURL

### Phase 2 (中优先级 - 增强功能)
1. Requirement 13: Cookie 管理
2. Requirement 14: 环境颜色标识
3. Requirement 15: 请求描述和文档
4. Requirement 17: 保存响应到文件
5. Requirement 18: 复制响应

### Phase 3 (低优先级 - 高级功能)
1. Requirement 8: WebSocket 请求支持
2. Requirement 9: gRPC 请求支持
3. Requirement 24-26: 响应查看器增强
4. Requirement 27-28: 设置增强

### Phase 4 (可选功能)
1. Requirement 19: Git 同步
2. Requirement 20: 工作区加密
3. Requirement 21: 插件系统
4. Requirement 22: 自动更新
5. Requirement 23: 发送历史记录

---

## 与现有需求的关系

本文档是对 `requirements.md` 的补充，原文档已涵盖：
- Requirement 1-7: UI 改进（侧边栏、响应查看器、请求管理等）

本文档新增：
- Requirement 8-28: 遗漏的核心功能和增强功能

建议将这些需求合并到主需求文档中，并相应更新设计文档和任务列表。
