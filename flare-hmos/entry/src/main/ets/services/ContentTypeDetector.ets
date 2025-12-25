/**
 * ContentTypeDetector Service
 * Detects content type from HTTP response headers and content
 * Based on Tauri's contentType.ts implementation
 */

export interface ContentTypeInfo {
  category: 'text' | 'image' | 'video' | 'audio' | 'pdf' | 'binary';
  language: 'json' | 'xml' | 'html' | 'css' | 'javascript' | 'text' | 'none';
  mimeType: string;
  canFormat: boolean;
}

export class ContentTypeDetector {
  private static readonly MIME_TYPE_MAP: Map<string, ContentTypeInfo> = ContentTypeDetector.initMimeTypeMap();

  private static initMimeTypeMap(): Map<string, ContentTypeInfo> {
    const map: Map<string, ContentTypeInfo> = new Map();
    
    // JSON
    const jsonInfo1: ContentTypeInfo = { category: 'text', language: 'json', mimeType: 'application/json', canFormat: true };
    map.set('application/json', jsonInfo1);
    
    const jsonInfo2: ContentTypeInfo = { category: 'text', language: 'json', mimeType: 'application/ld+json', canFormat: true };
    map.set('application/ld+json', jsonInfo2);
    
    const jsonInfo3: ContentTypeInfo = { category: 'text', language: 'json', mimeType: 'application/vnd.api+json', canFormat: true };
    map.set('application/vnd.api+json', jsonInfo3);
    
    // XML
    const xmlInfo1: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'application/xml', canFormat: true };
    map.set('application/xml', xmlInfo1);
    
