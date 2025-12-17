import { HttpResponse } from '../model';

@ComponentV2
export struct ResponseInfoTab {
  @Param response: HttpResponse | null = null;

  build() {
    Column() {
      if (!this.response) {
        this.buildEmptyState();
      } else {
        this.buildInfoContent();
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.background'))
  }

  @Builder
  buildEmptyState() {
    Column() {
      Text('No response information')
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_secondary'))
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }

  @Builder
  buildInfoContent() {
    Scroll() {
      Column() {
        // Status Information
        this.buildSection('Status Information', [
          { label: 'Status Code', value: `${this.response?.status_code || 0}` },
          { label: 'Status Text', value: this.response?.status_text || 'N/A' },
          { label: 'State', value: this.formatState(this.response?.state || 'pending') }
        ]);

        // Timing Information
        this.buildSection('Timing Information', [
          { label: 'Total Time', value: `${this.response?.elapsed_time || 0} ms` },
          { label: 'Request Sent', value: this.formatTimestamp(this.response?.created_at || 0) }
        ]);

        // Size Information
        this.buildSection('Size Information', [
          { label: 'Response Size', value: this.formatSize(this.response?.size || 0) },
          { label: 'Headers Count', value: `${this.response?.headers.length || 0}` }
        ]);

        // Response Metadata
        this.buildSection('Response Metadata', [
          { label: 'Response ID', value: this.response?.id || 'N/A' },
          { label: 'Request ID', value: this.response?.request_id || 'N/A' },
          { label: 'Body Path', value: this.response?.body_path || 'N/A' }
        ]);
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
  }

  @Builder
  buildSection(title: string, items: Array<{ label: string; value: string }>) {
    Column() {
      // Section Title
      Text(title)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: $r('app.float.spacing_sm') })

      // Section Items
      Column() {
        ForEach(items, (item: { label: string; value: string }, index: number) => {
          this.buildInfoItem(item.label, item.value, index);
        }, (item: { label: string; value: string }, index: number) => `${title}-${index}`)
      }
      .width('100%')
      .backgroundColor($r('app.color.surface'))
      .borderRadius($r('app.float.border_radius_md'))
      .padding($r('app.float.spacing_sm'))
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_lg') })
  }

  @Builder
  buildInfoItem(label: string, value: string, index: number) {
    Row() {
      // Label
      Text(label)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('40%')

      // Value
      Text(value)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_primary'))
        .layoutWeight(1)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
        .margin({ left: $r('app.float.spacing_md') })
    }
    .width('100%')
    .padding({
      top: $r('app.float.spacing_sm'),
      bottom: $r('app.float.spacing_sm')
    })
    .border({
      width: { bottom: index < 2 ? 1 : 0 },
      color: $r('app.color.divider')
    })
  }

  private formatState(state: string): string {
    switch (state) {
      case 'pending':
        return 'Pending';
      case 'success':
        return 'Success';
      case 'error':
        return 'Error';
      case 'cancelled':
        return 'Cancelled';
      default:
        return state;
    }
  }

  private formatTimestamp(timestamp: number): string {
    if (!timestamp) return 'N/A';

    const date = new Date(timestamp);
    const year = date.getFullYear();
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const day = String(date.getDate()).padStart(2, '0');
    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    return `${year}-${month}-${day} ${hours}:${minutes}:${seconds}`;
  }

  private formatSize(bytes: number): string {
    if (bytes < 1024) {
      return `${bytes} B`;
    } else if (bytes < 1024 * 1024) {
      return `${(bytes / 1024).toFixed(2)} KB`;
    } else {
      return `${(bytes / (1024 * 1024)).toFixed(2)} MB`;
    }
  }
}
