// components/MeetingCard.ets
// 主页列表项。

import { Meeting, MEETING_STATUS_LABEL } from '../data/types';
import { COLOR_STATUS_IN_PROGRESS, COLOR_STATUS_COMPLETED } from '../common/Constants';
import { StatusBadge } from './StatusBadge';

@Component
export struct MeetingCard {
  @ObjectLink meeting: Meeting;
  @Prop actionItemCount: number = 0;

  build() {
    Column() {
      Row() {
        Text(this.meeting.title)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .layoutWeight(1)
        StatusBadge({
          label: MEETING_STATUS_LABEL[this.meeting.status],
          color: this.meeting.status === 'completed' ? COLOR_STATUS_COMPLETED : COLOR_STATUS_IN_PROGRESS
        })
      }
      .width('100%')
      .margin({ bottom: 8 })

      Row() {
        Text(new Date(this.meeting.meetingTime).toLocaleString())
          .fontSize(12)
          .fontColor('#999999')
          .layoutWeight(1)
        Text(`${this.actionItemCount} 项待办`)
          .fontSize(12)
          .fontColor('#666666')
      }
      .width('100%')

      if (this.meeting.tags && this.meeting.tags.length > 0) {
        Row({ space: 4 }) {
          ForEach(this.meeting.tags, (tag: string) => {
            Text(`#${tag}`)
              .fontSize(11)
              .fontColor('#5B7FFF')
              .backgroundColor('#EEF2FF')
              .padding({ left: 6, right: 6, top: 1, bottom: 1 })
              .borderRadius(3)
          })
        }
        .margin({ top: 8 })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .margin({ bottom: 8 })
  }
}
