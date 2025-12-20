/**
 * Inheritance Service
 * Handles authentication and header inheritance from folders and workspaces
 */

import { HttpRequest, AuthConfig, HttpHeader } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Workspace } from '../model/Workspace';

/**
 * Inherited header with source information
 */
export interface InheritedHeaderWithSource {
  header: HttpHeader;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}

/**
 * Inherited authentication with source information
 */
export interface InheritedAuthInfo {
  auth: AuthConfig;
  sourceType: 'folder' | 'workspace';
  sourceId: string;
  sourceName: string;
}

export class InheritanceService {
  /**
   * Resolve authentication with inheritance
   * Priority: Request > Folder > Parent Folder > ... > Workspace
   */
  static resolveAuth(
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): AuthConfig | null {
    // If request has explicit auth, use it
    if (request.auth !== null && request.auth.type !== 'none') {
      return request.auth;
    }

    // Traverse folder hierarchy
    let currentFolderId: string | null = request.folder_id;
    while (currentFolderId !== null) {
      const folder: Folder | undefined = folders.find((f: Folder) => f.id === currentFolderId);
      if (folder === undefined) {
        break;
      }

      // Check if folder has auth
      if (folder.auth !== null && folder.auth.type !== 'none') {
        return folder.auth;
      }

      // Move to parent folder
      currentFolderId = folder.folder_id;
    }

    // Check workspace auth
    if (workspace !== null && workspace.auth !== null && workspace.auth.type !== 'none') {
      return workspace.auth;
    }

    return null;
  }

  /**
   * Resolve headers with inheritance and merging
   * Priority: Request headers override folder headers
   * Merges all headers from request → folder → parent folder → workspace
   */
  static resolveHeaders(
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): HttpHeader[] {
    const headerMap: Map<string, HttpHeader> = new Map();

    // Start with workspace headers (lowest priority)
    if (workspace !== null && workspace.headers.length > 0) {
      workspace.headers.forEach((header: HttpHeader) => {
        if (header.enabled) {
          headerMap.set(header.name.toLowerCase(), header);
        }
      });
    }

    // Add folder headers in order from root to leaf (middle priority)
    const folderChain: Folder[] = InheritanceService.getFolderChain(request.folder_id, folders);
    folderChain.forEach((folder: Folder) => {
      folder.headers.forEach((header: HttpHeader) => {
        if (header.enabled) {
          headerMap.set(header.name.toLowerCase(), header);
        }
      });
    });

    // Add request headers (highest priority)
    request.headers.forEach((header: HttpHeader) => {
      if (header.enabled) {
        headerMap.set(header.name.toLowerCase(), header);
      }
    });

    // Convert map back to array
    const result: HttpHeader[] = [];
    headerMap.forEach((header: HttpHeader) => {
      result.push(header);
    });

    return result;
  }

  /**
   * Get folder chain from leaf to root
   */
  private static getFolderChain(folderId: string | null, folders: Folder[]): Folder[] {
    const chain: Folder[] = [];
    let currentFolderId: string | null = folderId;

    while (currentFolderId !== null) {
      const folder: Folder | undefined = folders.find((f: Folder) => f.id === currentFolderId);
      if (folder === undefined) {
        break;
      }
      chain.unshift(folder); // Add to beginning to maintain root-to-leaf order
      currentFolderId = folder.folder_id;
    }

    return chain;
  }

  /**
   * Check if auth is inherited (not directly set on request)
   */
  static isAuthInherited(request: HttpRequest): boolean {
    return request.auth === null || request.auth.type === 'none';
  }

  /**
   * Check if a specific header is inherited
   */
  static isHeaderInherited(headerName: string, request: HttpRequest): boolean {
    const requestHeader: HttpHeader | undefined = request.headers.find(
      (h: HttpHeader) => h.name?.toLowerCase() === headerName.toLowerCase()
    );
    return requestHeader === undefined;
  }

  /**
   * Get the source of auth inheritance
   */
  static getAuthSource(
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): string {
    // If request has explicit auth
    if (request.auth !== null && request.auth.type !== 'none') {
      return 'request';
    }

    // Check folder hierarchy
    let currentFolderId: string | null = request.folder_id;
    while (currentFolderId !== null) {
      const folder: Folder | undefined = folders.find((f: Folder) => f.id === currentFolderId);
      if (folder === undefined) {
        break;
      }

      if (folder.auth !== null && folder.auth.type !== 'none') {
        return `folder: ${folder.name}`;
      }

      currentFolderId = folder.folder_id;
    }

    // Check workspace
    if (workspace !== null && workspace.auth !== null && workspace.auth.type !== 'none') {
      return `workspace: ${workspace.name}`;
    }

    return 'none';
  }

