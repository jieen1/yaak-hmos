# Design Document - Text to ThemedText Migration

## Overview

This design outlines the systematic approach to migrating all native `Text()` components to `ThemedText()` components throughout the Flare HarmonyOS application. The migration will be performed in phases, with each phase focusing on a logical group of components to minimize risk and enable incremental testing.

## Architecture

### Migration Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Migration Process                         │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Analyze Component                                        │
│     ├─ Identify all Text() usage                           │
│     ├─ Categorize by type (interface/editor)               │
│     └─ Document current styling                            │
│                                                              │
│  2. Transform Syntax                                         │
│     ├─ Replace Text() with ThemedText()                    │
│     ├─ Convert properties to parameters                    │
│     ├─ Set appropriate fontType                            │
│     └─ Preserve all styling                                │
│                                                              │
│  3. Update Imports                                           │
│     ├─ Add ThemedText import                               │
│     └─ Clean up unused imports                             │
│                                                              │
│  4. Verify                                                   │
│     ├─ Compile and check for errors                        │
│     ├─ Visual inspection                                    │
│     └─ Test font changes                                    │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### Migration Patterns

#### Pattern 1: Simple Text (No Styling)

**Before:**
```typescript
Text('Hello World')
```

**After:**
```typescript
ThemedText({
  content: 'Hello World'
})
```

#### Pattern 2: Text with Font Size

**Before:**
```typescript
Text('Title')
  .fontSize(20)
  .fontColor($r('app.color.text_primary'))
```

**After:**
```typescript
ThemedText({
  content: 'Title',
  fontSizeOverride: 20,
  fontColor: $r('app.color.text_primary')
})
```

#### Pattern 3: Text with Multiple Properties

**Before:**
```typescript
Text('Description')
  .fontSize($r('app.float.font_size_sm'))
  .fontColor($r('app.color.text_secondary'))
  .maxLines(2)
  .textOverflow({ overflow: TextOverflow.Ellipsis })
```

**After:**
```typescript
ThemedText({
  content: 'Description',
  fontColor: $r('app.color.text_secondary'),
  maxLines: 2,
  textOverflow: TextOverflow.Ellipsis
})
```

Note: fontSize removed because we want to use global setting

#### Pattern 4: Editor/Code Text

**Before:**
```typescript
Text('const x = 10;')
  .fontSize(14)
  .fontFamily('monospace')
```

**After:**
```typescript
ThemedText({
  content: 'const x = 10;',
  fontType: 'editor'
})
```

#### Pattern 5: Dynamic Text

**Before:**
```typescript
Text(`Status: ${this.status}`)
  .fontSize($r('app.float.font_size_md'))
```

**After:**
```typescript
ThemedText({
  content: `Status: ${this.status}`
})
```

#### Pattern 6: Resource String

**Before:**
```typescript
Text($r('app.string.welcome'))
  .fontSize(16)
```

**After:**
```typescript
ThemedText({
  content: $r('app.string.welcome'),
  fontSizeOverride: 16
})
```

## Data Models

### Migration Tracking

```typescript
interface MigrationRecord {
  componentPath: string;
  textInstancesFound: number;
  textInstancesMigrated: number;
  fontType: 'interface' | 'editor' | 'mixed';
  status: 'pending' | 'in-progress' | 'completed' | 'verified';
  notes: string;
}
```

### Component Categories

```typescript
enum ComponentCategory {
  DIALOG = 'dialog',
  VIEWER = 'viewer',
  MAIN = 'main',
  AUTH = 'auth',
  UTILITY = 'utility'
}

interface ComponentGroup {
  category: ComponentCategory;
  priority: number;
  components: string[];
  estimatedTextCount: number;
}
```

## Correctness Properties

### Property 1: Complete Migration
*For any* component file in the codebase (excluding ThemedText.ets itself), after migration is complete, searching for `Text(` should return zero matches for component instantiation
**Validates: Requirements 1.5**

