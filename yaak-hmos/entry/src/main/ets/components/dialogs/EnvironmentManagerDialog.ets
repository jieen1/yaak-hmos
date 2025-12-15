import { EnvironmentRepository } from '../../database/EnvironmentRepository';
import { Environment } from '../../model/Environment';
import { ThemeColors, ThemeManager } from '../../theme/Theme';
import { KeyValueTable } from '../KeyValueTable';
import { CreateEnvironmentDialog } from './CreateEnvironmentDialog';

@CustomDialog
@Component
export struct EnvironmentManagerDialog {

  controller: CustomDialogController;
  @State workspaceId: string = '';
  @State onUpdate: () => void = () => {}; // Callback when envs change
  environments: Environment[] = [];
  selectedEnv: Environment | null = null;
  @StorageLink('currentTheme') theme: ThemeColors = ThemeManager.getInstance().currentTheme;


  async aboutToAppear() {
    this.loadEnvironments();
  }

  async loadEnvironments() {
    this.environments = await EnvironmentRepository.getEnvironmentsByWorkspaceId(this.workspaceId);
    if (this.environments.length > 0 && !this.selectedEnv) {
      this.selectedEnv = this.environments[0];
    }
    // Update active selection reference if it was updated
    if (this.selectedEnv) {
      const found = this.environments.find(e => e.id === this.selectedEnv?.id);
      if (found) this.selectedEnv = found;
    }
  }

  createDialogController: CustomDialogController = new CustomDialogController({
    builder: CreateEnvironmentDialog({
      workspaceId: this.workspaceId,
      onCreate: () => {
        this.loadEnvironments();
        this.onUpdate();
      }
    }),
    alignment: DialogAlignment.Center,
    autoCancel: true,
    customStyle: true
  });

  build() {
    Column() {
      // Header
      Row() {
        Text("Manage Environments")
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.theme.text)
        
        Blank()
        
        Button("Close")
           .onClick(() => {
             this.onUpdate(); // Ensure sync on close
           })
           .backgroundColor(Color.Transparent)
           .fontColor(this.theme.textSecondary)
      }
      .width('100%')
      .padding({ bottom: 10 })
      .border({ width: { bottom: 1 }, color: this.theme.border })
      
      // Body
      Row() {
        // Sidebar (List)
        Column() {
          List() {
             ForEach(this.environments, (env: Environment) => {
               ListItem() {
                 Row() {
                   Text(env.name)
                     .fontSize(14)
                     .fontColor(this.selectedEnv?.id === env.id ? this.theme.primary : this.theme.text)
                     .fontWeight(this.selectedEnv?.id === env.id ? FontWeight.Bold : FontWeight.Normal)
                 }
                 .width('100%')
                 .padding(10)
                 .backgroundColor(this.selectedEnv?.id === env.id ? this.theme.surfaceHighlight : Color.Transparent)
                 .onClick(() => {
                   this.selectedEnv = env;
                 })
               }
             })
          }
          .layoutWeight(1)
          .width('100%')
          
          Button("+ New Environment")
            .onClick(() => {
               this.createDialogController.open();
            })
            .width('100%')
            .backgroundColor(Color.Transparent)
            .fontColor(this.theme.primary)
            .margin({ top: 5 })
        }
        .width('30%')
        .height('100%')
        .border({ width: { right: 1 }, color: this.theme.border })
        
        // Editor
        Column() {
          if (this.selectedEnv) {
            Text("Name")
              .fontSize(12)
              .fontColor(this.theme.textSecondary)
              .width('100%')
              .margin({ top: 10, bottom: 5 })
              
            TextInput({ text: this.selectedEnv.name })
              .onChange(async (value: string) => {
                if (this.selectedEnv) {
                  this.selectedEnv.name = value;
                  // Persist immediately or on blur? 
                  // For simplicity, persist immediately but debounce in real app
                  this.selectedEnv.updated_at = Date.now();
                  await EnvironmentRepository.updateEnvironment(this.selectedEnv);
                  
                  // Update local list visual
                  const index = this.environments.findIndex(e => e.id === this.selectedEnv?.id);
                  if (index !== -1) {
                    this.environments[index].name = value;
                  }
                  this.onUpdate();
                }
              })
              .backgroundColor(this.theme.inputBackground)
              .fontColor(this.theme.text)
              .height(35)
              .border({ width: 1, color: this.theme.border, radius: 4 })
              
            Text("Variables")
              .fontSize(12)
              .fontColor(this.theme.textSecondary)
              .width('100%')
              .margin({ top: 15, bottom: 5 })
              
            // V2 Component in V1:
            KeyValueTable({
              data: this.selectedEnv.variables,
              $data: async (val: string) => {
                if (this.selectedEnv) {
                   this.selectedEnv.variables = val;
                   this.selectedEnv.updated_at = Date.now();
                   await EnvironmentRepository.updateEnvironment(this.selectedEnv);
                   this.onUpdate();
                }
              }
            })
            .layoutWeight(1)
            
            Button("Delete Environment")
              .onClick(async () => {
                if (this.selectedEnv) {
                  await EnvironmentRepository.deleteEnvironment(this.selectedEnv.id);
                  this.selectedEnv = null;
                  this.loadEnvironments();
                  this.onUpdate();
                }
              })
              .backgroundColor(Color.Transparent)
              .fontColor(this.theme.danger)
              .margin({ top: 10 })
          } else {
             Text("Select an environment").fontColor(this.theme.textSecondary).margin({ top: 50 })
          }
        }
        .layoutWeight(1)
        .height('100%')
        .padding({ left: 10 })
      }
      .layoutWeight(1)
      .width('100%')
      .alignItems(VerticalAlign.Top)
    }
    .backgroundColor(this.theme.background)
    .padding(20)
    .borderRadius(10)
    .width('90%')
    .height('80%')
  }
}

