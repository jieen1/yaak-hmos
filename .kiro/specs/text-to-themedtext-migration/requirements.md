# Requirements Document - Text to ThemedText Migration

## Introduction

This specification defines the requirements for migrating all native `Text()` components to the new `ThemedText()` component throughout the Flare HarmonyOS application. This migration will enable global interface font control, allowing users to customize UI text fonts from settings.

**Note:** Editor fonts are already implemented in ThemedTextInput and other editor components. This migration focuses on **interface fonts only** (UI labels, buttons, dialogs, status messages, etc.).

## Glossary

- **Text Component**: The native HarmonyOS ArkUI text display component
- **ThemedText Component**: Custom wrapper component that applies global font settings automatically
- **FontSettings**: Singleton service managing global font configuration using `@ObservedV2` and `@Trace` decorators
- **Interface Font**: Font used for UI elements (buttons, labels, menus, dialogs)
- **Editor Font**: Font used for code/data display (JSON, XML, request/response bodies)
- **Font Override**: Local font size specification that takes precedence over global settings

## Requirements

### Requirement 1: Component Migration Strategy

**User Story:** As a developer, I want a systematic approach to migrate all Text components, so that the migration is complete, consistent, and maintainable.

#### Acceptance Criteria

1. WHEN analyzing the codebase THEN the system SHALL identify all Text component usage locations
2. WHEN categorizing Text components THEN the system SHALL classify each by type (interface vs editor content)
3. WHEN migrating components THEN the system SHALL preserve all existing styling properties
4. WHEN migrating components THEN the system SHALL maintain existing functionality without regression
5. WHEN migration is complete THEN the system SHALL have zero remaining native Text components (except in ThemedText itself)

### Requirement 2: Interface Text Migration

**User Story:** As a user, I want all UI text elements to use the interface font setting, so that I can customize the application's appearance consistently.

#### Acceptance Criteria

1. WHEN migrating dialog headers THEN the system SHALL use ThemedText with fontType='interface'
2. WHEN migrating button labels THEN the system SHALL use ThemedText with fontType='interface'
3. WHEN migrating menu items THEN the system SHALL use ThemedText with fontType='interface'
4. WHEN migrating status messages THEN the system SHALL use ThemedText with fontType='interface'
5. WHEN migrating form labels THEN the system SHALL use ThemedText with fontType='interface'
6. WHEN preserving visual hierarchy THEN the system SHALL use fontSizeOverride for titles and headings

### Requirement 3: Property Preservation

**User Story:** As a developer, I want all existing text styling to be preserved during migration, so that the visual appearance remains unchanged.

#### Acceptance Criteria

1. WHEN migrating Text with fontSize THEN the system SHALL convert to fontSizeOverride parameter
2. WHEN migrating Text with fontColor THEN the system SHALL convert to fontColor parameter
3. WHEN migrating Text with fontWeight THEN the system SHALL convert to fontWeight parameter
4. WHEN migrating Text with maxLines THEN the system SHALL convert to maxLines parameter
5. WHEN migrating Text with textOverflow THEN the system SHALL convert to textOverflow parameter
6. WHEN migrating Text with other modifiers THEN the system SHALL preserve them as component modifiers

### Requirement 4: Component-by-Component Migration

**User Story:** As a developer, I want to migrate components in logical groups, so that I can test incrementally and minimize risk.

#### Acceptance Criteria

1. WHEN migrating dialog components THEN the system SHALL complete all dialogs before moving to next group
2. WHEN migrating viewer components THEN the system SHALL complete all viewers before moving to next group
3. WHEN migrating each component THEN the system SHALL verify compilation succeeds
4. WHEN migrating each component THEN the system SHALL verify no visual regressions occur
5. WHEN completing each group THEN the system SHALL document the changes made

### Requirement 5: Special Cases Handling

**User Story:** As a developer, I want special text cases handled correctly, so that edge cases don't break the application.

#### Acceptance Criteria

