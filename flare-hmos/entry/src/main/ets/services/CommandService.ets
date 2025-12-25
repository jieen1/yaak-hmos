/**
 * CommandService - Manage available commands and search
 *
 * Provides:
 * - Built-in commands
 * - Fuzzy search
 * - Command execution
 */

import { HttpRequest } from '../model/HttpRequest';
import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';

/**
 * Command category
 */
export type CommandCategory = 'action' | 'request' | 'environment' | 'workspace' | 'navigation';

/**
 * Command definition
 */
export interface Command {
  id: string;
  label: string;
  category: CommandCategory;
  shortcut: string;
  icon: string;
  action: () => void;
}

/**
 * Command result for search
 */
export interface CommandResult {
  type: CommandCategory;
  id: string;
  label: string;
  description: string;
  shortcut: string;
  icon: string;
  score: number;
}

/**
 * Search context
 */
export interface SearchContext {
  workspaces: Workspace[];
  requests: HttpRequest[];
  environments: Environment[];
  currentWorkspaceId: string;
}

/**
 * Fuzzy match result
 */
interface FuzzyMatchResult {
  matched: boolean;
  score: number;
  highlights: number[];
}

/**
 * Built-in command definition (without action)
 */
interface BuiltInCommandDef {
  id: string;
  label: string;
  category: CommandCategory;
  shortcut: string;
  icon: string;
}

export class CommandService {
  private static builtInCommands: BuiltInCommandDef[] = [];
  private static initialized: boolean = false;

  /**
   * Initialize built-in commands
   */
  private static initBuiltInCommands(): void {
    if (CommandService.initialized) {
      return;
    }

    CommandService.builtInCommands = [];

    const newRequest: BuiltInCommandDef = {
      id: 'new-request',
      label: '新建 HTTP 请求',
      category: 'action',
      shortcut: 'Ctrl+N',
      icon: '📄'
    };
    CommandService.builtInCommands.push(newRequest);

    const newFolder: BuiltInCommandDef = {
      id: 'new-folder',
      label: '新建文件夹',
      category: 'action',
      shortcut: '',
      icon: '📁'
    };
    CommandService.builtInCommands.push(newFolder);

    const newWorkspace: BuiltInCommandDef = {
      id: 'new-workspace',
      label: '新建工作区',
      category: 'action',
      shortcut: '',
      icon: '🗂️'
    };
    CommandService.builtInCommands.push(newWorkspace);

    const importCmd: BuiltInCommandDef = {
      id: 'import',
      label: '导入...',
      category: 'action',
      shortcut: 'Ctrl+I',
      icon: '📥'
    };
    CommandService.builtInCommands.push(importCmd);

    const exportCmd: BuiltInCommandDef = {
      id: 'export',
      label: '导出...',
      category: 'action',
      shortcut: 'Ctrl+E',
      icon: '📤'
    };
    CommandService.builtInCommands.push(exportCmd);

    const settings: BuiltInCommandDef = {
      id: 'settings',
      label: '设置',
      category: 'action',
      shortcut: 'Ctrl+,',
      icon: '⚙️'
    };
    CommandService.builtInCommands.push(settings);

    const sendRequest: BuiltInCommandDef = {
      id: 'send-request',
      label: '发送请求',
      category: 'action',
      shortcut: 'Ctrl+Enter',
      icon: '▶️'
    };
    CommandService.builtInCommands.push(sendRequest);

    const duplicateRequest: BuiltInCommandDef = {
      id: 'duplicate-request',
      label: '复制请求',
      category: 'action',
      shortcut: 'Ctrl+D',
      icon: '📋'
    };
    CommandService.builtInCommands.push(duplicateRequest);

    const toggleSidebar: BuiltInCommandDef = {
      id: 'toggle-sidebar',
      label: '切换侧边栏',
      category: 'navigation',
      shortcut: 'Ctrl+B',
      icon: '📊'
    };
    CommandService.builtInCommands.push(toggleSidebar);

    const focusUrl: BuiltInCommandDef = {
      id: 'focus-url',
      label: '聚焦 URL 栏',
      category: 'navigation',
      shortcut: 'Ctrl+L',
      icon: '🔗'
    };
    CommandService.builtInCommands.push(focusUrl);

    const copyAsCurl: BuiltInCommandDef = {
      id: 'copy-as-curl',
      label: '复制为 cURL',
      category: 'action',
      shortcut: '',
      icon: '📋'
    };
    CommandService.builtInCommands.push(copyAsCurl);

    const toggleResponse: BuiltInCommandDef = {
      id: 'toggle-response',
      label: '切换响应面板',
      category: 'navigation',
      shortcut: '',
      icon: '📊'
    };
    CommandService.builtInCommands.push(toggleResponse);

    CommandService.initialized = true;
  }

  /**
   * Get all built-in command definitions
   */
  static getBuiltInCommands(): BuiltInCommandDef[] {
    CommandService.initBuiltInCommands();
    return CommandService.builtInCommands;
  }

