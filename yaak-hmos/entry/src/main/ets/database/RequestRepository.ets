import { DatabaseManager } from './DatabaseManager';
import { HttpRequest } from '../model/HttpRequest';
import relationalStore from '@ohos.data.relationalStore';

export class RequestRepository {
  public static async getRequestsByWorkspaceId(workspaceId: string): Promise<HttpRequest[]> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return [];

    const predicates = new relationalStore.RdbPredicates('http_requests');
    predicates.equalTo('workspace_id', workspaceId);
    predicates.orderByDesc('created_at');

    const resultSet = await store.query(predicates);
    const requests: HttpRequest[] = [];
    while (resultSet.goToNextRow()) {
      const request = new HttpRequest();
      request.id = resultSet.getString(resultSet.getColumnIndex('id'));
      request.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
      request.folder_id = resultSet.getString(resultSet.getColumnIndex('folder_id'));
      request.name = resultSet.getString(resultSet.getColumnIndex('name'));
      request.url = resultSet.getString(resultSet.getColumnIndex('url'));
      request.method = resultSet.getString(resultSet.getColumnIndex('method'));
      request.headers = resultSet.getString(resultSet.getColumnIndex('headers'));
      request.body = resultSet.getString(resultSet.getColumnIndex('body'));
      request.body_type = resultSet.getString(resultSet.getColumnIndex('body_type'));
      request.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
      request.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
      requests.push(request);
    }
    resultSet.close();
    return requests;
  }

  public static async createRequest(request: HttpRequest): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: request.id,
      model: request.model,
      workspace_id: request.workspace_id,
      folder_id: request.folder_id,
      name: request.name,
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: request.body,
      body_type: request.body_type,
      created_at: request.created_at,
      updated_at: request.updated_at,
      deleted_at: request.deleted_at
    };

    await store.insert('http_requests', valueBucket);
  }
}

