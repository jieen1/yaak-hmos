---
inclusion: always
---

# ArkTS Strict Rules - Critical Coding Guidelines

## Overview
ArkTS is a strict subset of TypeScript with additional constraints. This document outlines critical rules that MUST be followed to avoid compilation errors.

## 🚫 Absolutely Forbidden

### 1. Object Literals (arkts-no-untyped-obj-literals)
**NEVER use inline object literals without explicit type declarations.**

❌ **WRONG:**
```typescript
const options = items.map(item => ({ value: item.name }));
Select(options.map(opt => ({ value: opt.label })));
```

✅ **CORRECT:**
```typescript
interface SelectOption {
  label: string;
  value: string;
}

private buildOptions(): SelectOption[] {
  const result: SelectOption[] = [];
  this.items.forEach((item: Item) => {
    const option: SelectOption = {
      label: item.name,
      value: item.id
    };
    result.push(option);
  });
  return result;
}
```

### 2. Any and Unknown Types
**NEVER use `any` or `unknown` types.**

❌ **WRONG:**
```typescript
let data: any = getData();
let value: unknown = getValue();
const parsed = JSON.parse(jsonString);  // Returns any
```

✅ **CORRECT:**
```typescript
interface DataType {
  id: string;
  name: string;
}

let data: DataType = getData();
let value: string | number = getValue();

// For JSON.parse, use ESObject type cast
const parsed: ESObject = JSON.parse(jsonString) as ESObject;
```

**Special Case - JSON.parse:**
`JSON.parse()` returns `any` type. Always cast to `ESObject` or a specific interface:
```typescript
// Generic object
const obj: ESObject = JSON.parse(jsonStr) as ESObject;

// Specific interface (if structure is known)
interface User {
  id: string;
  name: string;
}
const user: User = JSON.parse(jsonStr) as User;
```

### 3. Callback Context Loss with @BuilderParam
**NEVER pass callbacks through @BuilderParam - they lose their context.**

This is a critical issue that causes runtime crashes with "undefined is not callable" errors.

❌ **WRONG:**
```typescript
// Parent Component
@ComponentV2
struct Parent {
  @Builder
  buildContent() {
    ChildComponent({
      onAction: this.handleAction  // Context lost!
    })
  }

  handleAction = (): void => {
    this.doSomething();
  }

  build() {
    WrapperComponent({
      content: this.buildContent  // Callbacks in builder lose context
    })
  }
}

// Wrapper Component
@ComponentV2
struct WrapperComponent {
  @BuilderParam content: () => void;
  
  build() {
    Column() {
      this.content();  // Callbacks passed through here lose context
    }
  }
}
```

✅ **CORRECT - Inline the logic instead:**
```typescript
@ComponentV2
struct Parent {
  @Local width: number = 250;

  handleAction = (): void => {
    this.doSomething();
  }

  build() {
    Row() {
      // Inline the wrapper logic directly
      Column() {
        ChildComponent({
          onAction: this.handleAction  // Context preserved!
        })
      }
      .width(this.width)
      
      // Add resize handle or other wrapper features inline
      Column() {
        // Resize handle
      }
      .gesture(/* ... */)
    }
  }
}
```

**Why this happens:**
- When you pass a `@Builder` method to a component via `@BuilderParam`, the builder is executed in a different context
- Any callbacks passed to child components within that builder lose their `this` binding
- This causes runtime errors when the callback tries to access `this.method()` or `this.property`

**Solution:**
- Avoid using `@BuilderParam` for content that contains callbacks
- Inline the wrapper logic directly in the parent component
- Use arrow function properties (`handleAction = () => {}`) for callbacks to preserve context

### 4. Property Name Conflicts
**NEVER use property names that conflict with built-in component attributes.**

❌ **WRONG:**
```typescript
@ComponentV2
export struct MyComponent {
  @Param onClick: () => void = () => {};  // Conflicts with built-in onClick
  @Param size: string = 'md';             // Conflicts with built-in size
  @Param type: string = 'primary';        // Conflicts with built-in type
}
```

✅ **CORRECT:**
```typescript
@ComponentV2
export struct MyComponent {
  @Param onButtonClick: () => void = () => {};
  @Param buttonSize: string = 'md';
  @Param buttonType: string = 'primary';
}
```

### 5. Component Attribute Limitations
**Check component documentation for supported attributes. Not all attributes work on all components.**

❌ **WRONG:**
```typescript
Select(options)
  .fontSize($r('app.float.font_size_md'))  // Select doesn't support fontSize
```

✅ **CORRECT:**
```typescript
Select(options)
  .height($r('app.float.input_height_md'))  // Use supported attributes only
```

## ✅ Best Practices