  /**
   * Search commands, requests, and workspaces
   */
  static search(query: string, context: SearchContext): CommandResult[] {
    CommandService.initBuiltInCommands();

    const results: CommandResult[] = [];
    const lowerQuery: string = query.toLowerCase().trim();

    if (lowerQuery.length === 0) {
      // Return all built-in commands when query is empty
      CommandService.builtInCommands.forEach((cmd: BuiltInCommandDef) => {
        const result: CommandResult = {
          type: cmd.category,
          id: cmd.id,
          label: cmd.label,
          description: '',
          shortcut: cmd.shortcut,
          icon: cmd.icon,
          score: 100
        };
        results.push(result);
      });
      return results;
    }

    // Search built-in commands
    CommandService.builtInCommands.forEach((cmd: BuiltInCommandDef) => {
      const match: FuzzyMatchResult = CommandService.fuzzyMatch(lowerQuery, cmd.label.toLowerCase());
      if (match.matched) {
        const result: CommandResult = {
          type: cmd.category,
          id: cmd.id,
          label: cmd.label,
          description: '',
          shortcut: cmd.shortcut,
          icon: cmd.icon,
          score: match.score
        };
        results.push(result);
      }
    });

    // Search requests in current workspace
    context.requests.forEach((request: HttpRequest) => {
      if (request.workspace_id !== context.currentWorkspaceId) {
        return;
      }

      const match: FuzzyMatchResult = CommandService.fuzzyMatch(lowerQuery, request.name.toLowerCase());
      if (match.matched) {
        const result: CommandResult = {
          type: 'request',
          id: request.id,
          label: request.name,
          description: `${request.method} ${request.url}`,
          shortcut: '',
          icon: CommandService.getMethodIcon(request.method),
          score: match.score
        };
        results.push(result);
      }
    });

    // Search workspaces
    context.workspaces.forEach((workspace: Workspace) => {
      const match: FuzzyMatchResult = CommandService.fuzzyMatch(lowerQuery, workspace.name.toLowerCase());
      if (match.matched) {
        const result: CommandResult = {
          type: 'workspace',
          id: workspace.id,
          label: workspace.name,
          description: workspace.description,
          shortcut: '',
          icon: '🗂️',
          score: match.score
        };
        results.push(result);
      }
    });

    // Search environments
    context.environments.forEach((env: Environment) => {
      const match: FuzzyMatchResult = CommandService.fuzzyMatch(lowerQuery, env.name.toLowerCase());
      if (match.matched) {
        const result: CommandResult = {
          type: 'environment',
          id: env.id,
          label: env.name,
          description: `${env.variables.length} 个变量`,
          shortcut: '',
          icon: '🔧',
          score: match.score
        };
        results.push(result);
      }
    });

    // Sort by score (higher is better)
    results.sort((a: CommandResult, b: CommandResult) => b.score - a.score);

    // Limit results
    const maxResults: number = 20;
    if (results.length > maxResults) {
      return results.slice(0, maxResults);
    }

    return results;
  }

  /**
   * Fuzzy match algorithm
   */
  private static fuzzyMatch(query: string, text: string): FuzzyMatchResult {
    const result: FuzzyMatchResult = {
      matched: false,
      score: 0,
      highlights: []
    };

    if (query.length === 0) {
      result.matched = true;
      result.score = 100;
      return result;
    }

    if (text.length === 0) {
      return result;
    }

    // Exact match gets highest score
    if (text === query) {
      result.matched = true;
      result.score = 1000;
      for (let i = 0; i < text.length; i++) {
        result.highlights.push(i);
      }
      return result;
    }

    // Starts with gets high score
    if (text.startsWith(query)) {
      result.matched = true;
      result.score = 900 + (query.length / text.length) * 100;
      for (let i = 0; i < query.length; i++) {
        result.highlights.push(i);
      }
      return result;
    }

    // Contains gets medium score
    const containsIndex: number = text.indexOf(query);
    if (containsIndex >= 0) {
      result.matched = true;
      result.score = 700 + (query.length / text.length) * 100 - containsIndex;
      for (let i = 0; i < query.length; i++) {
        result.highlights.push(containsIndex + i);
      }
      return result;
    }

    // Fuzzy match - characters in order
    let queryIndex: number = 0;
    let score: number = 0;
    let consecutiveBonus: number = 0;
    let lastMatchIndex: number = -1;

    for (let i = 0; i < text.length && queryIndex < query.length; i++) {
      if (text.charAt(i) === query.charAt(queryIndex)) {
        result.highlights.push(i);

        // Bonus for consecutive matches
        if (lastMatchIndex === i - 1) {
          consecutiveBonus += 10;
        } else {
          consecutiveBonus = 0;
        }

        // Bonus for matching at word boundaries
        if (i === 0 || text.charAt(i - 1) === ' ' || text.charAt(i - 1) === '_' || text.charAt(i - 1) === '-') {
          score += 20;
        }

        score += 10 + consecutiveBonus;
        lastMatchIndex = i;
        queryIndex++;
      }
    }

    // All query characters must be found
    if (queryIndex === query.length) {
      result.matched = true;
      result.score = score;
    }

    return result;
  }

  /**
   * Get icon for HTTP method
   */
  private static getMethodIcon(method: string): string {
    switch (method.toUpperCase()) {
      case 'GET':
        return '🟢';
      case 'POST':
        return '🟡';
      case 'PUT':
        return '🟠';
      case 'DELETE':
        return '🔴';
      case 'PATCH':
        return '🟣';
      default:
        return '⚪';
    }
  }
}
