/**
 * FontService
 * 全局字体管理服务
 * 使用 @ObservedV2 实现响应式字体设置
 */

// 默认值
const DEFAULT_INTERFACE_FONT: string = 'HarmonyOS Sans';
const DEFAULT_INTERFACE_FONT_SIZE: number = 14;
const DEFAULT_EDITOR_FONT: string = 'monospace';
const DEFAULT_EDITOR_FONT_SIZE: number = 14;

/**
 * 全局字体设置类
 * 使用 @ObservedV2 和 @Trace 实现响应式更新
 */
@ObservedV2
export class FontSettings {
  private static instance: FontSettings | null = null;
  
  @Trace interfaceFont: string = DEFAULT_INTERFACE_FONT;
  @Trace interfaceFontSize: number = DEFAULT_INTERFACE_FONT_SIZE;
  @Trace editorFont: string = DEFAULT_EDITOR_FONT;
  @Trace editorFontSize: number = DEFAULT_EDITOR_FONT_SIZE;
  
  private constructor() {}
  
  static getInstance(): FontSettings {
    if (FontSettings.instance === null) {
      FontSettings.instance = new FontSettings();
    }
    return FontSettings.instance;
  }
  
  /**
   * 设置界面字体
   */
  setInterfaceFont(font: string): void {
    this.interfaceFont = font === 'system' ? DEFAULT_INTERFACE_FONT : font;
  }
  
  /**
   * 设置界面字体大小
   */
  setInterfaceFontSize(size: number): void {
    this.interfaceFontSize = size;
  }
  
  /**
   * 设置编辑器字体
   */
  setEditorFont(font: string): void {
    this.editorFont = font === 'system' ? DEFAULT_EDITOR_FONT : font;
  }
  
  /**
   * 设置编辑器字体大小
   */
  setEditorFontSize(size: number): void {
    this.editorFontSize = size;
  }
  
  /**
   * 初始化字体设置
   */
  init(interfaceFont: string, interfaceFontSize: number, editorFont: string, editorFontSize: number): void {
    this.setInterfaceFont(interfaceFont);
    this.setInterfaceFontSize(interfaceFontSize);
    this.setEditorFont(editorFont);
    this.setEditorFontSize(editorFontSize);
  }
}

// 便捷函数
export function getFontSettings(): FontSettings {
  return FontSettings.getInstance();
}

export function setInterfaceFont(font: string): void {
  FontSettings.getInstance().setInterfaceFont(font);
}

export function setInterfaceFontSize(size: number): void {
  FontSettings.getInstance().setInterfaceFontSize(size);
}

export function setEditorFont(font: string): void {
  FontSettings.getInstance().setEditorFont(font);
}

export function setEditorFontSize(size: number): void {
  FontSettings.getInstance().setEditorFontSize(size);
}

export function getEditorFont(): string {
  return FontSettings.getInstance().editorFont;
}

export function getEditorFontSize(): number {
  return FontSettings.getInstance().editorFontSize;
}

export function getInterfaceFont(): string {
  return FontSettings.getInstance().interfaceFont;
}

export function getInterfaceFontSize(): number {
  return FontSettings.getInstance().interfaceFontSize;
}

// 移除不再需要的 initFontStorage
export function initFontStorage(): void {
  // 空实现，保持兼容性
}
