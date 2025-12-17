/**
 * Environment Service
 * Manages environment variables and variable resolution
 */

import { Environment, EnvironmentVariable } from '../model/Environment';

export class EnvironmentService {
  /**
   * Merge variables from multiple environments
   * Later environments override earlier ones
   */
  static mergeVariables(environments: Environment[]): Map<string, string> {
    const variables = new Map<string, string>();

    // Merge all enabled environments
    environments.forEach(env => {
      env.variables
        .filter(v => v.enabled)
        .forEach(v => {
          variables.set(v.name, v.value);
        });
    });

    return variables;
  }

  /**
   * Merge variables from a single environment
   */
  static getVariablesFromEnvironment(environment: Environment): Map<string, string> {
    const variables = new Map<string, string>();

    environment.variables
      .filter(v => v.enabled)
      .forEach(v => {
        variables.set(v.name, v.value);
      });

    return variables;
  }

  /**
   * Resolve a single variable by name
   * Returns the value if found, otherwise returns the placeholder
   */
  static resolveVariable(
    name: string,
    variables: Map<string, string>
  ): string {
    const value = variables.get(name);
    return value !== undefined ? value : `{{${name}}}`;
  }

  /**
   * Get all variable names from environments
   */
  static getAllVariableNames(environments: Environment[]): string[] {
    const names = new Set<string>();

    environments.forEach(env => {
      env.variables.forEach(v => {
        names.add(v.name);
      });
    });

    return Array.from(names);
  }

  /**
   * Check if a variable exists in any environment
   */
  static hasVariable(name: string, environments: Environment[]): boolean {
    return environments.some(env =>
      env.variables.some(v => v.name === name)
    );
  }

  /**
   * Get variable value from specific environment
   */
  static getVariableValue(
    name: string,
    environment: Environment
  ): string | undefined {
    const variable = environment.variables.find(v => v.name === name && v.enabled);
    return variable?.value;
  }

  /**
   * Filter secret variables
   */
  static getSecretVariables(environment: Environment): EnvironmentVariable[] {
    return environment.variables.filter(v => v.is_secret);
  }

  /**
   * Filter public variables
   */
  static getPublicVariables(environment: Environment): EnvironmentVariable[] {
    return environment.variables.filter(v => !v.is_secret);
  }

  /**
   * Create a variable map with masked secret values
   */
  static getMaskedVariables(environment: Environment): Map<string, string> {
    const variables = new Map<string, string>();

    environment.variables
      .filter(v => v.enabled)
      .forEach(v => {
        const value = v.is_secret ? '********' : v.value;
        variables.set(v.name, value);
      });

    return variables;
  }
}
