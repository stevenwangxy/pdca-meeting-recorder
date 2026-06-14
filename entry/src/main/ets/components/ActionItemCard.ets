// components/ActionItemCard.ets
// 行动项卡片。

import { ActionItem, ACTION_STATUS_LABEL, PRIORITY_LABEL } from '../data/types';
import {
  COLOR_STATUS_PENDING,
  COLOR_STATUS_IN_PROGRESS,
  COLOR_STATUS_COMPLETED,
  COLOR_STATUS_DELAYED,
  COLOR_PRIORITY_HIGH,
  COLOR_PRIORITY_MEDIUM,
  COLOR_PRIORITY_LOW
} from '../common/Constants';
import { StatusBadge } from './StatusBadge';
import { PriorityBadge } from './PriorityBadge';

@Component
export struct ActionItemCard {
  @ObjectLink item: ActionItem;
  onClick: () => void = () => {};

  private getStatusColor(): string {
    switch (this.item.status) {
      case 'pending': return COLOR_STATUS_PENDING;
      case 'in_progress': return COLOR_STATUS_IN_PROGRESS;
      case 'completed': return COLOR_STATUS_COMPLETED;
      case 'delayed': return COLOR_STATUS_DELAYED;
    }
  }

  private getPriorityColor(): string {
    switch (this.item.priority) {
      case 'high': return COLOR_PRIORITY_HIGH;
      case 'medium': return COLOR_PRIORITY_MEDIUM;
      case 'low': return COLOR_PRIORITY_LOW;
    }
  }

  build() {
    Row() {
      Column() {
        Text(this.item.content)
          .fontSize(14)
          .fontColor('#333333')
          .maxLines(2)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Row({ space: 8 }) {
          if (this.item.owner) {
            Text(`👤 ${this.item.owner}`)
              .fontSize(12)
              .fontColor('#666666')
          }
          if (this.item.deadline > 0) {
            Text(`📅 ${new Date(this.item.deadline).toLocaleDateString()}`)
              .fontSize(12)
              .fontColor('#666666')
          }
        }
        .margin({ top: 6 })

        Row({ space: 6 }) {
          StatusBadge({ label: ACTION_STATUS_LABEL[this.item.status], color: this.getStatusColor() })
          PriorityBadge({ label: PRIORITY_LABEL[this.item.priority], color: this.getPriorityColor() })
        }
        .margin({ top: 6 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)

      Text('›')
        .fontSize(20)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding(12)
    .backgroundColor('#FFFFFF')
    .borderRadius(6)
    .margin({ bottom: 6 })
    .onClick(() => this.onClick())
  }
}
