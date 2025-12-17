/**
 * Request Repository
 * Handles CRUD operations for HTTP requests
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { HttpMethod, BodyType } from '../model/Types';

export class RequestRepository extends BaseRepository {
  constructor() {
    super('http_requests');
  }

  /**
   * Get all requests by workspace ID
   */
  async getRequestsByWorkspaceId(workspaceId: string): Promise<HttpRequest[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('sort_priority');

    const resultSet = await this.query(predicates);
    const requests: HttpRequest[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const request = this.mapResultSetToRequest(resultSet);
        requests.push(request);
      }
    } finally {
      resultSet.close();
    }

    return requests;
  }

  /**
   * Get request by ID
   */
  async getRequestById(id: string): Promise<HttpRequest | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);
    predicates.isNull('deleted_at');

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToRequest(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Get requests by folder ID
   */
  async getRequestsByFolderId(folderId: string): Promise<HttpRequest[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('folder_id', folderId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('sort_priority');

    const resultSet = await this.query(predicates);
    const requests: HttpRequest[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const request = this.mapResultSetToRequest(resultSet);
        requests.push(request);
      }
    } finally {
      resultSet.close();
    }

    return requests;
  }

  /**
   * Create a new request
   */
  async createRequest(request: HttpRequest): Promise<string> {
    const now = this.getCurrentTimestamp();
    request.id = request.id || this.generateId('rq');
    request.created_at = now;
    request.updated_at = now;

    const valueBucket: relationalStore.ValuesBucket = {
      id: request.id,
      model: request.model,
      workspace_id: request.workspace_id,
      folder_id: request.folder_id,
      created_at: request.created_at,
      updated_at: request.updated_at,
      deleted_at: request.deleted_at,
      name: request.name,
      url: request.url,
      method: request.method,
      headers: this.stringifyJson(request.headers),
      query_params: this.stringifyJson(request.query_params),
      body: request.body,
      body_type: request.body_type,
      auth: this.stringifyJson(request.auth),
      sort_priority: request.sort_priority
    };

    await this.insert(valueBucket);
    return request.id;
  }

  /**
   * Update an existing request
   */
  async updateRequest(request: HttpRequest): Promise<void> {
    request.updated_at = this.getCurrentTimestamp();

    const valueBucket: relationalStore.ValuesBucket = {
      updated_at: request.updated_at,
      folder_id: request.folder_id,
      name: request.name,
      url: request.url,
      method: request.method,
      headers: this.stringifyJson(request.headers),
      query_params: this.stringifyJson(request.query_params),
      body: request.body,
      body_type: request.body_type,
      auth: this.stringifyJson(request.auth),
      sort_priority: request.sort_priority
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', request.id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Delete a request (soft delete)
   */
  async deleteRequest(id: string): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      deleted_at: this.getCurrentTimestamp()
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Permanently delete a request
   */
  async permanentlyDeleteRequest(id: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.delete(predicates);
  }

  /**
   * Update request sort priority
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
   * Map ResultSet to HttpRequest object
   */
  private mapResultSetToRequest(resultSet: relationalStore.ResultSet): HttpRequest {
    const request = new HttpRequest();
    
    request.id = resultSet.getString(resultSet.getColumnIndex('id'));
    request.model = resultSet.getString(resultSet.getColumnIndex('model'));
    request.workspace_id = resultSet.getString(resultSet.getColumnIndex('workspace_id'));
    
    const folderIdIndex = resultSet.getColumnIndex('folder_id');
    request.folder_id = resultSet.isColumnNull(folderIdIndex) ? null : resultSet.getString(folderIdIndex);
    
    request.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    request.updated_at = resultSet.getLong(resultSet.getColumnIndex('updated_at'));
    
    const deletedAtIndex = resultSet.getColumnIndex('deleted_at');
    request.deleted_at = resultSet.isColumnNull(deletedAtIndex) ? null : resultSet.getLong(deletedAtIndex);
    
    request.name = resultSet.getString(resultSet.getColumnIndex('name'));
    request.url = resultSet.getString(resultSet.getColumnIndex('url'));
    request.method = resultSet.getString(resultSet.getColumnIndex('method')) as HttpMethod;
    
    const headersStr = resultSet.getString(resultSet.getColumnIndex('headers'));
    request.headers = this.parseJson(headersStr, []);
    
    const queryParamsStr = resultSet.getString(resultSet.getColumnIndex('query_params'));
    request.query_params = this.parseJson(queryParamsStr, []);
    
    const bodyIndex = resultSet.getColumnIndex('body');
    request.body = resultSet.isColumnNull(bodyIndex) ? null : resultSet.getString(bodyIndex);
    
    request.body_type = resultSet.getString(resultSet.getColumnIndex('body_type')) as BodyType;
    
    const authStr = resultSet.getString(resultSet.getColumnIndex('auth'));
    request.auth = this.parseJson(authStr, new AuthConfig());
    
    request.sort_priority = resultSet.getDouble(resultSet.getColumnIndex('sort_priority'));

    return request;
  }
}
