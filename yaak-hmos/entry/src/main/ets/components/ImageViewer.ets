/**
 * ImageViewer Component
 * Displays image content with zoom and pan support
 */

import { ThemedText } from './ThemedText';

@ComponentV2
export struct ImageViewer {
  @Param imagePath: string = '';
  @Local imageScale: number = 1.0;
  @Local imageOffsetX: number = 0;
  @Local imageOffsetY: number = 0;

  build() {
    Column() {
      if (this.imagePath) {
        // Image with gesture support
        Image('file://' + this.imagePath)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .scale({ x: this.imageScale, y: this.imageScale })
          .translate({ x: this.imageOffsetX, y: this.imageOffsetY })
          .gesture(
            // Pinch to zoom
            PinchGesture()
              .onActionUpdate((event: GestureEvent) => {
                if (event.scale) {
                  this.imageScale = Math.max(0.5, Math.min(5.0, event.scale));
                }
              })
          )
          .gesture(
            // Pan to move
            PanGesture()
              .onActionUpdate((event: GestureEvent) => {
                if (event.offsetX !== undefined && event.offsetY !== undefined) {
                  this.imageOffsetX = event.offsetX;
                  this.imageOffsetY = event.offsetY;
                }
              })
          )
          .gesture(
            // Double tap to reset
            TapGesture({ count: 2 })
              .onAction(() => {
                this.imageScale = 1.0;
                this.imageOffsetX = 0;
                this.imageOffsetY = 0;
              })
          )
      } else {
        this.buildEmptyState();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState() {
    Column() {
      ThemedText({
        content: 'No image to display',
        fontColor: $r('app.color.text_secondary')
      })
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}
