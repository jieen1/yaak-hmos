/**
 * Cookie Repository
 * Handles CRUD operations for cookie jars
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { CookieJar, Cookie } from '../model/CookieJar';

export class CookieRepository extends BaseRepository {
  constructor() {
    super('cookie_jars');
  }

  /**
   * Get cookie jar by workspace ID
   */
  async getCookieJarByWorkspaceId(workspaceId: string): Promise<CookieJar | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToCookieJar(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Get all cookies for a workspace
   */
  async getAllCookies(workspaceId: string): Promise<Cookie[]> {
    const cookieJar = await this.getCookieJarByWorkspaceId(workspaceId);
    return cookieJar ? cookieJar.cookies : [];
  }

  /**
   * Create or update cookie jar
   */
  async upsertCookieJar(cookieJar: CookieJar): Promise<string> {
    const existing = await this.getCookieJarByWorkspaceId(cookieJar.workspace_id);

    if (existing) {
      // Update existing
      cookieJar.id = existing.id;
      await this.updateCookieJar(cookieJar);
      return cookieJar.id;
    } else {
      // Create new
      return await this.createCookieJar(cookieJar);
    }
  }

  /**
   * Create a new cookie jar
   */
  private async createCookieJar(cookieJar: CookieJar): Promise<string> {
    const now = this.getCurrentTimestamp();
    cookieJar.id = cookieJar.id || this.generateId('cj');
    cookieJar.created_at = now;
    cookieJar.updated_at = now;

    const valueBucket: relationalStore.ValuesBucket = {
      id: cookieJar.id,
      model: cookieJar.model,
      workspace_id: cookieJar.workspace_id,
      created_at: cookieJar.created_at,
      updated_at: cookieJar.updated_at,
      cookies: this.stringifyJson(cookieJar.cookies)
    };

    await this.insert(valueBucket);
    return cookieJar.id;
  }

  /**
   * Update an existing cookie jar
   */
  private async updateCookieJar(cookieJar: CookieJar): Promise<void> {
    cookieJar.updated_at = this.getCurrentTimestamp();

    const valueBucket: relationalStore.ValuesBucket = {
      updated_at: cookieJar.updated_at,
      cookies: this.stringifyJson(cookieJar.cookies)
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', cookieJar.id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Add or update a cookie
   */
  async upsertCookie(workspaceId: string, cookie: Cookie): Promise<void> {
    let cookieJar = await this.getCookieJarByWorkspaceId(workspaceId);

    if (!cookieJar) {
      // Create new cookie jar
      cookieJar = new CookieJar();
      cookieJar.workspace_id = workspaceId;
      cookieJar.cookies = [];
    }

    // Find existing cookie with same name and domain
    const existingIndex = cookieJar.cookies.findIndex(
      c => c.name === cookie.name && c.domain === cookie.domain && c.path === cookie.path
    );

    if (existingIndex >= 0) {
      // Update existing cookie
      cookieJar.cookies[existingIndex] = cookie;
    } else {
      // Add new cookie
      cookie.id = cookie.id || this.generateId('ck');
      cookieJar.cookies.push(cookie);
    }

    await this.upsertCookieJar(cookieJar);
  }

  /**
   * Delete a cookie
   */
  async deleteCookie(workspaceId: string, cookieId: string): Promise<void> {
    const cookieJar = await this.getCookieJarByWorkspaceId(workspaceId);

    if (cookieJar) {
      cookieJar.cookies = cookieJar.cookies.filter(c => c.id !== cookieId);
      await this.updateCookieJar(cookieJar);
    }
  }

  /**
   * Delete expired cookies
   */
  async deleteExpiredCookies(workspaceId: string): Promise<void> {
    const cookieJar = await this.getCookieJarByWorkspaceId(workspaceId);

    if (cookieJar) {
      const now = Date.now();
      cookieJar.cookies = cookieJar.cookies.filter(
        c => !c.expires || c.expires > now
      );
      await this.updateCookieJar(cookieJar);
    }
  }

  /**
   * Clear all cookies for a workspace
   */
  async clearAllCookies(workspaceId: string): Promise<void> {
    const cookieJar = await this.getCookieJarByWorkspaceId(workspaceId);

    if (cookieJar) {
      cookieJar.cookies = [];
      await this.updateCookieJar(cookieJar);
    }
  }

  /**
   * Map ResultSet to CookieJar object
   */
  private mapResultSetToCookieJar(resultSet: relationalStore.ResultSet): CookieJar {
    const cookieJar = new CookieJar();
    
    cookieJar.id = resultSet.getString(resultSet.getColumnIndex('id'));
    cookieJar.model = resultSet.getString(resultSet.getColumnIndex('model'));
    cookieJar.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
    cookieJar.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    cookieJar.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    
    const cookiesStr = resultSet.getString(resultSet.getColumnIndex('cookies'));
    cookieJar.cookies = this.parseJson(cookiesStr, []);

    return cookieJar;
  }
}
