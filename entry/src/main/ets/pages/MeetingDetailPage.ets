// pages/MeetingDetailPage.ets
// 会议详情：PDCA 4 段 + 行动项 Tab 切换 + 快速追加。

import { router } from '@kit.ArkUI';
import { Meeting, ActionItem, PdcaField, PDCA_FIELDS, PDCA_LABEL, MEETING_STATUS_LABEL } from '../data/types';
import { getMeeting, updateMeeting, appendPdcaSegment } from '../data/MeetingRepo';
import { listActionItems } from '../data/ActionItemRepo';
import { ROUTE_MEETING_EDIT, ROUTE_ACTION_ITEM_EDIT } from '../common/Constants';
import { COLOR_STATUS_IN_PROGRESS, COLOR_STATUS_COMPLETED } from '../common/Constants';
import { PdcaSegmentCard } from '../components/PdcaSegmentCard';
import { ActionItemCard } from '../components/ActionItemCard';
import { EmptyState } from '../components/EmptyState';
import { StatusBadge } from '../components/StatusBadge';

interface RouteParams {
  id: string;
}

@Entry
@Component
struct MeetingDetailPage {
  @State meeting: Meeting | null = null;
  @State actionItems: ActionItem[] = [];
  @State currentTabIndex: number = 0;
  @State quickAddVisible: boolean = false;
  @State quickAddText: string = '';

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as RouteParams;
    if (params && params.id) {
      this.load(params.id);
    }
  }

  async load(id: string): Promise<void> {
    this.meeting = await getMeeting(id);
    this.actionItems = await listActionItems(id);
  }

  private async toggleStatus(): Promise<void> {
    if (!this.meeting) return;
    const newStatus = this.meeting.status === 'completed' ? 'in_progress' : 'completed';
    const updated: Meeting = { ...this.meeting, status: newStatus, updatedAt: Date.now() };
    await updateMeeting(updated);
    this.meeting = updated;
  }

  private async onQuickAdd(): Promise<void> {
    if (!this.meeting || !this.quickAddText.trim()) {
      this.quickAddVisible = false;
      return;
    }
    const field = PDCA_FIELDS[this.currentTabIndex];
    await appendPdcaSegment(this.meeting.id, field, this.quickAddText.trim());
    this.quickAddText = '';
    this.quickAddVisible = false;
    await this.load(this.meeting.id);
  }

  private async onAddActionItem(): Promise<void> {
    if (!this.meeting) return;
    router.pushUrl({
      url: ROUTE_ACTION_ITEM_EDIT,
      params: { id: '', meetingId: this.meeting.id, mode: 'create' }
    });
  }

  build() {
    Column() {
      if (!this.meeting) {
        Column() {
          Text('加载中...')
        }
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 顶部
        Row() {
          Text('←')
            .fontSize(24)
            .padding(8)
            .onClick(() => router.back())
          Column() {
            Text(this.meeting.title)
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(new Date(this.meeting.meetingTime).toLocaleString())
              .fontSize(12)
              .fontColor('#999999')
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)

          StatusBadge({
            label: MEETING_STATUS_LABEL[this.meeting.status],
            color: this.meeting.status === 'completed' ? COLOR_STATUS_COMPLETED : COLOR_STATUS_IN_PROGRESS
          })
          Text('✏️')
            .fontSize(18)
            .padding(8)
            .onClick(() => {
              router.pushUrl({ url: ROUTE_MEETING_EDIT, params: { id: this.meeting!.id } });
            })
        }
        .width('100%')
        .padding(8)
        .backgroundColor('#FFFFFF')

        // Tab 栏
        Row({ space: 0 }) {
          ForEach([0, 1, 2, 3, 4], (idx: number) => {
            Column() {
              Text(this.getTabLabel(idx))
                .fontSize(14)
                .fontColor(this.currentTabIndex === idx ? '#5B7FFF' : '#666666')
                .fontWeight(this.currentTabIndex === idx ? FontWeight.Bold : FontWeight.Normal)
                .padding({ top: 12, bottom: 12 })
              if (this.currentTabIndex === idx) {
                Text('')
                  .height(2)
                  .width('60%')
                  .backgroundColor('#5B7FFF')
              } else {
                Text('').height(2)
              }
            }
            .layoutWeight(1)
            .onClick(() => { this.currentTabIndex = idx })
          })
        }
        .width('100%')
        .backgroundColor('#FFFFFF')

        // Tab 内容
        Column() {
          if (this.currentTabIndex < 4) {
            const field = PDCA_FIELDS[this.currentTabIndex];
            PdcaSegmentCard({
              field: field,
              content: this.getMeetingField(field),
              onAppend: () => { this.quickAddVisible = true }
            })
          } else {
            if (this.actionItems.length === 0) {
              EmptyState({
                title: $r('app.string.detail_empty_actions'),
                subtitle: '点击 ➕ 添加第一个'
              })
            } else {
              List() {
                ForEach(this.actionItems, (item: ActionItem) => {
                  ListItem() {
                    ActionItemCard({
                      item: item,
                      onClick: () => {
                        router.pushUrl({
                          url: ROUTE_ACTION_ITEM_EDIT,
                          params: { id: item.id, meetingId: item.meetingId, mode: 'edit' }
                        });
                      }
                    })
                  }
                })
              }
              .layoutWeight(1)
            }
          }
        }
        .layoutWeight(1)
        .padding(16)

        // 快速追加输入框
        if (this.quickAddVisible) {
          Column() {
            Text(`追加到「${PDCA_LABEL[PDCA_FIELDS[this.currentTabIndex]]}」`)
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 8 })
            TextArea({ text: this.quickAddText, placeholder: '输入要追加的内容...' })
              .height(80)
              .onChange((v: string) => { this.quickAddText = v })
            Row({ space: 8 }) {
              Button('取消')
                .layoutWeight(1)
                .backgroundColor('#F0F0F0')
                .fontColor('#333333')
                .onClick(() => { this.quickAddVisible = false; this.quickAddText = '' })
              Button('保存')
                .layoutWeight(1)
                .backgroundColor('#5B7FFF')
                .onClick(() => this.onQuickAdd())
            }
            .width('100%')
            .margin({ top: 8 })
          }
          .width('100%')
          .padding(12)
          .backgroundColor('#FFFFFF')
          .borderRadius(8)
          .margin(16)
        }

        // 底部 FAB / 状态切换
        Row() {
          if (this.meeting.status === 'completed') {
            Button($r('app.string.detail_btn_reopen'))
              .layoutWeight(1)
              .backgroundColor('#FFA500')
              .onClick(() => this.toggleStatus())
          } else {
            Button($r('app.string.detail_btn_complete'))
              .layoutWeight(1)
              .backgroundColor('#4CAF50')
              .onClick(() => this.toggleStatus())
          }
          Text('➕')
            .fontSize(22)
            .fontColor('#FFFFFF')
            .width(48)
            .height(48)
            .borderRadius(24)
            .backgroundColor('#5B7FFF')
            .textAlign(TextAlign.Center)
            .margin({ left: 8 })
            .onClick(() => {
              if (this.currentTabIndex < 4) {
                this.quickAddVisible = true;
              } else {
                this.onAddActionItem();
              }
            })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private getTabLabel(idx: number): string {
    return ['P', 'D', 'C', 'A', '行动项'][idx];
  }

  private getMeetingField(field: PdcaField): string {
    if (!this.meeting) return '';
    return this.meeting[field];
  }
}
