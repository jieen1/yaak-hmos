/**
 * Sidebar Component
 * Main sidebar with search, action buttons, and tree view
 */

import { SidebarItem } from '../viewmodel/SidebarItem';
import { HttpRequest } from '../model/HttpRequest';
import { FolderItemComponent } from './FolderItemComponent';
import { RequestItemComponent } from './RequestItemComponent';
import { ThemedTextInput } from './ThemedTextInput';
import { ThemedButton } from './ThemedButton';
import { ThemedDivider } from './ThemedDivider';

@ComponentV2
export struct SidebarComponent {
  @Param items: SidebarItem[] = [];
  @Param selectedRequestId: string = '';
  @Param onRequestCreate: () => void = () => {};
  @Param onFolderCreate: () => void = () => {};
  @Param onRequestSelect: (requestId: string) => void = () => {};
  @Param onFolderToggle: (folderId: string) => void = () => {};

  @Local filterText: string = '';
  @Local expandedFolders: Set<string> = new Set();

  build() {
    Column() {
      // Search/Filter input
      ThemedTextInput({
        value: this.filterText,
        placeholder: 'Search requests...',
        onValueChange: (value: string) => {
          this.filterText = value;
        }
      })
        .margin({
          left: $r('app.float.spacing_md'),
          right: $r('app.float.spacing_md'),
          top: $r('app.float.spacing_md'),
          bottom: $r('app.float.spacing_sm')
        })

      // Action buttons
      Row() {
        ThemedButton({
          text: 'New Request',
          onButtonClick: () => {
            this.onRequestCreate();
          },
          buttonSize: 'sm'
        })
          .flexGrow(1)
          .margin({ right: $r('app.float.spacing_xs') })

        ThemedButton({
          text: 'New Folder',
          onButtonClick: () => {
            this.onFolderCreate();
          },
          buttonType: 'secondary',
          buttonSize: 'sm'
        })
          .flexGrow(1)
          .margin({ left: $r('app.float.spacing_xs') })
      }
      .width('100%')
      .padding({
        left: $r('app.float.spacing_md'),
        right: $r('app.float.spacing_md')
      })
      .margin({ bottom: $r('app.float.spacing_sm') })

      ThemedDivider({})

      // Tree view
      List() {
        ForEach(this.getFilteredItems(), (item: SidebarItem) => {
          ListItem() {
            this.buildTreeItem(item)
          }
        }, (item: SidebarItem) => item.getId())
      }
      .width('100%')
      .layoutWeight(1)
      .padding({
        left: $r('app.float.spacing_sm'),
        right: $r('app.float.spacing_sm')
      })
      .scrollBar(BarState.Auto)
    }
    .width('100%')
    .height('100%')
    .backgroundColor($r('app.color.sidebar_background'))
  }

  /**
   * Build tree item (folder or request)
   */
  @Builder
  buildTreeItem(item: SidebarItem) {
    Column() {
      if (item.isFolder()) {
        FolderItemComponent({
          folder: item.getFolder()!,
          level: item.level,
          isExpanded: item.isExpanded,
          onToggle: () => {
            item.toggleExpanded();
            this.onFolderToggle(item.getId());
          },
          onSelect: () => {
            item.toggleExpanded();
          }
        })

        // Show children if expanded
        if (item.isExpanded) {
          ForEach(item.children, (child: SidebarItem) => {
            this.buildTreeItem(child)
          }, (child: SidebarItem) => child.getId())
        }
      } else if (item.isRequest()) {
        RequestItemComponent({
          request: item.getRequest()!,
          level: item.level,
          isSelected: item.getId() === this.selectedRequestId,
          onSelect: () => {
            this.onRequestSelect(item.getId());
          }
        })
      }
    }
    .width('100%')
  }

  /**
   * Get filtered items based on search text
   */
  private getFilteredItems(): SidebarItem[] {
    if (!this.filterText || this.filterText.trim() === '') {
      return this.items;
    }

    const searchText = this.filterText.toLowerCase();
    const filtered: SidebarItem[] = [];

    const filterItem = (item: SidebarItem): boolean => {
      const nameMatch = item.getName().toLowerCase().includes(searchText);
      
      // For requests, also check URL
      if (item.isRequest()) {
        const request = item.getRequest();
        const urlMatch = request ? request.url.toLowerCase().includes(searchText) : false;
        return nameMatch || urlMatch;
      }

      // For folders, check if any children match
      const childrenMatch = item.children.some(child => filterItem(child));
      
      return nameMatch || childrenMatch;
    };

    this.items.forEach(item => {
      if (filterItem(item)) {
        filtered.push(item);
      }
    });

    return filtered;
  }
}
