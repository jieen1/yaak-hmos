import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;

  private constructor() {
  }

  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  public async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initPromise) return this.initPromise;

    this.initPromise = new Promise<void>(async (resolve, reject) => {
      const STORE_CONFIG: relationalStore.StoreConfig = {
        name: 'yaak.db',
        securityLevel: relationalStore.SecurityLevel.S1
      };

      try {
        this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
        await this.initTables();
        resolve();
      } catch (err) {
        console.error(`Failed to get RdbStore. Code:${err.code}, message:${err.message}`);
        reject(err);
      }
    });

    return this.initPromise;
  }

  public async waitForInit(): Promise<void> {
    if (this.initPromise) {
      await this.initPromise;
    }
  }

  private async initTables(): Promise<void> {
    if (!this.rdbStore) return;

    const createWorkspacesTable = `
      CREATE TABLE IF NOT EXISTS workspaces (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'workspace',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        description TEXT NOT NULL
      )
    `;

    // Added folder_id
    const createHttpRequestsTable = `
      CREATE TABLE IF NOT EXISTS http_requests (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'http_request',
        workspace_id TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        method TEXT NOT NULL,
        headers TEXT NOT NULL,
        body TEXT,
        body_type TEXT,
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
      )
    `;

    const createEnvironmentsTable = `
      CREATE TABLE IF NOT EXISTS environments (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'environment',
        workspace_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        data TEXT NOT NULL DEFAULT '{}',
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
      )
    `;

    const createSettingsTable = `
      CREATE TABLE IF NOT EXISTS settings (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'settings',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        theme TEXT NOT NULL DEFAULT 'system',
        font_size REAL NOT NULL DEFAULT 14
      )
    `;
    
    const createFoldersTable = `
      CREATE TABLE IF NOT EXISTS folders (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'folder',
        workspace_id TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        sort_priority REAL DEFAULT 0 NOT NULL,
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
      )
    `;

    await this.rdbStore.executeSql(createWorkspacesTable);
    // Note: If table exists, executeSql won't alter it. 
    // In a real migration scenario, we need ALTER TABLE checks.
    // For this port, we assume fresh install or handle manually.
    // To be safe for existing runs, try to add columns if missing (catch error)
    // But ArkTS RDB doesn't support easy "ADD COLUMN IF NOT EXISTS".
    // We will assume for now this is a dev build and schema changes might require reinstall 
    // or we can try to run ALTER TABLE ignoring errors.
    
    try { await this.rdbStore.executeSql(createHttpRequestsTable); } catch(e) {}
    try { await this.rdbStore.executeSql(createEnvironmentsTable); } catch(e) {}
    try { await this.rdbStore.executeSql(createSettingsTable); } catch(e) {}
    try { await this.rdbStore.executeSql(createFoldersTable); } catch(e) {}

    // Attempt to add folder_id to http_requests if it was created before
    try {
      await this.rdbStore.executeSql('ALTER TABLE http_requests ADD COLUMN folder_id TEXT');
    } catch (e) {
      // Ignore if already exists
    }
  }

  public getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }
}
