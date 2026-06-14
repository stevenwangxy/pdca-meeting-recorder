// components/StatusBadge.ets
// 状态徽章：会议状态或行动项状态。

@Component
export struct StatusBadge {
  @Prop label: string;
  @Prop color: string;

  build() {
    Text(this.label)
      .fontSize(12)
      .fontColor('#FFFFFF')
      .backgroundColor(this.color)
      .padding({ left: 8, right: 8, top: 2, bottom: 2 })
      .borderRadius(4)
  }
}
