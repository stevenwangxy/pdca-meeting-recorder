// common/Uuid.ets
// 生成符合 RFC 4122 v4 规范的 UUID。优先使用 HarmonyOS 的 cryptoFramework；
// 不可用时回退到基于 crypto.getRandomValues 的纯 JS 实现，方便在测试环境运行。

import { crypto } from '@kit.ArkTS';
import { cryptoFramework } from '@kit.CoreCryptoKit';

export function generateUuidV4(): string {
  try {
    // 尝试用 HarmonyOS crypto 框架
    const rand = cryptoFramework.createRandom();
    const data = rand.generateRandomSync(16);
    return formatUuid(data.data);
  } catch (e) {
    // 沙盒/测试环境回退
    return fallbackUuid();
  }
}

// 暴露给纯测试用例的纯函数
export function formatUuid(bytes: Uint8Array): string {
  if (bytes.length < 16) {
    throw new Error('UUID requires at least 16 bytes');
  }
  const b = bytes.slice(0, 16);
  // 设置版本 (4) 和变体 (RFC 4122)
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

function fallbackUuid(): string {
  const bytes = new Uint8Array(16);
  // Node 18+ / 浏览器 / 现代 HarmonyOS JS 引擎都支持
  if (typeof crypto !== 'undefined' && typeof crypto.getRandomValues === 'function') {
    crypto.getRandomValues(bytes);
  } else {
    for (let i = 0; i < 16; i++) {
      bytes[i] = Math.floor(Math.random() * 256);
    }
  }
  return formatUuid(bytes);
}
