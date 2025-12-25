import { HttpResponse } from '../model';
import { ThemedText } from './ThemedText';

interface InfoItem {
  label: string;
  value: string;
}

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
      ThemedText({
        content: '没有响应信息',
        fontColor: $r('app.color.text_secondary')
      })
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
        this.buildSection('Status Information', this.buildStatusItems());

        // Timing Information
        this.buildSection('Timing Information', this.buildTimingItems());

        // Size Information
        this.buildSection('Size Information', this.buildSizeItems());

        // Response Metadata
        this.buildSection('Response Metadata', this.buildMetadataItems());
      }
      .width('100%')
      .padding($r('app.float.spacing_md'))
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Auto)
    .align(Alignment.Top)
  }

  private buildStatusItems(): InfoItem[] {
    const items: InfoItem[] = [];
    
    const statusCodeItem: InfoItem = {
      label: 'Status Code',
      value: `${this.response?.status_code || 0}`
    };
    items.push(statusCodeItem);
    
    const statusTextItem: InfoItem = {
      label: 'Status Text',
      value: this.response?.status_text || 'N/A'
    };
    items.push(statusTextItem);
    
    const stateItem: InfoItem = {
      label: 'State',
      value: this.formatState(this.response?.state || 'pending')
    };
    items.push(stateItem);
    
    return items;
  }

  private buildTimingItems(): InfoItem[] {
    const items: InfoItem[] = [];
    
    const totalTimeItem: InfoItem = {
      label: 'Total Time',
      value: `${this.response?.elapsed_time || 0} ms`
    };
    items.push(totalTimeItem);
    
    const requestSentItem: InfoItem = {
      label: 'Request Sent',
      value: this.formatTimestamp(this.response?.created_at || 0)
    };
    items.push(requestSentItem);
    
    return items;
  }

  private buildSizeItems(): InfoItem[] {
    const items: InfoItem[] = [];
    
    const responseSizeItem: InfoItem = {
      label: 'Response Size',
      value: this.formatSize(this.response?.size || 0)
    };
    items.push(responseSizeItem);
    
    const headersCountItem: InfoItem = {
      label: 'Headers Count',
      value: `${this.response?.headers.length || 0}`
    };
    items.push(headersCountItem);
    
    return items;
  }

  private buildMetadataItems(): InfoItem[] {
    const items: InfoItem[] = [];
    
    const responseIdItem: InfoItem = {
      label: 'Response ID',
      value: this.response?.id || 'N/A'
    };
    items.push(responseIdItem);
    
    const requestIdItem: InfoItem = {
      label: 'Request ID',
      value: this.response?.request_id || 'N/A'
    };
    items.push(requestIdItem);
    
    const bodyPathItem: InfoItem = {
      label: 'Body Path',
      value: this.response?.body_path || 'N/A'
    };
    items.push(bodyPathItem);
    
    return items;
  }

  @Builder
  buildSection(title: string, items: InfoItem[]) {
    Column() {
      // Section Title
      ThemedText({
        content: title,
        fontWeight: FontWeight.Bold,
        fontColor: $r('app.color.text_primary')
      })
        .margin({ bottom: $r('app.float.spacing_sm') })

      // Section Items
      Column() {
        ForEach(items, (item: InfoItem, index: number) => {
          this.buildInfoItem(item.label, item.value, index);
        }, (item: InfoItem, index: number) => `${title}-${index}`)
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
      ThemedText({
        content: label,
        fontColor: $r('app.color.text_secondary')
      })
        .width('40%')

      // Value
      ThemedText({
        content: value,
        maxLines: 2,
        fontColor: $r('app.color.text_primary')
      })
        .layoutWeight(1)
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
