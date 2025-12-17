# Requirements Document

## Introduction

This document specifies the requirements for developing a complete HarmonyOS native version of the Yaak API Client application. The application SHALL be built using ArkTS language with State Management V2 (@ObservedV2, @Trace, @ComponentV2, @Local) and SHALL implement all features from the original Yaak open-source project without any mock code, TODO items, or demo content. The application SHALL provide a professional-grade API testing tool comparable to Postman and Insomnia.

## Glossary

- **System**: The Yaak HarmonyOS API Client application
- **User**: A person using the application to test and manage HTTP/gRPC/WebSocket requests
- **Workspace**: A container for organizing related API requests, folders, and environments with workspace-level settings
- **Request**: An HTTP, gRPC, or WebSocket request configuration with full metadata
- **Folder**: A hierarchical container for organizing requests with inheritance support
- **Environment**: A collection of variables that can be used in requests with public/private scope
- **Response**: The result returned from executing a request, persisted to filesystem
- **Variable**: A named value that can be referenced in requests using {{ variableName }} syntax
- **Cookie Jar**: A storage container for HTTP cookies with domain and path management
- **Authentication**: Security credentials configuration for requests (Basic, Bearer, OAuth2, API Key, etc.)
- **Body Type**: The format of request payload (JSON, XML, Form Data, GraphQL, Binary, etc.)
- **Template Function**: A function that can be called within {{ }} syntax for dynamic values
- **Plugin**: An extension that adds functionality like authentication methods or template functions
- **Introspection**: GraphQL schema discovery and autocomplete support
- **Proto File**: Protocol Buffer definition file for gRPC services
- **Sort Priority**: A numeric value determining the display order of items in the sidebar

## Requirements

### Requirement 1: Workspace Management

**User Story:** As a user, I want to manage multiple workspaces, so that I can organize different API projects separately.

#### Acceptance Criteria

1. WHEN the System starts, THE System SHALL load all existing workspaces from the database
2. WHEN no workspaces exist, THE System SHALL create a default workspace automatically
3. WHEN a user selects a workspace, THE System SHALL load all associated requests, folders, and environments
4. WHEN a user creates a new workspace, THE System SHALL persist it to the database with a unique identifier
5. WHEN a user switches between workspaces, THE System SHALL update the UI to display the selected workspace's content

### Requirement 2: HTTP Request Management

**User Story:** As a user, I want to create, edit, and organize HTTP requests, so that I can test various API endpoints.

#### Acceptance Criteria

1. WHEN a user creates a new request, THE System SHALL generate a unique identifier with prefix "rq" and persist it to the database
2. WHEN a user edits a request URL, THE System SHALL debounce updates and save to database within 500ms
3. WHEN a user changes the HTTP method, THE System SHALL support GET, POST, PUT, DELETE, PATCH, HEAD, and OPTIONS
4. WHEN a user adds query parameters, THE System SHALL store them separately from URL with enabled/disabled state
5. WHEN a user adds headers, THE System SHALL store them as key-value pairs with enabled/disabled state and unique IDs
6. WHEN a user configures request body, THE System SHALL support JSON, XML, Form-Data (multipart and urlencoded), Binary file, GraphQL, and plain text formats
7. WHEN a user deletes a request, THE System SHALL remove it and all associated responses from the database
8. WHEN a user renames a request, THE System SHALL trim whitespace and update the name
9. WHEN a user adds URL parameters with placeholders (/:param), THE System SHALL extract and display them separately
10. WHEN a user sets sort_priority, THE System SHALL use it to order requests in the sidebar

### Requirement 3: Folder Organization

**User Story:** As a user, I want to organize requests into folders, so that I can maintain a clear project structure.

#### Acceptance Criteria

1. WHEN a user creates a folder, THE System SHALL persist it with a unique identifier
2. WHEN a user moves a request into a folder, THE System SHALL update the request's folder_id
3. WHEN a user creates nested folders, THE System SHALL support unlimited folder depth
4. WHEN a user deletes a folder, THE System SHALL prompt for confirmation
5. WHEN a folder is deleted, THE System SHALL handle child requests according to user preference

### Requirement 4: Request Execution

**User Story:** As a user, I want to send HTTP requests and view responses, so that I can test API functionality.

#### Acceptance Criteria

