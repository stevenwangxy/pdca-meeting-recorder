// components/PriorityBadge.ets
// 优先级徽章。

@Component
export struct PriorityBadge {
  @Prop label: string;
  @Prop color: string;

  build() {
    Text(this.label)
      .fontSize(11)
      .fontColor('#FFFFFF')
      .backgroundColor(this.color)
      .padding({ left: 6, right: 6, top: 1, bottom: 1 })
      .borderRadius(3)
  }
}
