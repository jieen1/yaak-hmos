/**
 * Folder Repository
 * Handles CRUD operations for folders
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { Folder } from '../model/Folder';
import { AuthConfig, HttpHeader } from '../model/HttpRequest';

export class FolderRepository extends BaseRepository {
  constructor() {
    super('folders');
  }

  /**
   * Get all folders by workspace ID
   */
  async getFoldersByWorkspaceId(workspaceId: string): Promise<Folder[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('sort_priority');

    const resultSet = await this.query(predicates);
    const folders: Folder[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const folder = this.mapResultSetToFolder(resultSet);
        folders.push(folder);
      }
    } finally {
      resultSet.close();
    }

    return folders;
  }

  /**
   * Get folder by ID
   */
  async getFolderById(id: string): Promise<Folder | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);
    predicates.isNull('deleted_at');

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToFolder(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Get child folders by parent folder ID
   */
  async getChildFolders(parentFolderId: string): Promise<Folder[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('folder_id', parentFolderId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('sort_priority');

    const resultSet = await this.query(predicates);
    const folders: Folder[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const folder = this.mapResultSetToFolder(resultSet);
        folders.push(folder);
      }
    } finally {
      resultSet.close();
    }

    return folders;
  }

  /**
   * Create a new folder
   */
  async createFolder(folder: Folder): Promise<string> {
    const now = this.getCurrentTimestamp();
    folder.id = folder.id || this.generateId('fld');
    folder.created_at = now;
    folder.updated_at = now;

    const valueBucket: relationalStore.ValuesBucket = {
      id: folder.id,
      model: folder.model,
      workspace_id: folder.workspace_id,
      folder_id: folder.folder_id,
      created_at: folder.created_at,
      updated_at: folder.updated_at,
      deleted_at: folder.deleted_at,
      name: folder.name,
      sort_priority: folder.sort_priority,
      auth: folder.auth ? this.stringifyJson(folder.auth) : null,
      headers: this.stringifyJson(folder.headers)
    };

    await this.insert(valueBucket);
    return folder.id;
  }

  /**
   * Update an existing folder
   */
  async updateFolder(folder: Folder): Promise<void> {
    folder.updated_at = this.getCurrentTimestamp();

    const valueBucket: relationalStore.ValuesBucket = {
      updated_at: folder.updated_at,
      folder_id: folder.folder_id,
      name: folder.name,
      sort_priority: folder.sort_priority,
      auth: folder.auth ? this.stringifyJson(folder.auth) : null,
      headers: this.stringifyJson(folder.headers)
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', folder.id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Delete a folder (soft delete)
   */
  async deleteFolder(id: string): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      deleted_at: this.getCurrentTimestamp()
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Permanently delete a folder
   */
  async permanentlyDeleteFolder(id: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.delete(predicates);
  }

  /**
   * Update folder sort priority
   */
  async updateSortPriority(id: string, sortPriority: number): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      sort_priority: sortPriority,
      updated_at: this.getCurrentTimestamp()
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Map ResultSet to Folder object
   */
  private mapResultSetToFolder(resultSet: relationalStore.ResultSet): Folder {
    const folder = new Folder();
    
    folder.id = resultSet.getString(resultSet.getColumnIndex('id'));
    folder.model = resultSet.getString(resultSet.getColumnIndex('model'));
    folder.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
    
    const folderIdIndex = resultSet.getColumnIndex('folder_id');
    folder.folder_id = resultSet.isColumnNull(folderIdIndex) ? null : resultSet.getString(folderIdIndex);
    
    folder.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    folder.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    
    const deletedAtIndex = resultSet.getColumnIndex('deleted_at');
    folder.deleted_at = resultSet.isColumnNull(deletedAtIndex) ? null : resultSet.getLong(deletedAtIndex);
    
    folder.name = resultSet.getString(resultSet.getColumnIndex('name'));
    folder.sort_priority = resultSet.getDouble(resultSet.getColumnIndex('sort_priority'));
    
    const authIndex = resultSet.getColumnIndex('auth');
    if (!resultSet.isColumnNull(authIndex)) {
      const authStr = resultSet.getString(authIndex);
      folder.auth = this.parseJson(authStr, null);
    } else {
      folder.auth = null;
    }
    
    const headersStr = resultSet.getString(resultSet.getColumnIndex('headers'));
    folder.headers = this.parseJson(headersStr, []);

    return folder;
  }
}