    const xmlInfo2: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'text/xml', canFormat: true };
    map.set('text/xml', xmlInfo2);
    
    const xmlInfo3: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'application/atom+xml', canFormat: true };
    map.set('application/atom+xml', xmlInfo3);
    
    const xmlInfo4: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'application/rss+xml', canFormat: true };
    map.set('application/rss+xml', xmlInfo4);
    
    const xmlInfo5: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'application/soap+xml', canFormat: true };
    map.set('application/soap+xml', xmlInfo5);
    
    // HTML
    const htmlInfo1: ContentTypeInfo = { category: 'text', language: 'html', mimeType: 'text/html', canFormat: true };
    map.set('text/html', htmlInfo1);
    
    const htmlInfo2: ContentTypeInfo = { category: 'text', language: 'html', mimeType: 'application/xhtml+xml', canFormat: true };
    map.set('application/xhtml+xml', htmlInfo2);
    
    // CSS
    const cssInfo: ContentTypeInfo = { category: 'text', language: 'css', mimeType: 'text/css', canFormat: true };
    map.set('text/css', cssInfo);
    
    // JavaScript
    const jsInfo1: ContentTypeInfo = { category: 'text', language: 'javascript', mimeType: 'application/javascript', canFormat: true };
    map.set('application/javascript', jsInfo1);
    
    const jsInfo2: ContentTypeInfo = { category: 'text', language: 'javascript', mimeType: 'text/javascript', canFormat: true };
    map.set('text/javascript', jsInfo2);
    
    const jsInfo3: ContentTypeInfo = { category: 'text', language: 'javascript', mimeType: 'application/x-javascript', canFormat: true };
    map.set('application/x-javascript', jsInfo3);
    
    // Plain Text
    const textInfo1: ContentTypeInfo = { category: 'text', language: 'text', mimeType: 'text/plain', canFormat: false };
    map.set('text/plain', textInfo1);
    
    const textInfo2: ContentTypeInfo = { category: 'text', language: 'text', mimeType: 'text/csv', canFormat: false };
    map.set('text/csv', textInfo2);
    
    // Images
    const imgInfo1: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/jpeg', canFormat: false };
    map.set('image/jpeg', imgInfo1);
    
    const imgInfo2: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/jpg', canFormat: false };
    map.set('image/jpg', imgInfo2);
    
    const imgInfo3: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/png', canFormat: false };
    map.set('image/png', imgInfo3);
    
    const imgInfo4: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/gif', canFormat: false };
    map.set('image/gif', imgInfo4);
    
    const imgInfo5: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/webp', canFormat: false };
    map.set('image/webp', imgInfo5);
    
    const imgInfo6: ContentTypeInfo = { category: 'text', language: 'xml', mimeType: 'image/svg+xml', canFormat: true };
    map.set('image/svg+xml', imgInfo6);
    
    const imgInfo7: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/bmp', canFormat: false };
    map.set('image/bmp', imgInfo7);
    
    const imgInfo8: ContentTypeInfo = { category: 'image', language: 'none', mimeType: 'image/x-icon', canFormat: false };
    map.set('image/x-icon', imgInfo8);
    
    // Video
    const videoInfo1: ContentTypeInfo = { category: 'video', language: 'none', mimeType: 'video/mp4', canFormat: false };
    map.set('video/mp4', videoInfo1);
    
    const videoInfo2: ContentTypeInfo = { category: 'video', language: 'none', mimeType: 'video/webm', canFormat: false };
    map.set('video/webm', videoInfo2);
    
    const videoInfo3: ContentTypeInfo = { category: 'video', language: 'none', mimeType: 'video/ogg', canFormat: false };
    map.set('video/ogg', videoInfo3);
    
    const videoInfo4: ContentTypeInfo = { category: 'video', language: 'none', mimeType: 'video/mpeg', canFormat: false };
    map.set('video/mpeg', videoInfo4);
    
    const videoInfo5: ContentTypeInfo = { category: 'video', language: 'none', mimeType: 'video/quicktime', canFormat: false };
    map.set('video/quicktime', videoInfo5);
    
    // Audio
    const audioInfo1: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/mpeg', canFormat: false };
    map.set('audio/mpeg', audioInfo1);
    
    const audioInfo2: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/mp3', canFormat: false };
    map.set('audio/mp3', audioInfo2);
    
    const audioInfo3: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/wav', canFormat: false };
    map.set('audio/wav', audioInfo3);
    
    const audioInfo4: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/ogg', canFormat: false };
    map.set('audio/ogg', audioInfo4);
    
    const audioInfo5: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/webm', canFormat: false };
    map.set('audio/webm', audioInfo5);
    
    const audioInfo6: ContentTypeInfo = { category: 'audio', language: 'none', mimeType: 'audio/aac', canFormat: false };
    map.set('audio/aac', audioInfo6);
    
    // PDF
    const pdfInfo: ContentTypeInfo = { category: 'pdf', language: 'none', mimeType: 'application/pdf', canFormat: false };
    map.set('application/pdf', pdfInfo);
    
    // Binary
    const binaryInfo: ContentTypeInfo = { category: 'binary', language: 'none', mimeType: 'application/octet-stream', canFormat: false };
    map.set('application/octet-stream', binaryInfo);
    
    return map;
  }

  /**
   * Detect content type from Content-Type header and content
   * @param contentTypeHeader - Content-Type header value (e.g., "application/json; charset=utf-8")
   * @param content - Response body content (first 20 bytes for detection)
   * @returns ContentTypeInfo object
   */
  static detect(contentTypeHeader: string | null, content: string): ContentTypeInfo {
    console.info(`[ContentTypeDetector] Detecting content type, header: ${contentTypeHeader}`);

    // Parse Content-Type header
    if (contentTypeHeader) {
      const mimeType: string = ContentTypeDetector.parseMimeType(contentTypeHeader);
      console.info(`[ContentTypeDetector] Parsed MIME type: ${mimeType}`);

      // Check exact match
      const exactMatch: ContentTypeInfo | undefined = ContentTypeDetector.MIME_TYPE_MAP.get(mimeType);
      if (exactMatch) {
        console.info(`[ContentTypeDetector] Exact match found: ${exactMatch.category}/${exactMatch.language}`);
        return exactMatch;
      }

      // Check wildcard matches
      if (mimeType.startsWith('image/')) {
        console.info('[ContentTypeDetector] Wildcard match: image/*');
        const info: ContentTypeInfo = {
          category: 'image',
          language: 'none',
          mimeType: mimeType,
          canFormat: false
        };
        return info;
      }

      if (mimeType.startsWith('video/')) {
        console.info('[ContentTypeDetector] Wildcard match: video/*');
        const info: ContentTypeInfo = {
          category: 'video',
          language: 'none',
          mimeType: mimeType,
          canFormat: false
        };
        return info;
      }

      if (mimeType.startsWith('audio/')) {
        console.info('[ContentTypeDetector] Wildcard match: audio/*');
        const info: ContentTypeInfo = {
          category: 'audio',
          language: 'none',
          mimeType: mimeType,
          canFormat: false
        };
        return info;
      }

      if (mimeType.startsWith('text/')) {
        console.info('[ContentTypeDetector] Wildcard match: text/*');
        const info: ContentTypeInfo = {
          category: 'text',
          language: 'text',
          mimeType: mimeType,
          canFormat: false
        };
        return info;
      }
    }

    // Fallback to content-based detection
    console.info('[ContentTypeDetector] No header match, using content-based detection');
    return ContentTypeDetector.detectFromContent(content);
  }

  /**
   * Parse MIME type from Content-Type header
   * Removes charset and other parameters
   */
  private static parseMimeType(contentTypeHeader: string): string {
    const parts: string[] = contentTypeHeader.split(';');
    const mimeType: string = parts[0] ? parts[0].trim().toLowerCase() : '';
    return mimeType;
  }

  /**
   * Detect content type from content itself
   * Checks first 20 bytes for common patterns
   */
  private static detectFromContent(content: string): ContentTypeInfo {
    if (content.length === 0) {
      console.info('[ContentTypeDetector] Empty content, defaulting to text/plain');
      const info: ContentTypeInfo = {
        category: 'text',
        language: 'text',
        mimeType: 'text/plain',
        canFormat: false
      };
      return info;
    }

    // Get first 20 bytes for detection
    const prefix: string = content.substring(0, 20).trim();
    console.info(`[ContentTypeDetector] Content prefix: ${prefix}`);

    // Check for JSON
    if (prefix.startsWith('{') || prefix.startsWith('[')) {
      console.info('[ContentTypeDetector] Content-based detection: JSON');
      const info: ContentTypeInfo = {
        category: 'text',
        language: 'json',
        mimeType: 'application/json',
        canFormat: true
      };
      return info;
    }

    // Check for HTML
    if (prefix.toLowerCase().startsWith('<!doctype html') ||
        prefix.toLowerCase().startsWith('<html')) {
      console.info('[ContentTypeDetector] Content-based detection: HTML');
      const info: ContentTypeInfo = {
        category: 'text',
        language: 'html',
        mimeType: 'text/html',
        canFormat: true
      };
      return info;
    }

    // Check for XML
    if (prefix.startsWith('<?xml') || prefix.startsWith('<')) {
      console.info('[ContentTypeDetector] Content-based detection: XML');
      const info: ContentTypeInfo = {
        category: 'text',
        language: 'xml',
        mimeType: 'application/xml',
        canFormat: true
      };
      return info;
    }

    // Default to plain text
    console.info('[ContentTypeDetector] Content-based detection: plain text (default)');
    const info: ContentTypeInfo = {
      category: 'text',
      language: 'text',
      mimeType: 'text/plain',
      canFormat: false
    };
    return info;
  }
}
