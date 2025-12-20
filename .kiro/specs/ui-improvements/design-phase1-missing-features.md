# Design Document - Phase 1 Missing Features

## Overview

This document outlines the technical design for implementing Phase 1 high-priority missing features:

1. **数据导入功能 (Data Import)** - Import API collections from OpenAPI, Postman, Insomnia, Swagger, and cURL
2. **数据导出功能 (Data Export)** - Export workspaces and requests to JSON format
3. **命令面板 (Command Palette)** - Quick access to commands, requests, and workspaces via Ctrl+K
4. **复制为 cURL (Copy as cURL)** - Generate cURL commands from HTTP requests

## Architecture

### High-Level Component Structure

```
Index.ets (Main Page)
├── CommandPalette (Modal Overlay)
│   ├── SearchInput
│   ├── ResultsList
│   │   ├── ActionItem
│   │   ├── RequestItem
│   │   └── WorkspaceItem
│   └── KeyboardHints
├── ImportDialog (Modal)
│   ├── FormatSelector
│   ├── FileDropZone
│   ├── PreviewPane
│   └── ImportSummary
├── ExportDialog (Modal)
│   ├── WorkspaceSelector
│   ├── OptionsPanel
│   └── ExportProgress
└── Services
    ├── ImportService
    │   ├── OpenAPIImporter
    │   ├── PostmanImporter
    │   ├── InsomniaImporter
    │   ├── SwaggerImporter
    │   └── CurlImporter
    ├── ExportService
    └── CurlGenerator
```

### State Management

New state atoms for Phase 1 features:

- `@Local commandPaletteVisible: boolean` - Command palette visibility
- `@Local commandPaletteQuery: string` - Search query in palette
- `@Local commandPaletteResults: CommandResult[]` - Filtered results
- `@Local importDialogVisible: boolean` - Import dialog visibility
- `@Local importFormat: ImportFormat` - Selected import format
- `@Local exportDialogVisible: boolean` - Export dialog visibility
- `@Local selectedExportWorkspaces: string[]` - Workspaces to export



---

## Feature 1: 数据导入功能 (Data Import)

### Components and Interfaces

#### ImportService

**Purpose**: Central service for handling all import operations

```typescript
export class ImportService {
  /**
   * Detect import format from file content
   */
  static detectFormat(content: string): ImportFormat;
  
  /**
   * Import from detected or specified format
   */
  static async import(
    content: string,
    format: ImportFormat,
    workspaceId: string
  ): Promise<ImportResult>;
}

type ImportFormat = 'openapi' | 'postman' | 'insomnia' | 'swagger' | 'curl' | 'yaak';

interface ImportResult {
  success: boolean;
  requestsCreated: number;
  foldersCreated: number;
  environmentsCreated: number;
  errors: ImportError[];
}

interface ImportError {
  path: string;
  message: string;
  recoverable: boolean;
}
```

#### OpenAPIImporter

**Purpose**: Parse OpenAPI 3.0/3.1 specifications

```typescript
export class OpenAPIImporter {
  /**
   * Parse OpenAPI spec and create requests
   */
  static async import(
    spec: OpenAPISpec,
    workspaceId: string
  ): Promise<ImportResult>;
  
  /**
   * Convert OpenAPI operation to HttpRequest
   */
  private static operationToRequest(
    path: string,
    method: string,
    operation: OpenAPIOperation,
    servers: OpenAPIServer[]
  ): HttpRequest;
  
  /**
   * Extract parameters from OpenAPI spec
   */
  private static extractParameters(
    operation: OpenAPIOperation
  ): { headers: HttpHeader[]; queryParams: QueryParam[] };
  
  /**
   * Generate request body from schema
   */
  private static generateBodyFromSchema(
    requestBody: OpenAPIRequestBody
  ): { body: string; bodyType: BodyType };
}
```

#### PostmanImporter

**Purpose**: Parse Postman Collection v2/v2.1 format

```typescript
export class PostmanImporter {
  /**
   * Parse Postman collection and create requests
   */
  static async import(
    collection: PostmanCollection,
    workspaceId: string
  ): Promise<ImportResult>;
  
  /**
   * Convert Postman item to HttpRequest or Folder
   */
  private static itemToRequestOrFolder(
    item: PostmanItem,
    parentFolderId: string | null
  ): HttpRequest | Folder;
  
  /**
   * Convert Postman variables to Environment
   */
  private static variablesToEnvironment(
    variables: PostmanVariable[]
  ): Environment;
}
```

#### CurlImporter

**Purpose**: Parse cURL commands

