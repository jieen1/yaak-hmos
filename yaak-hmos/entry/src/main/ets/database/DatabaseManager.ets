/**
 * Database Manager
 * Singleton class for managing RDB Store connection and initialization
 * Includes error recovery with retry logic
 */

import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

const STORE_CONFIG: relationalStore.StoreConfig = {
  name: 'flare.db',
  securityLevel: relationalStore.SecurityLevel.S1,
  encrypt: false,
  customDir: 'database'
};

// Retry configuration interface
interface RetryConfig {
  maxRetries: number;
  baseDelayMs: number;
  maxDelayMs: number;
}

export class DatabaseManager {
  private static instance: DatabaseManager;
  private rdbStore: relationalStore.RdbStore | null = null;
  private initPromise: Promise<void> | null = null;
  private context: common.UIAbilityContext | null = null;
  private static readonly CURRENT_VERSION = 1;
  
  // Default retry configuration
  private static readonly DEFAULT_RETRY_CONFIG: RetryConfig = {
    maxRetries: 3,
    baseDelayMs: 100,
    maxDelayMs: 2000
  };

  private constructor() {
  }

  /**
   * Get singleton instance
   */
  public static getInstance(): DatabaseManager {
    if (!DatabaseManager.instance) {
      DatabaseManager.instance = new DatabaseManager();
    }
    return DatabaseManager.instance;
  }

