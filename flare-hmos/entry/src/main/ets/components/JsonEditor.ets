/**
 * JsonEditor Component
 * A JSON editor with syntax highlighting for viewing,
 * and TextArea for editing. Supports format button and collapsible blocks.
 */

import { FontSettings } from '../services/FontService';
import { JsonValidator, JsonValidationResult } from '../utils/JsonValidator';

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
    return '#FF6D4D';
  } else if (type === 'string') {
    return '#CE9178';
  } else if (type === 'number') {
    return '#ff45aa';
  } else if (type === 'boolean') {
    return '#569CD6';
  } else if (type === 'null') {
    return '#569CD6';
  } else if (type === 'bracket') {
    return '#444444';
  } else if (type === 'colon') {
    return '#CCCCCC';
  } else if (type === 'comma') {
    return '#CCCCCC';
  }
  return '#CCCCCC';
}

@ComponentV2
export struct JsonEditor {
  @Param content: string = '';
  @Param readonly: boolean = false;
  @Param showFormatButton: boolean = true;
  @Event onContentChange: (content: string) => void = () => {};

  @Local private fontSettings: FontSettings = FontSettings.getInstance();
  @Local private parsedLines: JsonLine[] = [];
  @Local private collapsedBlocks: Set<string> = new Set();
  @Local private errorLine: number = -1; // 错误所在行号，-1表示无错误
  @Local private isEditing: boolean = !this.readonly;
  @Local private editText: string = '';
  @Local private lineNumberOffsetY: number = 0; // 行号列的垂直偏移量（vp）
  private jsonValidator: JsonValidator = new JsonValidator(); // JSON 验证器
  private validationTimer: number = -1; // 验证防抖定时器

  aboutToAppear(): void {
    this.editText = this.content;
    this.parseJson();
  }

  @Monitor('content')
  onContentChanged(): void {
    // 只有在非编辑模式下才更新
    if (!this.isEditing) {
      this.editText = this.content;
      this.parseJson();
    }
  }

