# Implementation Plan - Text to ThemedText Migration

## Overview

This implementation plan outlines the step-by-step tasks for migrating all Text components to ThemedText components for **interface fonts only**. Editor fonts are already implemented in ThemedTextInput and other editor components.

**Focus:** UI text elements (labels, buttons, dialogs, status messages, etc.)

**Excluded:** Editor components (TextViewer, ThemedTextInput) - already have font support

---

## Phase 1: Dialog Components Migration

- [x] 1. Migrate SettingsDialog.ets


  - Replace ~15 Text instances with ThemedText
  - All text should use fontType='interface'
  - Preserve all fontSize, fontColor, and fontWeight properties
  - Add ThemedText import from './index'
  - Test: Compile successfully and verify visual appearance
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 4.1, 4.2, 4.3, 8.1_

- [x] 2. Migrate WorkspaceManagementDialog.ets


  - Replace ~8 Text instances with ThemedText
  - All text should use fontType='interface'
  - Preserve dialog header fontSize overrides for visual hierarchy
  - Add ThemedText import
  - Test: Compile and verify workspace list display
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 4.1, 4.2, 8.1_

- [x] 3. Migrate WorkspaceSettingsDialog.ets


  - Replace ~5 Text instances with ThemedText
  - All text should use fontType='interface'
  - Preserve form label styling
  - Add ThemedText import
  - Test: Compile and verify settings form display
  - _Requirements: 1.1, 1.3, 1.4, 2.5, 4.1, 4.2, 8.1_

- [x] 4. Migrate FolderSettingsDialog.ets


  - Replace ~4 Text instances with ThemedText
  - All text should use fontType='interface'
  - Preserve dialog header and label styling
  - Add ThemedText import
  - Test: Compile and verify folder settings display
  - _Requirements: 1.1, 1.3, 1.4, 2.5, 4.1, 4.2, 8.1_

- [x] 5. Phase 1 Verification


  - Run full compilation to ensure no errors
  - Visual test: Open each dialog and verify text displays correctly
  - Font test: Change interface font in settings and verify all dialog text updates
  - Document any issues or special cases encountered
  - _Requirements: 5.3, 5.4, 9.1, 9.2, 9.3_

---

## Phase 2: Viewer Components Migration

- [x] 6. Migrate ResponseViewerComponent.ets


  - Replace ~20 Text instances with ThemedText
  - **All text should use fontType='interface'** (status labels, headers, history, messages)
  - Note: Response content display is handled by TextViewer (already has editor font)
  - Preserve all status colors, sizes, and weights
  - Handle empty state and error messages
  - Add ThemedText import
  - Test: Compile and verify response display with various content types
  - _Requirements: 1.1, 1.3, 1.4, 2.4, 3.1, 3.2, 3.3, 7.1_

- [x] 7. Migrate ResponseInfoTab.ets


  - Replace ~4 Text instances with ThemedText
  - All text should use fontType='interface' (section titles and labels)
  - Preserve section title and info label styling
  - Add ThemedText import
  - Test: Compile and verify response info display
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 4.1, 4.2, 8.1_

- [x] 8. Migrate ImageViewer.ets


  - Replace ~1 Text instance with ThemedText
  - Empty state text should use fontType='interface'
  - Add ThemedText import
  - Test: Compile and verify empty state display
  - _Requirements: 1.1, 1.3, 1.4, 2.4, 8.1_

- [x] 9. Document Editor Components Special Cases

  - TextViewer already uses FontSettings.editorFont directly - no migration needed
  - ThemedTextInput already implements editor font - no migration needed
  - Document these as intentionally excluded from migration
  - Verify editor components still respond to font changes correctly
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5_

- [x] 10. Phase 2 Verification


  - Run full compilation to ensure no errors
  - Visual test: Send requests and verify response viewer displays correctly
  - Font test: Change interface font in settings, verify UI labels update
  - Note: Editor font changes are handled by existing editor components
  - Test with various response types (JSON, XML, images, large responses)
  - Document any issues or special cases encountered
  - _Requirements: 4.3, 4.4, 8.1, 8.2, 8.3_

---

## Phase 3: Main Components Migration

- [x] 11. Migrate Index.ets


  - Replace ~2 Text instances with ThemedText
  - Loading message should use fontType='interface'
  - Sidebar toggle icon text should use fontType='interface'
  - Add ThemedText import
  - Test: Compile and verify main page displays correctly
  - _Requirements: 1.1, 1.3, 1.4, 2.4, 8.1_

- [x] 12. Migrate RequestEditorComponent.ets


  - Replace ~1 Text instance with ThemedText (HTTP method display)
  - Method text should use fontType='interface'
  - Preserve method color styling
  - Add ThemedText import
  - Test: Compile and verify request editor displays correctly
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 4.2, 8.1_

