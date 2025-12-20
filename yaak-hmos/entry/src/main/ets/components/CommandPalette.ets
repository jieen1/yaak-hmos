/**
 * CommandPalette - Quick access modal for commands and navigation
 *
 * Features:
 * - Fuzzy search for commands, requests, workspaces
 * - Keyboard navigation (Up/Down/Enter/Escape)
 * - Grouped results by category
 */

import { CommandService, CommandResult, SearchContext, CommandCategory } from '../services/CommandService';
import { HttpRequest } from '../model/HttpRequest';
import { Workspace } from '../model/Workspace';
import { Environment } from '../model/Environment';

/**
 * Command action types
 */
export type CommandActionType =
  | 'new-request'
  | 'new-folder'
  | 'new-workspace'
  | 'import'
  | 'export'
  | 'settings'
  | 'send-request'
  | 'duplicate-request'
  | 'toggle-sidebar'
  | 'focus-url'
  | 'copy-as-curl'
  | 'toggle-response'
  | 'select-request'
  | 'select-workspace'
  | 'select-environment';

/**
 * Command action payload
 */
export interface CommandAction {
  type: CommandActionType;
  id: string;
}

@ComponentV2
export struct CommandPalette {
  @Param isVisible: boolean = false;
  @Param workspaces: Workspace[] = [];
  @Param requests: HttpRequest[] = [];
  @Param environments: Environment[] = [];
  @Param currentWorkspaceId: string = '';
  @Param onClose: () => void = () => {};
  @Param onAction: (action: CommandAction) => void = () => {};

  @Local query: string = '';
  @Local results: CommandResult[] = [];
  @Local selectedIndex: number = 0;
  @Local isLoading: boolean = false;

  private searchDebounceTimer: number = -1;
  private readonly DEBOUNCE_MS: number = 150;

  @Monitor('isVisible')
  onVisibilityChange(): void {
    if (this.isVisible) {
      this.query = '';
      this.selectedIndex = 0;
      this.performSearch();
    }
  }

  aboutToAppear(): void {
    this.performSearch();
  }

  build() {
    if (this.isVisible) {
      Column() {
        // Backdrop
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#80000000')
          .position({ x: 0, y: 0 })
          .onClick(() => {
            this.handleClose();
          })

        // Palette Container
        Column() {
          // Search Input
          this.buildSearchInput()

          // Results List
          this.buildResultsList()

          // Keyboard Hints
          this.buildKeyboardHints()
        }
        .width('80%')
        .width(600)
        .backgroundColor($r('app.color.button_background'))
        .borderRadius($r('app.float.border_radius_lg'))
        .padding($r('app.float.spacing_md'))
        .position({ x: '10%', y: '10%' })
      }
      .width('100%')
      .height('100%')
      .position({ x: 0, y: 0 })
    }
  }

  @Builder
  buildSearchInput() {
    Row() {
      Text('🔍')
        .fontSize(18)
        .margin({ right: $r('app.float.spacing_sm') })

      TextInput({ text: this.query, placeholder: 'Type a command or search...' })
        .layoutWeight(1)
        .height($r('app.float.input_height_md'))
        .fontSize($r('app.float.font_size_md'))
        .fontColor($r('app.color.text_primary'))
        .backgroundColor($r('app.color.input_background'))
        .borderRadius($r('app.float.border_radius_sm'))
        .onChange((value: string) => {
          this.query = value;
          this.debouncedSearch();
        })
        .onSubmit(() => {
          this.executeSelected();
        })
    }
    .width('100%')
    .margin({ bottom: $r('app.float.spacing_md') })
  }

  @Builder
  buildResultsList() {
    if (this.results.length === 0) {
      Column() {
        Text('No results found')
          .fontSize($r('app.float.font_size_md'))
          .fontColor($r('app.color.text_secondary'))
      }
      .width('100%')
      .height(100)
      .justifyContent(FlexAlign.Center)
    } else {
      Scroll() {
        Column() {
          ForEach(this.results, (result: CommandResult, index: number) => {
            this.buildResultItem(result, index)
          }, (result: CommandResult, index: number) => `${result.type}_${result.id}_${index}`)
        }
        .width('100%')
      }
      .width('100%')
      .height(300)
      .scrollBar(BarState.Auto)
    }
  }

