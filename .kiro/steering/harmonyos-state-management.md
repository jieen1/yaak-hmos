# HarmonyOS 状态管理与 UI 更新核心要点

## 概述

本文档总结了 HarmonyOS ArkTS 状态管理的核心要点，特别是列表 UI 更新的关键问题和解决方案。

---

## 🚨 核心问题：列表 UI 不刷新

### 问题现象
- 数据已更新（数据库正确）
- 重启应用后显示正确
- 搜索再清除后显示正确
- 但拖拽/修改后 UI 不更新

### 根本原因
HarmonyOS 的 `ForEach` 和 `Repeat` 组件使用 **key** 来决定是否复用组件。如果 key 没变，组件会被复用，即使数据变了也不会重新渲染。

---

## ✅ 解决方案：ForEach + @Monitor + 扁平化列表

### 1. 使用扁平化列表作为核心数据源

```typescript
// ❌ 错误：直接使用嵌套树结构
@Param items: SidebarItem[] = [];  // 嵌套结构，子项变化难以触发更新

// ✅ 正确：使用扁平化列表
@Local flatList: FlatListItem[] = [];  // 扁平结构，整体替换触发更新
```

### 2. 使用 @Monitor 监听数据变化

```typescript
// 监听原始数据变化，自动重建扁平列表
@Monitor('items', 'filterText')
onDataChange(): void {
  this.rebuildFlatList();
}
```

### 3. 重建列表时创建新数组

```typescript
private rebuildFlatList(): void {
  // ✅ 创建新数组，而不是修改原数组
  const newFlatList: FlatListItem[] = [];
  
  this.items.forEach((item: SidebarItem) => {
    this.flattenItem(item, 0, newFlatList);
  });
  
  // ✅ 直接赋值新数组，触发 UI 更新
  this.flatList = newFlatList;
}
```

### 4. ForEach 的 key 必须包含所有影响渲染的属性

```typescript
// ❌ 错误：key 不完整
ForEach(this.flatList, (item) => {
  // ...
}, (item) => item.id)  // 只有 id，level 变化时不会重新渲染

// ❌ 错误：key 缺少 level
ForEach(this.flatList, (item) => {
  // ...
}, (item) => item.id + '_' + item.type + '_' + this.expandedFolders.has(item.id))

// ✅ 正确：key 包含所有影响渲染的属性
ForEach(this.flatList, (item) => {
  // ...
}, (item) => item.id + '_' + item.type + '_' + item.level + '_' + this.expandedFolders.has(item.id))
```

---

## 📋 ForEach Key 设计原则

### Key 必须包含的内容

| 属性 | 说明 | 示例 |
|------|------|------|
| **唯一标识** | 区分不同项目 | `item.id` |
| **类型** | 区分不同类型的渲染 | `item.type` |
| **层级** | 影响缩进等样式 | `item.level` |
| **展开状态** | 影响子项显示 | `expandedFolders.has(item.id)` |
| **其他影响渲染的状态** | 任何会改变 UI 的属性 | `item.isSelected`, `item.isEditing` |

### Key 设计检查清单

- [ ] key 是否包含唯一标识？
- [ ] key 是否包含影响布局的属性（如 level）？
- [ ] key 是否包含影响样式的状态？
- [ ] 当这些属性变化时，key 是否会变化？

---

## 🔄 完整模式示例

```typescript
@ComponentV2
export struct ListComponent {
  @Param items: TreeItem[] = [];  // 原始嵌套数据
  @Local flatList: FlatListItem[] = [];  // 扁平化列表
  @Local expandedFolders: Set<string> = new Set();  // 展开状态

  aboutToAppear(): void {
    this.rebuildFlatList();
  }

  // 监听数据变化
  @Monitor('items')
  onDataChange(): void {
    this.rebuildFlatList();
  }

  // 重建扁平列表
  private rebuildFlatList(): void {
    const newFlatList: FlatListItem[] = [];
    this.items.forEach((item: TreeItem) => {
      this.flattenItem(item, 0, newFlatList);
    });
    this.flatList = newFlatList;
  }

  // 递归扁平化
  private flattenItem(item: TreeItem, level: number, list: FlatListItem[]): void {
    const flatItem: FlatListItem = {
      id: item.id,
      type: item.type,
      data: item,
      level: level
    };
    list.push(flatItem);

    if (item.children && this.expandedFolders.has(item.id)) {
      item.children.forEach((child: TreeItem) => {
        this.flattenItem(child, level + 1, list);
      });
    }
  }

  build() {
    List() {
      // ✅ key 包含所有影响渲染的属性
      ForEach(this.flatList, (flatItem: FlatListItem) => {
        ListItem() {
          ItemComponent({
            data: flatItem.data,
            level: flatItem.level  // 传递 level 用于缩进
          })
        }
      }, (flatItem: FlatListItem) => 
        flatItem.id + '_' + 
        flatItem.type + '_' + 
        flatItem.level + '_' + 
        this.expandedFolders.has(flatItem.id)
      )
    }
  }
}
```

---

## ⚠️ 常见错误

### 1. 修改原数组而不是创建新数组

```typescript
// ❌ 错误：修改原数组
this.flatList.push(newItem);
this.flatList.splice(index, 1);

// ✅ 正确：创建新数组
const newList: FlatListItem[] = [...this.flatList, newItem];
this.flatList = newList;
```

### 2. Key 不包含影响渲染的属性

```typescript
// ❌ 错误：level 变化时 UI 不更新
(item) => item.id

// ✅ 正确：level 变化时 key 变化，UI 更新
(item) => item.id + '_' + item.level
```

### 3. 使用 Repeat 处理复杂嵌套结构

```typescript
// ❌ 错误：Repeat 处理嵌套结构时更新不可靠
Repeat(this.items)
  .each((item) => {
    // 嵌套渲染子项...
  })

// ✅ 正确：先扁平化，再用 ForEach
ForEach(this.flatList, ...)
```

### 4. @Type 装饰器误用

```typescript
// ❌ 错误：@Type 只用于 PersistenceV2，不用于普通状态管理
@Type(SidebarItem)
children: SidebarItem[] = [];

// ✅ 正确：普通数组不需要 @Type
children: SidebarItem[] = [];
```

---

## 📝 总结

1. **扁平化列表** - 将嵌套树结构转换为扁平数组
2. **@Monitor 监听** - 监听原始数据变化，自动重建扁平列表
3. **创建新数组** - 不要修改原数组，而是创建新数组并赋值
4. **完整的 Key** - ForEach 的 key 必须包含所有影响渲染的属性（id、type、level、展开状态等）
5. **ForEach 优于 Repeat** - 对于需要精确控制更新的列表，ForEach 更可靠
