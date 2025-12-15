# Yaak HarmonyOS App Design Document

This document outlines the architecture, layout, and logic for the HarmonyOS port of the Yaak API Client, based on the original Tauri application structure.

## 1. Application Layout

The application uses a **3-pane layout**, adjustable via splitters (resizable handles).

```
+------------------+-----------------------------------------+-----------------------------------------+
|     Sidebar      |              Request Pane               |              Response Pane              |
|                  |                                         |                                         |
| [Filter Input  ] | [ Method ] [ URL Input       ] [ Send ] | [ Status ] [ Time ] [ Size ] [ Menu ]   |
|                  |                                         |                                         |
| - Folder 1       | [ Params | Auth | Headers | Body ]      | [ Preview | Headers | Info ]            |
|   - Request A    |                                         |                                         |
| - Request B      |  (Tab Content Area)                     |  (Response Content Area)                |
|                  |   - Key/Value Tables                    |   - JSON/XML Highlighter                |
|                  |   - JSON Editor                         |   - Image Viewer                        |
|                  |                                         |                                         |
+------------------+-----------------------------------------+-----------------------------------------+
```

### 1.1 Sidebar (Left Pane)
**Goal**: Navigate Workspaces, Folders, and Requests.
- **Header**:
  - Filter Input: Searches requests by name/URL.
  - Actions: "New Request", "New Folder" buttons.
- **Content**:
  - **Tree View**:
    - **Folders**: Expandable/Collapsible.
    - **Requests**: Displays HTTP Method (color-coded) and Name.
    - **Active State**: Highlight selected item.
  - **Context Menu**:
    - Rename, Duplicate, Delete, Move.
    - Create New Request/Folder inside.

### 1.2 Request Pane (Middle Pane)
**Goal**: Compose and Send HTTP Requests.
- **URL Bar**:
  - **Method Selector**: Dropdown (GET, POST, PUT, DELETE, PATCH, HEAD, OPTIONS).
  - **URL Input**: Text input for endpoint URL.
  - **Send Button**: Executes the request.
- **Tabs**:
  - **Params**: Query string parameters (Key-Value Editor).
  - **Auth**: Authentication configuration (No Auth, Basic Auth, Bearer Token).
  - **Headers**: Request headers (Key-Value Editor).
  - **Body**: Request body configuration.
    - Sub-types: None, JSON, Form-Data, x-www-form-urlencoded, Binary, XML.

### 1.3 Response Pane (Right Pane)
**Goal**: View Response Data.
- **Empty State**: Guide text or shortcuts when no response.
- **Loading State**: Spinner and "Cancel" button during execution.
- **Header (Status Bar)**:
  - Status Code (e.g., "200 OK" in green).
  - Duration (e.g., "150ms").
  - Size (e.g., "2.5KB").
- **Tabs**:
  - **Preview**: Rendered response body.
    - **Pretty**: Formatted JSON/XML.
    - **Raw**: Raw text.
    - **Visual**: Image/Audio/Video viewers if applicable.
  - **Headers**: List of response headers.
  - **Info**: Connection details (optional).

## 2. Core Logic & State Management

### 2.1 State Management (ArkTS `ComponentV2`)
The app uses `@ObservedV2` classes for deep reactivity and minimal re-renders.

- **`Workspace`**: Root container.
- **`HttpRequest`**: Mutable request object.
  - Properties: `url`, `method`, `headers`, `body`, `params`, `auth`.
- **`HttpResponse`**: Immutable response object (persisted).
  - Properties: `status`, `bodyPath`, `headers`, `elapsed`, `contentLength`.
- **`Environment`**: Variable store (`{{ host }}`).

### 2.2 Data Persistence (SQLite/RDB)
- **Tables**: `workspaces`, `folders`, `http_requests`, `http_responses`, `environments`.
- **Sync**: Changes to `HttpRequest` are auto-saved (debounced) to DB.

### 2.3 Network Layer
- **Executor**: Uses `rcp` (Remote Communication Kit) or `http` module.
- **Variable Substitution**: Pre-flight pass to replace `{{ var }}` in URL/Headers/Body.

## 3. UI Components Specification

### 3.1 `Index.ets` (Main Layout)
- **Structure**: `Row` container with 3 `Column` children (Sidebar, Request, Response).
- **Resizing**: Implements `Divider` with touch gesture handling to adjust widths.

### 3.2 `SidebarComponent`
- **Props**: `items` (Tree Data), `selectedRequest`.
- **Interaction**:
  - Click Request -> Select.
  - Click Folder -> Toggle Expand.
  - Right Click/Long Press -> Show `Menu`.

### 3.3 `RequestEditorComponent`
- **Components**:
  - `UrlBarComponent`: Method + URL + Send.
  - `RequestTabsComponent`: TabController for switching views.
  - `KeyValueTableComponent`: Reusable generic Key-Value editor (for Params/Headers).
  - `BodyEditorComponent`: Multi-mode editor (JSON/Form).

### 3.4 `ResponseViewerComponent`
- **Components**:
  - `ResponseStatusBarComponent`.
  - `ResponseTabsComponent`.
  - `CodeHighlighterComponent`: For pretty-printing JSON.

## 4. Implementation Steps

1.  **Models Update**: Ensure `HttpRequest` supports `params` (Query Params) separate from URL.
2.  **UI Refactor**:
    - Update `Index.ets` to new 3-pane responsive design.
    - Implement `KeyValueTable` with "Enabled" checkbox and "Delete" button.
    - Implement `UrlBar` with Method styling.
    - Implement `ResponseStatusBar` with styling.
3.  **Business Logic**:
    - Wire up "Send" to execute request and populate `HttpResponse` object.
    - Wire up "Params" to auto-update URL query string.

