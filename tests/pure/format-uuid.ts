// tests/pure/format-uuid.ts
// 这是 entry/src/main/ets/common/Uuid.ets 中 formatUuid 的纯 TS 副本，
// 用于沙盒内单测。两者实现必须保持一致。

export function formatUuid(bytes: Uint8Array): string {
  if (bytes.length < 16) {
    throw new Error('UUID requires at least 16 bytes');
  }
  const b = bytes.slice(0, 16);
  b[6] = (b[6] & 0x0f) | 0x40;
  b[8] = (b[8] & 0x3f) | 0x80;
  const hex: string[] = [];
  for (let i = 0; i < 16; i++) {
    hex.push(b[i].toString(16).padStart(2, '0'));
  }
  return (
    hex.slice(0, 4).join('') + '-' +
    hex.slice(4, 6).join('') + '-' +
    hex.slice(6, 8).join('') + '-' +
    hex.slice(8, 10).join('') + '-' +
    hex.slice(10, 16).join('')
  );
}
