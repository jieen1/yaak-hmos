/**
 * Body Type Handlers
 * Handles different request body types: JSON, XML, Form-Data, Form-Urlencoded, Binary, GraphQL
 */

import fs from '@ohos.file.fs';
import util from '@ohos.util';
import { TemplateEngine } from './TemplateEngine';

export interface FormDataField {
  name: string;
  value: string;
  type: 'text' | 'file';
  filename?: string;
  contentType?: string;
  enabled: boolean;
}

export class BodyTypeHandlers {
  /**
   * Handle JSON body (pass-through with template resolution)
   */
  static handleJsonBody(body: string, variables: Map<string, string>): string {
    return TemplateEngine.resolve(body, variables);
  }

  /**
   * Handle XML body (pass-through with template resolution)
   */
  static handleXmlBody(body: string, variables: Map<string, string>): string {
    return TemplateEngine.resolve(body, variables);
  }

  /**
   * Handle text body (pass-through with template resolution)
   */
  static handleTextBody(body: string, variables: Map<string, string>): string {
    return TemplateEngine.resolve(body, variables);
  }

  /**
   * Handle GraphQL body (JSON format with query and variables)
   */
  static handleGraphQLBody(body: string, variables: Map<string, string>): string {
    try {
      const graphqlData = JSON.parse(body);
      
      // Resolve template variables in query
      if (graphqlData.query) {
        graphqlData.query = TemplateEngine.resolve(graphqlData.query, variables);
      }

      // Resolve template variables in GraphQL variables
      if (graphqlData.variables) {
        const resolvedVariables: Record<string, any> = {};
        Object.entries(graphqlData.variables).forEach(([key, value]) => {
          if (typeof value === 'string') {
            resolvedVariables[key] = TemplateEngine.resolve(value, variables);
          } else {
            resolvedVariables[key] = value;
          }
        });
        graphqlData.variables = resolvedVariables;
      }

      return JSON.stringify(graphqlData);
    } catch (error) {
      console.error(`Failed to handle GraphQL body: ${error}`);
      return body;
    }
  }

  /**
   * Handle form-urlencoded body with URL encoding
   */
  static handleFormUrlencodedBody(body: string, variables: Map<string, string>): string {
    try {
      const fields = JSON.parse(body) as FormDataField[];
      const params: string[] = [];

      fields
        .filter(field => field.enabled)
        .forEach(field => {
          const name = TemplateEngine.resolve(field.name, variables);
          const value = TemplateEngine.resolve(field.value, variables);
          params.push(`${encodeURIComponent(name)}=${encodeURIComponent(value)}`);
        });

      return params.join('&');
    } catch (error) {
      console.error(`Failed to handle form-urlencoded body: ${error}`);
      return body;
    }
  }

  /**
   * Handle multipart form-data body with boundary generation
   */
  static async handleFormDataBody(
    body: string,
    variables: Map<string, string>
  ): Promise<{ body: string; contentType: string }> {
    try {
      const fields = JSON.parse(body) as FormDataField[];
      const boundary = this.generateBoundary();
      const parts: string[] = [];

      for (const field of fields) {
        if (!field.enabled) continue;

        const name = TemplateEngine.resolve(field.name, variables);

        if (field.type === 'text') {
          const value = TemplateEngine.resolve(field.value, variables);
          parts.push(this.buildTextPart(name, value));
        } else if (field.type === 'file') {
          const filePart = await this.buildFilePart(
            name,
            field.value,
            field.filename,
            field.contentType
          );
          parts.push(filePart);
        }
      }

      const bodyContent = parts.join('') + `--${boundary}--\r\n`;
      const contentType = `multipart/form-data; boundary=${boundary}`;

      return { body: bodyContent, contentType };
    } catch (error) {
      console.error(`Failed to handle form-data body: ${error}`);
      return { body, contentType: 'multipart/form-data' };
    }
  }

  /**
   * Handle binary file body
   */
  static async handleBinaryBody(filePath: string): Promise<ArrayBuffer> {
    try {
      // Check if file exists
      await fs.access(filePath);

      // Read file
      const file = await fs.open(filePath, fs.OpenMode.READ_ONLY);
      const stat = await fs.stat(filePath);
      const buffer = new ArrayBuffer(stat.size);
      await fs.read(file.fd, buffer);
      await fs.close(file.fd);

      return buffer;
    } catch (error) {
      console.error(`Failed to read binary file: ${error}`);
      throw new Error(`Failed to read file: ${filePath}`);
    }
  }

  /**
   * Generate unique boundary for multipart form-data
   */
  private static generateBoundary(): string {
    const timestamp = Date.now().toString(36);
    const random = Math.random().toString(36).substring(2);
    return `----YaakFormBoundary${timestamp}${random}`;
  }

  /**
   * Build text part for multipart form-data
   */
  private static buildTextPart(name: string, value: string): string {
    return `Content-Disposition: form-data; name="${name}"\r\n\r\n${value}\r\n`;
  }

  /**
   * Build file part for multipart form-data
   */
  private static async buildFilePart(
    name: string,
    filePath: string,
    filename?: string,
    contentType?: string
  ): Promise<string> {
    try {
      // Read file content
      const buffer = await this.handleBinaryBody(filePath);
      const decoder = new util.TextDecoder('utf-8', { ignoreBOM: true });
      const content = decoder.decodeWithStream(new Uint8Array(buffer), { stream: false });

      // Determine filename
      const actualFilename = filename || filePath.split('/').pop() || 'file';

      // Determine content type
      const actualContentType = contentType || this.guessContentType(actualFilename);

      return `Content-Disposition: form-data; name="${name}"; filename="${actualFilename}"\r\n` +
        `Content-Type: ${actualContentType}\r\n\r\n${content}\r\n`;
    } catch (error) {
      console.error(`Failed to build file part: ${error}`);
      return '';
    }
  }

  /**
   * Guess content type from filename
   */
  private static guessContentType(filename: string): string {
    const ext = filename.split('.').pop()?.toLowerCase();

    const mimeTypes: Record<string, string> = {
      'txt': 'text/plain',
      'html': 'text/html',
      'css': 'text/css',
      'js': 'application/javascript',
      'json': 'application/json',
      'xml': 'application/xml',
      'pdf': 'application/pdf',
      'zip': 'application/zip',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'svg': 'image/svg+xml',
      'mp3': 'audio/mpeg',
      'mp4': 'video/mp4',
      'avi': 'video/x-msvideo'
    };

    return mimeTypes[ext || ''] || 'application/octet-stream';
  }

  /**
   * URL encode special characters
   */
  static urlEncode(str: string): string {
    return encodeURIComponent(str)
      .replace(/[!'()*]/g, (c) => {
        return '%' + c.charCodeAt(0).toString(16).toUpperCase();
      });
  }

  /**
   * URL decode string
   */
  static urlDecode(str: string): string {
    try {
      return decodeURIComponent(str);
    } catch (error) {
      console.error(`Failed to decode URL: ${error}`);
      return str;
    }
  }
}