1. WHEN a user clicks Send, THE System SHALL execute the HTTP request with configured parameters
2. WHEN a request is executing, THE System SHALL display a loading indicator
3. WHEN a response is received, THE System SHALL display status code, duration, and size
4. WHEN a response contains JSON, THE System SHALL format it with syntax highlighting
5. WHEN a response contains XML, THE System SHALL format it with syntax highlighting
6. WHEN a response contains images, THE System SHALL display the image
7. WHEN a request fails, THE System SHALL display the error message
8. WHEN a user cancels a request, THE System SHALL abort the network operation

### Requirement 5: Environment Variables

**User Story:** As a user, I want to use environment variables in requests, so that I can easily switch between different environments (dev, staging, production).

#### Acceptance Criteria

1. WHEN a user creates an environment, THE System SHALL persist it with a unique identifier
2. WHEN a user defines variables in an environment, THE System SHALL store them as key-value pairs
3. WHEN a user references a variable using {{ variableName }}, THE System SHALL substitute the value before sending the request
4. WHEN a user switches environments, THE System SHALL use the selected environment's variables
5. WHEN a variable is not defined, THE System SHALL leave the placeholder unchanged

### Requirement 6: Authentication Configuration

**User Story:** As a user, I want to configure authentication for requests, so that I can access protected APIs.

#### Acceptance Criteria

1. WHEN a user selects No Auth, THE System SHALL send requests without authentication headers
2. WHEN a user selects Basic Auth, THE System SHALL encode credentials and add Authorization header
3. WHEN a user selects Bearer Token, THE System SHALL add Authorization header with token
4. WHEN a user selects API Key, THE System SHALL add the key as header or query parameter
5. WHEN a user selects OAuth 2.0, THE System SHALL handle the OAuth flow

### Requirement 7: Response Viewing

**User Story:** As a user, I want to view response data in multiple formats, so that I can analyze API responses effectively.

#### Acceptance Criteria

1. WHEN viewing JSON responses, THE System SHALL provide Pretty and Raw modes
2. WHEN viewing XML responses, THE System SHALL provide Pretty and Raw modes
3. WHEN viewing image responses, THE System SHALL display the image
4. WHEN viewing response headers, THE System SHALL display them as a list
5. WHEN viewing response info, THE System SHALL display connection details

### Requirement 8: Sidebar Navigation

**User Story:** As a user, I want to navigate through workspaces, folders, and requests using a sidebar, so that I can quickly access my API collections.

#### Acceptance Criteria

1. WHEN the sidebar displays, THE System SHALL show a tree view of folders and requests
2. WHEN a user clicks a request, THE System SHALL load it in the request editor
3. WHEN a user clicks a folder, THE System SHALL expand or collapse it
4. WHEN a user searches in the sidebar, THE System SHALL filter requests by name or URL
5. WHEN a user right-clicks an item, THE System SHALL display a context menu with actions

### Requirement 9: Data Persistence

**User Story:** As a user, I want my requests and configurations to be saved automatically, so that I don't lose my work.

#### Acceptance Criteria

1. WHEN a user modifies a request, THE System SHALL save changes to the database within 500ms
2. WHEN the System starts, THE System SHALL load all data from the database
3. WHEN the database is corrupted, THE System SHALL display an error message
4. WHEN a user exports data, THE System SHALL create a backup file
5. WHEN a user imports data, THE System SHALL merge it with existing data

### Requirement 10: UI Layout

**User Story:** As a user, I want a responsive three-pane layout, so that I can view sidebar, request editor, and response viewer simultaneously.

#### Acceptance Criteria

1. WHEN the UI displays, THE System SHALL show sidebar, request pane, and response pane
2. WHEN a user resizes panes, THE System SHALL adjust the layout proportionally
3. WHEN a user hides the sidebar, THE System SHALL expand the request and response panes
4. WHEN a user switches to vertical layout, THE System SHALL stack request and response panes
5. WHEN the window is resized, THE System SHALL maintain proportional pane sizes

### Requirement 11: State Management V2

**User Story:** As a developer, I want to use HarmonyOS State Management V2, so that the application has optimal performance and reactivity.

#### Acceptance Criteria

