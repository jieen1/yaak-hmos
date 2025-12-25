@ObservedV2
export class BaseModel {
  @Trace id: string = '';
  @Trace model: string = '';
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
}