  /**
   * Get the source of a specific header
   */
  static getHeaderSource(
    headerName: string,
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): string {
    // Check request headers
    const requestHeader: HttpHeader | undefined = request.headers.find(
      (h: HttpHeader) => h.name.toLowerCase() === headerName.toLowerCase()
    );
    if (requestHeader !== undefined) {
      return 'request';
    }

    // Check folder hierarchy (leaf to root)
    let currentFolderId: string | null = request.folder_id;
    while (currentFolderId !== null) {
      const folder: Folder | undefined = folders.find((f: Folder) => f.id === currentFolderId);
      if (folder === undefined) {
        break;
      }

      const folderHeader: HttpHeader | undefined = folder.headers.find(
        (h: HttpHeader) => h.name?.toLowerCase() === headerName.toLowerCase()
      );
      if (folderHeader !== undefined) {
        return `folder: ${folder.name}`;
      }

      currentFolderId = folder.folder_id;
    }

    // Check workspace
    if (workspace !== null) {
      const workspaceHeader: HttpHeader | undefined = workspace.headers.find(
        (h: HttpHeader) => h.name?.toLowerCase() === headerName.toLowerCase()
      );
      if (workspaceHeader !== undefined) {
        return `workspace: ${workspace.name}`;
      }
    }

    return 'unknown';
  }

  /**
   * Get inherited headers with source information
   * Returns headers from parent folders and workspace (not from the request itself)
   */
  static getInheritedHeadersWithSource(
    folderId: string | null,
    folders: Folder[],
    workspace: Workspace | null
  ): InheritedHeaderWithSource[] {
    const result: InheritedHeaderWithSource[] = [];
    const seenHeaders: Set<string> = new Set();

    // Start with workspace headers (lowest priority, will be overridden)
    if (workspace !== null && workspace.headers.length > 0) {
      workspace.headers.forEach((header: HttpHeader) => {
        if (header.enabled && header.name) {
          const key: string = header.name.toLowerCase();
          if (!seenHeaders.has(key)) {
            const inheritedHeader: InheritedHeaderWithSource = {
              header: header,
              sourceType: 'workspace',
              sourceId: workspace.id,
              sourceName: workspace.name
            };
            result.push(inheritedHeader);
            seenHeaders.add(key);
          }
        }
      });
    }

    // Add folder headers in order from root to leaf (higher priority overrides)
    const folderChain: Folder[] = InheritanceService.getFolderChain(folderId, folders);
    
    // Process from root to leaf, later folders override earlier ones
    folderChain.forEach((folder: Folder) => {
      folder.headers.forEach((header: HttpHeader) => {
        if (header.enabled && header.name) {
          const key: string = header.name.toLowerCase();
          // Remove existing header with same name (will be replaced)
          const existingIndex: number = result.findIndex(
            (h: InheritedHeaderWithSource) => h.header.name.toLowerCase() === key
          );
          if (existingIndex >= 0) {
            result.splice(existingIndex, 1);
          }
          
          const inheritedHeader: InheritedHeaderWithSource = {
            header: header,
            sourceType: 'folder',
            sourceId: folder.id,
            sourceName: folder.name
          };
          result.push(inheritedHeader);
          seenHeaders.add(key);
        }
      });
    });

    return result;
  }

  /**
   * Get inherited headers for a request (excludes request's own headers)
   */
  static getInheritedHeadersForRequest(
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): InheritedHeaderWithSource[] {
    const inherited: InheritedHeaderWithSource[] = InheritanceService.getInheritedHeadersWithSource(
      request.folder_id,
      folders,
      workspace
    );

    // Filter out headers that are overridden by request's own headers
    const requestHeaderNames: Set<string> = new Set();
    request.headers.forEach((h: HttpHeader) => {
      if (h.name) {
        requestHeaderNames.add(h.name.toLowerCase());
      }
    });

    const filtered: InheritedHeaderWithSource[] = inherited.filter(
      (ih: InheritedHeaderWithSource) => !requestHeaderNames.has(ih.header.name.toLowerCase())
    );

    return filtered;
  }

  /**
   * Get inherited authentication with source information
   * Returns auth from parent folder or workspace if request doesn't have explicit auth
   */
  static getInheritedAuthWithSource(
    folderId: string | null,
    folders: Folder[],
    workspace: Workspace | null
  ): InheritedAuthInfo | null {
    // Traverse folder hierarchy
    let currentFolderId: string | null = folderId;
    while (currentFolderId !== null) {
      const folder: Folder | undefined = folders.find((f: Folder) => f.id === currentFolderId);
      if (folder === undefined) {
        break;
      }

      // Check if folder has auth
      if (folder.auth !== null && folder.auth.type !== 'none') {
        const authInfo: InheritedAuthInfo = {
          auth: folder.auth,
          sourceType: 'folder',
          sourceId: folder.id,
          sourceName: folder.name
        };
        return authInfo;
      }

      // Move to parent folder
      currentFolderId = folder.folder_id;
    }

    // Check workspace auth
    if (workspace !== null && workspace.auth !== null && workspace.auth.type !== 'none') {
      const authInfo: InheritedAuthInfo = {
        auth: workspace.auth,
        sourceType: 'workspace',
        sourceId: workspace.id,
        sourceName: workspace.name
      };
      return authInfo;
    }

    return null;
  }

  /**
   * Get inherited auth for a request (only if request doesn't have explicit auth)
   */
  static getInheritedAuthForRequest(
    request: HttpRequest,
    folders: Folder[],
    workspace: Workspace | null
  ): InheritedAuthInfo | null {
    // If request has explicit auth, no inheritance
    if (request.auth !== null && request.auth.type !== 'none') {
      return null;
    }

    return InheritanceService.getInheritedAuthWithSource(
      request.folder_id,
      folders,
      workspace
    );
  }
}
