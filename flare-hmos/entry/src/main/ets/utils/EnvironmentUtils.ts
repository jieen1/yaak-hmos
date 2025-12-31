
export interface TextFragment {
  text: string;
  type: 'text' | 'variable';
  variableName?: string;
}

export class EnvironmentUtils {
  /**
   * Parse text into fragments of plain text and variables
   * Example: "Host: {{url}}" -> [
   *   { text: "Host: ", type: 'text' },
   *   { text: "{{url}}", type: 'variable', variableName: "url" }
   * ]
   */
  static parseString(input: string): TextFragment[] {
    if (!input) {
      return [];
    }

    const fragments: TextFragment[] = [];
    const regex = /\{\{([\w\-\._]+)\}\}/g;
    let lastIndex = 0;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(input)) !== null) {
      // Add plain text before the match
      if (match.index > lastIndex) {
        fragments.push({
          text: input.substring(lastIndex, match.index),
          type: 'text'
        });
      }

      // Add the variable
      fragments.push({
        text: match[0],
        type: 'variable',
        variableName: match[1]
      });

      lastIndex = regex.lastIndex;
    }

    // Add remaining text
    if (lastIndex < input.length) {
      fragments.push({
        text: input.substring(lastIndex),
        type: 'text'
      });
    }

    return fragments;
  }
}
