import { DatabaseManager } from './DatabaseManager';
import { Folder } from '../model/Folder';
import relationalStore from '@ohos.data.relationalStore';

export class FolderRepository {
  public static async getFoldersByWorkspaceId(workspaceId: string): Promise<Folder[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return [];

    const predicates = new relationalStore.RdbPredicates('folders');
    predicates.equalTo('workspace_id', workspaceId);
    predicates.orderByAsc('sort_priority');

    const resultSet = await store.query(predicates);
    const folders: Folder[] = [];
    while (resultSet.goToNextRow()) {
      const folder = new Folder();
      folder.id = resultSet.getString(resultSet.getColumnIndex('id'));
      folder.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
      folder.folder_id = resultSet.getString(resultSet.getColumnIndex('folder_id'));
      folder.name = resultSet.getString(resultSet.getColumnIndex('name'));
      folder.sort_priority = resultSet.getDouble(resultSet.getColumnIndex('sort_priority'));
      folder.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      folder.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      folders.push(folder);
    }
    resultSet.close();
    return folders;
  }

  public static async createFolder(folder: Folder): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: folder.id,
      model: folder.model,
      workspace_id: folder.workspace_id,
      folder_id: folder.folder_id,
      name: folder.name,
      sort_priority: folder.sort_priority,
      created_at: folder.created_at,
      updated_at: folder.updated_at,
      deleted_at: folder.deleted_at
    };

    await store.insert('folders', valueBucket);
  }
}