```typescript
export class CurlImporter {
  /**
   * Parse cURL command string
   */
  static parse(curlCommand: string): HttpRequest;
  
  /**
   * Detect if string is a cURL command
   */
  static isCurlCommand(text: string): boolean;
  
  /**
   * Parse cURL flags and arguments
   */
  private static parseFlags(args: string[]): CurlFlags;
}

interface CurlFlags {
  url: string;
  method: HttpMethod;
  headers: Record<string, string>;
  data: string | null;
  user: string | null;
  insecure: boolean;
}
```

#### ImportDialog Component

**Purpose**: UI for selecting and importing files

```typescript
@ComponentV2
export struct ImportDialog {
  @Param visible: boolean = false;
  @Param onClose: () => void = () => {};
  @Param onImportComplete: (result: ImportResult) => void = () => {};
  
  @Local selectedFormat: ImportFormat = 'openapi';
  @Local fileContent: string = '';
  @Local fileName: string = '';
  @Local isImporting: boolean = false;
  @Local previewData: ImportPreview | null = null;
  @Local importResult: ImportResult | null = null;
}
```

### Data Models

#### ImportPreview

```typescript
interface ImportPreview {
  format: ImportFormat;
  requestCount: number;
  folderCount: number;
  environmentCount: number;
  items: ImportPreviewItem[];
}

interface ImportPreviewItem {
  type: 'request' | 'folder' | 'environment';
  name: string;
  method?: HttpMethod;
  url?: string;
  children?: ImportPreviewItem[];
}
```



---

## Feature 2: 数据导出功能 (Data Export)

### Components and Interfaces

#### ExportService

**Purpose**: Export workspaces and requests to various formats

```typescript
export class ExportService {
  /**
   * Export workspace to Yaak JSON format
   */
  static async exportWorkspace(
    workspaceId: string,
    options: ExportOptions
  ): Promise<ExportResult>;
  
  /**
   * Export multiple workspaces
   */
  static async exportWorkspaces(
    workspaceIds: string[],
    options: ExportOptions
  ): Promise<ExportResult>;
  
  /**
   * Generate export data structure
   */
  private static buildExportData(
    workspace: Workspace,
    requests: HttpRequest[],
    folders: Folder[],
    environments: Environment[],
    options: ExportOptions
  ): YaakExportData;
}

interface ExportOptions {
  includePrivateEnvironments: boolean;
  includeResponses: boolean;
  prettify: boolean;
}

interface ExportResult {
  success: boolean;
  filePath: string;
  fileSize: number;
  workspacesExported: number;
  requestsExported: number;
  error?: string;
}
```

#### YaakExportData

```typescript
interface YaakExportData {
  version: string;
  exportedAt: number;
  workspaces: WorkspaceExport[];
}

interface WorkspaceExport {
  workspace: Workspace;
  folders: Folder[];
  requests: HttpRequest[];
  environments: Environment[];
  cookieJar?: CookieJar;
}
```

#### ExportDialog Component

```typescript
@ComponentV2
export struct ExportDialog {
  @Param visible: boolean = false;
  @Param workspaces: Workspace[] = [];
  @Param onClose: () => void = () => {};
  @Param onExportComplete: (result: ExportResult) => void = () => {};
  
  @Local selectedWorkspaceIds: string[] = [];
  @Local includePrivateEnvs: boolean = false;
  @Local isExporting: boolean = false;
  @Local exportResult: ExportResult | null = null;
}
```

---

## Feature 3: 命令面板 (Command Palette)

### Components and Interfaces

#### CommandPalette Component

**Purpose**: Quick access modal for commands and navigation

```typescript
@ComponentV2
export struct CommandPalette {
  @Param visible: boolean = false;
  @Param onClose: () => void = () => {};
  @Param onAction: (action: CommandAction) => void = () => {};
  
  @Local query: string = '';
  @Local results: CommandResult[] = [];
  @Local selectedIndex: number = 0;
  @Local isLoading: boolean = false;
}
```

#### CommandService

**Purpose**: Manage available commands and search

```typescript
export class CommandService {
  /**
   * Get all available commands
   */
  static getCommands(): Command[];
  
  /**
   * Search commands, requests, and workspaces
   */
  static async search(
    query: string,
    context: SearchContext
  ): Promise<CommandResult[]>;
  
  /**
   * Fuzzy match algorithm
   */
  private static fuzzyMatch(query: string, text: string): FuzzyMatchResult;
  
  /**
   * Execute command action
   */
  static executeCommand(command: Command): void;
}

interface Command {
  id: string;
  label: string;
  category: CommandCategory;
  shortcut?: string;
  icon?: string;
  action: () => void;
}

type CommandCategory = 'action' | 'request' | 'environment' | 'workspace' | 'navigation';

interface CommandResult {
  type: CommandCategory;
  id: string;
  label: string;
  description?: string;
  shortcut?: string;
  icon?: string;
  score: number;
}

interface SearchContext {
  workspaces: Workspace[];
  requests: HttpRequest[];
  environments: Environment[];
  currentWorkspaceId: string;
}

interface FuzzyMatchResult {
  matched: boolean;
  score: number;
  highlights: number[];
}
```

