/**
 * Request Repository
 * Handles CRUD operations for HTTP requests
 * Supports encryption of auth credentials
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { HttpRequest, HttpHeader, QueryParam, AuthConfig } from '../model/HttpRequest';
import { HttpMethod, BodyType } from '../model/Types';
import { SecureDataService } from '../services/SecureDataService';

export class RequestRepository extends BaseRepository {
  private secureDataService: SecureDataService;

  constructor() {
    super('http_requests');
    this.secureDataService = SecureDataService.getInstance();
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
        // Decrypt auth credentials
        request.auth = await this.secureDataService.decryptAuthConfig(request.auth);
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
        const request = this.mapResultSetToRequest(resultSet);
        // Decrypt auth credentials
        request.auth = await this.secureDataService.decryptAuthConfig(request.auth);
        return request;
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
        // Decrypt auth credentials
        request.auth = await this.secureDataService.decryptAuthConfig(request.auth);
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

    // Encrypt auth credentials before saving
    const encryptedAuth: AuthConfig = await this.secureDataService.encryptAuthConfig(request.auth);

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
      auth: this.stringifyJson(encryptedAuth),
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

    // Encrypt auth credentials before saving
    const encryptedAuth: AuthConfig = await this.secureDataService.encryptAuthConfig(request.auth);

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
      auth: this.stringifyJson(encryptedAuth),
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

  /**
   * Get requests by workspace ID with pagination
   * @param workspaceId The workspace ID
   * @param offset The offset for pagination
   * @param limit The maximum number of results
   * @returns Paginated list of requests
   */
  async getRequestsByWorkspaceIdPaginated(
    workspaceId: string,
    offset: number,
    limit: number
  ): Promise<HttpRequest[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);
    predicates.isNull('deleted_at');
    predicates.orderByAsc('sort_priority');
    predicates.offsetAs(offset);
    predicates.limitAs(limit);

    const resultSet = await this.query(predicates);
    const requests: HttpRequest[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const request = this.mapResultSetToRequest(resultSet);
        request.auth = await this.secureDataService.decryptAuthConfig(request.auth);
        requests.push(request);
      }
    } finally {
      resultSet.close();
    }

    return requests;
  }

  /**
   * Get total count of requests in a workspace
   * @param workspaceId The workspace ID
   * @returns Total count
   */
  async getRequestCountByWorkspaceId(workspaceId: string): Promise<number> {
    const predicates = this.createPredicates();
    predicates.equalTo('workspace_id', workspaceId);
    predicates.isNull('deleted_at');

    const resultSet = await this.query(predicates);
    try {
      return resultSet.rowCount;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Batch create multiple requests
   * @param requests Array of requests to create
   * @returns Array of created request IDs
   */
  async batchCreateRequests(requests: HttpRequest[]): Promise<string[]> {
    const ids: string[] = [];
    const now = this.getCurrentTimestamp();

    await this.executeInTransaction(async () => {
      for (let i = 0; i < requests.length; i++) {
        const request: HttpRequest | undefined = requests[i];
        if (request) {
          request.id = request.id || this.generateId('rq');
          request.created_at = now;
          request.updated_at = now;

          const encryptedAuth: AuthConfig = await this.secureDataService.encryptAuthConfig(request.auth);

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
            auth: this.stringifyJson(encryptedAuth),
            sort_priority: request.sort_priority
          };

          await this.insert(valueBucket);
          ids.push(request.id);
        }
      }
    });

    return ids;
  }

  /**
   * Batch update multiple requests
   * @param requests Array of requests to update
   */
  async batchUpdateRequests(requests: HttpRequest[]): Promise<void> {
    const now = this.getCurrentTimestamp();

    await this.executeInTransaction(async () => {
      for (let i = 0; i < requests.length; i++) {
        const request: HttpRequest | undefined = requests[i];
        if (request) {
          request.updated_at = now;

          const encryptedAuth: AuthConfig = await this.secureDataService.encryptAuthConfig(request.auth);

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
            auth: this.stringifyJson(encryptedAuth),
            sort_priority: request.sort_priority
          };

          const predicates = this.createPredicates();
          predicates.equalTo('id', request.id);

          await this.update(valueBucket, predicates);
        }
      }
    });
  }

  /**
   * Batch delete multiple requests (soft delete)
   * @param ids Array of request IDs to delete
   */
  async batchDeleteRequests(ids: string[]): Promise<void> {
    const now = this.getCurrentTimestamp();

    await this.executeInTransaction(async () => {
      for (let i = 0; i < ids.length; i++) {
        const id: string | undefined = ids[i];
        if (id) {
          const valueBucket: relationalStore.ValuesBucket = {
            deleted_at: now
          };

          const predicates = this.createPredicates();
          predicates.equalTo('id', id);

          await this.update(valueBucket, predicates);
        }
      }
    });
  }
}
