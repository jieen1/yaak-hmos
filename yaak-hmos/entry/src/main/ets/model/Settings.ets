import { BaseModel } from './BaseModel';

@Observed
export class Settings extends BaseModel {
  theme: string = 'system'; // 'light', 'dark', 'system'
  fontSize: number = 14;
  
  constructor() {
    super();
    this.model = 'settings';
    this.id = 'global_settings';
  }
}