1. WHEN defining data models, THE System SHALL use @ObservedV2 and @Trace decorators
2. WHEN defining components, THE System SHALL use @ComponentV2 decorator
3. WHEN defining component state, THE System SHALL use @Local decorator
4. WHEN data changes, THE System SHALL update only affected UI components
5. WHEN using arrays, THE System SHALL observe array mutations (push, pop, splice, etc.)

### Requirement 12: Request History

**User Story:** As a user, I want to view previous responses for a request, so that I can compare results over time.

#### Acceptance Criteria

1. WHEN a request is executed, THE System SHALL save the response to the database
2. WHEN viewing a request, THE System SHALL display a list of recent responses
3. WHEN a user selects a previous response, THE System SHALL display it in the response viewer
4. WHEN a user clears history, THE System SHALL delete old responses from the database
5. WHEN storage is limited, THE System SHALL automatically delete oldest responses

### Requirement 13: Cookie Management

**User Story:** As a user, I want the system to manage cookies automatically, so that I can test APIs that require session management.

#### Acceptance Criteria

1. WHEN a response includes Set-Cookie headers, THE System SHALL store cookies in the cookie jar
2. WHEN sending a request, THE System SHALL include relevant cookies from the cookie jar
3. WHEN a user views cookies, THE System SHALL display all stored cookies
4. WHEN a user deletes a cookie, THE System SHALL remove it from the cookie jar
5. WHEN cookies expire, THE System SHALL remove them automatically

### Requirement 14: Import/Export

**User Story:** As a user, I want to import requests from other tools, so that I can migrate my existing API collections.

#### Acceptance Criteria

1. WHEN a user imports a cURL command, THE System SHALL parse it and create a request
2. WHEN a user imports Postman collection, THE System SHALL convert it to native format
3. WHEN a user imports OpenAPI specification, THE System SHALL generate requests from endpoints
4. WHEN a user exports a workspace, THE System SHALL create a JSON file
5. WHEN a user exports a request, THE System SHALL generate a cURL command

### Requirement 15: Theme Support

**User Story:** As a user, I want to customize the application theme, so that I can work comfortably in different lighting conditions.

#### Acceptance Criteria

1. WHEN a user selects light theme, THE System SHALL apply light color scheme
2. WHEN a user selects dark theme, THE System SHALL apply dark color scheme
3. WHEN system theme changes, THE System SHALL update automatically if auto-theme is enabled
4. WHEN theme changes, THE System SHALL persist the preference
5. WHEN the application starts, THE System SHALL load the saved theme preference

### Requirement 16: GraphQL Support

**User Story:** As a user, I want to send GraphQL queries, so that I can test GraphQL APIs.

#### Acceptance Criteria

1. WHEN a user selects GraphQL body type, THE System SHALL display a GraphQL editor
2. WHEN a user writes a GraphQL query, THE System SHALL provide syntax highlighting
3. WHEN a user defines GraphQL variables, THE System SHALL include them in the request
4. WHEN sending a GraphQL request, THE System SHALL set Content-Type to application/json
5. WHEN receiving a GraphQL response, THE System SHALL format it as JSON

### Requirement 17: WebSocket Support

**User Story:** As a user, I want to test WebSocket connections, so that I can work with real-time APIs.

#### Acceptance Criteria

1. WHEN a user creates a WebSocket request, THE System SHALL support ws:// and wss:// protocols
2. WHEN a user connects to a WebSocket, THE System SHALL establish the connection
3. WHEN messages are received, THE System SHALL display them in chronological order
4. WHEN a user sends a message, THE System SHALL transmit it through the WebSocket
5. WHEN a user disconnects, THE System SHALL close the WebSocket connection

### Requirement 18: gRPC Support

**User Story:** As a user, I want to test gRPC services, so that I can work with gRPC APIs.

#### Acceptance Criteria

1. WHEN a user creates a gRPC request, THE System SHALL support proto file import
2. WHEN a user selects a service method, THE System SHALL display the request schema
3. WHEN a user sends a gRPC request, THE System SHALL serialize the message
4. WHEN a response is received, THE System SHALL deserialize and display it
5. WHEN using streaming, THE System SHALL handle bidirectional streams

### Requirement 19: Request Duplication

**User Story:** As a user, I want to duplicate requests, so that I can create similar requests quickly.

#### Acceptance Criteria

