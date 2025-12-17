/**
 * Base Repository
 * Provides common CRUD operations and transaction support for all repositories
 */

import relationalStore from '@ohos.data.relationalStore';
import { DatabaseManager } from './DatabaseManager';

export class BaseRepository {
  protected tableName: string;

  constructor(tableName: string) {
    this.tableName = tableName;
  }

  /**
   * Get database store instance
   */
  protected getStore(): relationalStore.RdbStore {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) {
      throw new Error('Database not initialized');
    }
    return store;
  }

  /**
   * Execute operation within a transaction
   */
  protected async executeInTransaction<T>(
    operation: () => Promise<T>
  ): Promise<T> {
    const store = this.getStore();
    
    try {
      await store.beginTransaction();
      const result = await operation();
      await store.commit();
      return result;
    } catch (error) {
      await store.rollback();
      console.error(`Transaction failed: ${JSON.stringify(error)}`);
      throw error;
    }
  }

  /**
   * Insert a record
   */
  protected async insert(valueBucket: relationalStore.ValuesBucket): Promise<number> {
    const store = this.getStore();
    return await store.insert(this.tableName, valueBucket);
  }

  /**
   * Update records
   */
  protected async update(
    valueBucket: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    const store = this.getStore();
    return await store.update(valueBucket, predicates);
  }

  /**
   * Delete records
   */
  protected async delete(predicates: relationalStore.RdbPredicates): Promise<number> {
    const store = this.getStore();
    return await store.delete(predicates);
  }

  /**
   * Query records
   */
  protected async query(predicates: relationalStore.RdbPredicates): Promise<relationalStore.ResultSet> {
    const store = this.getStore();
    return await store.query(predicates);
  }

  /**
   * Execute raw SQL query
   */
  protected async executeSql(sql: string, args?: Array<relationalStore.ValueType>): Promise<void> {
    const store = this.getStore();
    await store.executeSql(sql, args);
  }

  /**
   * Query with raw SQL
   */
  protected async querySql(sql: string, args?: Array<relationalStore.ValueType>): Promise<relationalStore.ResultSet> {
    const store = this.getStore();
    return await store.querySql(sql, args);
  }

  /**
   * Create RdbPredicates for this table
   */
  protected createPredicates(): relationalStore.RdbPredicates {
    const store = this.getStore();
    return new relationalStore.RdbPredicates(this.tableName);
  }

  /**
   * Generate unique ID with prefix
   */
  protected generateId(prefix: string): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    return `${prefix}_${timestamp}_${random}`;
  }

  /**
   * Get current timestamp
   */
  protected getCurrentTimestamp(): number {
    return Date.now();
  }

  /**
   * Parse JSON string safely
   */
  protected parseJson<T>(jsonStr: string, defaultValue: T): T {
    try {
      return JSON.parse(jsonStr) as T;
    } catch (error) {
      console.error(`Failed to parse JSON: ${error}`);
      return defaultValue;
    }
  }

  /**
   * Stringify object safely
   */
  protected stringifyJson(obj: Object): string {
    try {
      return JSON.stringify(obj);
    } catch (error) {
      console.error(`Failed to stringify JSON: ${error}`);
      return '{}';
    }
  }
}
