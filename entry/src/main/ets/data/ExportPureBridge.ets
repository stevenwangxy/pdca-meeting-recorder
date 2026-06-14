// data/ExportPureBridge.ets
// 桥接纯逻辑函数（与 tests/pure/export-pure.ts 保持一致）。
// 因为 ArkTS 项目不能直接跨 .ets/.ts 引用，这里 inline 一次。

import { Meeting, ActionItem, ExportPayload } from './types';
import { EXPORT_VERSION } from '../common/Constants';

export interface ImportReport {
  insertedMeetings: number;
  insertedActionItems: number;
  skippedMeetings: number;
  skippedActionItems: number;
}

export function buildExportPayload(
  meetings: Meeting[],
  actionItems: ActionItem[],
  now: number = Date.now()
): ExportPayload {
  return {
    version: EXPORT_VERSION,
    exportedAt: now,
    meetings: meetings.map(m => ({ ...m, tags: [...m.tags] })),
    actionItems: actionItems.map(a => ({ ...a })),
  };
}

export function parseExportPayload(text: string): ExportPayload {
  let data: any;
  try {
    data = JSON.parse(text);
  } catch (e) {
    throw new Error('JSON 解析失败：文件不是合法的 JSON');
  }
  if (typeof data !== 'object' || data === null) {
    throw new Error('JSON 解析失败：根节点不是对象');
  }
  if (typeof data.version !== 'string') {
    throw new Error('不兼容的备份版本：缺少 version 字段');
  }
  if (!Array.isArray(data.meetings) || !Array.isArray(data.actionItems)) {
    throw new Error('JSON 格式错误：缺少 meetings 或 actionItems 数组');
  }
  return data as ExportPayload;
}

export function mergeImport(
  payload: ExportPayload,
  existingMeetings: Meeting[],
  existingActionItems: ActionItem[]
): {
  meetingsToInsert: Meeting[];
  actionItemsToInsert: ActionItem[];
  report: ImportReport;
} {
  const existingMeetingIds = new Set(existingMeetings.map(m => m.id));
  const existingActionItemIds = new Set(existingActionItems.map(a => a.id));
  const meetingsToInsert = payload.meetings.filter(m => !existingMeetingIds.has(m.id));
  const actionItemsToInsert = payload.actionItems.filter(
    a => !existingActionItemIds.has(a.id)
  );
  return {
    meetingsToInsert,
    actionItemsToInsert,
    report: {
      insertedMeetings: meetingsToInsert.length,
      insertedActionItems: actionItemsToInsert.length,
      skippedMeetings: payload.meetings.length - meetingsToInsert.length,
      skippedActionItems: payload.actionItems.length - actionItemsToInsert.length,
    },
  };
}