  /**
   * Parse JSON content into lines with tokens
   */
  private parseJson(): void {
    const textToParse: string = this.isEditing ? this.editText : this.content;
    
    if (!textToParse || textToParse.trim() === '') {
      this.parsedLines = [];
      this.errorLine = -1;
      return;
    }

    // 对于大 JSON（超过 50KB），跳过自定义验证，直接使用 JSON.parse
    // 这样可以提高性能，但会失去精确的错误定位
    const textSize: number = textToParse.length;
    const useFastPath: boolean = textSize > 50000;

    if (useFastPath) {
      // 快速路径：直接使用 JSON.parse
      try {
        const parsed: ESObject = JSON.parse(textToParse) as ESObject;
        const formatted: string = JSON.stringify(parsed, null, 2);
        this.buildLines(formatted);
        this.errorLine = -1;
      } catch (e) {
        console.warn('[JsonEditor] Large JSON parse failed, showing raw content');
        this.errorLine = -1; // 大 JSON 不显示错误行号
        this.buildLinesFromRaw(textToParse);
      }
      return;
    }

    // 正常路径：使用自定义验证器检查 JSON 格式
    try {
      const validationResult: JsonValidationResult = this.jsonValidator.validate(textToParse);
      
      if (validationResult.valid) {
        // JSON 有效，格式化并构建行
        try {
          const parsed: ESObject = JSON.parse(textToParse) as ESObject;
          const formatted: string = JSON.stringify(parsed, null, 2);
          this.buildLines(formatted);
          this.errorLine = -1;
        } catch (e) {
          // 理论上不应该到这里，因为验证器已经通过了
          console.error('[JsonEditor] Unexpected parse error after validation:', e);
          this.errorLine = -1;
          this.buildLinesFromRaw(textToParse);
        }
      } else {
        // JSON 无效，显示错误
        console.info('[JsonEditor] JSON validation failed:', validationResult.errorMessage);
        if (validationResult.errorLine) {
          console.info('[JsonEditor] Error at line:', validationResult.errorLine, 'column:', validationResult.errorColumn);
          this.errorLine = validationResult.errorLine;
        } else {
          this.errorLine = -1;
        }
        this.buildLinesFromRaw(textToParse);
      }
    } catch (e) {
      // 验证过程中出错，回退到原生 JSON.parse
      console.error('[JsonEditor] Validation error, falling back to JSON.parse:', e);
      try {
        const parsed: ESObject = JSON.parse(textToParse) as ESObject;
        const formatted: string = JSON.stringify(parsed, null, 2);
        this.buildLines(formatted);
        this.errorLine = -1;
      } catch (parseError) {
        this.errorLine = -1;
        this.buildLinesFromRaw(textToParse);
      }
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

      const isBlockStart: boolean = trimmedLine.endsWith('{') || trimmedLine.endsWith('[');
      const isBlockEnd: boolean = trimmedLine.startsWith('}') || trimmedLine.startsWith(']');

      let blockId: string = '';
      const topBlock: string | undefined = blockStack[blockStack.length - 1];
      let parentBlockId: string = blockStack.length > 0 && topBlock ? topBlock : '';

      if (isBlockEnd && blockStack.length > 0) {
        blockId = blockStack.pop() || '';
        const newTopBlock: string | undefined = blockStack[blockStack.length - 1];
        parentBlockId = blockStack.length > 0 && newTopBlock ? newTopBlock : '';
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
      const charAtIndex: string | undefined = line[i];
      if (!charAtIndex) {
        i++;
        continue;
      }
      const char: string = charAtIndex;

      if (char === ' ') {
        i++;
        continue;
      }

      if (char === '{' || char === '}' || char === '[' || char === ']') {
        const token: JsonToken = { type: 'bracket', value: char };
        tokens.push(token);
        i++;
        continue;
      }

      if (char === ':') {
        const token: JsonToken = { type: 'colon', value: ': ' };
        tokens.push(token);
        i++;
        continue;
      }

      if (char === ',') {
        const token: JsonToken = { type: 'comma', value: ',' };
        tokens.push(token);
        i++;
        continue;
      }

      if (char === '"') {
        const startIndex: number = i;
        i++;
        while (i < line.length) {
          const currentChar: string | undefined = line[i];
          const prevChar: string | undefined = line[i - 1];
          if (!currentChar) {
            break;
          }
          if (currentChar === '"' && prevChar !== '\\') {
            break;
          }
          i++;
        }
        i++;
        const stringValue: string = line.substring(startIndex, i);

        let isKey: boolean = false;
        let j: number = i;
        while (j < line.length) {
          const spaceChar: string | undefined = line[j];
          if (!spaceChar || spaceChar !== ' ') {
            break;
          }
          j++;
        }
        const colonChar: string | undefined = line[j];
        if (j < line.length && colonChar === ':') {
          isKey = true;
        }

        const token: JsonToken = { type: isKey ? 'key' : 'string', value: stringValue };
        tokens.push(token);
        continue;
      }

      if (char === '-' || (char >= '0' && char <= '9')) {
        const startIndex: number = i;
        while (i < line.length) {
          const numCharAtIndex: string | undefined = line[i];
          if (!numCharAtIndex) {
            break;
          }
          const numChar: string = numCharAtIndex;
          if (!(numChar === '-' || numChar === '.' || numChar === 'e' || numChar === 'E' ||
            numChar === '+' || (numChar >= '0' && numChar <= '9'))) {
            break;
          }
          i++;
        }
        const token: JsonToken = { type: 'number', value: line.substring(startIndex, i) };
        tokens.push(token);
        continue;
      }

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

    let currentBlockId: string = line.parentBlockId;
    while (currentBlockId !== '') {
      if (this.collapsedBlocks.has(currentBlockId)) {
        if (line.isBlockEnd && line.blockId === currentBlockId) {
          return false;
        }
        return false;
      }
      const parentLine: JsonLine | undefined = this.parsedLines.find((l: JsonLine) => l.blockId === currentBlockId);
      if (!parentLine) {
        break;
      }
      currentBlockId = parentLine.parentBlockId;
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

    const startLine: JsonLine | undefined = this.parsedLines[startLineIndex];
    if (!startLine) {
      return '...';
    }
    
    const lastToken: JsonToken | undefined = startLine.tokens[startLine.tokens.length - 1];
    const bracketType: string = lastToken ? lastToken.value : '{';
    const isObject: boolean = bracketType === '{';

    let itemCount: number = 0;
    let depth: number = 1;
    
    for (let i = startLineIndex + 1; i < this.parsedLines.length && depth > 0; i++) {
      const line: JsonLine | undefined = this.parsedLines[i];
      if (!line) {
        continue;
      }
      
      if (line.isBlockStart) {
        if (depth === 1) {
          itemCount++;
        }
        depth++;
      } else if (line.isBlockEnd) {
        depth--;
      } else if (depth === 1) {
        if (isObject) {
          if (line.tokens.some((t: JsonToken) => t.type === 'key')) {
            itemCount++;
          }
        } else {
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
   * Format JSON content
   */
  private formatJson(): void {
    const textToFormat: string = this.isEditing ? this.editText : this.content;
    if (!textToFormat || textToFormat.trim() === '') {
      return;
    }
    try {
      const parsed: ESObject = JSON.parse(textToFormat) as ESObject;
      const formatted: string = JSON.stringify(parsed, null, 2);
      this.editText = formatted;
      this.onContentChange(formatted);
      this.parseJson();
      this.showToast('JSON 格式化成功');
    } catch (e) {
      this.showToast('JSON 格式化失败: 无效的 JSON');
    }
  }

  /**
   * Show toast message
   */
  private showToast(message: string): void {
    try {
      this.getUIContext().getPromptAction().showToast({
        message: message,
        duration: 2000
      });
    } catch (error) {
      console.error('[JsonEditor] Toast error:', error);
    }
  }

  /**
   * Start editing mode
   */
  private startEditing(): void {
    if (this.readonly) {
      return;
    }
    this.isEditing = true;
    this.editText = this.content;
  }

  /**
   * Finish editing and update content
   */
  private finishEditing(): void {
    this.isEditing = false;
    if (this.editText !== this.content) {
      this.onContentChange(this.editText);
    }
    this.parseJson();
  }

  /**
   * Get visible lines (filtered by collapsed state)
   */
  private getVisibleLines(): JsonLine[] {
    return this.parsedLines.filter((line: JsonLine) => this.isLineVisible(line));
  }

  build() {
    Column() {
      // Toolbar with format button
      if (!this.readonly && this.showFormatButton) {
        Row() {
          Blank()
            .layoutWeight(1)
          
          Button('格式化')
            .fontSize($r('app.float.font_size_sm'))
            .fontColor($r('app.color.button_text'))
            .backgroundColor($r('app.color.primary'))
            .height(28)
            .onClick(() => {
              this.formatJson();
            })
        }
        .width('100%')
        .padding({ left: 8, right: 8, top: 4, bottom: 4 })
        .backgroundColor($r('app.color.code_background'))
      }

      // Editor content
      if (this.readonly) {
        // Readonly mode: syntax highlighted view
        this.buildReadonlyView()
      } else if (this.isEditing) {
        // Edit mode: TextArea with line numbers
        this.buildTextAreaView()
      } else {
        // Preview mode: syntax highlighted view (clickable to edit)
        this.buildPreviewView()
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.code_background'))
    .clip(true)
  }

  @Builder
  buildReadonlyView() {
    if (this.parsedLines.length === 0) {
      Column() {
        Text('没有内容')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Row() {
          // Line numbers column with fold buttons
          Column() {
            ForEach(this.getVisibleLines(), (line: JsonLine) => {
              this.buildLineNumber(line, true)
            }, (line: JsonLine) => `ln_${line.lineNumber}_${this.collapsedBlocks.has(line.blockId)}_${this.errorLine === line.lineNumber}`)
          }
          .width(55)
          .alignItems(HorizontalAlign.End)
          .padding({ right: 8 })

          // Code content column with horizontal scroll
          Scroll() {
            Column() {
              ForEach(this.getVisibleLines(), (line: JsonLine) => {
                this.buildCodeLine(line)
              }, (line: JsonLine) => `code_${line.lineNumber}_${this.collapsedBlocks.has(line.blockId)}`)
            }
            .alignItems(HorizontalAlign.Start)
          }
          .layoutWeight(1)
          .scrollable(ScrollDirection.Horizontal)
          .scrollBar(BarState.Off)
          .align(Alignment.TopStart)
        }
        .width('100%')
      }
      .width('100%')
      .layoutWeight(1)
      .scrollBar(BarState.Auto)
      .backgroundColor($r('app.color.code_background'))
      .align(Alignment.Top)
    }
  }

  @Builder
  buildPreviewView() {
    Scroll() {
      Row() {
        // Line numbers column with fold buttons
        Column() {
          ForEach(this.getVisibleLines(), (line: JsonLine) => {
            this.buildLineNumber(line, true)
          }, (line: JsonLine) => `ln_${line.lineNumber}_${this.collapsedBlocks.has(line.blockId)}_${this.errorLine === line.lineNumber}`)
        }
        .width(55)
        .alignItems(HorizontalAlign.End)
        .padding({ right: 8 })

        // Code content column with horizontal scroll
        Scroll() {
          Column() {
            ForEach(this.getVisibleLines(), (line: JsonLine) => {
              this.buildCodeLine(line)
            }, (line: JsonLine) => `code_${line.lineNumber}_${this.collapsedBlocks.has(line.blockId)}`)
          }
          .alignItems(HorizontalAlign.Start)
        }
        .layoutWeight(1)
        .scrollable(ScrollDirection.Horizontal)
        .scrollBar(BarState.Off)
        .align(Alignment.TopStart)
      }
      .width('100%')
    }
    .width('100%')
    .layoutWeight(1)
    .scrollBar(BarState.Auto)
    .backgroundColor($r('app.color.code_background'))
    .align(Alignment.Top)
    .onClick(() => {
      this.startEditing();
    })
  }

  @Builder
  buildTextAreaView() {
    // 编辑模式：左侧行号 + 右侧 TextArea
    Row() {
      // 行号列 - 使用 offset 来同步滚动位置，并限制在 TextArea 的高度范围内
      Column() {
        Column() {
          ForEach(this.getEditableLineNumbers(), (lineNum: number) => this.buildLineNum(lineNum),
            (lineNum: number) => `edit_ln_${lineNum}_${this.errorLine === lineNum}`)
        }
        .alignItems(HorizontalAlign.Start)
        .offset({ x: 0, y: this.lineNumberOffsetY })
      }
      .width(55)
      .height('100%')
      .padding({ right: 8, top: 1 })
      .clip(true)  // 裁剪超出边界的内容

      // TextArea 编辑区
      TextArea({ text: this.editText })
        .height('100%')
        .lineHeight(this.fontSettings.editorFontSize + 6)
        .backgroundColor(Color.Transparent)
        .fontColor($r('app.color.code_text'))
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)
        .borderRadius(0)
        .padding({ right: 12, bottom: 12, top: 0, left:0 })
        .onChange((value: string) => {
          this.editText = value;
          this.onContentChange(value);
          // 实时解析检查错误
          this.checkJsonError();
        })
        .onBlur(() => {
          this.finishEditing();
        })
        .onContentScroll((_totalOffsetX: number, totalOffsetY: number) => {
          // 同步行号列的滚动位置
          // totalOffsetY 单位是 px，需要转换为 vp
          const offsetVp: number = this.getUIContext().px2vp(totalOffsetY);
          this.lineNumberOffsetY = offsetVp;
        })
    }
    .width('100%')
    .layoutWeight(1)
    .backgroundColor($r('app.color.code_background'))
    .alignItems(VerticalAlign.Top)
  }

  /**
   * Get line numbers for editable view
   */
  private getEditableLineNumbers(): number[] {
    const result: number[] = [];
    const text: string = this.editText || '';
    const lineCount: number = Math.max(text.split('\n').length, 1);
    for (let i = 1; i <= lineCount; i++) {
      result.push(i);
    }
    return result;
  }

  /**
   * Check JSON error without updating parsedLines (with debounce for performance)
   */
  private checkJsonError(): void {
    // 清除之前的定时器
    if (this.validationTimer !== -1) {
      clearTimeout(this.validationTimer);
    }

    // 空内容直接返回
    if (!this.editText || this.editText.trim() === '') {
      this.errorLine = -1;
      return;
    }

    // 对于大 JSON（超过 10KB），使用防抖延迟验证
    const textSize: number = this.editText.length;
    if (textSize > 10000) {
      // 延迟 500ms 验证
      this.validationTimer = setTimeout(() => {
        this.performValidation();
      }, 500);
    } else {
      // 小 JSON 立即验证
      this.performValidation();
    }
  }

  /**
   * 执行实际的验证
   */
  private performValidation(): void {
    if (!this.editText || this.editText.trim() === '') {
      this.errorLine = -1;
      return;
    }

    try {
      // 使用自定义验证器检查错误
      const validationResult: JsonValidationResult = this.jsonValidator.validate(this.editText);
      
      if (validationResult.valid) {
        this.errorLine = -1;
      } else {
        this.errorLine = validationResult.errorLine || -1;
      }
    } catch (e) {
      // 验证过程中出错，不显示错误指示器
      console.error('[JsonEditor] Validation error:', e);
      this.errorLine = -1;
    }
  }

  @Builder
  buildLineNum(lineNum: number) {
    Row() {
      // 错误指示器
      if (this.errorLine === lineNum) {
        Text('●')
          .fontSize(10)
          .fontColor('#FF6B6B')
          .width(10)
      } else {
        Text('')
          .width(10)
      }

      Text(`${lineNum}`)
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)
        .fontColor('#858585')
        .textAlign(TextAlign.End)
        .width(25)
    }
    .height(this.fontSettings.editorFontSize + 6.2)
    .justifyContent(FlexAlign.End)
  }

  @Builder
  buildLineNumber(line: JsonLine, showFoldButton: boolean) {
    Row() {
      // 错误指示器
      if (this.errorLine === line.lineNumber) {
        Text('●')
          .fontSize(10)
          .fontColor('#FF6B6B')
          .width(10)
      } else {
        Text('')
          .width(10)
      }

      Text(`${line.lineNumber}`)
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)
        .fontColor('#858585')
        .textAlign(TextAlign.End)
        .width(25)

      if (showFoldButton && line.isCollapsible) {
        Text() {
          SymbolSpan(this.collapsedBlocks.has(line.blockId) ? $r('sys.symbol.chevron_right') : $r('sys.symbol.chevron_down'))
        }
          .fontSize(14)
          .fontColor('#858585')
          .width(14)
          .textAlign(TextAlign.Center)
          .onClick(() => {
            this.toggleBlock(line.blockId);
          })
      } else if (showFoldButton) {
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
      Text('  '.repeat(line.indent))
        .fontSize(this.fontSettings.editorFontSize)
        .fontFamily(this.fontSettings.editorFont)

      ForEach(line.tokens, (token: JsonToken) => {
        Text(token.value)
          .fontSize(this.fontSettings.editorFontSize)
          .fontFamily(this.fontSettings.editorFont)
          .fontColor(getTokenColor(token.type))
          .maxLines(1)
      }, (token: JsonToken, index: number) => `token_${line.lineNumber}_${index}_${token.value}`)

      if (line.isCollapsible && this.collapsedBlocks.has(line.blockId)) {
        Text(this.getCollapsedPreview(line.blockId))
          .fontSize(this.fontSettings.editorFontSize)
          .fontFamily(this.fontSettings.editorFont)
          .fontColor('#858585')
          .fontStyle(FontStyle.Italic)
          .maxLines(1)
      }
    }
    .height(this.fontSettings.editorFontSize + 6)
    .alignItems(VerticalAlign.Center)
  }
}
