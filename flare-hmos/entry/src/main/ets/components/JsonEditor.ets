/**
 * JsonEditor Component
 * A full-featured JSON editor/viewer with syntax highlighting,
 * line numbers, and collapsible blocks
 */

import { FontSettings } from '../services/FontService';

/**
 * JSON Token types for syntax highlighting
 */
type JsonTokenType = 'key' | 'string' | 'number' | 'boolean' | 'null' | 'bracket' | 'colon' | 'comma';

/**
 * Represents a single token in JSON
 */
interface JsonToken {
  type: JsonTokenType;
  value: string;
}

/**
 * Represents a line in the JSON view
 */
interface JsonLine {
  lineNumber: number;
  indent: number;
  tokens: JsonToken[];
  isCollapsible: boolean;
  blockId: string;
  isBlockStart: boolean;
  isBlockEnd: boolean;
  parentBlockId: string;
}

/**
 * Get token color by type
 */
function getTokenColor(type: JsonTokenType): string {
  if (type === 'key') {
    return '#FF6D4D';      // Light blue for keys
  } else if (type === 'string') {
    return '#CE9178';      // Orange for strings
  } else if (type === 'number') {
    return '#ff45aa';      // Light green for numbers
  } else if (type === 'boolean') {
    return '#569CD6';      // Blue for booleans
  } else if (type === 'null') {
    return '#569CD6';      // Blue for null
  } else if (type === 'bracket') {
    return '#444444';      // black for brackets
  } else if (type === 'colon') {
    return '#CCCCCC';      // Gray for colons
  } else if (type === 'comma') {
    return '#CCCCCC';      // Gray for commas
  }
  return '#CCCCCC';
}

@ComponentV2
export struct JsonEditor {
  @Param content: string = '';
  @Param readonly: boolean = false;
  @Param placeholder: string = '{\n  "key": "value"\n}';
  @Event onContentChange: (content: string) => void = () => {};

  @Local private fontSettings: FontSettings = FontSettings.getInstance();
  @Local private parsedLines: JsonLine[] = [];
  @Local private collapsedBlocks: Set<string> = new Set();
  @Local private parseError: string = '';
  @Local private isEditing: boolean = false;
  @Local private editText: string = '';

  aboutToAppear(): void {
    this.parseJson();
  }

  @Monitor('content')
  onContentChanged(): void {
    if (!this.isEditing) {
      this.parseJson();
    }
  }

  /**
   * Parse JSON content into lines with tokens
   */
  private parseJson(): void {
    if (!this.content || this.content.trim() === '') {
      this.parsedLines = [];
      this.parseError = '';
      return;
    }

    try {
      // Validate and format JSON
      const parsed: ESObject = JSON.parse(this.content) as ESObject;
      const formatted: string = JSON.stringify(parsed, null, 2);
      this.buildLines(formatted);
      this.parseError = '';
    } catch (e) {
      // Show raw content with error
      this.parseError = `JSON 解析错误: ${(e as Error).message}`;
      this.buildLinesFromRaw(this.content);
    }
  }

  /**
   * Build lines from formatted JSON
   */
  private buildLines(formatted: string): void {
    const lines: string[] = formatted.split('\n');
    const newParsedLines: JsonLine[] = [];
    const blockStack: string[] = [];
    let blockCounter: number = 0;

    lines.forEach((line: string, index: number) => {
      const lineNumber: number = index + 1;
      const indent: number = this.getIndent(line);
      const trimmedLine: string = line.trim();
      const tokens: JsonToken[] = this.tokenizeLine(trimmedLine);

      // Determine if this line starts or ends a block
      const isBlockStart: boolean = trimmedLine.endsWith('{') || trimmedLine.endsWith('[');
      const isBlockEnd: boolean = trimmedLine.startsWith('}') || trimmedLine.startsWith(']');

      let blockId: string = '';
      let parentBlockId: string = blockStack.length > 0 ? blockStack[blockStack.length - 1] : '';

      if (isBlockEnd && blockStack.length > 0) {
        blockId = blockStack.pop() || '';
        parentBlockId = blockStack.length > 0 ? blockStack[blockStack.length - 1] : '';
      }

      if (isBlockStart) {
        blockCounter++;
        blockId = `block_${blockCounter}`;
        blockStack.push(blockId);
      }

      const jsonLine: JsonLine = {
        lineNumber: lineNumber,
        indent: indent,
        tokens: tokens,
        isCollapsible: isBlockStart,
        blockId: blockId,
        isBlockStart: isBlockStart,
        isBlockEnd: isBlockEnd,
        parentBlockId: parentBlockId
      };

      newParsedLines.push(jsonLine);
    });

    this.parsedLines = newParsedLines;
  }