### Built-in Commands

```typescript
const BUILT_IN_COMMANDS: Command[] = [
  { id: 'new-request', label: 'New HTTP Request', category: 'action', shortcut: 'Ctrl+N' },
  { id: 'new-folder', label: 'New Folder', category: 'action' },
  { id: 'new-workspace', label: 'New Workspace', category: 'action' },
  { id: 'import', label: 'Import...', category: 'action', shortcut: 'Ctrl+I' },
  { id: 'export', label: 'Export...', category: 'action', shortcut: 'Ctrl+E' },
  { id: 'settings', label: 'Settings', category: 'action', shortcut: 'Ctrl+,' },
  { id: 'send-request', label: 'Send Request', category: 'action', shortcut: 'Ctrl+Enter' },
  { id: 'duplicate-request', label: 'Duplicate Request', category: 'action', shortcut: 'Ctrl+D' },
  { id: 'toggle-sidebar', label: 'Toggle Sidebar', category: 'action', shortcut: 'Ctrl+B' },
  { id: 'focus-url', label: 'Focus URL Bar', category: 'action', shortcut: 'Ctrl+L' },
];
```



---

## Feature 4: 复制为 cURL (Copy as cURL)

### Components and Interfaces

#### CurlGenerator

**Purpose**: Generate cURL commands from HTTP requests

```typescript
export class CurlGenerator {
  /**
   * Generate cURL command from HttpRequest
   */
  static generate(
    request: HttpRequest,
    variables: Map<string, string>,
    options?: CurlGeneratorOptions
  ): string;
  
  /**
   * Resolve template variables in request
   */
  private static resolveVariables(
    request: HttpRequest,
    variables: Map<string, string>
  ): ResolvedRequest;
  
  /**
   * Build cURL flags from request
   */
  private static buildFlags(request: ResolvedRequest): string[];
  
  /**
   * Escape shell special characters
   */
  private static escapeShell(value: string): string;
  
  /**
   * Format for readability (multi-line)
   */
  private static formatMultiLine(command: string): string;
}

interface CurlGeneratorOptions {
  multiLine: boolean;
  includeComments: boolean;
  shellType: 'bash' | 'cmd' | 'powershell';
}

interface ResolvedRequest {
  url: string;
  method: HttpMethod;
  headers: Record<string, string>;
  body: string | null;
  bodyType: BodyType;
}
```

#### Copy as cURL Integration

```typescript
// In RequestContextMenu or RequestEditorComponent
private async copyAsCurl(): Promise<void> {
  const variables = EnvironmentService.mergeVariables(this.environments);
  const curlCommand = CurlGenerator.generate(this.request, variables, {
    multiLine: true,
    includeComments: false,
    shellType: 'bash'
  });
  
  await pasteboard.setData(pasteboard.createData(pasteboard.MIMETYPE_TEXT_PLAIN, curlCommand));
  promptAction.showToast({ message: 'Copied as cURL' });
}
```

---

## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: cURL Round-Trip Consistency
*For any* valid HttpRequest, generating a cURL command and then parsing it back should produce an equivalent request (same URL, method, headers, and body).
**Validates: Requirements 10.6, 16.1, 16.2**

### Property 2: OpenAPI Import Completeness
*For any* valid OpenAPI 3.0/3.1 specification, importing should create exactly one HttpRequest for each path+method combination defined in the spec.
**Validates: Requirements 10.2**

### Property 3: Postman Import Structure Preservation
*For any* valid Postman Collection v2/v2.1, importing should preserve the folder hierarchy such that the depth and parent-child relationships match the original collection.
**Validates: Requirements 10.3**

### Property 4: Export-Import Round-Trip
*For any* workspace with requests, folders, and environments, exporting to Yaak JSON format and then importing should produce an identical workspace structure.
**Validates: Requirements 11.4, 11.5, 11.6**

### Property 5: Fuzzy Search Relevance
*For any* search query and set of items, the fuzzy search results should be ordered by relevance score, with exact matches scoring higher than partial matches.
**Validates: Requirements 12.3, 12.4**

### Property 6: cURL Variable Resolution
*For any* HttpRequest containing template variables, the generated cURL command should have all variables resolved to their actual values from the active environment.
**Validates: Requirements 16.3**



