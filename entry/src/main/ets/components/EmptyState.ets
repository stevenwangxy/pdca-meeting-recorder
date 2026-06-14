// components/EmptyState.ets
// 空状态展示。

@Component
export struct EmptyState {
  @Prop title: string;
  @Prop subtitle: string;
  @BuilderParam action?: CustomBuilder;

  build() {
    Column() {
      Text('📋')
        .fontSize(48)
        .margin({ bottom: 16 })
      Text(this.title)
        .fontSize(16)
        .fontColor('#666666')
        .margin({ bottom: 8 })
      Text(this.subtitle)
        .fontSize(14)
        .fontColor('#999999')
        .margin({ bottom: 16 })
      if (this.action) {
        this.action()
      }
    }
    .width('100%')
    .height('100%')
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .padding(32)
  }
}
