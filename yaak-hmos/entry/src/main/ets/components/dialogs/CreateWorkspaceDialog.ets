import { ThemeColors, ThemeManager } from '../../theme/Theme';
import { WorkspaceRepository } from '../../database/WorkspaceRepository';
import { Workspace } from '../../model/Workspace';
import { UUID } from '../../common/UUID';

@CustomDialog
@Component
export struct CreateWorkspaceDialog {
  controller: CustomDialogController;
  onCreate: () => void = () => {};
  
  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  @State workspaceName: string = '';

  build() {
    Column() {
      Text("Create Workspace")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 20 })

      Text("Name")
        .fontSize(14)
        .fontColor(this.theme.textSecondary)
        .width('100%')
        .margin({ bottom: 5 })

      TextInput({ placeholder: 'My Workspace', text: this.workspaceName })
        .onChange((value: string) => {
          this.workspaceName = value;
        })
        .height(40)
        .width('100%')
        .backgroundColor(this.theme.inputBackground)
        .fontColor(this.theme.text)
        .border({ width: 1, color: this.theme.border, radius: 4 })
        .margin({ bottom: 20 })

      Row() {
        Button("Cancel")
          .onClick(() => {
            this.controller.close();
          })
          .backgroundColor(Color.Transparent)
          .fontColor(this.theme.textSecondary)
          .margin({ right: 10 })
        
        Button("Create")
          .onClick(async () => {
            if (this.workspaceName.trim() === '') return;
            
            const ws = new Workspace();
            ws.id = UUID.randomUUID();
            ws.name = this.workspaceName;
            ws.created_at = Date.now();
            ws.updated_at = Date.now();
            
            await WorkspaceRepository.createWorkspace(ws);
            this.onCreate();
            this.controller.close();
          })
          .backgroundColor(this.theme.primary)
          .fontColor(Color.White)
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
    }
    .backgroundColor(this.theme.background)
    .padding(20)
    .borderRadius(10)
    .width('80%')
  }
}