### 1. Always Declare Interfaces
```typescript
// Define interfaces for all data structures
interface User {
  id: string;
  name: string;
  email: string;
}

// Use interfaces in function signatures
function processUser(user: User): void {
  // ...
}
```

### 2. Explicit Type Annotations
```typescript
// Always annotate array types
const users: User[] = [];

// Always annotate function return types
function getUser(id: string): User | null {
  // ...
}

// Always annotate variable types when not obvious
const count: number = 0;
const isActive: boolean = true;
```

### 3. Avoid Arrow Functions in Maps
```typescript
// Instead of inline arrow functions with object literals
❌ items.map(item => ({ id: item.id, name: item.name }))

// Use explicit helper methods
✅ this.buildItemList(items)

private buildItemList(items: Item[]): ItemData[] {
  const result: ItemData[] = [];
  items.forEach((item: Item) => {
    const data: ItemData = {
      id: item.id,
      name: item.name
    };
    result.push(data);
  });
  return result;
}
```

### 4. Component Property Naming Convention
```typescript
// Use descriptive prefixes to avoid conflicts
@ComponentV2
export struct ThemedButton {
  @Param buttonText: string = '';
  @Param onButtonClick: () => void = () => {};
  @Param buttonType: 'primary' | 'secondary' = 'primary';
  @Param buttonSize: 'sm' | 'md' | 'lg' = 'md';
  @Param isDisabled: boolean = false;
}
```

## 🔍 Common Pitfalls

### 1. Callback Parameters
```typescript
// ❌ WRONG: Using 'onChange' conflicts with built-in
@Param onChange: (value: string) => void = () => {};

// ✅ CORRECT: Use descriptive name
@Param onValueChange: (value: string) => void = () => {};
```

### 2. Generic Type Parameters
```typescript
// ❌ WRONG: Untyped generic
function process<T>(data: T): T {
  return data;
}

// ✅ CORRECT: Constrained generic
interface BaseData {
  id: string;
}

function process<T extends BaseData>(data: T): T {
  return data;
}
```

### 3. Array Operations
```typescript
// ❌ WRONG: Inline object creation
const mapped = array.map(x => ({ value: x }));

// ✅ CORRECT: Explicit type and method
interface MappedItem {
  value: string;
}

private mapArray(array: string[]): MappedItem[] {
  const result: MappedItem[] = [];
  array.forEach((item: string) => {
    const mapped: MappedItem = { value: item };
    result.push(mapped);
  });
  return result;
}
```

## 📋 Checklist Before Committing

- [ ] No `any` or `unknown` types used
- [ ] No inline object literals without explicit types
- [ ] All interfaces properly declared
- [ ] All function return types explicitly annotated
- [ ] No property name conflicts with built-in attributes
- [ ] All component attributes verified against documentation
- [ ] All array operations use explicit types
- [ ] All callback parameters have descriptive names
- [ ] No callbacks passed through @BuilderParam (inline wrapper logic instead)

## 🛠️ Quick Fixes

### Converting Object Literals
```typescript
// Before
const items = data.map(d => ({ id: d.id, name: d.name }));

// After
interface Item {
  id: string;
  name: string;
}

private convertData(data: DataType[]): Item[] {
  const items: Item[] = [];
  data.forEach((d: DataType) => {
    const item: Item = {
      id: d.id,
      name: d.name
    };
    items.push(item);
  });
  return items;
}
```

### Fixing Property Conflicts
```typescript
// Before
@Param onClick: () => void;
@Param size: string;

// After
@Param onButtonClick: () => void;
@Param buttonSize: string;
```

### Fixing Callback Context Loss
```typescript
// Before (CRASHES at runtime)
@ComponentV2
struct Parent {
  @Builder
  buildSidebar() {
    SidebarComponent({
      onCreate: this.handleCreate  // Context lost through @BuilderParam!
    })
  }

  handleCreate = (): void => {
    this.createItem();
  }

  build() {
    ResizablePane({
      content: this.buildSidebar  // @BuilderParam loses callback context
    })
  }
}

// After (WORKS correctly)
@ComponentV2
struct Parent {
  @Local paneWidth: number = 250;

  handleCreate = (): void => {
    this.createItem();
  }

  build() {
    Row() {
      // Inline the resizable pane logic
      Column() {
        SidebarComponent({
          onCreate: this.handleCreate  // Context preserved!
        })
      }
      .width(this.paneWidth)
      
      // Resize handle
      Column()
        .width(8)
        .gesture(
          PanGesture()
            .onActionUpdate((event: GestureEvent) => {
              this.paneWidth = /* calculate new width */;
            })
        )
    }
  }
}
```

## 📚 References