  /**
   * Build lines from raw content (when JSON is invalid)
   */
  private buildLinesFromRaw(content: string): void {
    const lines: string[] = content.split('\n');
    const newParsedLines: JsonLine[] = [];

    lines.forEach((line: string, index: number) => {
      const textToken: JsonToken = { type: 'string', value: line };
      const jsonLine: JsonLine = {
        lineNumber: index + 1,
        indent: 0,
        tokens: [textToken],
        isCollapsible: false,
        blockId: '',
        isBlockStart: false,
        isBlockEnd: false,
        parentBlockId: ''
      };
      newParsedLines.push(jsonLine);
    });

    this.parsedLines = newParsedLines;
  }

  /**
   * Get indentation level of a line
   */
  private getIndent(line: string): number {
    let count: number = 0;
    for (let i = 0; i < line.length; i++) {
      if (line[i] === ' ') {
        count++;
      } else {
        break;
      }
    }
    return Math.floor(count / 2);
  }

  /**
   * Tokenize a single line of JSON
   */
  private tokenizeLine(line: string): JsonToken[] {
    const tokens: JsonToken[] = [];
    let i: number = 0;

    while (i < line.length) {
      const char: string = line[i];

      // Skip whitespace
      if (char === ' ') {
        i++;
        continue;
      }

      // Brackets
      if (char === '{' || char === '}' || char === '[' || char === ']') {
        const token: JsonToken = { type: 'bracket', value: char };
        tokens.push(token);
        i++;
        continue;
      }

      // Colon
      if (char === ':') {
        const token: JsonToken = { type: 'colon', value: ': ' };
        tokens.push(token);
        i++;
        continue;
      }

      // Comma
      if (char === ',') {
        const token: JsonToken = { type: 'comma', value: ',' };
        tokens.push(token);
        i++;
        continue;
      }

      // String (key or value)
      if (char === '"') {
        const startIndex: number = i;
        i++; // Skip opening quote
        while (i < line.length && !(line[i] === '"' && line[i - 1] !== '\\')) {
          i++;
        }
        i++; // Skip closing quote
        const stringValue: string = line.substring(startIndex, i);

        // Check if this is a key (followed by colon)
        let isKey: boolean = false;
        let j: number = i;
        while (j < line.length && line[j] === ' ') {
          j++;
        }
        if (j < line.length && line[j] === ':') {
          isKey = true;
        }

        const token: JsonToken = { type: isKey ? 'key' : 'string', value: stringValue };
        tokens.push(token);
        continue;
      }

      // Number
      if (char === '-' || (char >= '0' && char <= '9')) {
        const startIndex: number = i;
        while (i < line.length && (line[i] === '-' || line[i] === '.' || line[i] === 'e' || line[i] === 'E' ||
          line[i] === '+' || (line[i] >= '0' && line[i] <= '9'))) {
          i++;
        }
        const token: JsonToken = { type: 'number', value: line.substring(startIndex, i) };
        tokens.push(token);
        continue;
      }

      // Boolean or null
      if (line.substring(i, i + 4) === 'true') {
        const token: JsonToken = { type: 'boolean', value: 'true' };
        tokens.push(token);
        i += 4;
        continue;
      }
      if (line.substring(i, i + 5) === 'false') {
        const token: JsonToken = { type: 'boolean', value: 'false' };
        tokens.push(token);
        i += 5;
        continue;
      }
      if (line.substring(i, i + 4) === 'null') {
        const token: JsonToken = { type: 'null', value: 'null' };
        tokens.push(token);
        i += 4;
        continue;
      }

      // Unknown character, skip
      i++;
    }

    return tokens;
  }

