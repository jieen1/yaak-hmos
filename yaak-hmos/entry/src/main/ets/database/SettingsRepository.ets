import { DatabaseManager } from './DatabaseManager';
import { Settings } from '../model/Settings';
import relationalStore from '@ohos.data.relationalStore';

export class SettingsRepository {
  public static async getSettings(): Promise<Settings> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return new Settings();

    const predicates = new relationalStore.RdbPredicates('settings');
    predicates.equalTo('id', 'global_settings');

    const resultSet = await store.query(predicates);
    if (resultSet.goToFirstRow()) {
      const settings = new Settings();
      settings.id = resultSet.getString(resultSet.getColumnIndex('id'));
      settings.theme = resultSet.getString(resultSet.getColumnIndex('theme'));
      settings.fontSize = resultSet.getDouble(resultSet.getColumnIndex('font_size'));
      resultSet.close();
      return settings;
    }
    
    // Create default if not exists
    const defaultSettings = new Settings();
    await this.createSettings(defaultSettings);
    return defaultSettings;
  }

  public static async createSettings(settings: Settings): Promise<void> {
    const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      id: settings.id,
      model: settings.model,
      theme: settings.theme,
      font_size: settings.fontSize,
      created_at: Date.now(),
      updated_at: Date.now()
    };
    
    // Check if table exists (it should be created in DatabaseManager, we need to add it there)
    await store.insert('settings', valueBucket);
  }
  
  public static async updateSettings(settings: Settings): Promise<void> {
     const store = DatabaseManager.getInstance().getStore();
    if (!store) return;

    const valueBucket: relationalStore.ValuesBucket = {
      theme: settings.theme,
      font_size: settings.fontSize,
      updated_at: Date.now()
    };

    const predicates = new relationalStore.RdbPredicates('settings');
    predicates.equalTo('id', settings.id);

    await store.update(valueBucket, predicates);
  }
}

