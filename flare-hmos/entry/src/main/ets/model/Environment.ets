/**
 * Environment Model
 * Represents a collection of variables that can be used in requests
 */

@ObservedV2
export class Environment {
  @Trace id: string = '';
  @Trace model: string = 'environment';
  @Trace workspace_id: string = '';
  @Trace created_at: number = 0;
  @Trace updated_at: number = 0;
  @Trace deleted_at: number | null = null;
  @Trace name: string = '';
  @Trace variables: EnvironmentVariable[] = [];
}

@ObservedV2
export class EnvironmentVariable {
  @Trace id: string = '';
  @Trace name: string = '';
  @Trace value: string = '';
  @Trace enabled: boolean = true;
  @Trace is_secret: boolean = false;
}
