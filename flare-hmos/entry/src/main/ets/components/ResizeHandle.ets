/**
 * ResizeHandle Component
 * Draggable handle for resizing panels
 * Based on Tauri's ResizeHandle implementation
 */

export interface ResizeEvent {
  x: number;
  y: number;
  xStart: number;
  yStart: number;
}

@ComponentV2
export struct ResizeHandle {
  @Param onResizeStart: () => void = () => {};
  @Param onResizeMove: (event: ResizeEvent) => void = () => {};
  @Param onResizeEnd: () => void = () => {};
  @Param onReset: () => void = () => {};
  @Param side: 'left' | 'right' = 'right';

  @Local private isDragging: boolean = false;
  @Local private startX: number = 0;
  @Local private startY: number = 0;

  build() {
    Column() {
      // Visual handle indicator
      Column()
        .width(4)
        .height(40)
        .backgroundColor(this.isDragging ? '#1890ff' : '#d9d9d9')
        .borderRadius(2)
        .opacity(this.isDragging ? 1.0 : 0.6)
    }
    .width(8)
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .backgroundColor('transparent')
    .gesture(
      PanGesture()
        .onActionStart((event: GestureEvent) => {
          if (event.fingerList && event.fingerList.length > 0) {
            this.isDragging = true;
            this.startX = event.fingerList[0].globalX;
            this.startY = event.fingerList[0].globalY;
            this.onResizeStart();
            console.info(`[ResizeHandle] Drag started at (${this.startX}, ${this.startY})`);
          }
        })
        .onActionUpdate((event: GestureEvent) => {
          if (event.fingerList && event.fingerList.length > 0) {
            const currentX = event.fingerList[0].globalX;
            const currentY = event.fingerList[0].globalY;
            this.onResizeMove({
              x: currentX,
              y: currentY,
              xStart: this.startX,
              yStart: this.startY
            });
          }
        })
        .onActionEnd(() => {
          this.isDragging = false;
          this.onResizeEnd();
          console.info('[ResizeHandle] Drag ended');
        })
    )
    .gesture(
      TapGesture({ count: 2 })
        .onAction(() => {
          console.info('[ResizeHandle] Double tap - resetting');
          this.onReset();
        })
    )
    .hitTestBehavior(HitTestMode.Default);
  }
}
