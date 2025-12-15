import { DatabaseManager } from './DatabaseManager';
import { Workspace } from '../model/Workspace';
import relationalStore from '@ohos.data.relationalStore';

export class WorkspaceRepository {
  public static async getAllWorkspaces(): Promise<Workspace[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return [];

    const predicates = new relationalStore.RdbPredicates('workspaces');
    predicates.orderByDesc('created_at');

    const resultSet = await store.query(predicates);
    const workspaces: Workspace[] = [];
    while (resultSet.goToNextRow()) {
      const workspace = new Workspace();
      workspace.id = resultSet.getString(resultSet.getColumnIndex('id'));
      workspace.name = resultSet.getString(resultSet.getColumnIndex('name'));
      workspace.description = resultSet.getString(resultSet.getColumnIndex('description'));
      workspace.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      workspace.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      workspaces.push(workspace);
    }
    resultSet.close();
    return workspaces;
  }

  public static async createWorkspace(workspace: Workspace): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: workspace.id,
      model: workspace.model,
      name: workspace.name,
      description: workspace.description,
      created_at: workspace.created_at,
      updated_at: workspace.updated_at,
      deleted_at: workspace.deleted_at
    };

    await store.insert('workspaces', valueBucket);
  }
}

