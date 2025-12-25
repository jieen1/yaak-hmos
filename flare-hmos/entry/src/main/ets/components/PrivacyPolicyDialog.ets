/**
 * Privacy Policy Dialog Component
 * Shows privacy policy and gets user consent before enabling cloud sync
 */

import { ThemedButton } from './ThemedButton';

@ComponentV2
export struct PrivacyPolicyDialog {
  @Param isVisible: boolean = false;
  @Param onAccept: () => void = () => {};
  @Param onDecline: () => void = () => {};

  build() {
    if (this.isVisible) {
      Stack() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('rgba(0, 0, 0, 0.5)')

        // Dialog Content
        Column() {
          // Header
          Text('隐私政策')
            .fontSize($r('app.float.font_size_xl'))
            .fontColor($r('app.color.text_primary'))
            .fontWeight(FontWeight.Bold)
            .width('100%')
            .textAlign(TextAlign.Center)
            .margin({ bottom: $r('app.float.spacing_lg') })

          // Policy content
          Scroll() {
            Column() {
              Text('在启用云同步功能之前，请阅读并同意以下隐私政策：')
                .fontSize($r('app.float.font_size_md'))
                .fontColor($r('app.color.text_primary'))
                .width('100%')
                .margin({ bottom: $r('app.float.spacing_md') })

              this.buildPolicySection('数据收集', 
                '我们将收集您的 API 请求配置数据（包括 URL、请求头、请求体等）用于云端同步。敏感数据（如密码、Token）将在本地加密后再上传。')

              this.buildPolicySection('数据存储',
                '您的数据将存储在华为云服务器上，采用行业标准的加密技术保护。数据仅用于跨设备同步，不会用于其他目的。')

              this.buildPolicySection('数据共享',
                '我们不会将您的数据出售或分享给第三方。只有您本人可以通过华为账号访问您的数据。')

              this.buildPolicySection('数据删除',
                '您可以随时在设置中关闭云同步功能。退出登录后，本地数据将保留，云端数据可通过华为账号管理页面删除。')

              this.buildPolicySection('用户权利',
                '您有权访问、更正或删除您的个人数据。如有任何疑问，请联系我们的客服团队。')
            }
            .width('100%')
            .padding($r('app.float.spacing_md'))
          }
          .layoutWeight(1)
          .width('100%')
          .backgroundColor($r('app.color.surface'))
          .borderRadius($r('app.float.border_radius_md'))
          .margin({ bottom: $r('app.float.spacing_lg') })

          // Buttons
          Row() {
            ThemedButton({
              text: '不同意',
              onButtonClick: () => {
                this.onDecline();
              },
              buttonType: 'secondary',
              buttonSize: 'md'
            })
              .layoutWeight(1)
              .margin({ right: $r('app.float.spacing_sm') })

            ThemedButton({
              text: '同意并继续',
              onButtonClick: () => {
                this.onAccept();
              },
              buttonSize: 'md'
            })
              .layoutWeight(1)
              .margin({ left: $r('app.float.spacing_sm') })
          }
          .width('100%')
        }
        .width('80%')
        .height('70%')
        .padding($r('app.float.spacing_xl'))
        .backgroundColor($r('app.color.background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .shadow({
          radius: 20,
          color: 'rgba(0, 0, 0, 0.3)',
          offsetX: 0,
          offsetY: 4
        })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
      .zIndex(1001)
    }
  }

  @Builder
  buildPolicySection(title: string, content: string) {
    Column() {
      Text(title)
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
        .fontWeight(FontWeight.Medium)
        .width('100%')
        .margin({ bottom: $r('app.float.spacing_xs') })

      Text(content)
        .fontSize($r('app.float.font_size_sm'))
        .fontColor($r('app.color.text_secondary'))
        .width('100%')
        .lineHeight(22)
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_md') })
  }
}
