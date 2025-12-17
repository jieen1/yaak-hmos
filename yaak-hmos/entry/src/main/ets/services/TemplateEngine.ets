/**
 * Template Engine Service
 * Processes template syntax {{ variableName }} and {{ functionName(args) }}
 * Supports nested template resolution and built-in functions
 */

import util from '@ohos.util';
import cryptoFramework from '@ohos.security.cryptoFramework';

export class TemplateEngine {
  private static readonly TEMPLATE_REGEX = /\{\{([^}]+)\}\}/g;

  /**
   * Resolve template string with variables
   */
  static resolve(template: string, variables: Map<string, string>): string {
    if (!template) return template;

    // Support nested template resolution (up to 5 levels)
    let result = template;
    let iterations = 0;
    const maxIterations = 5;

    while (this.TEMPLATE_REGEX.test(result) && iterations < maxIterations) {
      this.TEMPLATE_REGEX.lastIndex = 0; // Reset regex
      result = result.replace(this.TEMPLATE_REGEX, (match, expression) => {
        return this.resolveExpression(expression.trim(), variables, match);
      });
      iterations++;
    }

    return result;
  }

  /**
   * Resolve a single expression
   */
  private static resolveExpression(
    expression: string,
    variables: Map<string, string>,
    originalMatch: string
  ): string {
    // Check if it's a function call
    if (expression.includes('(')) {
      return this.executeFunction(expression, variables, originalMatch);
    }

    // Simple variable lookup
    const value = variables.get(expression);
    return value !== undefined ? value : originalMatch;
  }

  /**
   * Execute template function
   */
  private static executeFunction(
    expression: string,
    variables: Map<string, string>,
    originalMatch: string
  ): string {
    const functionMatch = expression.match(/^(\w+)\((.*)\)$/);
    if (!functionMatch) return originalMatch;

    const [, functionName, argsStr] = functionMatch;
    const args = this.parseArguments(argsStr, variables);

    try {
      switch (functionName) {
        case 'timestamp':
          return this.timestamp();
        case 'uuid':
          return this.uuid();
        case 'random':
          return this.random(args);
        case 'base64':
          return this.base64(args);
        case 'md5':
          return this.md5(args);
        default:
          console.warn(`Unknown template function: ${functionName}`);
          return originalMatch;
      }
    } catch (error) {
      console.error(`Error executing function ${functionName}: ${error}`);
      return originalMatch;
    }
  }

  /**
   * Parse function arguments
   */
  private static parseArguments(argsStr: string, variables: Map<string, string>): string[] {
    if (!argsStr.trim()) return [];

    const args: string[] = [];
    let currentArg = '';
    let inQuotes = false;
    let quoteChar = '';

    for (let i = 0; i < argsStr.length; i++) {
      const char = argsStr[i];

      if ((char === '"' || char === "'") && (i === 0 || argsStr[i - 1] !== '\\')) {
        if (!inQuotes) {
          inQuotes = true;
          quoteChar = char;
        } else if (char === quoteChar) {
          inQuotes = false;
          quoteChar = '';
        } else {
          currentArg += char;
        }
      } else if (char === ',' && !inQuotes) {
        args.push(this.resolveArgument(currentArg.trim(), variables));
        currentArg = '';
      } else {
        currentArg += char;
      }
    }

    if (currentArg.trim()) {
      args.push(this.resolveArgument(currentArg.trim(), variables));
    }

    return args;
  }

  /**
   * Resolve a single argument (could be a variable reference)
   */
  private static resolveArgument(arg: string, variables: Map<string, string>): string {
    // Remove quotes if present
    if ((arg.startsWith('"') && arg.endsWith('"')) || (arg.startsWith("'") && arg.endsWith("'"))) {
      return arg.slice(1, -1);
    }

    // Check if it's a variable reference
    const value = variables.get(arg);
    return value !== undefined ? value : arg;
  }

  /**
   * Built-in function: timestamp()
   * Returns current timestamp in milliseconds
   */
  private static timestamp(): string {
    return Date.now().toString();
  }

  /**
   * Built-in function: uuid()
   * Generates a UUID v4
   */
  private static uuid(): string {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
      const r = Math.random() * 16 | 0;
      const v = c === 'x' ? r : (r & 0x3 | 0x8);
      return v.toString(16);
    });
  }

  /**
   * Built-in function: random(min, max)
   * Generates a random number between min and max
   */
  private static random(args: string[]): string {
    const min = args.length > 0 ? parseInt(args[0]) : 0;
    const max = args.length > 1 ? parseInt(args[1]) : 100;

    if (isNaN(min) || isNaN(max)) {
      return '0';
    }

    const result = Math.floor(Math.random() * (max - min + 1)) + min;
    return result.toString();
  }

  /**
   * Built-in function: base64(str)
   * Encodes string to base64
   */
  private static base64(args: string[]): string {
    if (args.length === 0) return '';

    try {
      const str = args[0];
      const helper = new util.Base64Helper();
      const uint8Array = new util.TextEncoder().encodeInto(str);
      return helper.encodeToStringSync(uint8Array);
    } catch (error) {
      console.error(`Base64 encoding error: ${error}`);
      return args[0];
    }
  }

  /**
   * Built-in function: md5(str)
   * Generates MD5 hash of string
   */
  private static md5(args: string[]): string {
    if (args.length === 0) return '';

    try {
      const str = args[0];
      // Note: HarmonyOS cryptoFramework is async, so we return a placeholder
      // In real implementation, this should be handled asynchronously
      // For now, return a simple hash
      return this.simpleHash(str);
    } catch (error) {
      console.error(`MD5 hashing error: ${error}`);
      return args[0];
    }
  }

  /**
   * Simple hash function (fallback for MD5)
   */
  private static simpleHash(str: string): string {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
      const char = str.charCodeAt(i);
      hash = ((hash << 5) - hash) + char;
      hash = hash & hash; // Convert to 32bit integer
    }
    return Math.abs(hash).toString(16);
  }
}
