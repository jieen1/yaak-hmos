/**
 * JSON Validator
 * 独立的 JSON 格式校验工具，提供精确的错误位置信息
 */

/**
 * JSON 验证结果
 */
export interface JsonValidationResult {
  valid: boolean;           // 是否有效
  errorMessage?: string;    // 错误消息
  errorLine?: number;       // 错误行号（从 1 开始）
  errorColumn?: number;     // 错误列号（从 1 开始）
  errorPosition?: number;   // 错误字符位置（从 0 开始）
}

/**
 * Token 类型
 */
enum TokenType {
  LEFT_BRACE,      // {
  RIGHT_BRACE,     // }
  LEFT_BRACKET,    // [
  RIGHT_BRACKET,   // ]
  COLON,           // :
  COMMA,           // ,
  STRING,          // "string"
  NUMBER,          // 123, 123.45, -123, 1.23e10
  TRUE,            // true
  FALSE,           // false
  NULL,            // null
  EOF              // 文件结束
}

/**
 * Token
 */
interface Token {
  type: TokenType;
  value: string;
  position: number;  // 在原始字符串中的位置
  line: number;      // 行号
  column: number;    // 列号
}

/**
 * JSON 验证器
 */
export class JsonValidator {
  private input: string = '';
  private position: number = 0;
  private line: number = 1;
  private column: number = 1;
  private tokens: Token[] = [];

  /**
   * 验证 JSON 字符串
   */
  public validate(jsonString: string): JsonValidationResult {
    this.input = jsonString;
    this.position = 0;
    this.line = 1;
    this.column = 1;
    this.tokens = [];

    try {
      // 词法分析
      this.tokenize();
      
      // 语法分析
      this.parse();
      
      return {
        valid: true
      };
    } catch (e) {
      const error = e as Error;
      return this.createErrorResult(error.message);
    }
  }

