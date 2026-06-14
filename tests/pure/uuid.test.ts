// tests/pure/uuid.test.ts
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { formatUuid } from './format-uuid';

test('formatUuid sets version 4', () => {
  const bytes = new Uint8Array(16);
  const uuid = formatUuid(bytes);
  // 第 14 个字符（去掉前两个连字符的偏移）是版本号
  assert.equal(uuid[14], '4', `Expected version 4, got UUID ${uuid}`);
});

test('formatUuid sets RFC 4122 variant', () => {
  const bytes = new Uint8Array(16);
  const uuid = formatUuid(bytes);
  // 第 19 个字符是 variant 高位，必须是 8/9/a/b 之一
  assert.match(uuid[19], /[89ab]/, `Expected variant RFC4122, got ${uuid}`);
});

test('formatUuid lowercases output', () => {
  const bytes = new Uint8Array([0xab, 0xcd, 0xef, 0x12, 0x34, 0x56, 0x78, 0x9a,
                                 0xbc, 0xde, 0xf0, 0x12, 0x34, 0x56, 0x78, 0x9a]);
  const uuid = formatUuid(bytes);
  // byte[6] = 0x78 → (0x78 & 0x0f) | 0x40 = 0x48 (version 4)
  // byte[8] = 0xbc → (0xbc & 0x3f) | 0x80 = 0xbc (variant RFC4122 high)
  assert.equal(uuid, 'abcdef12-3456-489a-bcde-f0123456789a');
});

test('formatUuid throws on short input', () => {
  assert.throws(() => formatUuid(new Uint8Array(8)), /at least 16 bytes/);
});

test('formatUuid returns canonical 36-char string', () => {
  const bytes = new Uint8Array(16);
  const uuid = formatUuid(bytes);
  assert.equal(uuid.length, 36);
  assert.equal(uuid.split('-').length, 5);
  assert.equal(uuid.split('-').map(s => s.length).join(','), '8,4,4,4,12');
});
