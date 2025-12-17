/**
 * Request Executor Service
 * Handles HTTP request execution with full support for authentication, headers, and body types
 */

import http from '@ohos.net.http';
import { HttpRequest } from '../model/HttpRequest';
import { HttpResponse, ResponseHeader } from '../model/HttpResponse';
import { TemplateEngine } from './TemplateEngine';
import { AuthService } from './AuthService';
import { CookieService } from './CookieService';
import { ResponseStorageService } from './ResponseStorageService';
import { ResponseRepository } from '../database/ResponseRepository';

export interface RequestExecutionResult {
  response: HttpResponse;
  bodyContent: string;
}

export class RequestExecutor {
  private static responseRepository = new ResponseRepository();

  /**
   * Execute HTTP request
   */
  static async execute(
    request: HttpRequest,
    workspaceId: string,
    variables: Map<string, string>
  ): Promise<RequestExecutionResult> {
    const startTime = Date.now();
    const httpClient = http.createHttp();

    try {
      // 1. Resolve template variables in URL
      const resolvedUrl = this.buildUrl(request, variables);

      // 2. Resolve headers
      const resolvedHeaders = this.resolveHeaders(request, variables);

      // 3. Apply authentication
      const authHeaders = AuthService.getAuthHeaders(request.auth, variables);
      const finalHeaders = { ...resolvedHeaders, ...authHeaders };

      // 4. Get cookies
      const cookieHeader = await CookieService.getCookieHeader(workspaceId, resolvedUrl);
      if (cookieHeader) {
        finalHeaders['Cookie'] = cookieHeader;
      }

      // 5. Resolve body
      const resolvedBody = this.resolveBody(request, variables);

      // 6. Build HTTP request options
      const options: http.HttpRequestOptions = {
        method: this.mapHttpMethod(request.method),
        header: finalHeaders,
        expectDataType: http.HttpDataType.STRING,
        connectTimeout: 30000,
        readTimeout: 30000
      };

      if (resolvedBody) {
        options.extraData = resolvedBody;
      }

      // 7. Execute request
      console.info(`Executing ${request.method} ${resolvedUrl}`);
      const httpResponse = await httpClient.request(resolvedUrl, options);

      // 8. Calculate elapsed time
      const elapsedTime = Date.now() - startTime;

      // 9. Store cookies from response
      await CookieService.storeCookies(workspaceId, httpResponse.header, resolvedUrl);

      // 10. Create response object
      const response = new HttpResponse();
      response.request_id = request.id;
      response.status_code = httpResponse.responseCode;
      response.status_text = this.getStatusText(httpResponse.responseCode);
      response.headers = this.parseResponseHeaders(httpResponse.header);
      response.elapsed_time = elapsedTime;
      response.state = 'success';

      // 11. Get response body
      const bodyContent = typeof httpResponse.result === 'string'
        ? httpResponse.result
        : JSON.stringify(httpResponse.result);
      response.size = bodyContent.length;

      // 12. Save response body to file
      response.body_path = await ResponseStorageService.saveResponseBody(
        response.id || this.generateResponseId(),
        bodyContent
      );

      // 13. Save response to database
      await this.responseRepository.createResponse(response);

      console.info(`Request completed: ${response.status_code} in ${elapsedTime}ms`);

      return {
        response,
        bodyContent
      };
    } catch (error) {
      console.error(`Request execution failed: ${JSON.stringify(error)}`);

      // Create error response
      const elapsedTime = Date.now() - startTime;
      const response = new HttpResponse();
      response.request_id = request.id;
      response.status_code = 0;
      response.status_text = 'Error';
      response.headers = [];
      response.elapsed_time = elapsedTime;
      response.state = 'error';
      response.size = 0;

      const errorMessage = `Request failed: ${JSON.stringify(error)}`;
      response.body_path = await ResponseStorageService.saveResponseBody(
        response.id || this.generateResponseId(),
        errorMessage
      );

      await this.responseRepository.createResponse(response);

      return {
        response,
        bodyContent: errorMessage
      };
    } finally {
      httpClient.destroy();
    }
  }

