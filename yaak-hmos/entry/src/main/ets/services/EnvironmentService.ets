import { Environment } from '../model/Environment';
import { EnvironmentRepository } from '../database/EnvironmentRepository';
import { UUID } from '../common/UUID';

export class EnvironmentService {
  /**
   * Parses the environment variables from the JSON string stored in the Environment model.
   * Returns a key-value map.
   */
  public static parseVariables(env: Environment): Record<string, string> {
    try {
      // In ArkTS, JSON.parse returns Object/any, need explicit cast or check
      let parsed = JSON.parse(env.data) as Record<string, string>;
      return parsed;
    } catch (e) {
      console.warn('Failed to parse environment data', JSON.stringify(e));
      return {};
    }
  }

  /**
   * Merges variables from multiple environments.
   * Typically: Global Env < Workspace Env < Folder Env < Selected Env
   * For now, we'll just handle Workspace/Selected Env.
   */
  public static mergeVariables(environments: Environment[]): Record<string, string> {
    let merged: Record<string, string> = {};
    for (const env of environments) {
      const vars = EnvironmentService.parseVariables(env);
      // Object.assign or loop to merge without spread
      let keys = Object.keys(vars);
      for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        merged[key] = vars[key];
      }
    }
    return merged;
  }
}
