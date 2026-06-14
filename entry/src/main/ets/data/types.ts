// data/types.ts
// 项目级数据类型定义。

export type MeetingStatus = 'in_progress' | 'completed';

export type ActionItemStatus = 'pending' | 'in_progress' | 'completed' | 'delayed';

export type Priority = 'high' | 'medium' | 'low';

export interface Meeting {
  id: string;
  title: string;
  meetingTime: number;        // 毫秒时间戳
  createdAt: number;          // 系统字段
  updatedAt: number;          // 系统字段
  status: MeetingStatus;
  plan: string;
  doContent: string;
  checkContent: string;
  actContent: string;
  tags: string[];             // 标签数组
  notes: string;
}

export interface ActionItem {
  id: string;
  meetingId: string;
  content: string;
  owner: string;
  deadline: number;           // 0 表示未设
  priority: Priority;
  status: ActionItemStatus;
  order: number;
  createdAt: number;
  updatedAt: number;
}

export interface ExportPayload {
  version: string;
  exportedAt: number;
  meetings: Meeting[];
  actionItems: ActionItem[];
}

// UI 层用于筛选/渲染的枚举标签映射。
export const MEETING_STATUS_LABEL: Record<MeetingStatus, string> = {
  in_progress: '进行中',
  completed: '已完成',
};

export const ACTION_STATUS_LABEL: Record<ActionItemStatus, string> = {
  pending: '待办',
  in_progress: '进行中',
  completed: '完成',
  delayed: '延期',
};

export const PRIORITY_LABEL: Record<Priority, string> = {
  high: '高',
  medium: '中',
  low: '低',
};

// PDCA 四段字段的元信息，方便 Tab 切换和批量编辑。
export const PDCA_FIELDS = ['plan', 'doContent', 'checkContent', 'actContent'] as const;
export type PdcaField = (typeof PDCA_FIELDS)[number];

export const PDCA_LABEL: Record<PdcaField, string> = {
  plan: 'Plan 计划',
  doContent: 'Do 执行',
  checkContent: 'Check 检查',
  actContent: 'Act 改进',
};
