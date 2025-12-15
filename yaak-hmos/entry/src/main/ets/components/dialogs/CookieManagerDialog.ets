import { ThemeColors, ThemeManager } from '../../theme/Theme';
import { Cookie } from '../../model/CookieJar';

@CustomDialog
@Component
export struct CookieManagerDialog {
  controller: CustomDialogController;
  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  
  // Mock data for now, in real app would load from DB
  @State cookies: Cookie[] = [
    { domain: 'example.com', key: 'session', value: '12345', path: '/', expires: 'Session', secure: true, httpOnly: true },
    { domain: 'api.test.com', key: 'auth', value: 'abcdef', path: '/', expires: '2025-12-31', secure: true, httpOnly: false }
  ];

  build() {
    Column() {
      Text("Manage Cookies")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 20 })

      // Header
      Row() {
        Text("Domain").fontSize(14).fontColor(this.theme.textSecondary).width('30%')
        Text("Name").fontSize(14).fontColor(this.theme.textSecondary).width('20%')
        Text("Value").fontSize(14).fontColor(this.theme.textSecondary).width('30%')
        Text("Action").fontSize(14).fontColor(this.theme.textSecondary).width('20%').textAlign(TextAlign.End)
      }
      .width('100%')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: this.theme.border })

      // List
      List() {
        ForEach(this.cookies, (cookie: Cookie, index: number) => {
          ListItem() {
            Row() {
              Text(cookie.domain).fontSize(14).fontColor(this.theme.text).width('30%')
              Text(cookie.key).fontSize(14).fontColor(this.theme.text).width('20%')
              Text(cookie.value).fontSize(14).fontColor(this.theme.textSecondary).width('30%').textOverflow({ overflow: TextOverflow.Ellipsis }).maxLines(1)
              
              Button("Delete")
                .onClick(() => {
                  this.cookies.splice(index, 1);
                })
                .fontSize(12)
                .fontColor(this.theme.danger)
                .backgroundColor(Color.Transparent)
                .width('20%')
            }
            .width('100%')
            .padding({ top: 10, bottom: 10 })
            .border({ width: { bottom: 1 }, color: this.theme.surfaceHighlight })
          }
        })
      }
      .width('100%')
      .height(300)

      Blank().height(20)

      Button("Done")
        .onClick(() => {
          this.controller.close();
        })
        .backgroundColor(this.theme.primary)
        .fontColor(Color.White)
        .width('100%')
    }
    .backgroundColor(this.theme.background)
    .padding(20)
    .borderRadius(10)
    .width('90%')
  }
}