---

## Error Handling

### Import Errors

**Scenario**: Invalid file format
- **Detection**: JSON parse error or schema validation failure
- **Recovery**: Show error message with format hints
- **User Feedback**: "Invalid file format. Please select a valid OpenAPI/Postman/Insomnia file."

**Scenario**: Partial import failure
- **Detection**: Some items fail to import while others succeed
- **Recovery**: Import successful items, collect errors
- **User Feedback**: Show summary with success count and error list

**Scenario**: File too large
- **Detection**: File size > 10MB
- **Recovery**: Show warning, allow user to proceed
- **User Feedback**: "Large file detected. Import may take longer."

### Export Errors

**Scenario**: File write failure
- **Detection**: File system error during save
- **Recovery**: Retry with different location
- **User Feedback**: "Failed to save file. Please choose a different location."

**Scenario**: No workspaces selected
- **Detection**: Empty selection
- **Recovery**: Disable export button
- **User Feedback**: "Please select at least one workspace to export."

### Command Palette Errors

**Scenario**: Command execution failure
- **Detection**: Exception during action execution
- **Recovery**: Show error toast, keep palette open
- **User Feedback**: "Failed to execute command: [error message]"

### cURL Generation Errors

**Scenario**: Unresolved variables
- **Detection**: Template variables without values
- **Recovery**: Include unresolved variables as-is with warning
- **User Feedback**: "Warning: Some variables could not be resolved."

---

## Testing Strategy

### Unit Tests

**ImportService Tests**:
- Test format detection for each supported format
- Test parsing of valid and invalid files
- Test error handling for malformed input

**CurlImporter Tests**:
- Test parsing of various cURL flag combinations
- Test URL extraction with query parameters
- Test header parsing (-H flag)
- Test body parsing (-d, --data flags)
- Test authentication parsing (-u flag)

**CurlGenerator Tests**:
- Test generation with all HTTP methods
- Test header escaping
- Test body formatting for different content types
- Test multi-line formatting

**CommandService Tests**:
- Test fuzzy matching algorithm
- Test result sorting by relevance
- Test category grouping

### Property-Based Tests

**cURL Round-Trip Test**:
```typescript
// Property 1: cURL Round-Trip Consistency
it('should round-trip cURL commands', () => {
  fc.assert(fc.property(
    arbitraryHttpRequest(),
    (request) => {
      const curl = CurlGenerator.generate(request, new Map());
      const parsed = CurlImporter.parse(curl);
      return requestsAreEquivalent(request, parsed);
    }
  ));
});
```

**Export-Import Round-Trip Test**:
```typescript
// Property 4: Export-Import Round-Trip
it('should round-trip workspace export/import', () => {
  fc.assert(fc.property(
    arbitraryWorkspace(),
    async (workspace) => {
      const exported = await ExportService.exportWorkspace(workspace.id, {});
      const imported = await ImportService.import(exported.data, 'yaak', 'new-workspace');
      return workspacesAreEquivalent(workspace, imported);
    }
  ));
});
```

### Integration Tests

**Import Flow**:
1. Open import dialog
2. Select file format
3. Upload/paste file content
4. Preview import items
5. Confirm import
6. Verify items created in database
7. Verify items appear in sidebar

**Export Flow**:
1. Open export dialog
2. Select workspaces
3. Configure options
4. Execute export
5. Verify file created
6. Verify file content matches workspace data

**Command Palette Flow**:
1. Press Ctrl+K
2. Verify palette opens
3. Type search query
4. Verify results update
5. Navigate with arrow keys
6. Press Enter to execute
7. Verify action executed

---

## Performance Considerations

### Import Performance

- **Large files**: Stream parsing for files > 1MB
- **Many items**: Batch database inserts (100 items per transaction)
- **Progress feedback**: Show progress bar for imports > 50 items

### Command Palette Performance

- **Search debouncing**: 150ms debounce on input
- **Result limiting**: Show max 50 results
- **Lazy loading**: Load request details on demand
- **Caching**: Cache search index, invalidate on data change

### cURL Generation Performance

- **Variable resolution**: Cache resolved variables per request
- **Clipboard operation**: Use async clipboard API

---

## Security Considerations

### Import Security

- **File validation**: Validate file content before parsing
- **Size limits**: Reject files > 50MB
- **Sanitization**: Sanitize imported URLs and headers
- **No code execution**: Never execute imported scripts

### Export Security

- **Sensitive data**: Warn before exporting environments with secrets
- **File permissions**: Use app sandbox for file operations

### cURL Security

- **Credential handling**: Mask passwords in generated commands (optional)
- **Shell escaping**: Properly escape all values to prevent injection

