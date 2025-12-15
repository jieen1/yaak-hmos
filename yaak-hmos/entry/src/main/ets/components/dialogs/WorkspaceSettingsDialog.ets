import { ThemeColors, ThemeManager } from '../../theme/Theme';
import { WorkspaceRepository } from '../../database/WorkspaceRepository';
import { Workspace } from '../../model/Workspace';

@CustomDialog
@Component
export struct WorkspaceSettingsDialog {
  controller: CustomDialogController;
  workspace: Workspace | null = null;
  onUpdate: () => void = () => {};
  onDelete: () => void = () => {};

  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  @State workspaceName: string = '';

  aboutToAppear() {
    if (this.workspace) {
      this.workspaceName = this.workspace.name;
    }
  }

  build() {
    Column() {
      Text("Workspace Settings")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 20 })

      Text("Name")
        .fontSize(14)
        .fontColor(this.theme.textSecondary)
        .width('100%')
        .margin({ bottom: 5 })

      TextInput({ text: this.workspaceName })
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
        Button("Delete Workspace")
          .onClick(async () => {
             // TODO: Add confirmation?
             if (this.workspace) {
               await WorkspaceRepository.deleteWorkspace(this.workspace.id);
               this.onDelete();
               this.controller.close();
             }
          })
          .backgroundColor(Color.Transparent)
          .fontColor(this.theme.danger)
          .margin({ right: 'auto' }) // Push to left
        
        Button("Save")
          .onClick(async () => {
            if (this.workspaceName.trim() === '' || !this.workspace) return;
            
            this.workspace.name = this.workspaceName;
            this.workspace.updated_at = Date.now();
            await WorkspaceRepository.updateWorkspace(this.workspace);
            
            this.onUpdate();
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