- ArkTS Official Documentation: https://developer.harmonyos.com/cn/docs/documentation/doc-guides-V3/arkts-get-started-0000001504769321-V3
- Component Attribute Reference: Check HarmonyOS API documentation for each component
- State Management V2: Use @ObservedV2, @Trace, @ComponentV2, @Local, @Param

## 🎯 Remember

**When in doubt, be explicit!** ArkTS favors verbosity and type safety over brevity. Always declare types, interfaces, and use helper methods instead of inline operations.


### 6. @Builder Method Calls
**NEVER call @Builder methods directly inside another @Builder method.**

This causes "Only UI component syntax can be written here" compilation errors.

❌ **WRONG:**
```typescript
@Builder
buildBodyTab() {
  Column() {
    if (!this.data) {
      this.buildEmptyState();  // ERROR: Direct @Builder call
    } else {
      this.buildContent();     // ERROR: Direct @Builder call
    }
  }
}

@Builder
buildEmptyState() {
  Text('Empty')
}
```

✅ **CORRECT - Wrap in UI containers:**
```typescript
@Builder
buildBodyTab() {
  Column() {
    this.buildContentViewer();  // Call @Builder that returns proper UI
  }
}

@Builder
buildContentViewer() {
  if (!this.data) {
    Column() {
      Text('Empty')
    }
    .width('100%')
    .layoutWeight(1)
  } else {
    Column() {
      MyComponent({ data: this.data })
    }
    .width('100%')
    .layoutWeight(1)
  }
}
```

**Alternative - Use helper methods for logic:**
```typescript
@Builder
buildBodyTab() {
  Column() {
    if (this.shouldShowEmpty()) {
      Column() {
        Text('Empty')
      }
    } else {
      Column() {
        MyComponent({ data: this.data })
      }
    }
  }
}

private shouldShowEmpty(): boolean {
  return !this.data;
}
```

### 7. Map Initialization with Object Literals
**NEVER use array literals with object literals in Map constructor.**

❌ **WRONG:**
```typescript
private static readonly MAP: Map<string, Info> = new Map([
  ['key1', { category: 'text', language: 'json' }],  // ERROR
  ['key2', { category: 'image', language: 'none' }]  // ERROR
]);
```

✅ **CORRECT - Use initialization method:**
```typescript
private static readonly MAP: Map<string, Info> = ContentTypeDetector.initMap();

private static initMap(): Map<string, Info> {
  const map: Map<string, Info> = new Map();
  
  const info1: Info = { category: 'text', language: 'json' };
  map.set('key1', info1);
  
  const info2: Info = { category: 'image', language: 'none' };
  map.set('key2', info2);
  
  return map;
}
```

**Rules:**
- Create a separate static initialization method
- Each object must be explicitly typed and assigned to a variable
- Use `map.set()` to add entries one by one

### 8. Type Imports in Decorated Signatures
**Use `import type` for types used only in decorated signatures.**

❌ **WRONG:**
```typescript
import { ContextMenuItem, MenuPosition } from './ContextMenu';

@ComponentV2
export struct RequestItem {
  @Param menuPosition: MenuPosition = { x: 0, y: 0 };  // ERROR
}
```

✅ **CORRECT:**
```typescript
import { ContextMenu } from './ContextMenu';
import type { ContextMenuItem, MenuPosition } from './ContextMenu';

@ComponentV2
export struct RequestItem {
  @Param menuPosition: MenuPosition = { x: 0, y: 0 };  // OK
}
```

**Rule:** When `isolatedModules` and `emitDecoratorMetadata` are enabled, types referenced in decorated signatures (@Param, @Local, etc.) must be imported with `import type`.

## 📋 Complete Checklist

Before committing code, verify:

- [ ] No `any` or `unknown` types used
- [ ] No inline object literals without explicit types
- [ ] All interfaces properly declared
- [ ] All function return types explicitly annotated
- [ ] No property name conflicts with built-in attributes
- [ ] All component attributes verified against documentation
- [ ] All array operations use explicit types
- [ ] All callback parameters have descriptive names
- [ ] No callbacks passed through @BuilderParam
- [ ] No direct @Builder method calls inside @Builder methods
- [ ] Map initialization uses helper method, not array literals
- [ ] Type imports use `import type` for decorated signatures
- [ ] All object literals in @Param have explicit interface types

## 🎯 Summary

**When in doubt, be explicit!** ArkTS favors verbosity and type safety over brevity. Always:
1. Declare interfaces for all object shapes
2. Use helper methods for complex initialization
3. Wrap UI components properly in @Builder methods
4. Import types correctly for decorated properties
5. Avoid inline operations - create explicit helper methods instead
