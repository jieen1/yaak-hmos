import http from '@ohos.net.http';
import { HttpRequest } from '../model/HttpRequest';
import { TemplateEngine } from './TemplateEngine';
import { HeaderItem } from '../model/Types';

export class RequestExecutor {
  public static async execute(request: HttpRequest, variables: Record<string, string> = {}): Promise<http.HttpResponse> {
    const httpRequest = http.createHttp();
    
    // 1. Render variables in URL, Method, Headers, Body
    const url = TemplateEngine.render(request.url, variables);
    const methodStr = TemplateEngine.render(request.method, variables);
    const headersStr = TemplateEngine.render(request.headers, variables);
    const bodyStr = request.body ? TemplateEngine.render(request.body, variables) : ""; // Ensure string

    let method = http.RequestMethod.GET;
    switch (methodStr.toUpperCase()) {
      case 'POST': method = http.RequestMethod.POST; break;
      case 'PUT': method = http.RequestMethod.PUT; break;
      case 'DELETE': method = http.RequestMethod.DELETE; break;
      case 'OPTIONS': method = http.RequestMethod.OPTIONS; break;
      case 'HEAD': method = http.RequestMethod.HEAD; break;
      // PATCH is not directly in RequestMethod enum in some API versions, check compat or use string if allowed (often not in strict mode)
      // If PATCH is missing, we might need a workaround or omit it. 
      // For standard ArkTS/API 9+, PATCH might be missing.
      // Let's assume unsupported if error persists, or map to POST with override header if API supports it?
      // Re-checking API docs for PATCH. If not present, remove it.
      // case 'PATCH': method = http.RequestMethod.PATCH; break; 
    }

    let headers: Record<string, string> = {};
    try {
      const headersArray: Array<HeaderItem> = JSON.parse(headersStr) as Array<HeaderItem>;
      headersArray.forEach((h: HeaderItem) => {
        if (h.enabled !== false && h.name) {
            headers[h.name] = h.value;
        }
      });
    } catch (e) {
      console.warn('Failed to parse headers', JSON.stringify(e));
    }

    const options: http.HttpRequestOptions = {
      method: method,
      header: headers,
      extraData: bodyStr, 
      expectDataType: http.HttpDataType.STRING, 
    };

    try {
        const response = await httpRequest.request(url, options);
        httpRequest.destroy();
        return response;
    } catch (err) {
        httpRequest.destroy();
        throw new Error(JSON.stringify(err)); // Wrap error in Error object
    }
  }
}
