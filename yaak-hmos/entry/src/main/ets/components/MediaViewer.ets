/**
 * MediaViewer Component
 * Displays video and audio content with playback controls
 */

@ComponentV2
export struct VideoViewer {
  @Param videoPath: string = '';
  private videoController: VideoController = new VideoController();

  build() {
    Column() {
      if (this.videoPath) {
        Video({
          src: 'file://' + this.videoPath,
          controller: this.videoController
        })
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Contain)
          .controls(true)
          .autoPlay(false)
          .onError((error: ESObject) => {
            console.error('[VideoViewer] Video error:', JSON.stringify(error));
          })
      } else {
        this.buildEmptyState('没有可展示视频');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildEmptyState(message: string) {
    Column() {
      Text(message)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

@ComponentV2
export struct AudioViewer {
  @Param audioPath: string = '';
  @Local isPlaying: boolean = false;
  @Local currentTime: number = 0;
  @Local duration: number = 0;

  build() {
    Column() {
      if (this.audioPath) {
        Column() {
          // Audio icon
          Text('🎵')
            .fontSize(64)
            .margin({ bottom: $r('app.float.spacing_lg') })

          // Audio info
          Text('Audio File')
            .fontSize($r('app.float.font_size_lg'))
            .fontColor($r('app.color.text_primary'))
            .margin({ bottom: $r('app.float.spacing_md') })

          // Progress bar
          Row() {
            Text(this.formatTime(this.currentTime))
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.text_secondary'))

            Slider({
              value: this.currentTime,
              min: 0,
              max: this.duration || 100,
              style: SliderStyle.OutSet
            })
              .layoutWeight(1)
              .margin({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })

            Text(this.formatTime(this.duration))
              .fontSize($r('app.float.font_size_sm'))
              .fontColor($r('app.color.text_secondary'))
          }
          .width('80%')
          .margin({ top: $r('app.float.spacing_lg') })

          // Play/Pause button
          Button(this.isPlaying ? 'Pause' : 'Play')
            .fontSize($r('app.float.font_size_md'))
            .margin({ top: $r('app.float.spacing_lg') })
            .onClick(() => {
              this.isPlaying = !this.isPlaying;
              // Note: Actual audio playback would require native audio APIs
              console.info('[AudioViewer] Play/Pause clicked');
            })
        }
        .width('100%')
        .height('100%')
        .justifyContent(FlexAlign.Center)
        .alignItems(HorizontalAlign.Center)
      } else {
        this.buildEmptyState('没有可展示音频');
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildEmptyState(message: string) {
    Column() {
      Text(message)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
    }
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  private formatTime(seconds: number): string {
    const mins: number = Math.floor(seconds / 60);
    const secs: number = Math.floor(seconds % 60);
    return `${mins}:${secs.toString().padStart(2, '0')}`;
  }
}
