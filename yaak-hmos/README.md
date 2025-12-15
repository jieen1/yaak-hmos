# Yaak HarmonyOS Native Port

This project is a native HarmonyOS port of the Yaak API Client, built using ArkTS and ArkUI.

## Architecture

The project follows a Clean Architecture (MVVM) pattern:

- **`model/`**: Data entities (Request, Workspace, Environment) mirroring the original SQLite schema.
- **`database/`**: Persistence layer using `relationalStore` (RDB).
- **`services/`**: Business logic including Network Execution, Template Engine (Variable Substitution), and Import logic.
- **`components/`**: Reusable UI components (Sidebar, Editors, Viewers).
- **`pages/`**: Main application views.

## Key Features Implemented

1.  **Request Management**: Create, Read, Update, Delete (CRUD) HTTP Requests.
2.  **Environment Variables**: Support for global/local environments and variable substitution (`{{ host }}`).
3.  **Request Execution**: robust HTTP client wrapper supporting custom Methods, Headers, and Body.
4.  **Data Persistence**: Full SQLite compatibility for data storage.
5.  **UI**: Split-pane layout with responsive Sidebar, Request Editor, and Response Viewer.
6.  **Settings**: Basic framework for application settings (Theme, Font Size).
7.  **Import**: Foundation for importing cURL commands.

## Getting Started

1.  Open the project in DevEco Studio.
2.  Sync Gradle/Hvigor projects.
3.  Run on a HarmonyOS Emulator or Device (API 12+ recommended).

