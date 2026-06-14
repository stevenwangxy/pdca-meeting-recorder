// pages/SettingsPage.ets
// 设置页：导出/导入。

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { listMeetings, insertMeeting, deleteMeeting } from '../data/MeetingRepo';
import { listAllActionItems, insertActionItem } from '../data/ActionItemRepo';
import { exportToJson, importFromJson, mergeImport } from '../data/ExportService';

@Entry
@Component
struct SettingsPage {
  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .padding(8)
          .onClick(() => router.back())
        Text($r('app.string.settings_title'))
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        Text(' ')
          .fontSize(24)
          .padding(8)
      }
      .width('100%')
      .padding(8)
      .backgroundColor('#FFFFFF')

      Column({ space: 12 }) {
        this.buildMenuItem(
          $r('app.string.settings_export'),
          $r('app.string.settings_export_desc'),
          '📤',
          () => this.onExport()
        )
        this.buildMenuItem(
          $r('app.string.settings_import'),
          $r('app.string.settings_import_desc'),
          '📥',
          () => this.onImport()
        )

        Column() {
          Text($r('app.string.settings_about'))
            .fontSize(14)
            .fontColor('#666666')
          Text($r('app.string.settings_version'))
            .fontSize(12)
            .fontColor('#999999')
            .margin({ top: 4 })
        }
        .width('100%')
        .padding(16)
        .backgroundColor('#FFFFFF')
        .borderRadius(8)
        .alignItems(HorizontalAlign.Start)
      }
      .padding(16)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildMenuItem(title: Resource, subtitle: Resource, icon: string, onTap: () => void) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 12 })
      Column() {
        Text(title)
          .fontSize(15)
          .fontWeight(FontWeight.Medium)
        Text(subtitle)
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      Text('›')
        .fontSize(20)
        .fontColor('#CCCCCC')
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
    .borderRadius(8)
    .onClick(() => onTap())
  }

  private async onExport(): Promise<void> {
    try {
      const meetings = await listMeetings();
      const actionItems = await listAllActionItems();
      await exportToJson(meetings, actionItems);
      promptAction.showToast({ message: $r('app.string.settings_toast_export_ok') });
    } catch (e) {
      const msg = e instanceof Error ? e.message : '导出失败';
      promptAction.showToast({ message: msg });
    }
  }

  private async onImport(): Promise<void> {
    try {
      const payload = await importFromJson();
      const confirmed = await promptAction.showDialog({
        title: '导入策略',
        message: '选择导入方式',
        buttons: [
          { text: '取消', color: '#999999' },
          { text: '合并', color: '#5B7FFF' },
          { text: '覆盖', color: '#F44336' }
        ]
      });
      if (confirmed.index === 0) {
        return;
      }

      const existingMeetings = await listMeetings();
      const existingActionItems = await listAllActionItems();

      if (confirmed.index === 2) {
        // 覆盖：清空后批量插入
        for (const m of existingMeetings) {
          await deleteMeeting(m.id);
        }
        for (const m of payload.meetings) {
          await insertMeeting(m);
        }
        for (const a of payload.actionItems) {
          await insertActionItem(a);
        }
        promptAction.showToast({ message: `覆盖导入完成：${payload.meetings.length} 会议` });
      } else {
        // 合并
        const result = mergeImport(payload, existingMeetings, existingActionItems);
        for (const m of result.meetingsToInsert) {
          await insertMeeting(m);
        }
        for (const a of result.actionItemsToInsert) {
          await insertActionItem(a);
        }
        promptAction.showToast({
          message: `新增 ${result.report.insertedMeetings} 会议，跳过 ${result.report.skippedMeetings} 冲突`
        });
      }
    } catch (e) {
      const msg = e instanceof Error ? e.message : '导入失败';
      promptAction.showToast({ message: msg });
    }
  }
}