### Property 2: Property Preservation
*For any* migrated Text component, all original styling properties (fontSize, fontColor, fontWeight, maxLines, textOverflow) should be preserved in the ThemedText equivalent
**Validates: Requirements 4.1, 4.2, 4.3, 4.4, 4.5**

### Property 3: Font Type Consistency
*For any* UI element (button, label, dialog header), the fontType should be 'interface', and for any code/data display element, the fontType should be 'editor'
**Validates: Requirements 2.1, 2.2, 2.3, 3.1, 3.2, 3.3**

### Property 4: Import Correctness
*For any* component file using ThemedText, the import statement `import { ThemedText } from './index'` or equivalent should be present
**Validates: Requirements 8.1, 8.2**

### Property 5: Compilation Success
*For any* migrated component, running the ArkTS compiler should produce zero errors related to Text/ThemedText usage
**Validates: Requirements 9.1**

### Property 6: Visual Consistency
*For any* migrated component, the visual appearance with default font settings should be identical to the pre-migration appearance
**Validates: Requirements 1.4, 9.2**

### Property 7: Reactive Updates
*For any* ThemedText component, when FontSettings.interfaceFont or FontSettings.editorFont changes, the component should automatically re-render with the new font
**Validates: Requirements 9.3**

## Error Handling

### Compilation Errors

1. **Missing Import**: If ThemedText is used without import
   - **Detection**: Compilation error "Cannot find name 'ThemedText'"
   - **Resolution**: Add `import { ThemedText } from './index'` or `import { ThemedText } from '../components'`

2. **Invalid Parameter**: If parameter name is incorrect
   - **Detection**: Compilation error about unknown parameter
   - **Resolution**: Check parameter names match ThemedText interface (content, fontType, fontSizeOverride, etc.)

3. **Type Mismatch**: If parameter type is wrong
   - **Detection**: Type error from ArkTS compiler
   - **Resolution**: Ensure content is ResourceStr, fontType is 'interface'|'editor', etc.

### Runtime Errors

1. **Undefined Content**: If content parameter is undefined
   - **Detection**: Empty text display
   - **Resolution**: Provide default value or conditional rendering

2. **Invalid Font Type**: If fontType is neither 'interface' nor 'editor'
   - **Detection**: Falls back to 'interface' (default)
   - **Resolution**: Use correct fontType value

### Visual Regressions

1. **Layout Shift**: If text size changes unexpectedly
   - **Detection**: Visual inspection
   - **Resolution**: Use fontSizeOverride to maintain specific sizes

2. **Font Mismatch**: If wrong font type is used
   - **Detection**: Monospace font in UI or proportional font in code
   - **Resolution**: Correct fontType parameter

## Testing Strategy

### Unit Testing

Not applicable for this migration - focus is on integration and visual testing.

### Integration Testing

1. **Compilation Test**: Verify all components compile without errors
2. **Import Test**: Verify all ThemedText imports are correct
3. **Font Change Test**: Change font settings and verify all text updates

### Visual Testing

1. **Baseline Comparison**: Compare screenshots before and after migration
2. **Font Settings Test**: Test with different font combinations
3. **Edge Cases**: Test with very long text, empty text, special characters

### Manual Testing Checklist

For each migrated component:
- [ ] Component compiles without errors
- [ ] Text displays correctly with default fonts
- [ ] Changing interface font updates UI text
- [ ] Changing editor font updates code/data text
- [ ] Text wrapping and overflow work correctly
- [ ] Colors and weights are preserved
- [ ] No layout shifts or visual regressions

## Implementation Plan

### Phase 1: Dialog Components (Priority 1)

**Components:**
1. SettingsDialog.ets (~15 instances)
2. WorkspaceManagementDialog.ets (~8 instances)
3. WorkspaceSettingsDialog.ets (~5 instances)
4. FolderSettingsDialog.ets (~4 instances)

**Rationale:** Dialogs are self-contained and have clear UI text, making them ideal for initial migration.

**Font Type:** All interface (UI elements)