1. WHEN a user duplicates a request, THE System SHALL create a copy with a new identifier
2. WHEN duplicating, THE System SHALL copy all configuration including headers, body, and auth
3. WHEN duplicating, THE System SHALL append "Copy" to the request name
4. WHEN duplicating a folder, THE System SHALL recursively copy all child items
5. WHEN duplication completes, THE System SHALL select the new item

### Requirement 20: Keyboard Shortcuts

**User Story:** As a user, I want to use keyboard shortcuts, so that I can work more efficiently.

#### Acceptance Criteria

1. WHEN a user presses Ctrl+Enter, THE System SHALL send the current request
2. WHEN a user presses Ctrl+N, THE System SHALL create a new request
3. WHEN a user presses Ctrl+F, THE System SHALL focus the sidebar search
4. WHEN a user presses Ctrl+S, THE System SHALL save the current request
5. WHEN a user presses Ctrl+D, THE System SHALL duplicate the current request



### Requirement 21: Template Engine and Variable Substitution

**User Story:** As a user, I want to use template syntax in requests, so that I can create dynamic and reusable API tests.

#### Acceptance Criteria

1. WHEN a user types {{ variableName }}, THE System SHALL substitute it with the environment variable value
2. WHEN a user types {{ functionName(args) }}, THE System SHALL execute the template function and substitute the result
3. WHEN a variable is undefined, THE System SHALL leave the placeholder unchanged
4. WHEN rendering fails, THE System SHALL display the error message to the user
5. WHEN a user uses nested templates, THE System SHALL resolve them recursively
6. WHEN template functions include timestamp(), uuid(), random(), THE System SHALL provide built-in implementations
7. WHEN a user references {{ request.url }}, THE System SHALL support request context variables

### Requirement 22: Response Body Storage

**User Story:** As a user, I want response bodies stored efficiently, so that I can review large responses without memory issues.

#### Acceptance Criteria

1. WHEN a response is received, THE System SHALL write the body to a file in app_data_dir/responses/
2. WHEN storing response body, THE System SHALL use the response ID as the filename
3. WHEN a response is streaming, THE System SHALL write chunks incrementally to disk
4. WHEN displaying a response, THE System SHALL read from the body_path file
5. WHEN a response is deleted, THE System SHALL remove the associated body file
6. WHEN storage space is limited, THE System SHALL implement cleanup of old response files

### Requirement 23: Workspace Settings

**User Story:** As a user, I want to configure workspace-level settings, so that I can control request behavior per project.

#### Acceptance Criteria

1. WHEN a user enables "Follow Redirects", THE System SHALL automatically follow HTTP 3xx redirects
2. WHEN a user disables "Validate Certificates", THE System SHALL accept self-signed SSL certificates
3. WHEN a user sets request timeout, THE System SHALL abort requests exceeding the timeout duration
4. WHEN a user configures proxy settings, THE System SHALL route requests through the specified proxy
5. WHEN a user adds client certificates, THE System SHALL use them for matching hosts
6. WHEN workspace settings change, THE System SHALL apply them to subsequent requests

### Requirement 24: Folder Inheritance

**User Story:** As a user, I want folders to inherit authentication and headers, so that I can configure common settings once.

#### Acceptance Criteria

1. WHEN a folder has authentication configured, THE System SHALL apply it to child requests without authentication
2. WHEN a folder has headers configured, THE System SHALL merge them with child request headers
3. WHEN a request explicitly sets authentication, THE System SHALL override folder authentication
4. WHEN resolving inheritance, THE System SHALL traverse from request to root folder to workspace
5. WHEN displaying inherited values, THE System SHALL visually distinguish them from direct values

### Requirement 25: Request Duplication

**User Story:** As a user, I want to duplicate requests and folders, so that I can quickly create similar configurations.

#### Acceptance Criteria

1. WHEN a user duplicates a request, THE System SHALL create a copy with a new unique ID
2. WHEN duplicating, THE System SHALL append " Copy" to the name
3. WHEN duplicating a folder, THE System SHALL recursively duplicate all child items
4. WHEN duplication completes, THE System SHALL select the new item in the sidebar
5. WHEN duplicating, THE System SHALL preserve all configuration including headers, body, and authentication

### Requirement 26: Response Headers and Info

**User Story:** As a user, I want to view detailed response information, so that I can debug API issues.

#### Acceptance Criteria

