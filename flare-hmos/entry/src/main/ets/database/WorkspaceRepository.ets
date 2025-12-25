/**
 * Workspace Repository
 * Handles CRUD operations for workspaces
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { Workspace, WorkspaceSettings } from '../model/Workspace';

export class WorkspaceRepository extends BaseRepository {
  constructor() {
    super('workspaces');
  }

  /**
   * Get all workspaces
   */
  async getAllWorkspaces(): Promise<Workspace[]> {
    const predicates = this.createPredicates();
    predicates.isNull('deleted_at');
    predicates.orderByAsc('created_at');

    const resultSet = await this.query(predicates);
    const workspaces: Workspace[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const workspace = this.mapResultSetToWorkspace(resultSet);
        workspaces.push(workspace);
      }
    } finally {
      resultSet.close();
    }

    return workspaces;
  }

  /**
   * Get workspace by ID
   */
  async getWorkspaceById(id: string): Promise<Workspace | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);
    predicates.isNull('deleted_at');

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToWorkspace(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Create a new workspace
   */
  async createWorkspace(workspace: Workspace): Promise<string> {
    const now = this.getCurrentTimestamp();
    workspace.id = workspace.id || this.generateId('ws');
    workspace.created_at = now;
    workspace.updated_at = now;

    const valueBucket: relationalStore.ValuesBucket = {
      id: workspace.id,
      model: workspace.model,
      created_at: workspace.created_at,
      updated_at: workspace.updated_at,
      deleted_at: workspace.deleted_at,
      name: workspace.name,
      description: workspace.description,
      settings: this.stringifyJson(workspace.settings)
    };

    await this.insert(valueBucket);
    return workspace.id;
  }

  /**
   * Update an existing workspace
   */
  async updateWorkspace(workspace: Workspace): Promise<void> {
    workspace.updated_at = this.getCurrentTimestamp();

    const valueBucket: relationalStore.ValuesBucket = {
      updated_at: workspace.updated_at,
      name: workspace.name,
      description: workspace.description,
      settings: this.stringifyJson(workspace.settings)
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', workspace.id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Delete a workspace (soft delete)
   */
  async deleteWorkspace(id: string): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      deleted_at: this.getCurrentTimestamp()
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Permanently delete a workspace
   */
  async permanentlyDeleteWorkspace(id: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.delete(predicates);
  }

  /**
   * Map ResultSet to Workspace object
   */
  private mapResultSetToWorkspace(resultSet: relationalStore.ResultSet): Workspace {
    const workspace = new Workspace();
    
    workspace.id = resultSet.getString(resultSet.getColumnIndex('id'));
    workspace.model = resultSet.getString(resultSet.getColumnIndex('model'));
    workspace.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    workspace.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    
    const deletedAtIndex = resultSet.getColumnIndex('deleted_at');
    workspace.deleted_at = resultSet.isColumnNull(deletedAtIndex) ? null : resultSet.getLong(deletedAtIndex);
    
    workspace.name = resultSet.getString(resultSet.getColumnIndex('name'));
    workspace.description = resultSet.getString(resultSet.getColumnIndex('description'));
    
    const settingsStr = resultSet.getString(resultSet.getColumnIndex('settings'));
    workspace.settings = this.parseJson(settingsStr, new WorkspaceSettings());

    return workspace;
  }
}