1. WHEN encountering empty text THEN the system SHALL handle empty strings gracefully
2. WHEN encountering dynamic text THEN the system SHALL preserve template expressions
3. WHEN encountering resource strings THEN the system SHALL preserve $r() references
4. WHEN encountering conditional text THEN the system SHALL preserve conditional logic
5. WHEN encountering text with complex styling THEN the system SHALL maintain all style chains

### Requirement 6: TextViewer and Editor Components Special Handling

**User Story:** As a developer, I want editor components handled specially, so that they continue to work with their existing font implementations.

#### Acceptance Criteria

1. WHEN analyzing TextViewer THEN the system SHALL recognize it already uses FontSettings
2. WHEN analyzing ThemedTextInput THEN the system SHALL recognize it already implements editor fonts
3. WHEN migrating THEN the system SHALL skip all editor components (TextViewer, ThemedTextInput, etc.)
4. WHEN documenting migration THEN the system SHALL note editor components as special cases
5. WHEN testing THEN the system SHALL verify editor components still work correctly

### Requirement 7: Import Statement Management

**User Story:** As a developer, I want import statements managed correctly, so that all components have proper dependencies.

#### Acceptance Criteria

1. WHEN migrating a component THEN the system SHALL add ThemedText import if not present
2. WHEN adding imports THEN the system SHALL use the components index export
3. WHEN removing unused imports THEN the system SHALL clean up if Text is no longer used
4. WHEN organizing imports THEN the system SHALL maintain alphabetical order
5. WHEN completing migration THEN the system SHALL verify all imports are correct

### Requirement 8: Testing and Verification

**User Story:** As a developer, I want comprehensive testing after migration, so that I can ensure nothing is broken.

#### Acceptance Criteria

1. WHEN migration is complete THEN the system SHALL compile without errors
2. WHEN testing UI THEN the system SHALL display all text correctly
3. WHEN changing font settings THEN the system SHALL update all text automatically
4. WHEN testing edge cases THEN the system SHALL handle empty and long text correctly
5. WHEN testing performance THEN the system SHALL maintain acceptable rendering speed

### Requirement 9: Documentation Updates

**User Story:** As a developer, I want migration documentation, so that future developers understand the changes.

#### Acceptance Criteria

1. WHEN migration is complete THEN the system SHALL document all migrated components
2. WHEN documenting THEN the system SHALL list components by category
3. WHEN documenting THEN the system SHALL note any special cases or exceptions
4. WHEN documenting THEN the system SHALL provide before/after examples
5. WHEN documenting THEN the system SHALL update coding guidelines to use ThemedText

## Migration Scope

Based on codebase analysis, the following components contain Text usage for **interface elements**:

**Note:** Editor components (TextViewer, ThemedTextInput, etc.) already implement editor fonts and are excluded from this migration.

### Dialog Components (Priority 1)
- SettingsDialog.ets (~15 Text instances)
- WorkspaceManagementDialog.ets (~8 Text instances)
- WorkspaceSettingsDialog.ets (~5 Text instances)
- FolderSettingsDialog.ets (~4 Text instances)

### Viewer Components (Priority 2)
- ResponseViewerComponent.ets (~20 Text instances - **interface labels only**)
- ResponseInfoTab.ets (~4 Text instances - interface)
- ImageViewer.ets (~1 Text instance - interface)
- ~~TextViewer.ets~~ (excluded - already uses FontSettings for editor font)

### Main Components (Priority 3)
- Index.ets (~2 Text instances)
- RequestEditorComponent.ets (~1 Text instance)
- SidebarComponent.ets (~1 Text instance)
- WorkspaceHeader.ets (~1 Text instance)

### Authentication Components (Priority 4)
- LoginComponent.ets (~8 Text instances)

### Total Estimated Interface Text Components: ~65 instances

**Excluded from migration:**
- TextViewer.ets - already uses FontSettings.editorFont directly
- ThemedTextInput.ets - already implements editor font
- Other editor components - already have font support

## Success Criteria

1. All Text components replaced with ThemedText (except ThemedText.ets itself)
2. Zero compilation errors
3. All text displays correctly with default fonts
4. Font changes in settings update all text automatically
5. No visual regressions in UI layout or styling
6. Performance remains acceptable (no noticeable slowdown)
7. Complete documentation of migration process
