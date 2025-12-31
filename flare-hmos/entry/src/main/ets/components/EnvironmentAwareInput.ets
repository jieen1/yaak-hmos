/**
 * Environment Aware Input Component
 * Input component that supports environment variable highlighting and autocomplete
 * Uses RichEditor for rich text capabilities
 */

import { RichEditor, RichEditorController, RichEditorTextSpanResult, RichEditorImageSpanResult, RichEditorTextStyle, RichEditorSpanPosition } from '@ohos.arkui.advanced.RichEditor';
import { FontSettings } from '../services/FontService';
import { EnvironmentVariable } from '../model/Environment';
import { EnvironmentUtils, TextFragment } from '../utils/EnvironmentUtils';

@ComponentV2
export struct EnvironmentAwareInput {
  @Param value: string = '';
  @Param placeholder: string = '';
  @Param variables: EnvironmentVariable[] = [];
  @Param onValueChange: (value: string) => void = () => {};
  @Param inputSize: 'sm' | 'md' | 'lg' = 'md';
  @Param readOnly: boolean = false;

  // Internal state
  @Local fontSettings: FontSettings = FontSettings.getInstance();
  @Local showAutocomplete: boolean = false;
  @Local filterText: string = ''; // Text after {{ to filter variables
  @Local selectedIndex: number = 0;
  @Local showVariableTooltip: boolean = false;
  @Local currentHoveredVariable: EnvironmentVariable | null = null;
  @Local internalValue: string = ''; // Local copy of value for modification
  
  private controller: RichEditorController = new RichEditorController();
  private isInternalChange: boolean = false;
  private debounceTimer: number = -1;

  aboutToAppear() {
    this.internalValue = this.value;
  }

  @Monitor('value')
  onValuePropChange() {
    if (this.value !== this.internalValue) {
      this.internalValue = this.value;
      // Re-render when external value changes
      this.renderContent();
    }
  }

  build() {
    Column() {
      Stack({ alignContent: Alignment.TopStart }) {
        // The Editor
        RichEditor({ controller: this.controller })
          .width('100%')
          .height(this.getHeight())
          .backgroundColor($r('app.color.input_background'))
          .borderRadius($r('app.float.border_radius_md'))
          .border({
            width: $r('app.float.border_width_thin'),
            color: $r('app.color.input_border')
          })
          .padding({
            left: $r('app.float.spacing_md'),
            right: $r('app.float.spacing_md'),
            top: 6, // Adjust vertical padding to center text visually
            bottom: 6
          })
          .onReady(() => {
            this.renderContent();
          })
          .aboutToIMEInput((value) => {
            // Block newlines to mimic single-line input
            if (value.insertValue.includes('\n')) {
              return false; 
            }
            return true;
          })
          .onDidChange(() => {
            this.handleInputChange();
          })
          .onFocus(() => {
             // Handle focus style if needed
          })
          .onBlur(() => {
            this.showAutocomplete = false;
            this.showVariableTooltip = false;
            // Re-render on blur to ensure proper highlighting
            this.renderContent();
          })
          .bindPopup(this.showVariableTooltip, {
            builder: this.VariableTooltipBuilder,
            placement: Placement.Top,
            mask: false,
            onStateChange: (e) => {
              if (!e.isVisible) {
                this.showVariableTooltip = false;
              }
            }
          })

        // Placeholder (overlay)
        if (!this.internalValue && this.placeholder) {
          Text(this.placeholder)
            .fontColor($r('app.color.text_secondary'))
            .fontSize(this.fontSettings.editorFontSize)
            .fontFamily(this.fontSettings.editorFont)
            .margin({
              left: $r('app.float.spacing_md'),
              top: 10 // Approximate vertical center
            })
            .hitTestBehavior(HitTestMode.None)
        }
      }
      .width('100%')
      .zIndex(1)

      // Autocomplete Dropdown
      if (this.showAutocomplete) {
        List() {
          ForEach(this.getFilteredVariables(), (item: EnvironmentVariable, index: number) => {
            ListItem() {
              Row() {
                Text(item.name)
                  .fontColor(this.selectedIndex === index ? $r('app.color.text_on_primary') : $r('app.color.text_primary'))
                  .fontSize(this.fontSettings.interfaceFontSize) // Corrected from uiFontSize
                  .fontWeight(FontWeight.Medium)
                
                Blank()
                
                Text(item.value)
                  .fontColor(this.selectedIndex === index ? $r('app.color.text_on_primary') : $r('app.color.text_secondary'))
                  .fontSize(12)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                  .constraintSize({ maxWidth: '50%' })
              }
              .width('100%')
              .padding({ left: 12, right: 12, top: 8, bottom: 8 })
              .backgroundColor(this.selectedIndex === index ? $r('app.color.primary') : $r('app.color.surface'))
              .onClick(() => {
                this.insertVariable(item.name);
              })
            }
          })
        }
        .width('100%')
        .constraintSize({ maxHeight: 200 })
        .backgroundColor($r('app.color.surface'))
        .borderRadius($r('app.float.border_radius_md'))
        .shadow(ShadowStyle.OUTER_DEFAULT_MD)
        .margin({ top: 4 })
        .zIndex(2) // Above other content
      }
    }
    .width('100%')
  }

  @Builder
  VariableTooltipBuilder() {
    if (this.currentHoveredVariable) {
      Column() {
        Text(this.currentHoveredVariable.name)
          .fontWeight(FontWeight.Bold)
          .fontSize(12)
          .fontColor($r('app.color.text_primary'))
          .margin({ bottom: 4 })
        
        Text(this.currentHoveredVariable.value)
          .fontSize(12)
          .fontColor($r('app.color.text_secondary'))
          .maxLines(5)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
      }
      .padding(8)
      .backgroundColor($r('app.color.surface'))
      .borderRadius(4)
      .shadow(ShadowStyle.OUTER_DEFAULT_SM)
    }
  }

