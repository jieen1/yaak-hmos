# Requirements Document

## Introduction

This document defines the requirements for implementing inheritance UI features in the yaak-hmos HarmonyOS application. The feature allows users to see and understand inherited authentication and headers from parent folders and workspaces, matching the functionality in the Tauri/web version.

## Glossary

- **Inheritance_Service**: The service that resolves authentication and headers from the folder/workspace hierarchy
- **Inherited_Headers**: HTTP headers that are inherited from parent folders or workspace, not directly set on the request
- **Inherited_Auth**: Authentication configuration inherited from parent folders or workspace
- **Auth_Source**: The entity (request, folder, or workspace) from which authentication is inherited
- **Header_Source**: The entity from which a specific header is inherited
- **Headers_Editor**: The UI component for editing HTTP headers
- **Auth_Editor**: The UI component for editing authentication configuration

## Requirements

### Requirement 1: Display Inherited Headers in Headers Editor

**User Story:** As a user, I want to see inherited headers from parent folders and workspace, so that I understand what headers will be sent with my request.

#### Acceptance Criteria

1. WHEN the Headers_Editor is displayed for a request THEN THE Headers_Editor SHALL show inherited headers in a collapsible section above the editable headers
2. WHEN inherited headers exist THEN THE Headers_Editor SHALL display a count badge showing the number of inherited headers
3. WHEN an inherited header is displayed THEN THE Headers_Editor SHALL show it as read-only (disabled)
4. WHEN no inherited headers exist THEN THE Headers_Editor SHALL not display the inherited section
5. THE Headers_Editor SHALL only display enabled inherited headers (where enabled = true)

### Requirement 2: Display Inherited Authentication in Auth Editor

**User Story:** As a user, I want to see when authentication is inherited from a parent folder or workspace, so that I understand where my auth settings come from.

#### Acceptance Criteria

1. WHEN the Auth_Editor is displayed for a request with inherited auth THEN THE Auth_Editor SHALL show "Inherited from [source name]" message
2. WHEN auth is inherited from a folder THEN THE Auth_Editor SHALL display the folder name as the source
3. WHEN auth is inherited from workspace THEN THE Auth_Editor SHALL display "Workspace" as the source
4. WHEN the user taps on the inherited auth source THEN THE Auth_Editor SHALL navigate to the source's settings
5. WHEN auth type is set to "none" and no parent has auth THEN THE Auth_Editor SHALL display "No authentication"
6. WHEN auth is directly set on the request (not inherited) THEN THE Auth_Editor SHALL display the auth configuration form

### Requirement 3: Folder Settings Dialog with Inheritance Support

**User Story:** As a user, I want to configure authentication and headers on folders, so that all requests in the folder inherit these settings.

#### Acceptance Criteria

1. WHEN the Folder_Settings_Dialog is opened THEN THE Folder_Settings_Dialog SHALL display tabs for Headers and Auth
2. WHEN editing folder headers THEN THE Headers_Editor SHALL show inherited headers from parent folders and workspace
3. WHEN editing folder auth THEN THE Auth_Editor SHALL show inherited auth from parent folders and workspace
4. WHEN folder auth is set THEN THE Folder_Settings_Dialog SHALL apply auth to all requests in the folder

### Requirement 4: Workspace Settings Dialog with Inheritance Support

**User Story:** As a user, I want to configure authentication and headers on workspaces, so that all requests in the workspace inherit these settings.

#### Acceptance Criteria

1. WHEN the Workspace_Settings_Dialog is opened THEN THE Workspace_Settings_Dialog SHALL display tabs for Headers and Auth
2. WHEN editing workspace headers THEN THE Headers_Editor SHALL allow adding headers that apply to all requests
3. WHEN editing workspace auth THEN THE Auth_Editor SHALL allow setting auth that applies to all requests
4. WHEN workspace auth is set THEN THE Workspace_Settings_Dialog SHALL apply auth to all requests without explicit auth

### Requirement 5: Inheritance Source Indication

**User Story:** As a user, I want to know the source of inherited settings, so that I can easily navigate to modify them.

#### Acceptance Criteria

1. WHEN displaying inherited headers THEN THE Headers_Editor SHALL indicate the source (folder name or "Workspace") for each header
2. WHEN displaying inherited auth THEN THE Auth_Editor SHALL indicate the source (folder name or "Workspace")
3. WHEN the user taps on an inheritance source indicator THEN THE System SHALL navigate to that source's settings dialog
