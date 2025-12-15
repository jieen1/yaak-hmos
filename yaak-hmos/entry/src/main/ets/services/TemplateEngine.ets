
export class TemplateEngine {
  /**
   * Renders a string by substituting variables in the format {{ variableName }}.
   * @param content The string content to render.
   * @param variables A map of variable names to their values.
   * @returns The rendered string.
   */
  public static render(content: string, variables: Record<string, string>): string {
    if (!content) return '';
    
    // Simple regex for {{ variable }}
    // Captures the variable name inside the braces
    return content.replace(/\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/g, (match: string, varName: string) => {
      // Return the variable value if found, otherwise keep the original tag
      // or return empty string? Keeping original tag is often better for debugging.
      // But for execution, we might want empty string or error.
      // Let's return the value if it exists, otherwise the match.
      return variables[varName] !== undefined ? variables[varName] : match;
    });
  }

  /**
   * Recursively renders values in an object or array.
   */
  public static renderObject(obj: Object | null, variables: Record<string, string>): Object | null {
    if (typeof obj === 'string') {
      return TemplateEngine.render(obj as string, variables);
    } else if (Array.isArray(obj)) {
      return (obj as Object[]).map((item: Object) => TemplateEngine.renderObject(item, variables));
    } else if (typeof obj === 'object' && obj !== null) {
      // In ArkTS, we can't easily iterate Keys of Object directly if it's not a Record or Map
      // But if we treat it as JSON compatible object:
      let result: Record<string, Object | null> = {};
      let keys = Object.keys(obj);
      for (let i = 0; i < keys.length; i++) {
        let key = keys[i];
        // Using Record access
        let value = (obj as Record<string, Object>)[key];
        result[key] = TemplateEngine.renderObject(value, variables);
      }
      return result;
    }
    return obj;
  }
}
