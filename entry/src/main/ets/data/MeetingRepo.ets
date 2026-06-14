// data/MeetingRepo.ets
// 会议表的 CRUD 封装。所有外部调用都通过这一层访问数据库。

import { relationalStore } from '@kit.ArkData';
import { ValuesBucket } from '@kit.ArkData';
import { getRdb } from './DbHelper';
import { TABLE_MEETING } from '../common/Constants';
import { Meeting, MeetingStatus } from './types';

function rowToMeeting(row: relationalStore.KeysValues): Meeting {
  return {
    id: row['id'] as string,
    title: row['title'] as string,
    meetingTime: row['meeting_time'] as number,
    createdAt: row['created_at'] as number,
    updatedAt: row['updated_at'] as number,
    status: row['status'] as MeetingStatus,
    plan: row['plan'] as string,
    doContent: row['do_content'] as string,
    checkContent: row['check_content'] as string,
    actContent: row['act_content'] as string,
    tags: JSON.parse((row['tags'] as string) || '[]'),
    notes: (row['notes'] as string) || '',
  };
}

function meetingToValues(m: Meeting, omitTimestamps: boolean = false): ValuesBucket {
  const v: ValuesBucket = {
    id: m.id,
    title: m.title,
    meeting_time: m.meetingTime,
    status: m.status,
    plan: m.plan,
    do_content: m.doContent,
    check_content: m.checkContent,
    act_content: m.actContent,
    tags: JSON.stringify(m.tags || []),
    notes: m.notes || '',
  };
  if (!omitTimestamps) {
    v['created_at'] = m.createdAt;
    v['updated_at'] = m.updatedAt;
  }
  return v;
}

export async function insertMeeting(m: Meeting): Promise<void> {
  const rdb = getRdb();
  await rdb.insert(TABLE_MEETING, meetingToValues(m));
}

export async function updateMeeting(m: Meeting): Promise<void> {
  const rdb = getRdb();
  const v = meetingToValues(m, true);
  v['updated_at'] = Date.now();
  await rdb.update(v, { id: m.id }, TABLE_MEETING);
}

export async function deleteMeeting(id: string): Promise<void> {
  const rdb = getRdb();
  // 外键 ON DELETE CASCADE 会自动删除关联的 action_item
  await rdb.delete({ id }, TABLE_MEETING);
}

export async function getMeeting(id: string): Promise<Meeting | null> {
  const rdb = getRdb();
  const result = await rdb.query(
    new relationalStore.RdbPredicates(TABLE_MEETING).equalTo('id', id)
  );
  if (result.rowCount === 0) {
    result.close();
    return null;
  }
  result.goToFirstRow();
  const row = result.getRow();
  result.close();
  return rowToMeeting(row);
}

export async function listMeetings(filter?: {
  status?: MeetingStatus;
}): Promise<Meeting[]> {
  const rdb = getRdb();
  const predicates = new relationalStore.RdbPredicates(TABLE_MEETING);
  if (filter?.status) {
    predicates.equalTo('status', filter.status);
  }
  predicates.orderByDesc('meeting_time');
  const result = await rdb.query(predicates);
  const list: Meeting[] = [];
  while (result.goToNextRow()) {
    list.push(rowToMeeting(result.getRow()));
  }
  result.close();
  return list;
}

// 追加一段文字到指定 PDCA 段。会中快速记录用。
export async function appendPdcaSegment(
  id: string,
  field: 'plan' | 'doContent' | 'checkContent' | 'actContent',
  text: string
): Promise<void> {
  const rdb = getRdb();
  const m = await getMeeting(id);
  if (!m) {
    throw new Error(`Meeting ${id} not found`);
  }
  const current = m[field];
  const sep = current ? '\n' : '';
  m[field] = current + sep + text;
  m.updatedAt = Date.now();
  await updateMeeting(m);
}