  /**
   * Build URL with query parameters and template resolution
   */
  private static buildUrl(request: HttpRequest, variables: Map<string, string>): string {
    let url = TemplateEngine.resolve(request.url, variables);

    // Add enabled query parameters
    const queryParams = request.query_params
      .filter(p => p.enabled)
      .map(p => {
        const name = TemplateEngine.resolve(p.name, variables);
        const value = TemplateEngine.resolve(p.value, variables);
        return `${encodeURIComponent(name)}=${encodeURIComponent(value)}`;
      });

    // Add API key as query parameter if needed
    const apiKeyParams = AuthService.getApiKeyQueryParams(request.auth, variables);
    Object.entries(apiKeyParams).forEach(([name, value]) => {
      queryParams.push(`${encodeURIComponent(name)}=${encodeURIComponent(value)}`);
    });

    if (queryParams.length > 0) {
      const separator = url.includes('?') ? '&' : '?';
      url += separator + queryParams.join('&');
    }

    return url;
  }

  /**
   * Resolve headers with template variables
   */
  private static resolveHeaders(
    request: HttpRequest,
    variables: Map<string, string>
  ): Record<string, string> {
    const headers: Record<string, string> = {};

    request.headers
      .filter(h => h.enabled)
      .forEach(header => {
        const name = TemplateEngine.resolve(header.name, variables);
        const value = TemplateEngine.resolve(header.value, variables);
        headers[name] = value;
      });

    return headers;
  }

  /**
   * Resolve request body based on body type
   */
  private static resolveBody(
    request: HttpRequest,
    variables: Map<string, string>
  ): string | null {
    if (!request.body || request.body_type === 'none') {
      return null;
    }

    switch (request.body_type) {
      case 'json':
      case 'xml':
      case 'text':
      case 'graphql':
        return TemplateEngine.resolve(request.body, variables);
      case 'form-urlencoded':
        return this.buildFormUrlEncoded(request.body, variables);
      case 'form-data':
        // Form-data requires special handling, will be implemented in task 13
        return request.body;
      case 'binary':
        // Binary requires file reading, will be implemented in task 13
        return request.body;
      default:
        return request.body;
    }
  }

  /**
   * Build form-urlencoded body
   */
  private static buildFormUrlEncoded(body: string, variables: Map<string, string>): string {
    try {
      const data = JSON.parse(body);
      const params: string[] = [];

      Object.entries(data).forEach(([key, value]) => {
        const resolvedKey = TemplateEngine.resolve(key, variables);
        const resolvedValue = TemplateEngine.resolve(String(value), variables);
        params.push(`${encodeURIComponent(resolvedKey)}=${encodeURIComponent(resolvedValue)}`);
      });

      return params.join('&');
    } catch (error) {
      console.error(`Failed to build form-urlencoded body: ${error}`);
      return body;
    }
  }

  /**
   * Map HttpMethod to http.RequestMethod
   */
  private static mapHttpMethod(method: string): http.RequestMethod {
    switch (method.toUpperCase()) {
      case 'GET':
        return http.RequestMethod.GET;
      case 'POST':
        return http.RequestMethod.POST;
      case 'PUT':
        return http.RequestMethod.PUT;
      case 'DELETE':
        return http.RequestMethod.DELETE;
      case 'PATCH':
        return http.RequestMethod.PATCH;
      case 'HEAD':
        return http.RequestMethod.HEAD;
      case 'OPTIONS':
        return http.RequestMethod.OPTIONS;
      default:
        return http.RequestMethod.GET;
    }
  }

  /**
   * Parse response headers
   */
  private static parseResponseHeaders(headers: Object): ResponseHeader[] {
    const responseHeaders: ResponseHeader[] = [];

    Object.entries(headers).forEach(([name, value]) => {
      const header = new ResponseHeader();
      header.name = name;
      header.value = Array.isArray(value) ? value.join(', ') : String(value);
      responseHeaders.push(header);
    });

    return responseHeaders;
  }

  /**
   * Get status text for status code
   */
  private static getStatusText(statusCode: number): string {
    const statusTexts: Record<number, string> = {
      200: 'OK',
      201: 'Created',
      204: 'No Content',
      400: 'Bad Request',
      401: 'Unauthorized',
      403: 'Forbidden',
      404: 'Not Found',
      500: 'Internal Server Error',
      502: 'Bad Gateway',
      503: 'Service Unavailable'
    };

    return statusTexts[statusCode] || 'Unknown';
  }

  /**
   * Generate response ID
   */
  private static generateResponseId(): string {
    const timestamp = Date.now();
    const random = Math.floor(Math.random() * 10000);
    return `res_${timestamp}_${random}`;
  }

  /**
   * Cancel request (placeholder for future implementation)
   */
  static async cancelRequest(requestId: string): Promise<void> {
    // Will be implemented when we add request tracking
    console.info(`Cancel request: ${requestId}`);
  }
}