  /**
   * 词法分析 - 将输入字符串转换为 token 序列
   */
  private tokenize(): void {
    while (this.position < this.input.length) {
      this.skipWhitespace();
      
      if (this.position >= this.input.length) {
        break;
      }

      const char: string = this.currentChar();
      const tokenStart: number = this.position;
      const tokenLine: number = this.line;
      const tokenColumn: number = this.column;

      if (char === '{') {
        this.tokens.push({
          type: TokenType.LEFT_BRACE,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === '}') {
        this.tokens.push({
          type: TokenType.RIGHT_BRACE,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === '[') {
        this.tokens.push({
          type: TokenType.LEFT_BRACKET,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === ']') {
        this.tokens.push({
          type: TokenType.RIGHT_BRACKET,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === ':') {
        this.tokens.push({
          type: TokenType.COLON,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === ',') {
        this.tokens.push({
          type: TokenType.COMMA,
          value: char,
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance();
      } else if (char === '"') {
        this.tokens.push(this.readString(tokenStart, tokenLine, tokenColumn));
      } else if (char === '-' || (char >= '0' && char <= '9')) {
        this.tokens.push(this.readNumber(tokenStart, tokenLine, tokenColumn));
      } else if (this.input.substring(this.position, this.position + 4) === 'true') {
        this.tokens.push({
          type: TokenType.TRUE,
          value: 'true',
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance(4);
      } else if (this.input.substring(this.position, this.position + 5) === 'false') {
        this.tokens.push({
          type: TokenType.FALSE,
          value: 'false',
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance(5);
      } else if (this.input.substring(this.position, this.position + 4) === 'null') {
        this.tokens.push({
          type: TokenType.NULL,
          value: 'null',
          position: tokenStart,
          line: tokenLine,
          column: tokenColumn
        });
        this.advance(4);
      } else {
        throw new Error(`Unexpected character '${char}' at line ${this.line}, column ${this.column}`);
      }
    }

    // 添加 EOF token
    this.tokens.push({
      type: TokenType.EOF,
      value: '',
      position: this.position,
      line: this.line,
      column: this.column
    });
  }

  /**
   * 读取字符串 token
   */
  private readString(startPos: number, startLine: number, startColumn: number): Token {
    let value: string = '';
    this.advance(); // 跳过开始的引号

    while (this.position < this.input.length) {
      const char: string = this.currentChar();

      if (char === '"') {
        this.advance(); // 跳过结束的引号
        return {
          type: TokenType.STRING,
          value: value,
          position: startPos,
          line: startLine,
          column: startColumn
        };
      } else if (char === '\\') {
        // 处理转义字符
        this.advance();
        if (this.position >= this.input.length) {
          throw new Error(`Unterminated string at line ${startLine}, column ${startColumn}`);
        }
        const escapeChar: string = this.currentChar();
        if (escapeChar === '"' || escapeChar === '\\' || escapeChar === '/' ||
            escapeChar === 'b' || escapeChar === 'f' || escapeChar === 'n' ||
            escapeChar === 'r' || escapeChar === 't') {
          value += '\\' + escapeChar;
          this.advance();
        } else if (escapeChar === 'u') {
          // Unicode 转义
          value += '\\u';
          this.advance();
          for (let i = 0; i < 4; i++) {
            if (this.position >= this.input.length) {
              throw new Error(`Invalid unicode escape at line ${this.line}, column ${this.column}`);
            }
            const hexChar: string = this.currentChar();
            if (!this.isHexDigit(hexChar)) {
              throw new Error(`Invalid unicode escape at line ${this.line}, column ${this.column}`);
            }
            value += hexChar;
            this.advance();
          }
        } else {
          throw new Error(`Invalid escape character '\\${escapeChar}' at line ${this.line}, column ${this.column}`);
        }
      } else if (char === '\n' || char === '\r') {
        throw new Error(`Unterminated string at line ${startLine}, column ${startColumn}`);
      } else {
        value += char;
        this.advance();
      }
    }

    throw new Error(`Unterminated string at line ${startLine}, column ${startColumn}`);
  }

  /**
   * 读取数字 token
   */
  private readNumber(startPos: number, startLine: number, startColumn: number): Token {
    let value: string = '';

    // 负号
    if (this.currentChar() === '-') {
      value += '-';
      this.advance();
    }

    // 整数部分
    if (this.currentChar() === '0') {
      value += '0';
      this.advance();
    } else if (this.currentChar() >= '1' && this.currentChar() <= '9') {
      while (this.position < this.input.length && this.currentChar() >= '0' && this.currentChar() <= '9') {
        value += this.currentChar();
        this.advance();
      }
    } else {
      throw new Error(`Invalid number at line ${this.line}, column ${this.column}`);
    }

    // 小数部分
    if (this.position < this.input.length && this.currentChar() === '.') {
      value += '.';
      this.advance();
      
      if (this.position >= this.input.length || !(this.currentChar() >= '0' && this.currentChar() <= '9')) {
        throw new Error(`Invalid number at line ${this.line}, column ${this.column}`);
      }
      
      while (this.position < this.input.length && this.currentChar() >= '0' && this.currentChar() <= '9') {
        value += this.currentChar();
        this.advance();
      }
    }

    // 指数部分
    if (this.position < this.input.length && (this.currentChar() === 'e' || this.currentChar() === 'E')) {
      value += this.currentChar();
      this.advance();
      
      if (this.position < this.input.length && (this.currentChar() === '+' || this.currentChar() === '-')) {
        value += this.currentChar();
        this.advance();
      }
      
      if (this.position >= this.input.length || !(this.currentChar() >= '0' && this.currentChar() <= '9')) {
        throw new Error(`Invalid number at line ${this.line}, column ${this.column}`);
      }
      
      while (this.position < this.input.length && this.currentChar() >= '0' && this.currentChar() <= '9') {
        value += this.currentChar();
        this.advance();
      }
    }

    return {
      type: TokenType.NUMBER,
      value: value,
      position: startPos,
      line: startLine,
      column: startColumn
    };
  }

  /**
   * 语法分析 - 验证 token 序列是否符合 JSON 语法
   */
  private parse(): void {
    let index: number = 0;

    const parseValue = (): void => {
      if (index >= this.tokens.length) {
        throw new Error('Unexpected end of input');
      }

      const token: Token | undefined = this.tokens[index];
      if (!token) {
        throw new Error('Unexpected end of input');
      }

      if (token.type === TokenType.LEFT_BRACE) {
        parseObject();
      } else if (token.type === TokenType.LEFT_BRACKET) {
        parseArray();
      } else if (token.type === TokenType.STRING || token.type === TokenType.NUMBER ||
                 token.type === TokenType.TRUE || token.type === TokenType.FALSE ||
                 token.type === TokenType.NULL) {
        index++;
      } else {
        throw new Error(`Unexpected token at line ${token.line}, column ${token.column}`);
      }
    };

    const parseObject = (): void => {
      const startToken: Token | undefined = this.tokens[index];
      index++; // 跳过 {

      // 空对象
      const nextToken: Token | undefined = this.tokens[index];
      if (index < this.tokens.length && nextToken && nextToken.type === TokenType.RIGHT_BRACE) {
        index++;
        return;
      }

      let expectingKey: boolean = true; // 是否期待键

      while (index < this.tokens.length) {
        const currentToken: Token | undefined = this.tokens[index];
        if (!currentToken) {
          const start: Token | undefined = startToken;
          throw new Error(`Unclosed object starting at line ${start ? start.line : 1}, column ${start ? start.column : 1}`);
        }

        if (expectingKey) {
          // 期待键（字符串）
          if (currentToken.type === TokenType.RIGHT_BRACE) {
            // 对象结束
            index++;
            return;
          }
          
          if (currentToken.type !== TokenType.STRING) {
            throw new Error(`Expected string key at line ${currentToken.line}, column ${currentToken.column}`);
          }
          index++;

          // 冒号
          const colonToken: Token | undefined = this.tokens[index];
          if (index >= this.tokens.length || !colonToken || colonToken.type !== TokenType.COLON) {
            const prevToken: Token | undefined = this.tokens[index - 1];
            const line: number = prevToken ? prevToken.line : 1;
            const column: number = prevToken ? prevToken.column + prevToken.value.length : 1;
            throw new Error(`Expected ':' after key at line ${line}, column ${column}`);
          }
          index++;

          // 值
          parseValue();
          
          expectingKey = false; // 下一个应该是逗号或右大括号
        } else {
          // 期待逗号或右大括号
          if (currentToken.type === TokenType.RIGHT_BRACE) {
            // 对象结束
            index++;
            return;
          } else if (currentToken.type === TokenType.COMMA) {
            index++;
            expectingKey = true; // 逗号后期待下一个键
            
            // 检查逗号后面是否直接是右大括号（尾随逗号）
            const afterComma: Token | undefined = this.tokens[index];
            if (index < this.tokens.length && afterComma && afterComma.type === TokenType.RIGHT_BRACE) {
              throw new Error(`Trailing comma at line ${currentToken.line}, column ${currentToken.column}`);
            }
          } else {
            // 缺少逗号
            throw new Error(`Expected ',' or '}' at line ${currentToken.line}, column ${currentToken.column}`);
          }
        }
      }

      const start: Token | undefined = startToken;
      throw new Error(`Unclosed object starting at line ${start ? start.line : 1}, column ${start ? start.column : 1}`);
    };

    const parseArray = (): void => {
      const startToken: Token | undefined = this.tokens[index];
      index++; // 跳过 [

      // 空数组
      const nextToken: Token | undefined = this.tokens[index];
      if (index < this.tokens.length && nextToken && nextToken.type === TokenType.RIGHT_BRACKET) {
        index++;
        return;
      }

      let expectingValue: boolean = true; // 是否期待值

      while (index < this.tokens.length) {
        const currentToken: Token | undefined = this.tokens[index];
        if (!currentToken) {
          const start: Token | undefined = startToken;
          throw new Error(`Unclosed array starting at line ${start ? start.line : 1}, column ${start ? start.column : 1}`);
        }

        if (expectingValue) {
          // 期待值
          if (currentToken.type === TokenType.RIGHT_BRACKET) {
            // 数组结束
            index++;
            return;
          }
          
          // 解析值
          parseValue();
          expectingValue = false; // 下一个应该是逗号或右方括号
        } else {
          // 期待逗号或右方括号
          if (currentToken.type === TokenType.RIGHT_BRACKET) {
            // 数组结束
            index++;
            return;
          } else if (currentToken.type === TokenType.COMMA) {
            index++;
            expectingValue = true; // 逗号后期待下一个值
            
            // 检查逗号后面是否直接是右方括号（尾随逗号）
            const afterComma: Token | undefined = this.tokens[index];
            if (index < this.tokens.length && afterComma && afterComma.type === TokenType.RIGHT_BRACKET) {
              throw new Error(`Trailing comma at line ${currentToken.line}, column ${currentToken.column}`);
            }
          } else {
            // 缺少逗号
            throw new Error(`Expected ',' or ']' at line ${currentToken.line}, column ${currentToken.column}`);
          }
        }
      }

      const start: Token | undefined = startToken;
      throw new Error(`Unclosed array starting at line ${start ? start.line : 1}, column ${start ? start.column : 1}`);
    };

    // 开始解析
    parseValue();

    // 确保没有多余的 token
    if (index < this.tokens.length - 1) { // -1 因为最后一个是 EOF
      const token: Token | undefined = this.tokens[index];
      if (token) {
        throw new Error(`Unexpected token at line ${token.line}, column ${token.column}`);
      }
    }
  }

  /**
   * 获取当前字符
   */
  private currentChar(): string {
    const char: string | undefined = this.input[this.position];
    return char || '';
  }

  /**
   * 前进指定步数
   */
  private advance(steps: number = 1): void {
    for (let i = 0; i < steps; i++) {
      if (this.position < this.input.length) {
        if (this.input[this.position] === '\n') {
          this.line++;
          this.column = 1;
        } else {
          this.column++;
        }
        this.position++;
      }
    }
  }

  /**
   * 跳过空白字符
   */
  private skipWhitespace(): void {
    while (this.position < this.input.length) {
      const char: string = this.currentChar();
      if (char === ' ' || char === '\t' || char === '\n' || char === '\r') {
        this.advance();
      } else {
        break;
      }
    }
  }

  /**
   * 判断是否是十六进制数字
   */
  private isHexDigit(char: string): boolean {
    return (char >= '0' && char <= '9') ||
           (char >= 'a' && char <= 'f') ||
           (char >= 'A' && char <= 'F');
  }

  /**
   * 创建错误结果
   */
  private createErrorResult(errorMessage: string): JsonValidationResult {
    // 从错误消息中提取行号和列号
    const lineMatch: RegExpMatchArray | null = errorMessage.match(/line (\d+)/);
    const columnMatch: RegExpMatchArray | null = errorMessage.match(/column (\d+)/);

    const result: JsonValidationResult = {
      valid: false,
      errorMessage: errorMessage
    };

    if (lineMatch && lineMatch[1]) {
      result.errorLine = parseInt(lineMatch[1]);
    }

    if (columnMatch && columnMatch[1]) {
      result.errorColumn = parseInt(columnMatch[1]);
    }

    return result;
  }
}