### Phase 2: Viewer Components (Priority 2)

**Components:**
1. ResponseViewerComponent.ets (~20 instances - mixed)
2. ResponseInfoTab.ets (~4 instances - interface)
3. ImageViewer.ets (~1 instance - interface)
4. TextViewer.ets (special case - already uses FontSettings)

**Rationale:** Viewers contain both UI text and data display, requiring careful categorization.

**Font Type:** Mixed (UI labels = interface, data content = editor)

### Phase 3: Main Components (Priority 3)

**Components:**
1. Index.ets (~2 instances - interface)
2. RequestEditorComponent.ets (~1 instance - interface)
3. SidebarComponent.ets (~1 instance - interface)
4. WorkspaceHeader.ets (~1 instance - interface)

**Rationale:** Core application components, migrate after dialogs and viewers are stable.

**Font Type:** All interface

### Phase 4: Authentication Components (Priority 4)

**Components:**
1. LoginComponent.ets (~8 instances - interface)

**Rationale:** Login screen is critical but isolated, migrate last to minimize risk.

**Font Type:** All interface

## Special Cases

### TextViewer Component

**Current Implementation:**
```typescript
Text(this.formatText())
  .fontFamily(this.fontSettings.editorFont)
  .fontSize(this.fontSettings.editorFontSize)
```

**Decision:** Keep as-is. TextViewer already uses FontSettings directly and will automatically respond to font changes. No migration needed.

**Rationale:** TextViewer is a specialized component that needs direct access to FontSettings for performance reasons (large text rendering).

### Empty Text Handling

**Pattern:**
```typescript
// Before
Text(this.message || '')

// After
ThemedText({
  content: this.message || ''
})
```

### Conditional Text

**Pattern:**
```typescript
// Before
if (this.showMessage) {
  Text(this.message)
}

// After
if (this.showMessage) {
  ThemedText({
    content: this.message
  })
}
```

### Text in Buttons

**Pattern:**
```typescript
// Before
Button() {
  Text('Click Me')
}

// After
Button() {
  ThemedText({
    content: 'Click Me'
  })
}
```

## Migration Checklist Template

For each component:

```markdown
## Component: [ComponentName].ets

### Analysis
- [ ] Total Text instances found: __
- [ ] Interface text count: __
- [ ] Editor text count: __
- [ ] Special cases identified: __

### Migration
- [ ] Added ThemedText import
- [ ] Migrated all Text instances
- [ ] Set correct fontType for each
- [ ] Preserved all styling properties
- [ ] Removed unused imports

### Verification
- [ ] Compilation successful
- [ ] Visual inspection passed
- [ ] Font change test passed
- [ ] No regressions detected

### Notes
[Any special considerations or issues]
```

## Performance Considerations

1. **FontSettings Singleton**: Single instance shared across all components - minimal memory overhead
2. **@Trace Reactivity**: Efficient change detection - only re-renders when font actually changes
3. **Component Count**: ~70 Text instances becoming ThemedText - negligible performance impact
4. **Rendering**: ThemedText is a thin wrapper - no additional rendering overhead

## Rollback Plan

If critical issues are discovered:

1. **Git Revert**: Each phase is committed separately, allowing selective rollback
2. **Component-Level**: Individual components can be reverted while keeping others
3. **Feature Flag**: Could add a flag to disable ThemedText and fall back to Text (not recommended)

## Success Metrics

1. **Coverage**: 100% of Text components migrated (except ThemedText.ets and TextViewer.ets)
2. **Errors**: Zero compilation errors
3. **Regressions**: Zero visual regressions
4. **Performance**: No measurable performance degradation
5. **Functionality**: Font settings work for all text elements

## Documentation Deliverables

1. **Migration Log**: Record of all migrated components with before/after examples
2. **Updated Coding Guidelines**: Add rule to use ThemedText instead of Text
3. **Component Catalog**: List of all components using ThemedText with their fontType
4. **Troubleshooting Guide**: Common issues and solutions during migration
