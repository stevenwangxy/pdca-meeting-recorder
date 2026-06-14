// data/ActionItemRepo.ets
// 行动项表的 CRUD 封装。

import { relationalStore } from '@kit.ArkData';
import { ValuesBucket } from '@kit.ArkData';
import { getRdb } from './DbHelper';
import { TABLE_ACTION_ITEM } from '../common/Constants';
import { ActionItem, ActionItemStatus, Priority } from './types';

function rowToActionItem(row: relationalStore.KeysValues): ActionItem {
  return {
    id: row['id'] as string,
    meetingId: row['meeting_id'] as string,
    content: row['content'] as string,
    owner: (row['owner'] as string) || '',
    deadline: (row['deadline'] as number) || 0,
    priority: row['priority'] as Priority,
    status: row['status'] as ActionItemStatus,
    order: (row['order'] as number) || 0,
    createdAt: row['created_at'] as number,
    updatedAt: row['updated_at'] as number,
  };
}

function actionItemToValues(a: ActionItem): ValuesBucket {
  return {
    id: a.id,
    meeting_id: a.meetingId,
    content: a.content,
    owner: a.owner || '',
    deadline: a.deadline || 0,
    priority: a.priority,
    status: a.status,
    order: a.order,
    created_at: a.createdAt,
    updated_at: a.updatedAt,
  };
}

export async function insertActionItem(a: ActionItem): Promise<void> {
  const rdb = getRdb();
  await rdb.insert(TABLE_ACTION_ITEM, actionItemToValues(a));
}

export async function updateActionItem(a: ActionItem): Promise<void> {
  const rdb = getRdb();
  const v = actionItemToValues(a);
  v['updated_at'] = Date.now();
  await rdb.update(v, { id: a.id }, TABLE_ACTION_ITEM);
}

export async function deleteActionItem(id: string): Promise<void> {
  const rdb = getRdb();
  await rdb.delete({ id }, TABLE_ACTION_ITEM);
}

export async function listActionItems(meetingId: string): Promise<ActionItem[]> {
  const rdb = getRdb();
  const predicates = new relationalStore.RdbPredicates(TABLE_ACTION_ITEM)
    .equalTo('meeting_id', meetingId)
    .orderByAsc('order');
  const result = await rdb.query(predicates);
  const list: ActionItem[] = [];
  while (result.goToNextRow()) {
    list.push(rowToActionItem(result.getRow()));
  }
  result.close();
  return list;
}

// 列出所有行动项（用于跨会议统计 / 导出）
export async function listAllActionItems(): Promise<ActionItem[]> {
  const rdb = getRdb();
  const result = await rdb.query(
    new relationalStore.RdbPredicates(TABLE_ACTION_ITEM).orderByAsc('meeting_id').orderByAsc('order')
  );
  const list: ActionItem[] = [];
  while (result.goToNextRow()) {
    list.push(rowToActionItem(result.getRow()));
  }
  result.close();
  return list;
}
