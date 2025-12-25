/**
 * TextViewer Component
 * Displays text content with optional syntax highlighting and formatting
 */

import { FontSettings } from '../services/FontService';

export interface TextViewerProps {
  text: string;
  language: 'json' | 'xml' | 'html' | 'text';
  pretty: boolean;
}

@ComponentV2
export struct TextViewer {
  @Param text: string = '';
  @Param language: 'json' | 'xml' | 'html' | 'text' = 'text';
  @Param pretty: boolean = true;
  
  // 使用全局字体设置（响应式）
  @Local fontSettings: FontSettings = FontSettings.getInstance();

  build() {
    Scroll() {
      Text(this.formatText())
        .fontFamily(this.fontSettings.editorFont)
        .fontSize(this.fontSettings.editorFontSize)
        .fontColor($r('app.color.text_primary'))
        .width('100%')
        .padding($r('app.float.spacing_md'))
        .copyOption(CopyOptions.InApp)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .scrollBar(BarState.Auto)
  }

  private formatText(): string {
    if (!this.text) {
      return '没有内容';
    }

    // Raw mode - return as-is
    if (!this.pretty) {
      return this.text;
    }

    // Pretty mode - format based on language
    switch (this.language) {
      case 'json':
        return this.formatJSON(this.text);
      case 'xml':
      case 'html':
        return this.formatXML(this.text);
      case 'text':
      default:
        return this.text;
    }
  }

  private formatJSON(content: string): string {
    try {
      const parsed: ESObject = JSON.parse(content) as ESObject;
      return JSON.stringify(parsed, null, 2);
    } catch (error) {
      console.warn('[TextViewer] Failed to parse JSON:', error);
      return content;
    }
  }

  private formatXML(content: string): string {
    // Basic XML/HTML formatting with indentation
    try {
      let formatted: string = '';
      let indent: number = 0;
      const lines: string[] = content.split('>');
      
      lines.forEach((line: string, index: number) => {
        if (line.trim().length === 0) return;
        
        // Decrease indent for closing tags
        if (line.trim().startsWith('</')) {
          indent = Math.max(0, indent - 2);
        }
        
        // Add indentation
        const indentStr: string = ' '.repeat(indent);
        formatted += indentStr + line.trim();
        
        // Add closing bracket except for last line
        if (index < lines.length - 1) {
          formatted += '>\n';
        }
        
        // Increase indent for opening tags (but not self-closing or closing tags)
        if (line.trim().startsWith('<') && 
            !line.trim().startsWith('</') && 
            !line.trim().endsWith('/') &&
            !line.includes('</')) {
          indent += 2;
        }
      });
      
      return formatted.trim();
    } catch (error) {
      console.warn('[TextViewer] Failed to format XML:', error);
      return content;
    }
  }
}
