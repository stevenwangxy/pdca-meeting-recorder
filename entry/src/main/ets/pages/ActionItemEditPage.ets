// pages/ActionItemEditPage.ets
// 行动项编辑页：支持新建和编辑。

import { router } from '@kit.ArkUI';
import { promptAction } from '@kit.ArkUI';
import { ActionItem, ActionItemStatus, Priority, ACTION_STATUS_LABEL, PRIORITY_LABEL } from '../data/types';
import { insertActionItem, updateActionItem, deleteActionItem, listActionItems } from '../data/ActionItemRepo';
import { generateUuidV4 } from '../common/Uuid';

interface RouteParams {
  id: string;
  meetingId: string;
  mode: string;
}

@Entry
@Component
struct ActionItemEditPage {
  @State itemId: string = '';
  @State meetingId: string = '';
  @State mode: string = 'create';
  @State content: string = '';
  @State owner: string = '';
  @State deadline: number = 0;
  @State priority: Priority = 'medium';
  @State status: ActionItemStatus = 'pending';
  @State order: number = 0;
  @State createdAt: number = 0;
  @State contentError: boolean = false;
  @State deadlinePickerVisible: boolean = false;
  @State priorityOptions: SelectOption[] = [
    { value: PRIORITY_LABEL.high },
    { value: PRIORITY_LABEL.medium },
    { value: PRIORITY_LABEL.low }
  ];
  @State statusOptions: SelectOption[] = [
    { value: ACTION_STATUS_LABEL.pending },
    { value: ACTION_STATUS_LABEL.in_progress },
    { value: ACTION_STATUS_LABEL.completed },
    { value: ACTION_STATUS_LABEL.delayed }
  ];

  aboutToAppear(): void {
    const params = this.getUIContext().getRouter().getParams() as RouteParams;
    if (params) {
      this.mode = params.mode;
      this.meetingId = params.meetingId;
      if (params.mode === 'edit') {
        this.itemId = params.id;
        this.load(params.meetingId, params.id);
      } else {
        this.itemId = generateUuidV4();
        this.order = Date.now();
      }
    }
  }

  async load(meetingId: string, id: string): Promise<void> {
    const items = await listActionItems(meetingId);
    const found = items.find(i => i.id === id);
    if (found) {
      this.content = found.content;
      this.owner = found.owner;
      this.deadline = found.deadline;
      this.priority = found.priority;
      this.status = found.status;
      this.order = found.order;
      this.createdAt = found.createdAt;
    }
  }

  private async save(): Promise<void> {
    if (!this.content.trim()) {
      this.contentError = true;
      return;
    }
    const now = Date.now();
    const item: ActionItem = {
      id: this.itemId,
      meetingId: this.meetingId,
      content: this.content.trim(),
      owner: this.owner.trim(),
      deadline: this.deadline,
      priority: this.priority,
      status: this.status,
      order: this.order,
      createdAt: this.mode === 'create' ? now : this.createdAt,
      updatedAt: now,
    };
    if (this.mode === 'create') {
      await insertActionItem(item);
    } else {
      await updateActionItem(item);
    }
    router.back();
  }

  private async onDelete(): Promise<void> {
    if (this.mode !== 'edit') {
      router.back();
      return;
    }
    const confirmed = await promptAction.showDialog({
      title: '确认删除',
      message: '确定要删除这个行动项吗？',
      buttons: [
        { text: '取消', color: '#999999' },
        { text: '删除', color: '#F44336' }
      ]
    });
    if (confirmed.index === 1) {
      await deleteActionItem(this.itemId);
      router.back();
    }
  }

  build() {
    Column() {
      Row() {
        Text('←')
          .fontSize(24)
          .padding(8)
          .onClick(() => router.back())
        Text(this.mode === 'create' ? '新建行动项' : '编辑行动项')
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

      Scroll() {
        Column({ space: 12 }) {
          // 内容
          Column() {
            Text($r('app.string.action_field_content'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            TextArea({ text: this.content, placeholder: '描述要做什么...' })
              .height(80)
              .onChange((v: string) => {
                this.content = v;
                if (v.trim()) this.contentError = false;
              })
            if (this.contentError) {
              Text('请输入待办内容')
                .fontSize(12)
                .fontColor('#F44336')
                .margin({ top: 4 })
            }
          }
          .alignItems(HorizontalAlign.Start)

          // 负责人
          Column() {
            Text($r('app.string.action_field_owner'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            TextInput({ text: this.owner, placeholder: '姓名' })
              .onChange((v: string) => { this.owner = v })
          }
          .alignItems(HorizontalAlign.Start)

          // 截止日期
          Column() {
            Text($r('app.string.action_field_deadline'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Row() {
              Text(this.deadline > 0 ? new Date(this.deadline).toLocaleDateString() : $r('app.string.action_no_deadline'))
                .fontSize(14)
                .layoutWeight(1)
                .padding(12)
                .backgroundColor('#F5F5F5')
                .borderRadius(4)
                .onClick(() => { this.deadlinePickerVisible = true })
              if (this.deadline > 0) {
                Text('清除')
                  .fontSize(13)
                  .fontColor('#F44336')
                  .padding(8)
                  .onClick(() => { this.deadline = 0 })
              }
            }
            .width('100%')
            if (this.deadlinePickerVisible) {
              DatePicker({
                start: new Date('2000-01-01'),
                end: new Date('2100-12-31'),
                selected: this.deadline > 0 ? new Date(this.deadline) : new Date()
              })
                .onDateChange((value: Date) => {
                  this.deadline = value.getTime();
                })
              Row({ space: 8 }) {
                Button('取消')
                  .layoutWeight(1)
                  .backgroundColor('#F0F0F0')
                  .fontColor('#333333')
                  .onClick(() => { this.deadlinePickerVisible = false })
                Button('确定')
                  .layoutWeight(1)
                  .backgroundColor('#5B7FFF')
                  .onClick(() => { this.deadlinePickerVisible = false })
              }
              .width('100%')
              .margin({ top: 8 })
            }
          }
          .alignItems(HorizontalAlign.Start)

          // 优先级
          Column() {
            Text($r('app.string.action_field_priority'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Select(this.priorityOptions)
              .selected(this.priorityIndex())
              .value(PRIORITY_LABEL[this.priority])
              .onSelect((idx: number) => {
                this.priority = (['high', 'medium', 'low'] as Priority[])[idx];
              })
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)

          // 状态
          Column() {
            Text($r('app.string.action_field_status'))
              .fontSize(13)
              .fontColor('#666666')
              .margin({ bottom: 4 })
            Select(this.statusOptions)
              .selected(this.statusIndex())
              .value(ACTION_STATUS_LABEL[this.status])
              .onSelect((idx: number) => {
                this.status = (['pending', 'in_progress', 'completed', 'delayed'] as ActionItemStatus[])[idx];
              })
              .width('100%')
          }
          .alignItems(HorizontalAlign.Start)

          if (this.mode === 'edit') {
            Button($r('app.string.action_btn_delete'))
              .width('100%')
              .backgroundColor('#FFFFFF')
              .fontColor('#F44336')
              .onClick(() => this.onDelete())
          }
        }
        .padding(16)
      }
      .layoutWeight(1)

      Button($r('app.string.action_btn_save'))
        .width('90%')
        .backgroundColor('#5B7FFF')
        .onClick(() => this.save())
        .margin(16)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }

  private priorityIndex(): number {
    return ['high', 'medium', 'low'].indexOf(this.priority);
  }

  private statusIndex(): number {
    return ['pending', 'in_progress', 'completed', 'delayed'].indexOf(this.status);
  }
}
