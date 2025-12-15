import { ConfigurationConstant } from '@kit.AbilityKit';

export interface ThemeColors {
  background: string;
  surface: string;
  surfaceHighlight: string;
  text: string;
  textSecondary: string;
  primary: string;
  secondary: string;
  border: string;
  success: string;
  warning: string;
  danger: string;
  headerBackground: string;
  sidebarBackground: string;
  inputBackground: string;
}

export const DarkTheme: ThemeColors = {
  background: '#111111',
  surface: '#1E1E1E',
  surfaceHighlight: '#2B2B2B',
  text: '#FFFFFF',
  textSecondary: '#AAAAAA',
  primary: '#3B82F6', // Blue 500
  secondary: '#6B7280', // Gray 500
  border: '#333333',
  success: '#10B981', // Emerald 500
  warning: '#F59E0B', // Amber 500
  danger: '#EF4444', // Red 500
  headerBackground: '#181818',
  sidebarBackground: '#181818',
  inputBackground: '#252525'
};

export const LightTheme: ThemeColors = {
  background: '#FFFFFF',
  surface: '#F3F4F6', // Gray 100
  surfaceHighlight: '#E5E7EB', // Gray 200
  text: '#111827', // Gray 900
  textSecondary: '#4B5563', // Gray 600
  primary: '#2563EB', // Blue 600
  secondary: '#9CA3AF', // Gray 400
  border: '#E5E7EB',
  success: '#059669', // Emerald 600
  warning: '#D97706', // Amber 600
  danger: '#DC2626', // Red 600
  headerBackground: '#F9FAFB', // Gray 50
  sidebarBackground: '#F9FAFB',
  inputBackground: '#FFFFFF'
};

@ObservedV2
export class ThemeManager {
  @Trace currentTheme: ThemeColors = DarkTheme;
  @Trace isDark: boolean = true;
  @Trace followSystem: boolean = true;

  private static instance: ThemeManager;

  static getInstance(): ThemeManager {
    if (!ThemeManager.instance) {
      ThemeManager.instance = new ThemeManager();
    }
    return ThemeManager.instance;
  }

  setSystemColorMode(mode: ConfigurationConstant.ColorMode) {
    if (this.followSystem) {
      if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
        this.setTheme(true);
      } else {
        this.setTheme(false);
      }
    }
  }

  setTheme(isDark: boolean) {
    this.isDark = isDark;
    this.currentTheme = isDark ? DarkTheme : LightTheme;
    // Sync to AppStorage for V1 components compatibility
    AppStorage.setOrCreate('isDark', this.isDark);
    AppStorage.setOrCreate('currentTheme', this.currentTheme);
  }

  toggleTheme() {
    this.followSystem = false; // Manual override disables system follow
    this.setTheme(!this.isDark);
  }
  
  toggleSystemFollow(follow: boolean) {
     this.followSystem = follow;
     // If re-enabling system follow, we might need to query system capability, 
     // but for now we wait for next update or just leave it.
  }
}