- [x] 13. Migrate SidebarComponent.ets


  - Replace ~1 Text instance with ThemedText (drop zone message)
  - Drop zone text should use fontType='interface'
  - Add ThemedText import
  - Test: Compile and verify sidebar drag-drop display
  - _Requirements: 1.1, 1.3, 1.4, 2.3, 8.1_

- [x] 14. Migrate WorkspaceHeader.ets


  - Replace ~1 Text instance with ThemedText (offline mode indicator)
  - Offline text should use fontType='interface'
  - Preserve red color for offline indicator
  - Add ThemedText import
  - Test: Compile and verify workspace header displays correctly
  - _Requirements: 1.1, 1.3, 1.4, 2.4, 4.2, 8.1_

- [x] 15. Phase 3 Verification

  - Run full compilation to ensure no errors
  - Visual test: Navigate through main application screens
  - Font test: Change interface font and verify all main UI text updates
  - Test drag-drop functionality in sidebar
  - Document any issues or special cases encountered
  - _Requirements: 5.3, 5.4, 9.1, 9.2, 9.3_

---

## Phase 4: Authentication Components Migration

- [x] 16. Migrate LoginComponent.ets


  - Replace ~8 Text instances with ThemedText
  - All text should use fontType='interface'
  - Preserve title size (32), subtitle size (16), and other styling
  - Preserve button text, error message, and footer text styling
  - Add ThemedText import
  - Test: Compile and verify login screen displays correctly
  - _Requirements: 1.1, 1.3, 1.4, 2.1, 4.1, 4.2, 4.3, 8.1_

- [x] 17. Phase 4 Verification

  - Run full compilation to ensure no errors
  - Visual test: View login screen and verify all text displays correctly
  - Font test: Change interface font and verify login screen text updates
  - Test login flow to ensure functionality is preserved
  - Document any issues or special cases encountered
  - _Requirements: 5.3, 5.4, 9.1, 9.2, 9.3_

---

## Final Verification and Documentation

- [x] 18. Complete Migration Verification

  - Search entire codebase for remaining `Text(` instances
  - Verify only ThemedText.ets itself contains native Text usage
  - Run full application compilation - zero errors expected
  - Perform comprehensive visual testing of all screens
  - Test font changes for both interface and editor fonts
  - Test with various font sizes (small, medium, large)
  - _Requirements: 1.5, 9.1, 9.2, 9.3, 9.4, 9.5_

- [x] 19. Create Migration Documentation

  - Document all migrated components with before/after examples
  - List components by category with their fontType usage
  - Document TextViewer as special case (no migration needed)
  - Create troubleshooting guide for common issues
  - Update coding guidelines to mandate ThemedText usage
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5_

- [x] 20. Performance Testing


  - Measure application startup time (should be unchanged)
  - Test font change responsiveness (should be immediate)
  - Test with large lists of text elements
  - Verify no memory leaks from FontSettings singleton
  - Document performance metrics
  - _Requirements: 9.5_

---

## Migration Statistics

**Total Components to Migrate:** 14 components (interface text only)
**Total Text Instances:** ~65 instances (interface labels, buttons, dialogs)
**Estimated Time per Component:** 10-20 minutes
**Total Estimated Time:** 3-5 hours

**Component Breakdown:**
- Phase 1 (Dialogs): 4 components, ~32 instances
- Phase 2 (Viewers): 3 components, ~25 instances (interface labels only)
- Phase 3 (Main): 4 components, ~5 instances
- Phase 4 (Auth): 1 component, ~8 instances

**Font Type Distribution:**
- Interface font: ~65 instances (100% of migration scope)
- Editor font: 0 instances (already implemented in editor components)

**Excluded Components:**
- TextViewer.ets - uses FontSettings.editorFont directly
- ThemedTextInput.ets - already implements editor font
- Other editor components - already have font support

---

## Rollback Plan

If critical issues are discovered during any phase:

1. **Immediate Rollback**: Use git to revert the specific phase commit
2. **Partial Rollback**: Revert individual component files if needed
3. **Issue Resolution**: Fix the issue and re-attempt migration
4. **Documentation**: Document the issue and resolution for future reference

---

## Success Criteria

- [ ] All interface Text components migrated to ThemedText
- [ ] Editor components (TextViewer, ThemedTextInput) remain unchanged
- [ ] Zero compilation errors
- [ ] Zero visual regressions
- [ ] Interface font settings work for all UI text elements
- [ ] Editor font settings continue to work in editor components
- [ ] Performance remains acceptable
- [ ] Complete documentation delivered

---

## Notes

- Each phase should be committed separately for easy rollback
- Visual testing is critical - use screenshots for comparison
- Interface font change testing should be done after each phase
- Document any unexpected issues or edge cases
- **All fontType should be 'interface'** - editor fonts are already implemented
- TextViewer.ets and ThemedTextInput.ets are intentionally excluded
- ThemedText currently supports: fontColor, fontWeight, maxLines (textOverflow not yet implemented)
