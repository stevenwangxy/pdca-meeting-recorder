// tests/pure/export.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { buildExportPayload, parseExportPayload, mergeImport } from './export-pure';
import { Meeting, ActionItem } from '../../entry/src/main/ets/data/types';

const M1: Meeting = {
  id: 'm1', title: 't', meetingTime: 1, createdAt: 1, updatedAt: 1,
  status: 'in_progress', plan: '', doContent: '', checkContent: '', actContent: '',
  tags: ['a', 'b'], notes: '',
};
const A1: ActionItem = {
  id: 'a1', meetingId: 'm1', content: 'x', owner: '', deadline: 0,
  priority: 'medium', status: 'pending', order: 0, createdAt: 1, updatedAt: 1,
};

test('buildExportPayload includes version and timestamp', () => {
  const p = buildExportPayload([M1], [A1], 100);
  assert.equal(p.version, '1.0');
  assert.equal(p.exportedAt, 100);
  assert.equal(p.meetings.length, 1);
  assert.equal(p.actionItems.length, 1);
});

test('buildExportPayload deep-copies tags array', () => {
  const p = buildExportPayload([M1], [], 0);
  p.meetings[0].tags.push('c');
  assert.deepEqual(M1.tags, ['a', 'b']);
});

test('parseExportPayload accepts valid payload', () => {
  const text = JSON.stringify({ version: '1.0', exportedAt: 0, meetings: [], actionItems: [] });
  const p = parseExportPayload(text);
  assert.equal(p.version, '1.0');
});

test('parseExportPayload rejects invalid JSON', () => {
  assert.throws(() => parseExportPayload('not json'), /JSON 解析失败/);
});

test('parseExportPayload rejects missing version', () => {
  const text = JSON.stringify({ meetings: [], actionItems: [] });
  assert.throws(() => parseExportPayload(text), /缺少 version 字段/);
});

test('parseExportPayload rejects missing arrays', () => {
  const text = JSON.stringify({ version: '1.0' });
  assert.throws(() => parseExportPayload(text), /缺少 meetings 或 actionItems/);
});

test('mergeImport skips conflicts, inserts new', () => {
  const newMeeting: Meeting = { ...M1, id: 'm2', title: 't2' };
  const newAction: ActionItem = { ...A1, id: 'a2' };
  const payload = buildExportPayload([M1, newMeeting], [A1, newAction], 0);
  const result = mergeImport(payload, [M1], [A1]);
  assert.equal(result.meetingsToInsert.length, 1);
  assert.equal(result.meetingsToInsert[0].id, 'm2');
  assert.equal(result.actionItemsToInsert.length, 1);
  assert.equal(result.actionItemsToInsert[0].id, 'a2');
  assert.equal(result.report.skippedMeetings, 1);
  assert.equal(result.report.skippedActionItems, 1);
});
