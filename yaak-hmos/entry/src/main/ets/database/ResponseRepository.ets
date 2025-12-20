/**
 * Response Repository
 * Handles CRUD operations for HTTP responses
 */

import relationalStore from '@ohos.data.relationalStore';
import { BaseRepository } from './BaseRepository';
import { HttpResponse, ResponseHeader } from '../model/HttpResponse';
import { ResponseState } from '../model/Types';

/**
 * Plain header object for JSON serialization (without @Trace decorators)
 */
interface PlainHeader {
  name: string;
  value: string;
}

export class ResponseRepository extends BaseRepository {
  constructor() {
    super('http_responses');
  }

  /**
   * Get all responses by request ID
   */
  async getResponsesByRequestId(requestId: string): Promise<HttpResponse[]> {
    const predicates = this.createPredicates();
    predicates.equalTo('request_id', requestId);
    predicates.orderByDesc('created_at');

    const resultSet = await this.query(predicates);
    const responses: HttpResponse[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const response = this.mapResultSetToResponse(resultSet);
        responses.push(response);
      }
    } finally {
      resultSet.close();
    }

    return responses;
  }

  /**
   * Get response by ID
   */
  async getResponseById(id: string): Promise<HttpResponse | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToResponse(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Get latest response for a request
   */
  async getLatestResponse(requestId: string): Promise<HttpResponse | null> {
    const predicates = this.createPredicates();
    predicates.equalTo('request_id', requestId);
    predicates.orderByDesc('created_at');
    predicates.limitAs(1);

    const resultSet = await this.query(predicates);

    try {
      if (resultSet.goToFirstRow()) {
        return this.mapResultSetToResponse(resultSet);
      }
      return null;
    } finally {
      resultSet.close();
    }
  }

  /**
   * Create a new response
   */
  async createResponse(response: HttpResponse): Promise<string> {
    response.id = response.id || this.generateId('res');
    response.created_at = this.getCurrentTimestamp();

    // Convert headers to plain objects to avoid @Trace serialization issues
    const plainHeaders: PlainHeader[] = [];
    response.headers.forEach((h: ResponseHeader) => {
      const plainHeader: PlainHeader = { name: h.name, value: h.value };
      plainHeaders.push(plainHeader);
    });

    const valueBucket: relationalStore.ValuesBucket = {
      id: response.id,
      model: response.model,
      request_id: response.request_id,
      created_at: response.created_at,
      status_code: response.status_code,
      status_text: response.status_text,
      headers: this.stringifyJson(plainHeaders),
      body_path: response.body_path,
      elapsed_time: response.elapsed_time,
      size: response.size,
      state: response.state
    };

    await this.insert(valueBucket);
    return response.id;
  }

  /**
   * Update response state
   */
  async updateResponseState(id: string, state: ResponseState): Promise<void> {
    const valueBucket: relationalStore.ValuesBucket = {
      state: state
    };

    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.update(valueBucket, predicates);
  }

  /**
   * Delete a response
   */
  async deleteResponse(id: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('id', id);

    await this.delete(predicates);
  }

  /**
   * Delete all responses for a request
   */
  async deleteResponsesByRequestId(requestId: string): Promise<void> {
    const predicates = this.createPredicates();
    predicates.equalTo('request_id', requestId);

    await this.delete(predicates);
  }

  /**
   * Delete old responses (older than specified timestamp)
   */
  async deleteOldResponses(olderThan: number): Promise<void> {
    const predicates = this.createPredicates();
    predicates.lessThan('created_at', olderThan);

    await this.delete(predicates);
  }

  /**
   * Get all responses
   */
  async getAllResponses(): Promise<HttpResponse[]> {
    const predicates = this.createPredicates();
    const resultSet = await this.query(predicates);
    const responses: HttpResponse[] = [];

    try {
      while (resultSet.goToNextRow()) {
        const response = this.mapResultSetToResponse(resultSet);
        responses.push(response);
      }
    } finally {
      resultSet.close();
    }

    return responses;
  }

  /**
   * Map ResultSet to HttpResponse object
   */
  private mapResultSetToResponse(resultSet: relationalStore.ResultSet): HttpResponse {
    const response = new HttpResponse();
    
    response.id = resultSet.getString(resultSet.getColumnIndex('id'));
    response.model = resultSet.getString(resultSet.getColumnIndex('model'));
    response.request_id = resultSet.getString(resultSet.getColumnIndex('request_id'));
    response.created_at = resultSet.getLong(resultSet.getColumnIndex('created_at'));
    response.status_code = resultSet.getLong(resultSet.getColumnIndex('status_code'));
    response.status_text = resultSet.getString(resultSet.getColumnIndex('status_text'));
    
    const headersStr = resultSet.getString(resultSet.getColumnIndex('headers'));
    console.info('[ResponseRepository] Loading headers from DB, raw string:', headersStr);
    const parsedHeaders: ESObject[] = this.parseJson(headersStr, []);
    console.info('[ResponseRepository] Parsed headers count:', parsedHeaders.length);
    
    // Ensure headers are properly typed ResponseHeader instances
    // Handle both normal properties (name, value) and @Trace decorated properties (__ob_name, __ob_value)
    response.headers = [];
    parsedHeaders.forEach((h: ESObject) => {
      const header: ResponseHeader = new ResponseHeader();
      // Check for @Trace decorated property names first, then fall back to normal names
      header.name = (h['__ob_name'] as string) || (h['name'] as string) || '';
      header.value = (h['__ob_value'] as string) || (h['value'] as string) || '';
      response.headers.push(header);
    });
    console.info('[ResponseRepository] Final headers count:', response.headers.length);
    
    response.body_path = resultSet.getString(resultSet.getColumnIndex('body_path'));
    response.elapsed_time = resultSet.getLong(resultSet.getColumnIndex('elapsed_time'));
    response.size = resultSet.getLong(resultSet.getColumnIndex('size'));
    response.state = resultSet.getString(resultSet.getColumnIndex('state')) as ResponseState;

    return response;
  }
}
