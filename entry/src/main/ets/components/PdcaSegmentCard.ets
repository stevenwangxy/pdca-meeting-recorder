// components/PdcaSegmentCard.ets
// PDCA 段展示（详情页 Tab 内容）。

import { PdcaField, PDCA_LABEL } from '../data/types';

@Component
export struct PdcaSegmentCard {
  @Prop field: PdcaField;
  @Prop content: string;
  onAppend: () => void = () => {};

  build() {
    Column() {
      Row() {
        Text(PDCA_LABEL[this.field])
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('+ 追加')
          .fontSize(13)
          .fontColor('#5B7FFF')
          .onClick(() => this.onAppend())
      }
      .width('100%')
      .margin({ bottom: 12 })

      if (this.content) {
        Text(this.content)
          .fontSize(14)
          .fontColor('#333333')
          .lineHeight(22)
          .width('100%')
      } else {
        Text('（暂无内容，点击右上角"追加"开始记录）')
          .fontSize(13)
          .fontColor('#999999')
          .width('100%')
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
  }
}
