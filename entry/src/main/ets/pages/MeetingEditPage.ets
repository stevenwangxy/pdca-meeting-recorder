// pages/MeetingEditPage.ets
// 新建/编辑会议页面。

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { Meeting, MeetingStatus } from '../data/types';
import { generateUuidV4 } from '../common/Uuid';
import { insertMeeting, updateMeeting, deleteMeeting, getMeeting } from '../data/MeetingRepo';

interface RouteParams {
  id?: string;
}

@Entry
@Component
struct MeetingEditPage {
  @State meetingId: string = '';
  @State title: string = '';
  @State meetingTime: number = Date.now();
  @State status: MeetingStatus = 'in_progress';
  @State plan: string = '';
  @State doContent: string = '';
  @State checkContent: string = '';
  @State actContent: string = '';
  @State tagsText: string = '';
  @State notes: string = '';
  @State titleError: boolean = false;
  @State isEdit: boolean = false;
  @State planExpanded: boolean = true;
  @State doExpanded: boolean = true;
  @State checkExpanded: boolean = true;
  @State actExpanded: boolean = true;
  @State notesExpanded: boolean = true;
  @State datePickerVisible: boolean = false;

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as RouteParams;
    if (params && params.id) {
      this.isEdit = true;
      this.loadMeeting(params.id);
    }
  }

  async loadMeeting(id: string): Promise<void> {
    const m = await getMeeting(id);
    if (m) {
      this.meetingId = m.id;
      this.title = m.title;
      this.meetingTime = m.meetingTime;
      this.status = m.status;
      this.plan = m.plan;
      this.doContent = m.doContent;
      this.checkContent = m.checkContent;
      this.actContent = m.actContent;
      this.tagsText = m.tags.join(', ');
      this.notes = m.notes;
    }
  }

  private async save(markComplete: boolean): Promise<void> {
    if (!this.title.trim()) {
      this.titleError = true;
      return;
    }
    const now = Date.now();
    const tags = this.tagsText
      .split(',')
      .map(s => s.trim())
      .filter(s => s.length > 0);
    if (this.isEdit) {
      const m: Meeting = {
        id: this.meetingId,
        title: this.title.trim(),
        meetingTime: this.meetingTime,
        createdAt: 0,
        updatedAt: now,
        status: markComplete ? 'completed' : this.status,
        plan: this.plan,
        doContent: this.doContent,
        checkContent: this.checkContent,
        actContent: this.actContent,
        tags,
        notes: this.notes,
      };
      await updateMeeting(m);
    } else {
      const m: Meeting = {
        id: generateUuidV4(),
        title: this.title.trim(),
        meetingTime: this.meetingTime,
        createdAt: now,
        updatedAt: now,
        status: markComplete ? 'completed' : 'in_progress',
        plan: this.plan,
        doContent: this.doContent,
        checkContent: this.checkContent,
        actContent: this.actContent,
        tags,
        notes: this.notes,
      };
      await insertMeeting(m);
    }
    router.back();
  }

  private async onDelete(): Promise<void> {
    const confirmed = await promptAction.showDialog({
      title: '确认删除',
      message: $r('app.string.edit_confirm_delete'),
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#F44336' }
      ]
    });
    if (confirmed.index === 1 && this.meetingId) {
      await deleteMeeting(this.meetingId);
      router.back();
    }
  }

  build() {
    Column() {
      // 顶部
      Row() {
        Text('←')
          .fontSize(24)
          .padding(8)
          .onClick(() => router.back())
        Text(this.isEdit ? $r('app.string.edit_title_edit') : $r('app.string.edit_title_new'))
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

      // 表单
      Scroll() {
        Column({ space: 12 }) {
          // 标题
          Column() {
            Text($r('app.string.edit_field_title'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            TextInput({ text: this.title, placeholder: '如：Q3 产品评审会' })
              .onChange((v: string) => {
                this.title = v;
                if (v.trim()) this.titleError = false;
              })
            if (this.titleError) {
              Text($r('app.string.edit_err_title_empty'))
                .fontSize(12)
                .fontColor('#F44336')
                .margin({ top: 4 })
            }
          }
          .alignItems(HorizontalAlign.Start)

          // 会议时间
          Column() {
            Text($r('app.string.edit_field_time'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Text(new Date(this.meetingTime).toLocaleString())
              .fontSize(14)
              .padding(12)
              .backgroundColor('#F5F5F5')
              .borderRadius(4)
              .width('100%')
              .onClick(() => { this.datePickerVisible = true })
            if (this.datePickerVisible) {
              DatePicker({
                start: new Date('2000-01-01'),
                end: new Date('2100-12-31'),
                selected: new Date(this.meetingTime)
              })
                .onDateChange((value: Date) => {
                  this.meetingTime = value.getTime();
                })
              Row({ space: 8 }) {
                Button('取消')
                  .layoutWeight(1)
                  .backgroundColor('#F0F0F0')
                  .fontColor('#333333')
                  .onClick(() => { this.datePickerVisible = false })
                Button('确定')
                  .layoutWeight(1)
                  .backgroundColor('#5B7FFF')
                  .onClick(() => { this.datePickerVisible = false })
              }
              .width('100%')
              .margin({ top: 8 })
            }
          }
          .alignItems(HorizontalAlign.Start)

          this.buildPdcaEditor('Plan 计划', this.plan, (v) => this.plan = v, this.planExpanded, () => { this.planExpanded = !this.planExpanded })
          this.buildPdcaEditor('Do 执行', this.doContent, (v) => this.doContent = v, this.doExpanded, () => { this.doExpanded = !this.doExpanded })
          this.buildPdcaEditor('Check 检查', this.checkContent, (v) => this.checkContent = v, this.checkExpanded, () => { this.checkExpanded = !this.checkExpanded })
          this.buildPdcaEditor('Act 改进', this.actContent, (v) => this.actContent = v, this.actExpanded, () => { this.actExpanded = !this.actExpanded })

          // 标签
          Column() {
            Text($r('app.string.edit_field_tags'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            TextInput({ text: this.tagsText, placeholder: '如：产品, 季度' })
              .onChange((v: string) => { this.tagsText = v })
          }
          .alignItems(HorizontalAlign.Start)

          // 备注
          Column() {
            Row() {
              Text($r('app.string.edit_field_notes'))
                .fontSize(13)
                .fontColor('#666666')
                .layoutWeight(1)
              Text(this.notesExpanded ? '收起' : '展开')
                .fontSize(12)
                .fontColor('#5B7FFF')
                .onClick(() => { this.notesExpanded = !this.notesExpanded })
            }
            .width('100%')
            .margin({ bottom: 4 })
            if (this.notesExpanded) {
              TextArea({ text: this.notes, placeholder: '可选' })
                .height(80)
                .onChange((v: string) => { this.notes = v })
            }
          }
          .alignItems(HorizontalAlign.Start)

          if (this.isEdit) {
            Button($r('app.string.edit_btn_delete'))
              .width('100%')
              .backgroundColor('#FFFFFF')
              .fontColor('#F44336')
              .onClick(() => this.onDelete())
          }
        }
        .padding(16)
      }
      .layoutWeight(1)

      // 底部按钮
      Row({ space: 12 }) {
        Button($r('app.string.edit_btn_save'))
          .layoutWeight(1)
          .backgroundColor('#5B7FFF')
          .onClick(() => this.save(false))
        Button($r('app.string.edit_btn_complete'))
          .layoutWeight(1)
          .backgroundColor('#4CAF50')
          .onClick(() => this.save(true))
      }
      .width('100%')
      .padding(16)
      .backgroundColor('#FFFFFF')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  @Builder
  buildPdcaEditor(label: string, value: string, onChange: (v: string) => void, expanded: boolean, toggle: () => void) {
    Column() {
      Row() {
        Text(label)
          .fontSize(13)
          .fontColor('#666666')
          .layoutWeight(1)
        Text(expanded ? '收起' : '展开')
          .fontSize(12)
          .fontColor('#5B7FFF')
          .onClick(() => toggle())
      }
      .width('100%')
      .margin({ bottom: 4 })
      if (expanded) {
        TextArea({ text: value, placeholder: '点击输入' })
          .height(100)
          .onChange((v: string) => onChange(v))
      }
    }
    .alignItems(HorizontalAlign.Start)
  }
}
