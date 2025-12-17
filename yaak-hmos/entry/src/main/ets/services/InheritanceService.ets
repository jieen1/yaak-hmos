/**
 * Inheritance Service
 * Handles authentication and header inheritance from folders and workspaces
 */

import { HttpRequest, AuthConfig, HttpHeader } from '../model/HttpRequest';
import { Folder } from '../model/Folder';
import { Workspace } from '../model/Workspace';

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
    const folderChain: Folder[] = this.getFolderChain(request.folder_id, folders);
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
      (h: HttpHeader) => h.name.toLowerCase() === headerName.toLowerCase()
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
        (h: HttpHeader) => h.name.toLowerCase() === headerName.toLowerCase()
      );
      if (folderHeader !== undefined) {
        return `folder: ${folder.name}`;
      }

      currentFolderId = folder.folder_id;
    }

    // Check workspace
    if (workspace !== null) {
      const workspaceHeader: HttpHeader | undefined = workspace.headers.find(
        (h: HttpHeader) => h.name.toLowerCase() === headerName.toLowerCase()
      );
      if (workspaceHeader !== undefined) {
        return `workspace: ${workspace.name}`;
      }
    }

    return 'unknown';
  }
}
