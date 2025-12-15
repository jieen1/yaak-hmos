import { ThemeColors, ThemeManager } from '../../theme/Theme';
import { EnvironmentRepository } from '../../database/EnvironmentRepository';
import { Environment } from '../../model/Environment';
import { UUID } from '../../common/UUID';

@CustomDialog
@Component
export struct CreateEnvironmentDialog {
  controller: CustomDialogController;
  workspaceId: string = '';
  onCreate: () => void = () => {};
  
  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;
  @State envName: string = '';

  build() {
    Column() {
      Text("Create Environment")
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.theme.text)
        .margin({ bottom: 20 })

      Text("Name")
        .fontSize(14)
        .fontColor(this.theme.textSecondary)
        .width('100%')
        .margin({ bottom: 5 })

      TextInput({ placeholder: 'Production', text: this.envName })
        .onChange((value: string) => {
          this.envName = value;
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
            if (this.envName.trim() === '') return;
            
            const env = new Environment();
            env.id = UUID.randomUUID();
            env.workspace_id = this.workspaceId;
            env.name = this.envName;
            env.variables = '[]';
            env.created_at = Date.now();
            env.updated_at = Date.now();
            
            await EnvironmentRepository.createEnvironment(env);
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

