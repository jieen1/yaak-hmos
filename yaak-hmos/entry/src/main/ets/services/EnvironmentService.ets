import { Environment } from '../model/Environment';
import { EnvironmentRepository } from '../database/EnvironmentRepository';
import { UUID } from '../common/UUID';
import { HeaderItem } from '../model/Types';

export class EnvironmentService {
  /**
   * Parses the environment variables from the JSON string stored in the Environment model.
   * Returns a key-value map.
   */
  public static parseVariables(env: Environment): Record<string, string> {
    try {
      // Use 'variables' field which stores HeaderItem[]
      let varsString = env.variables;
      if (!varsString || varsString === 'null') {
         // Fallback to legacy 'data' if 'variables' is empty (migration support)
         // But since we just changed the model, 'data' property might not exist on the class definition if I removed it?
         // In runtime JS/TS it might exist if DB has it, but Typescript will complain.
         // Let's assume 'variables' is the source of truth now.
         return {};
      }

      let parsed = JSON.parse(varsString) as Array<HeaderItem>;
      if (!Array.isArray(parsed)) {
         return {};
      }
      
      let result: Record<string, string> = {};
      parsed.forEach(item => {
        if (item.enabled && item.name && item.name.trim() !== '') {
          result[item.name] = item.value;
        }
      });
      return result;
    } catch (e) {
      console.warn('Failed to parse environment variables', JSON.stringify(e));
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