1. WHEN viewing response headers, THE System SHALL display them as name-value pairs
2. WHEN viewing response info, THE System SHALL show HTTP version, remote address, and URL
3. WHEN a response includes Set-Cookie headers, THE System SHALL display them in the headers tab
4. WHEN viewing response timing, THE System SHALL show elapsed time for headers and total
5. WHEN a response is redirected, THE System SHALL display the final URL

### Requirement 27: Multi-Part Form Data

**User Story:** As a user, I want to send multi-part form data, so that I can upload files in API requests.

#### Acceptance Criteria

1. WHEN a user selects multi-part body type, THE System SHALL display a form editor
2. WHEN a user adds a form field, THE System SHALL support text values and file uploads
3. WHEN a user selects a file, THE System SHALL store the file path and read it during send
4. WHEN sending multi-part data, THE System SHALL set Content-Type with boundary automatically
5. WHEN a file field has a custom filename, THE System SHALL use it in the Content-Disposition header
6. WHEN a field has a custom content-type, THE System SHALL include it in the part headers
7. WHEN a field is disabled, THE System SHALL exclude it from the request

### Requirement 28: URL-Encoded Form Data

**User Story:** As a user, I want to send URL-encoded form data, so that I can test form submission APIs.

#### Acceptance Criteria

1. WHEN a user selects URL-encoded body type, THE System SHALL display a key-value editor
2. WHEN sending URL-encoded data, THE System SHALL set Content-Type to application/x-www-form-urlencoded
3. WHEN a form field is disabled, THE System SHALL exclude it from the request body
4. WHEN form fields contain special characters, THE System SHALL properly URL-encode them
5. WHEN the request method is GET, THE System SHALL append form data as query parameters

### Requirement 29: Binary File Upload

**User Story:** As a user, I want to send binary files as request body, so that I can test file upload endpoints.

#### Acceptance Criteria

1. WHEN a user selects binary body type, THE System SHALL display a file picker
2. WHEN a user selects a file, THE System SHALL store the file path
3. WHEN sending the request, THE System SHALL read the file and send it as the request body
4. WHEN the file does not exist, THE System SHALL display an error message
5. WHEN a user sets a custom Content-Type, THE System SHALL use it instead of auto-detection

### Requirement 30: GraphQL Introspection

**User Story:** As a user, I want GraphQL schema introspection, so that I can explore and autocomplete GraphQL APIs.

#### Acceptance Criteria

1. WHEN a user sends a GraphQL introspection query, THE System SHALL store the schema
2. WHEN editing a GraphQL query, THE System SHALL provide autocomplete based on the schema
3. WHEN the schema is available, THE System SHALL validate queries against it
4. WHEN introspection data is outdated, THE System SHALL allow re-fetching
5. WHEN displaying GraphQL editor, THE System SHALL show query and variables sections

### Requirement 31: Request Description and Documentation

**User Story:** As a user, I want to add descriptions to requests, so that I can document API usage.

#### Acceptance Criteria

1. WHEN a user adds a description, THE System SHALL store it as markdown text
2. WHEN viewing the description tab, THE System SHALL render markdown with formatting
3. WHEN editing description, THE System SHALL provide a markdown editor
4. WHEN description contains links, THE System SHALL make them clickable
5. WHEN description contains code blocks, THE System SHALL apply syntax highlighting

### Requirement 32: Workspace Encryption

**User Story:** As a user, I want to encrypt sensitive workspace data, so that my API credentials are secure.

#### Acceptance Criteria

1. WHEN a user enables encryption for a workspace, THE System SHALL prompt for an encryption key
2. WHEN encryption is enabled, THE System SHALL encrypt authentication data and environment variables
3. WHEN opening an encrypted workspace, THE System SHALL prompt for the encryption key
4. WHEN the encryption key is incorrect, THE System SHALL display an error and prevent access
5. WHEN encryption key is lost, THE System SHALL provide a key recovery mechanism using encryption_key_challenge

### Requirement 33: Settings Management

**User Story:** As a user, I want to configure application settings, so that I can customize the app behavior.

#### Acceptance Criteria

