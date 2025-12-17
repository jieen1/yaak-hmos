import { DatabaseManager } from './DatabaseManager';
import { Environment } from '../model/Environment';
import relationalStore from '@ohos.data.relationalStore';

export class EnvironmentRepository {
  public static async getEnvironmentsByWorkspaceId(workspaceId: string): Promise<Environment[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return [];

    const predicates = new relationalStore.RdbPredicates('environments');
    predicates.equalTo('workspace_id', workspaceId);
    predicates.orderByDesc('created_at');

    const resultSet = await store.query(predicates);
    const environments: Environment[] = [];
    while (resultSet.goToNextRow()) {
      const env = new Environment();
      env.id = resultSet.getString(resultSet.getColumnIndex('id'));
      env.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
      env.name = resultSet.getString(resultSet.getColumnIndex('name'));
      env.variables = resultSet.getString(resultSet.getColumnIndex('variables'));
      env.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      env.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      environments.push(env);
    }
    resultSet.close();
    return environments;
  }

  public static async createEnvironment(env: Environment): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: env.id,
      model: env.model,
      workspace_id: env.workspace_id,
      name: env.name,
      variables: env.variables,
      created_at: env.created_at,
      updated_at: env.updated_at,
      deleted_at: env.deleted_at
    };

    await store.insert('environments', valueBucket);
  }

  public static async updateEnvironment(env: Environment): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      name: env.name,
      variables: env.variables,
      updated_at: Date.now()
    };

    const predicates = new relationalStore.RdbPredicates('environments');
    predicates.equalTo('id', env.id);

    await store.update(valueBucket, predicates);
  }

  public static async deleteEnvironment(id: string): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const predicates = new relationalStore.RdbPredicates('environments');
    predicates.equalTo('id', id);

    await store.delete(predicates);
  }
}