  /**
   * Initialize database with proper error handling and retry logic
   */
  public async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initPromise) return this.initPromise;
    
    this.context = context;

    this.initPromise = new Promise<void>(async (resolve, reject) => {
      try {
        this.rdbStore = await relationalStore.getRdbStore(context, STORE_CONFIG);
        await this.initTables();
        console.info('Database initialized successfully');
        resolve();
      } catch (err) {
        console.error(`Database init failed: ${JSON.stringify(err)}`);
        reject(err);
      }
    });

    return this.initPromise;
  }

  /**
   * Wait for initialization to complete
   */
  public async waitForInit(): Promise<void> {
    if (this.initPromise) {
      await this.initPromise;
    }
  }

  /**
   * Get database store instance
   */
  public getStore(): relationalStore.RdbStore | null {
    return this.rdbStore;
  }

  /**
   * Initialize all database tables
   */
  private async initTables(): Promise<void> {
    const store = this.rdbStore;
    if (!store) return;

    const currentVersion = store.version;

    if (currentVersion === 0) {
      // Fresh install - create all tables
      await this.createAllTables(store);
      store.version = DatabaseManager.CURRENT_VERSION;
    } else if (currentVersion < DatabaseManager.CURRENT_VERSION) {
      // Migration needed
      await this.migrateDatabase(store, currentVersion);
      store.version = DatabaseManager.CURRENT_VERSION;
    }
  }

  /**
   * Create all database tables
   */
  private async createAllTables(store: relationalStore.RdbStore): Promise<void> {
    // Create workspaces table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS workspaces (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'workspace',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        settings TEXT NOT NULL DEFAULT '{}'
      )
    `);

    // Create folders table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS folders (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'folder',
        workspace_id TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        sort_priority REAL NOT NULL DEFAULT 0,
        auth TEXT,
        headers TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE CASCADE
      )
    `);

    // Create indexes for folders
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_folders_workspace ON folders(workspace_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_folders_parent ON folders(folder_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_folders_sort ON folders(sort_priority)');

    // Create http_requests table
    await store.executeSql(`
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
        headers TEXT NOT NULL DEFAULT '[]',
        query_params TEXT NOT NULL DEFAULT '[]',
        body TEXT,
        body_type TEXT NOT NULL DEFAULT 'none',
        auth TEXT NOT NULL DEFAULT '{}',
        sort_priority REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    `);

    // Create indexes for http_requests
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_http_requests_workspace ON http_requests(workspace_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_http_requests_folder ON http_requests(folder_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_http_requests_sort ON http_requests(sort_priority)');

    // Create http_responses table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS http_responses (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'http_response',
        request_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        status_code INTEGER NOT NULL,
        status_text TEXT NOT NULL,
        headers TEXT NOT NULL DEFAULT '[]',
        body_path TEXT NOT NULL,
        elapsed_time INTEGER NOT NULL,
        size INTEGER NOT NULL,
        state TEXT NOT NULL DEFAULT 'pending',
        FOREIGN KEY (request_id) REFERENCES http_requests(id) ON DELETE CASCADE
      )
    `);

    // Create indexes for http_responses
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_http_responses_request ON http_responses(request_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_http_responses_created ON http_responses(created_at DESC)');

    // Create environments table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS environments (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'environment',
        workspace_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        variables TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
      )
    `);

    // Create index for environments
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_environments_workspace ON environments(workspace_id)');

    // Create cookie_jars table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS cookie_jars (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'cookie_jar',
        workspace_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        cookies TEXT NOT NULL DEFAULT '[]',
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE
      )
    `);

    // Create index for cookie_jars
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_cookie_jars_workspace ON cookie_jars(workspace_id)');

    // Create settings table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS settings (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'settings',
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        theme TEXT NOT NULL DEFAULT 'system',
        font_size REAL NOT NULL DEFAULT 14,
        editor_font_size REAL NOT NULL DEFAULT 14,
        editor_keymap TEXT NOT NULL DEFAULT 'default',
        soft_wrap INTEGER NOT NULL DEFAULT 0
      )
    `);

    // Create grpc_requests table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS grpc_requests (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'grpc_request',
        workspace_id TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        proto_file_path TEXT,
        service_name TEXT NOT NULL,
        method_name TEXT NOT NULL,
        metadata TEXT NOT NULL DEFAULT '[]',
        message TEXT NOT NULL DEFAULT '{}',
        sort_priority REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    `);

    // Create indexes for grpc_requests
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_grpc_requests_workspace ON grpc_requests(workspace_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_grpc_requests_folder ON grpc_requests(folder_id)');

    // Create websocket_requests table
    await store.executeSql(`
      CREATE TABLE IF NOT EXISTS websocket_requests (
        id TEXT PRIMARY KEY,
        model TEXT NOT NULL DEFAULT 'websocket_request',
        workspace_id TEXT NOT NULL,
        folder_id TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        deleted_at INTEGER,
        name TEXT NOT NULL,
        url TEXT NOT NULL,
        headers TEXT NOT NULL DEFAULT '[]',
        sort_priority REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (workspace_id) REFERENCES workspaces(id) ON DELETE CASCADE,
        FOREIGN KEY (folder_id) REFERENCES folders(id) ON DELETE SET NULL
      )
    `);

    // Create indexes for websocket_requests
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_websocket_requests_workspace ON websocket_requests(workspace_id)');
    await store.executeSql('CREATE INDEX IF NOT EXISTS idx_websocket_requests_folder ON websocket_requests(folder_id)');

    console.info('All database tables created successfully');
  }

  /**
   * Migrate database from old version to new version
   */
  private async migrateDatabase(store: relationalStore.RdbStore, fromVersion: number): Promise<void> {
    console.info(`Migrating database from version ${fromVersion} to ${DatabaseManager.CURRENT_VERSION}`);
    
    // Future migrations will be handled here
    // Example:
    // if (fromVersion === 1) {
    //   await store.executeSql('ALTER TABLE http_requests ADD COLUMN new_field TEXT');
    // }
  }

  /**
   * Close database connection
   */
  public async close(): Promise<void> {
    if (this.rdbStore) {
      // Note: RdbStore doesn't have a close method in current API
      // Just set to null for cleanup
      this.rdbStore = null;
      this.initPromise = null;
      console.info('Database connection closed');
    }
  }

  /**
   * Execute operation with retry logic and exponential backoff
   */
  public async executeWithRetry<T>(
    operation: () => Promise<T>,
    operationName: string,
    config: RetryConfig = DatabaseManager.DEFAULT_RETRY_CONFIG
  ): Promise<T> {
    let lastError: Error = new Error('Unknown error');
    
    for (let attempt = 0; attempt <= config.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error));
        
        if (attempt < config.maxRetries) {
          // Calculate delay with exponential backoff
          const delay: number = Math.min(
            config.baseDelayMs * Math.pow(2, attempt),
            config.maxDelayMs
          );
          
          console.warn(`[DatabaseManager] ${operationName} failed (attempt ${attempt + 1}/${config.maxRetries + 1}), retrying in ${delay}ms...`);
          
          await this.sleep(delay);
        }
      }
    }
    
    console.error(`[DatabaseManager] ${operationName} failed after ${config.maxRetries + 1} attempts`);
    throw lastError;
  }

  /**
   * Sleep for specified milliseconds
   */
  private sleep(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => {
        resolve();
      }, ms);
    });
  }

  /**
   * Execute SQL with retry
   */
  public async executeSqlWithRetry(sql: string): Promise<void> {
    await this.executeWithRetry(
      async () => {
        const store = this.getStore();
        if (!store) {
          throw new Error('Database not initialized');
        }
        await store.executeSql(sql);
      },
      `executeSql: ${sql.substring(0, 50)}...`
    );
  }

  /**
   * Check database integrity
   */
  public async checkIntegrity(): Promise<boolean> {
    try {
      const store = this.getStore();
      if (!store) {
        return false;
      }
      
      // Try a simple query to verify database is accessible
      const predicates = new relationalStore.RdbPredicates('workspaces');
      predicates.limitAs(1);
      const resultSet = await store.query(predicates, ['id']);
      resultSet.close();
      
      return true;
    } catch (error) {
      console.error('[DatabaseManager] Integrity check failed:', error);
      return false;
    }
  }

  /**
   * Attempt to recover from database errors
   * Returns true if recovery was successful
   */
  public async attemptRecovery(): Promise<boolean> {
    console.info('[DatabaseManager] Attempting database recovery...');
    
    try {
      // Close existing connection
      await this.close();
      
      // Wait a moment
      await this.sleep(500);
      
      // Reinitialize
      if (this.context) {
        await this.init(this.context);
        
        // Verify recovery
        const isHealthy: boolean = await this.checkIntegrity();
        
        if (isHealthy) {
          console.info('[DatabaseManager] Recovery successful');
          return true;
        }
      }
      
      console.error('[DatabaseManager] Recovery failed');
      return false;
    } catch (error) {
      console.error('[DatabaseManager] Recovery error:', error);
      return false;
    }
  }

  /**
   * Execute operation in a transaction
   */
  public async executeInTransaction<T>(operation: () => Promise<T>): Promise<T> {
    const store = this.getStore();
    if (!store) {
      throw new Error('Database not initialized');
    }

    try {
      await store.beginTransaction();
      const result: T = await operation();
      await store.commit();
      return result;
    } catch (error) {
      await store.rollBack();
      // ArkTS requires throwing Error instances, not arbitrary types
      const errorToThrow: Error = error instanceof Error ? error : new Error(String(error));
      throw errorToThrow;
    }
  }
}
