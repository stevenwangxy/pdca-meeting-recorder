// pages/HomePage.ets
// 主页：会议列表 + 状态筛选 + 新建/设置入口。

import { router } from '@kit.ArkUI';
import { Meeting, MeetingStatus } from '../data/types';
import { ROUTE_MEETING_EDIT, ROUTE_MEETING_DETAIL, ROUTE_SETTINGS } from '../common/Constants';
import { listMeetings } from '../data/MeetingRepo';
import { listAllActionItems } from '../data/ActionItemRepo';
import { MeetingCard } from '../components/MeetingCard';
import { EmptyState } from '../components/EmptyState';

@Entry
@Component
struct HomePage {
  @State meetings: Meeting[] = [];
  @State actionItemMap: Map<string, number> = new Map();
  @State filter: string = 'all';
  @State loading: boolean = true;

  aboutToAppear(): void {
    this.load();
  }

  async load(): Promise<void> {
    this.loading = true;
    try {
      const filterParam = this.filter === 'all' ? undefined : { status: this.filter as MeetingStatus };
      this.meetings = await listMeetings(filterParam);
      const allItems = await listAllActionItems();
      const map = new Map<string, number>();
      for (const m of this.meetings) {
        map.set(m.id, 0);
      }
      for (const a of allItems) {
        if (a.status !== 'completed') {
          map.set(a.meetingId, (map.get(a.meetingId) || 0) + 1);
        }
      }
      this.actionItemMap = map;
    } finally {
      this.loading = false;
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        Text($r('app.string.home_title'))
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
        Text('⚙️')
          .fontSize(20)
          .padding(8)
          .onClick(() => {
            router.pushUrl({ url: ROUTE_SETTINGS });
          })
      }
      .width('100%')
      .padding(16)

      // 筛选
      Row({ space: 8 }) {
        ForEach([
          { key: 'all', label: $r('app.string.home_filter_all') },
          { key: 'in_progress', label: $r('app.string.home_filter_in_progress') },
          { key: 'completed', label: $r('app.string.home_filter_completed') }
        ], (item: { key: string; label: any }) => {
          Text(item.label)
            .fontSize(13)
            .fontColor(this.filter === item.key ? '#FFFFFF' : '#333333')
            .backgroundColor(this.filter === item.key ? '#5B7FFF' : '#F0F0F0')
            .padding({ left: 12, right: 12, top: 6, bottom: 6 })
            .borderRadius(16)
            .onClick(() => {
              this.filter = item.key;
              this.load();
            })
        })
      }
      .width('100%')
      .padding({ left: 16, right: 16, bottom: 8 })

      // 列表或空状态
      if (this.loading) {
        Column() {
          Text('加载中...')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.meetings.length === 0) {
        EmptyState({
          title: $r('app.string.home_empty_title'),
          subtitle: $r('app.string.home_empty_subtitle')
        })
        .layoutWeight(1)
      } else {
        List({ space: 0 }) {
          ForEach(this.meetings, (m: Meeting) => {
            ListItem() {
              MeetingCard({
                meeting: m,
                actionItemCount: this.actionItemMap.get(m.id) || 0
              })
            }
            .onClick(() => {
              router.pushUrl({ url: ROUTE_MEETING_DETAIL, params: { id: m.id } });
            })
          })
        }
        .layoutWeight(1)
        .padding({ left: 16, right: 16 })
      }

      // FAB
      Row() {
        Text('➕')
          .fontSize(24)
          .fontColor('#FFFFFF')
          .width(56)
          .height(56)
          .borderRadius(28)
          .backgroundColor('#5B7FFF')
          .textAlign(TextAlign.Center)
          .onClick(() => {
            router.pushUrl({ url: ROUTE_MEETING_EDIT });
          })
      }
      .width('100%')
      .justifyContent(FlexAlign.End)
      .padding({ right: 16, bottom: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
}