  /**
   * Toggle block collapse state
   */
  private toggleBlock(blockId: string): void {
    const newCollapsed: Set<string> = new Set(this.collapsedBlocks);
    if (newCollapsed.has(blockId)) {
      newCollapsed.delete(blockId);
    } else {
      newCollapsed.add(blockId);
    }
    this.collapsedBlocks = newCollapsed;
  }

  /**
   * Check if a line should be visible
   */
  private isLineVisible(line: JsonLine): boolean {
    if (this.collapsedBlocks.size === 0) {
      return true;
    }

    // Check if any parent block is collapsed
    let currentBlockId: string = line.parentBlockId;
    while (currentBlockId !== '') {
      if (this.collapsedBlocks.has(currentBlockId)) {
        // This line is inside a collapsed block
        // But show the closing bracket of the collapsed block
        if (line.isBlockEnd && line.blockId === currentBlockId) {
          return false; // Hide closing bracket too
        }
        return false;
      }
      // Find parent of current block
      const parentLine: JsonLine | undefined = this.parsedLines.find((l: JsonLine) => l.blockId === currentBlockId);
      currentBlockId = parentLine ? parentLine.parentBlockId : '';
    }

    return true;
  }

  /**
   * Get collapsed block preview text
   */
  private getCollapsedPreview(blockId: string): string {
    const startLineIndex: number = this.parsedLines.findIndex((l: JsonLine) => l.blockId === blockId && l.isBlockStart);
    if (startLineIndex === -1) {
      return '...';
    }

    const startLine: JsonLine = this.parsedLines[startLineIndex];
    const lastToken: JsonToken | undefined = startLine.tokens[startLine.tokens.length - 1];
    const bracketType: string = lastToken ? lastToken.value : '{';
    const isObject: boolean = bracketType === '{';

    // Count items in the block
    let itemCount: number = 0;
    let depth: number = 1;
    
    for (let i = startLineIndex + 1; i < this.parsedLines.length && depth > 0; i++) {
      const line: JsonLine = this.parsedLines[i];
      
      // Track depth changes
      if (line.isBlockStart) {
        // Count this as an item at depth 1 (for arrays containing objects/arrays)
        if (depth === 1) {
          itemCount++;
        }
        depth++;
      } else if (line.isBlockEnd) {
        depth--;
      } else if (depth === 1) {
        // At depth 1, count items
        if (isObject) {
          // For objects, count lines with keys
          if (line.tokens.some((t: JsonToken) => t.type === 'key')) {
            itemCount++;
          }
        } else {
          // For arrays, count lines with values (string, number, boolean, null)
          if (line.tokens.some((t: JsonToken) => 
            t.type === 'string' || t.type === 'number' || t.type === 'boolean' || t.type === 'null')) {
            itemCount++;
          }
        }
      }
    }

    const itemText: string = isObject ? `${itemCount} 个属性` : `${itemCount} 个元素`;
    return ` ${itemText}`;
  }

  /**
   * Switch to edit mode
   */
  private startEditing(): void {
    if (this.readonly) {
      return;
    }
    this.isEditing = true;
    this.editText = this.content;
  }

  /**
   * Finish editing and parse
   */
  private finishEditing(): void {
    this.isEditing = false;
    if (this.editText !== this.content) {
      this.onContentChange(this.editText);
    }
    this.parseJson();
  }

