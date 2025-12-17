/**
 * Resizable Pane Component
 * A pane with draggable resize handle
 */

@ComponentV2
export struct ResizablePane {
  @Param minWidthValue: number = 200;
  @Param maxWidthValue: number = 800;
  @Param defaultWidthValue: number = 300;
  @Param storageKey: string = '';
  @Param onWidthChange: (width: number) => void = () => {};
  @BuilderParam content: () => void = this.defaultContent;

  @Local currentWidth: number = 300;
  @Local isDragging: boolean = false;
  @Local dragStartX: number = 0;
  @Local dragStartWidth: number = 0;

  @Builder
  defaultContent() {
    Column()
  }

  aboutToAppear(): void {
    // Load saved width from AppStorage
    if (this.storageKey) {
      const savedWidth: number | undefined = AppStorage.get<number>(this.storageKey);
      if (savedWidth !== undefined && savedWidth >= this.minWidthValue && savedWidth <= this.maxWidthValue) {
        this.currentWidth = savedWidth;
      } else {
        this.currentWidth = this.defaultWidthValue;
      }
    } else {
      this.currentWidth = this.defaultWidthValue;
    }
  }

  build() {
    Row() {
      // Content
      Column() {
        this.content();
      }
      .width(this.currentWidth)
      .height('100%')

      // Resize Handle
      Column() {
        // Visual indicator
        Column()
          .width(2)
          .height('100%')
          .backgroundColor(this.isDragging ? $r('app.color.primary') : $r('app.color.divider'))
      }
      .width(8)
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .backgroundColor(Color.Transparent)
      .gesture(
        PanGesture({ fingers: 1, direction: PanDirection.Horizontal, distance: 1 })
          .onActionStart((event: GestureEvent) => {
            this.isDragging = true;
            this.dragStartX = event.fingerList[0].globalX;
            this.dragStartWidth = this.currentWidth;
          })
          .onActionUpdate((event: GestureEvent) => {
            if (this.isDragging) {
              const currentX: number = event.fingerList[0].globalX;
              const deltaX: number = currentX - this.dragStartX;
              let newWidth: number = this.dragStartWidth + deltaX;

              // Apply constraints
              if (newWidth < this.minWidthValue) {
                newWidth = this.minWidthValue;
              } else if (newWidth > this.maxWidthValue) {
                newWidth = this.maxWidthValue;
              }

              this.currentWidth = newWidth;
            }
          })
          .onActionEnd(() => {
            this.isDragging = false;
            
            // Save width to AppStorage
            if (this.storageKey) {
              AppStorage.setOrCreate(this.storageKey, this.currentWidth);
            }

            // Notify parent
            this.onWidthChange(this.currentWidth);
          })
      )
    }
    .height('100%')
  }
}
