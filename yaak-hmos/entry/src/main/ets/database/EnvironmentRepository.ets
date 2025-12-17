/**
 * Environment Repository
 * Handles CRUD operations for environments
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { Environment, EnvironmentVariable } from '../model/Environment';

export class EnvironmentRepository extends BaseRepository {
  constructor() {
    super('environments');
  }

  /**
   * Get all environments by workspace ID
   */
  async getEnvironmentsByWorkspaceId(workspaceId: string): Promise<Environment[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('created_at');

    const resultSet = await this.query(predicates);
    const environments: Environment[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const environment = this.mapResultSetToEnvironment(resultSet);
        environments.push(environment);
      }
    } finally {
      resultSet.close();
    }

    return environments;
  }

  /**
   * Get environment by ID
   */
  async getEnvironmentById(id: string): Promise<Environment | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);
    predicates.isNull('deleted_at');

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToEnvironment(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Create a new environment
   */
  async createEnvironment(environment: Environment): Promise<string> {
    const now = this.getCurrentTimestamp();
    environment.id = environment.id || this.generateId('env');
    environment.created_at = now;
    environment.updated_at = now;

    const valueBucket: relationalStore.ValuesBucket = {
      id: environment.id,
      model: environment.model,
      workspace_id: environment.workspace_id,
      created_at: environment.created_at,
      updated_at: environment.updated_at,
      deleted_at: environment.deleted_at,
      name: environment.name,
      variables: this.stringifyJson(environment.variables)
    };

    await this.insert(valueBucket);
    return environment.id;
  }

  /**
   * Update an existing environment
   */
  async updateEnvironment(environment: Environment): Promise<void> {
    environment.updated_at = this.getCurrentTimestamp();

    const valueBucket: relationalStore.ValuesBucket = {
      updated_at: environment.updated_at,
      name: environment.name,
      variables: this.stringifyJson(environment.variables)
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', environment.id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Delete an environment (soft delete)
   */
  async deleteEnvironment(id: string): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      deleted_at: this.getCurrentTimestamp()
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Permanently delete an environment
   */
  async permanentlyDeleteEnvironment(id: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.delete(predicates);
  }

  /**
   * Map ResultSet to Environment object
   */
  private mapResultSetToEnvironment(resultSet: relationalStore.ResultSet): Environment {
    const environment = new Environment();
    
    environment.id = resultSet.getString(resultSet.getColumnIndex('id'));
    environment.model = resultSet.getString(resultSet.getColumnIndex('model'));
    environment.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
    environment.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    environment.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    
    const deletedAtIndex = resultSet.getColumnIndex('deleted_at');
    environment.deleted_at = resultSet.isColumnNull(deletedAtIndex) ? null : resultSet.getLong(deletedAtIndex);
    
    environment.name = resultSet.getString(resultSet.getColumnIndex('name'));
    
    const variablesStr = resultSet.getString(resultSet.getColumnIndex('variables'));
    environment.variables = this.parseJson(variablesStr, []);

    return environment;
  }
}