1. WHEN a user changes appearance, THE System SHALL support light, dark, and auto modes
2. WHEN a user changes editor font size, THE System SHALL apply it to all code editors
3. WHEN a user changes interface font size, THE System SHALL apply it to all UI text
4. WHEN a user changes editor keymap, THE System SHALL support default, vim, vscode, and emacs modes
5. WHEN a user enables soft wrap, THE System SHALL wrap long lines in editors
6. WHEN a user changes theme, THE System SHALL apply it immediately without restart
7. WHEN settings change, THE System SHALL persist them to the database

### Requirement 34: Proxy Configuration

**User Story:** As a user, I want to configure HTTP proxy, so that I can test APIs through corporate proxies.

#### Acceptance Criteria

1. WHEN a user enables proxy, THE System SHALL route HTTP and HTTPS requests through specified proxies
2. WHEN proxy requires authentication, THE System SHALL support username and password
3. WHEN a user specifies bypass patterns, THE System SHALL skip proxy for matching hosts
4. WHEN proxy is disabled, THE System SHALL use system proxy settings
5. WHEN proxy connection fails, THE System SHALL display a clear error message

### Requirement 35: Client Certificate Authentication

**User Story:** As a user, I want to use client certificates, so that I can access APIs requiring mutual TLS.

#### Acceptance Criteria

1. WHEN a user adds a client certificate, THE System SHALL store host, port, and certificate paths
2. WHEN sending a request, THE System SHALL match certificates by host and port
3. WHEN a certificate requires a passphrase, THE System SHALL prompt for it
4. WHEN using PFX format, THE System SHALL support pfx_file and passphrase
5. WHEN using PEM format, THE System SHALL support separate crt_file and key_file
6. WHEN a certificate is disabled, THE System SHALL not use it for requests

### Requirement 36: Response Cancellation

**User Story:** As a user, I want to cancel in-flight requests, so that I can stop long-running operations.

#### Acceptance Criteria

1. WHEN a request is executing, THE System SHALL display a cancel button
2. WHEN a user clicks cancel, THE System SHALL abort the network operation
3. WHEN a request is cancelled, THE System SHALL update the response state to "closed"
4. WHEN a request is cancelled, THE System SHALL record the elapsed time up to cancellation
5. WHEN a cancelled request has partial response, THE System SHALL save what was received

### Requirement 37: Recent Responses History

**User Story:** As a user, I want to view previous responses for a request, so that I can compare results over time.

#### Acceptance Criteria

1. WHEN a request is executed, THE System SHALL create a new response record
2. WHEN viewing responses, THE System SHALL display them in reverse chronological order
3. WHEN a user selects a previous response, THE System SHALL display it in the response viewer
4. WHEN responses exceed a limit, THE System SHALL automatically delete the oldest ones
5. WHEN a user clears history, THE System SHALL delete all responses for the request

### Requirement 38: Sidebar Filtering and Search

**User Story:** As a user, I want to filter requests in the sidebar, so that I can quickly find specific requests.

#### Acceptance Criteria

1. WHEN a user types in the filter input, THE System SHALL filter requests by name and URL
2. WHEN filtering, THE System SHALL show matching requests and their parent folders
3. WHEN a filter matches a folder, THE System SHALL show all its children
4. WHEN clearing the filter, THE System SHALL restore the full tree view
5. WHEN no results match, THE System SHALL display "No results" message

### Requirement 39: Drag and Drop Reordering

**User Story:** As a user, I want to drag and drop requests, so that I can organize them efficiently.

#### Acceptance Criteria

1. WHEN a user drags a request, THE System SHALL show a drop indicator
2. WHEN a user drops a request, THE System SHALL update its folder_id and sort_priority
3. WHEN dropping between items, THE System SHALL calculate appropriate sort_priority
4. WHEN dropping into a folder, THE System SHALL set the folder_id
5. WHEN sort priorities conflict, THE System SHALL recalculate all priorities in the folder

### Requirement 40: Context Menu Actions

**User Story:** As a user, I want context menu actions, so that I can quickly perform common operations.

#### Acceptance Criteria

1. WHEN a user right-clicks a request, THE System SHALL display a context menu
2. WHEN the context menu displays, THE System SHALL show Rename, Duplicate, Delete, and Send actions
3. WHEN a user right-clicks a folder, THE System SHALL show Rename, Duplicate, Delete, and Folder Settings actions
4. WHEN a user selects multiple items, THE System SHALL show bulk actions
5. WHEN a user clicks outside the menu, THE System SHALL close it

