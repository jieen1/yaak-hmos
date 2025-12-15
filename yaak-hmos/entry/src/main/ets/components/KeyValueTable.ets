import { HeaderItem } from '../model/Types';

@ComponentV2
export struct KeyValueTable {
  @Param @Require data: string; // JSON string of Array<HeaderItem>
  @Event $data: (val: string) => void;
  @Param placeholderKey: string = 'Name';
  @Param placeholderValue: string = 'Value';
  
  @Local items: Array<HeaderItem> = [];

  aboutToAppear() {
    this.parseData();
  }
  
  @Monitor('data')
  onDataChange() {
    this.parseData();
  }

  parseData() {
    try {
      let parsed = JSON.parse(this.data) as Array<HeaderItem>;
      if (!Array.isArray(parsed)) throw new Error("Not array");
      
      this.items = parsed.map((p: HeaderItem) => {
        let item = new HeaderItem();
        item.name = p.name;
        item.value = p.value;
        item.enabled = p.enabled;
        return item;
      });
    } catch (e) {
      this.items = [];
    }
    // Ensure at least one empty row
    this.ensureEmptyRow();
  }

  ensureEmptyRow() {
    if (this.items.length === 0 || (this.items[this.items.length - 1].name !== '' || this.items[this.items.length - 1].value !== '')) {
      let newItem = new HeaderItem();
      this.items.push(newItem);
    }
  }

  updateData() {
    // Filter out completely empty rows (except if it's the only one, but we handle that in parse)
    // Actually, we usually save all valid rows. The last empty row is transient for UI.
    const validItems = this.items.filter(i => i.name !== '' || i.value !== '');
    this.$data(JSON.stringify(validItems));
  }

  build() {
    Column() {
      List() {
        ForEach(this.items, (item: HeaderItem, index: number) => {
          ListItem() {
            Row() {
              Checkbox()
                .select(item.enabled)
                .onChange((value: boolean) => {
                  this.items[index].enabled = value;
                  this.updateData();
                })
                .width(20)
                .height(20)
                .margin({ right: 5 })

              TextInput({ text: item.name, placeholder: this.placeholderKey })
                .layoutWeight(1)
                .height(35)
                .fontSize(14)
                .onChange((value: string) => {
                  this.items[index].name = value;
                  this.ensureEmptyRow();
                  this.updateData();
                })
                .margin({ right: 5 })
                .backgroundColor(Color.Transparent)
                .border({ width: { bottom: 1 }, color: '#e0e0e0' })

              TextInput({ text: item.value, placeholder: this.placeholderValue })
                .layoutWeight(1)
                .height(35)
                .fontSize(14)
                .onChange((value: string) => {
                  this.items[index].value = value;
                  this.ensureEmptyRow();
                  this.updateData();
                })
                .margin({ right: 5 })
                .backgroundColor(Color.Transparent)
                .border({ width: { bottom: 1 }, color: '#e0e0e0' })

              if (index < this.items.length - 1) {
                Button("X")
                   .onClick(() => {
                     this.items.splice(index, 1);
                     this.updateData();
                   })
                   .width(25)
                   .height(25)
                   .fontSize(10)
                   .backgroundColor('#ff4444')
                   .fontColor(Color.White)
                   .margin({ left: 5 })
              } else {
                 Blank().width(30)
              }
            }
            .width('100%')
            .padding({ top: 2, bottom: 2 })
          }
        })
      }
      .width('100%')
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
  }
}