  build() {
    Column() {
      // Error banner
      if (this.parseError !== '') {
        Row() {
          Text(this.parseError)
            .fontSize(12)
            .fontColor('#FF6B6B')
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
        .width('100%')
        .padding({ left: 12, right: 12, top: 6, bottom: 6 })
        .backgroundColor('#2D1F1F')
      }

      if (this.isEditing) {
        // Edit mode - simple TextArea
        TextArea({ text: this.editText, placeholder: this.placeholder })
          .width('100%')
          .layoutWeight(1)
          .backgroundColor($r('app.color.code_background'))
          .fontColor($r('app.color.code_text'))
          .fontSize(this.fontSettings.editorFontSize)
          .fontFamily(this.fontSettings.editorFont)
          .padding(12)
          .onChange((value: string) => {
            this.editText = value;
          })
          .onBlur(() => {
            this.finishEditing();
          })
      } else {
        // View mode - syntax highlighted
        if (this.parsedLines.length === 0 && this.content.trim() === '') {
          // Empty state
          Column() {
            Text(this.readonly ? '没有内容' : '点击编辑 JSON')
              .fontSize($r('app.float.font_size_md'))
              .fontColor($r('app.color.text_secondary'))
          }
          .width('100%')
          .layoutWeight(1)
          .justifyContent(FlexAlign.Center)
          .onClick(() => {
            if (!this.readonly) {
              this.startEditing();
            }
          })
        } else {
          // JSON viewer with line numbers
          Scroll() {
            Row() {
              // Line numbers column
              Column() {
                ForEach(this.getVisibleLines(), (line: JsonLine) => {
                  this.buildLineNumber(line)
                }, (line: JsonLine) => `ln_${line.lineNumber}`)
              }
              .width(45)
              .alignItems(HorizontalAlign.End)
              .padding({ right: 8 })

              // Code content column
              Column() {
                ForEach(this.getVisibleLines(), (line: JsonLine) => {
                  this.buildCodeLine(line)
                }, (line: JsonLine) => `code_${line.lineNumber}_${this.collapsedBlocks.has(line.blockId)}`)
              }
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width('100%')
          }
          .width('100%')
          .layoutWeight(1)
          .scrollBar(BarState.Auto)
          .backgroundColor($r('app.color.code_background'))
          .onClick(() => {
            if (!this.readonly) {
              this.startEditing();
            }
          })
          .align(Alignment.Top)
        }
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.code_background'))
    .borderRadius($r('app.float.border_radius_md'))
    .clip(true)
  }

  /**
   * Get visible lines (filtered by collapsed state)
   */
  private getVisibleLines(): JsonLine[] {
    return this.parsedLines.filter((line: JsonLine) => this.isLineVisible(line));
  }

  @Builder
  buildLineNumber(line: JsonLine) {
    Row() {
      Text(`${line.lineNumber}`)
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)
        .fontColor('#858585')
        .textAlign(TextAlign.End)
        .width(25)

      // Collapse/expand arrow for collapsible lines (right side of line number)
      if (line.isCollapsible) {
        Text() {
          SymbolSpan(this.collapsedBlocks.has(line.blockId) ? $r('sys.symbol.chevron_right') : $r('sys.symbol.chevron_down'))
        }
          .fontSize(14)
          .fontColor('#858585')
          .width(14)
          .textAlign(TextAlign.Center)
          .onClick((event: ClickEvent) => {
            this.toggleBlock(line.blockId);
          })
      } else {
        Text('')
          .width(14)
      }
    }
    .height(this.fontSettings.editorFontSize + 6)
    .justifyContent(FlexAlign.End)
  }

  @Builder
  buildCodeLine(line: JsonLine) {
    Row() {
      // Indentation
      Text('  '.repeat(line.indent))
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)

      // Tokens
      ForEach(line.tokens, (token: JsonToken, index: number) => {
        Text(token.value)
          .fontSize(this.fontSettings.editorFontSize)
          .fontFamily(this.fontSettings.editorFont)
          .fontColor(getTokenColor(token.type))
      }, (token: JsonToken, index: number) => `token_${line.lineNumber}_${index}_${token.value}`)

      // Collapsed preview
      if (line.isCollapsible && this.collapsedBlocks.has(line.blockId)) {
        Text(this.getCollapsedPreview(line.blockId))
          .fontSize(this.fontSettings.editorFontSize)
          .fontFamily(this.fontSettings.editorFont)
          .fontColor('#858585')
          .fontStyle(FontStyle.Italic)
      }
    }
    .height(this.fontSettings.editorFontSize + 6)
    .alignItems(VerticalAlign.Center)
  }
}