  @Builder
  buildResultItem(result: CommandResult, index: number) {
    Row() {
      // Icon
      Text(result.icon)
        .fontSize(16)
        .width(28)

      // Content
      Column() {
        Text(result.label)
          .fontSize($r('app.float.font_size_sm'))
          .fontColor($r('app.color.text_primary'))
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        if (result.description.length > 0) {
          Text(result.description)
            .fontSize($r('app.float.font_size_xs'))
            .fontColor($r('app.color.text_secondary'))
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
        }
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      // Category Badge
      Text(this.getCategoryLabel(result.type))
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.input_background'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(4)
        .margin({ right: $r('app.float.spacing_sm') })

      // Shortcut Badge
      if (result.shortcut.length > 0) {
        Text(result.shortcut)
          .fontSize($r('app.float.font_size_xs'))
          .fontColor($r('app.color.text_secondary'))
          .backgroundColor($r('app.color.input_background'))
          .padding({ left: 6, right: 6, top: 2, bottom: 2 })
          .borderRadius(4)
      }
    }
    .width('100%')
    .padding($r('app.float.spacing_sm'))
    .backgroundColor(index === this.selectedIndex ? $r('app.color.primary_light') : Color.Transparent)
    .borderRadius($r('app.float.border_radius_sm'))
    .onClick(() => {
      this.selectedIndex = index;
      this.executeSelected();
    })
  }

  @Builder
  buildKeyboardHints() {
    Row() {
      this.buildHintItem('↑↓', 'Navigate')
      this.buildHintItem('Enter', 'Select')
      this.buildHintItem('Esc', 'Close')
    }
    .width('100%')
    .justifyContent(FlexAlign.Center)
    .margin({ top: $r('app.float.spacing_md') })
  }

  @Builder
  buildHintItem(key: string, label: string) {
    Row() {
      Text(key)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .backgroundColor($r('app.color.input_background'))
        .padding({ left: 6, right: 6, top: 2, bottom: 2 })
        .borderRadius(4)

      Text(label)
        .fontSize($r('app.float.font_size_xs'))
        .fontColor($r('app.color.text_secondary'))
        .margin({ left: 4 })
    }
    .margin({ left: $r('app.float.spacing_md'), right: $r('app.float.spacing_md') })
  }

  private getCategoryLabel(category: CommandCategory): string {
    switch (category) {
      case 'action':
        return 'Action';
      case 'request':
        return 'Request';
      case 'workspace':
        return 'Workspace';
      case 'environment':
        return 'Environment';
      case 'navigation':
        return 'Navigation';
      default:
        return '';
    }
  }

  private debouncedSearch(): void {
    if (this.searchDebounceTimer >= 0) {
      clearTimeout(this.searchDebounceTimer);
    }

    this.searchDebounceTimer = setTimeout(() => {
      this.performSearch();
    }, this.DEBOUNCE_MS);
  }

  private performSearch(): void {
    const context: SearchContext = {
      workspaces: this.workspaces,
      requests: this.requests,
      environments: this.environments,
      currentWorkspaceId: this.currentWorkspaceId
    };

    this.results = CommandService.search(this.query, context);
    this.selectedIndex = 0;
  }

  private executeSelected(): void {
    if (this.results.length === 0) {
      return;
    }

    const selected: CommandResult | undefined = this.results[this.selectedIndex];
    if (!selected) {
      return;
    }

    // Determine action type based on result
    let actionType: CommandActionType;

    switch (selected.type) {
      case 'request':
        actionType = 'select-request';
        break;
      case 'workspace':
        actionType = 'select-workspace';
        break;
      case 'environment':
        actionType = 'select-environment';
        break;
      default:
        // Built-in command
        actionType = selected.id as CommandActionType;
        break;
    }

    const action: CommandAction = {
      type: actionType,
      id: selected.id
    };

    this.onAction(action);
    this.handleClose();
  }

  /**
   * Handle keyboard navigation (called from parent)
   */
  handleKeyDown(keyCode: number): boolean {
    // Up arrow
    if (keyCode === 38) {
      if (this.selectedIndex > 0) {
        this.selectedIndex--;
      }
      return true;
    }

    // Down arrow
    if (keyCode === 40) {
      if (this.selectedIndex < this.results.length - 1) {
        this.selectedIndex++;
      }
      return true;
    }

    // Enter
    if (keyCode === 13) {
      this.executeSelected();
      return true;
    }

    // Escape
    if (keyCode === 27) {
      this.handleClose();
      return true;
    }

    return false;
  }

  private handleClose(): void {
    this.query = '';
    this.results = [];
    this.selectedIndex = 0;
    this.onClose();
  }
}
