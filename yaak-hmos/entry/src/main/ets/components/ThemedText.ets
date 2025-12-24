/**
 * ThemedText Component
 * 封装的 Text 组件，自动应用全局字体设置
 * 使用 FontSettings 单例实现响应式字体更新
 */

import { FontSettings } from '../services/FontService';

@ComponentV2
export struct ThemedText {
  // Text 内容
  @Param content: ResourceStr = '';
  
  // 可选的字体大小覆盖（如果不提供，使用全局设置，-1表示使用全局）
  @Param fontSizeOverride:  number | string | Resource = -1;
  
  // 可选的字体颜色（空字符串表示不设置）
  @Param fontColor: ResourceColor = '';
  
  // 可选的字体粗细
  @Param fontWeight: number | FontWeight | string = FontWeight.Normal;
  
  // 可选的最大行数（-1表示不限制）
  @Param maxLines: number = -1;
  
  // 可选的文本溢出处理
  @Param textOverflow: TextOverflow = TextOverflow.Clip;
  
  // 获取全局字体设置
  @Local fontSettings: FontSettings = FontSettings.getInstance();

  build() {
    this.buildText()
  }
  
  @Builder
  buildText() {
    // 根据是否有可选属性来决定渲染方式
    if (this.hasOptionalProps()) {
      this.buildTextWithProps()
    } else {
      this.buildTextBasic()
    }
  }
  
  @Builder
  buildTextBasic() {
    Text(this.content)
      .fontFamily(this.fontSettings.interfaceFont)
      .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
  }
  
  @Builder
  buildTextWithProps() {
    // 创建基础Text组件
    if (this.fontColor !== '' && this.fontWeight !== FontWeight.Normal && this.maxLines !== -1) {
      // 颜色 + 粗细 + 行数
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontColor(this.fontColor)
        .fontWeight(this.fontWeight)
        .maxLines(this.maxLines)
    } else if (this.fontColor !== '' && this.fontWeight !== FontWeight.Normal) {
      // 颜色 + 粗细
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontColor(this.fontColor)
        .fontWeight(this.fontWeight)
    } else if (this.fontColor !== '' && this.maxLines !== -1) {
      // 颜色 + 行数
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontColor(this.fontColor)
        .maxLines(this.maxLines)
    } else if (this.fontWeight !== FontWeight.Normal && this.maxLines !== -1) {
      // 粗细 + 行数
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontWeight(this.fontWeight)
        .maxLines(this.maxLines)
    } else if (this.fontColor !== '') {
      // 只有颜色
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontColor(this.fontColor)
    } else if (this.fontWeight !== FontWeight.Normal) {
      // 只有粗细
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .fontWeight(this.fontWeight)
    } else if (this.maxLines !== -1) {
      // 只有行数
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
        .maxLines(this.maxLines)
    } else {
      // 基础
      Text(this.content)
        .fontFamily(this.fontSettings.interfaceFont)
        .fontSize(this.fontSizeOverride !== -1 ?  this.fontSizeOverride : this.fontSettings.interfaceFontSize)
    }
  }
  
  /**
   * 是否有可选属性
   */
  private hasOptionalProps(): boolean {
    return this.fontColor !== '' || 
           this.fontWeight !== FontWeight.Normal || 
           this.maxLines !== -1 ||
           this.textOverflow !== TextOverflow.Clip;
  }
}