  private getHeight(): Resource {
    switch (this.inputSize) {
      case 'sm': return $r('app.float.input_height_sm');
      case 'md': return $r('app.float.input_height_md');
      case 'lg': return $r('app.float.input_height_lg');
      default: return $r('app.float.input_height_md');
    }
  }

  /**
   * Render the content with highlighting
   * Uses controller.deleteSpans and addTextSpan
   */
  private renderContent() {
    if (this.isInternalChange) return;
    
    this.controller.deleteSpans();
    
    if (!this.internalValue) return;

    const fragments = EnvironmentUtils.parseString(this.internalValue);
    
    fragments.forEach(frag => {
      if (frag.type === 'variable') {
        const style: RichEditorTextStyle = {
            fontColor: '#D97706', // Amber-600
            fontSize: this.fontSettings.editorFontSize,
            fontFamily: this.fontSettings.editorFont,
        };
        // Safely check if textBackgroundStyle is available in type definition or just suppress if known available
        // Since we are fixing strict errors, we will just set it if we can
        // However, 'RichEditorTextStyle' interface in standard SDK might not have textBackgroundStyle if it's new
        // We will try casting to any to bypass strict check for the optional property if needed, 
        // OR better: construct an object that matches runtime expectations but passes compilation
        
        // Using Partial<RichEditorTextStyle> or similar might work, but let's stick to base properties
        // and extend via casting if needed for new features
        const extendedStyle: Record<string, Object> = {
            fontColor: '#D97706',
            fontSize: this.fontSettings.editorFontSize,
            fontFamily: this.fontSettings.editorFont,
            textBackgroundStyle: {
              color: '#FEF3C7', // Amber-100
              radius: 4
            }
        };

        this.controller.addTextSpan(frag.text, {
          style: extendedStyle as RichEditorTextStyle
        });
      } else {
        this.controller.addTextSpan(frag.text, {
          style: {
            fontColor: $r('app.color.text_primary'),
            fontSize: this.fontSettings.editorFontSize,
            fontFamily: this.fontSettings.editorFont
          }
        });
      }
    });
  }

  /**
   * Handle text changes from the editor
   */
  private handleInputChange() {
    this.isInternalChange = true;
    
    let newValue = '';
    
    // Use getSpans as toStyledString might not be stable/available in all versions
    const spans = this.controller.getSpans();
    spans.forEach(span => {
      // Check if it is a text span
      if (typeof (span as RichEditorTextSpanResult).value === 'string') {
        newValue += (span as RichEditorTextSpanResult).value;
      }
    });

    // Only update if changed
    if (newValue !== this.internalValue) {
      this.internalValue = newValue;
      this.onValueChange(newValue);
      this.checkForAutocomplete(newValue);
      this.checkForHover(newValue);
    }
    
    this.isInternalChange = false;
  }

  /**
   * Check if we should show autocomplete
   */
  private checkForAutocomplete(text: string) {
    const caretOffset = this.controller.getCaretOffset();
    const textBeforeCaret = text.substring(0, caretOffset);
    
    // Check for open {{ without closing }}
    const lastOpen = textBeforeCaret.lastIndexOf('{{');
    const lastClose = textBeforeCaret.lastIndexOf('}}');
    
    if (lastOpen > -1 && lastOpen > lastClose) {
      this.filterText = textBeforeCaret.substring(lastOpen + 2);
      this.showAutocomplete = true;
      this.selectedIndex = 0;
    } else {
      this.showAutocomplete = false;
    }
  }

  /**
   * Check if cursor is inside a variable to show tooltip
   */
  private checkForHover(text: string) {
    const caretOffset = this.controller.getCaretOffset();
    
    // Simple check: is caret inside {{ and }}
    // Find nearest {{ before caret
    const lastOpen = text.lastIndexOf('{{', caretOffset);
    // Find nearest }} after caret
    const nextClose = text.indexOf('}}', caretOffset);
    
    if (lastOpen !== -1 && nextClose !== -1 && nextClose > lastOpen) {
       // Check if there are no other {{ or }} in between
       const sub = text.substring(lastOpen, nextClose + 2);
       if ((sub.match(/\{\{/g) || []).length === 1 && (sub.match(/\}\}/g) || []).length === 1) {
         const varName = text.substring(lastOpen + 2, nextClose);
         const variable = this.variables.find(v => v.name === varName);
         
         if (variable) {
           this.currentHoveredVariable = variable;
           this.showVariableTooltip = true;
           return;
         }
       }
    }
    
    this.showVariableTooltip = false;
    this.currentHoveredVariable = null;
  }

  private getFilteredVariables(): EnvironmentVariable[] {
    if (!this.filterText) return this.variables;
    return this.variables.filter(v => 
      v.name.toLowerCase().includes(this.filterText.toLowerCase())
    );
  }

  private insertVariable(name: string) {
    const caretOffset = this.controller.getCaretOffset();
    let text = '';
    
    const spans = this.controller.getSpans();
    spans.forEach(span => {
      if (typeof (span as RichEditorTextSpanResult).value === 'string') {
        text += (span as RichEditorTextSpanResult).value;
      }
    });
    
    const lastOpen = text.substring(0, caretOffset).lastIndexOf('{{');
    if (lastOpen === -1) return;
    
    const prefix = text.substring(0, lastOpen);
    const suffix = text.substring(caretOffset);
    
    const newValue = `${prefix}{{${name}}}${suffix}`;
    
    this.internalValue = newValue;
    this.onValueChange(newValue);
    this.showAutocomplete = false;
    
    // Defer render
    setTimeout(() => {
      this.renderContent();
    }, 10);
  }
}
