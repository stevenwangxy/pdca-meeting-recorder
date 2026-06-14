// data/DbHelper.ets
// 负责初始化 RDB、创建表、版本迁移。
// 提供 getRdb() 单例供各 Repo 使用。

import { relationalStore } from '@kit.ArkData';
import { BusinessError } from '@kit.BasicServicesKit';
import { DB_NAME, DB_VERSION, TABLE_MEETING, TABLE_ACTION_ITEM } from '../common/Constants';

let rdbStore: relationalStore.RdbStore | null = null;

const SQL_CREATE_MEETING = `
  CREATE TABLE IF NOT EXISTS ${TABLE_MEETING} (
    id TEXT PRIMARY KEY,
    title TEXT NOT NULL,
    meeting_time INTEGER NOT NULL,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    status TEXT NOT NULL DEFAULT 'in_progress',
    plan TEXT NOT NULL DEFAULT '',
    do_content TEXT NOT NULL DEFAULT '',
    check_content TEXT NOT NULL DEFAULT '',
    act_content TEXT NOT NULL DEFAULT '',
    tags TEXT NOT NULL DEFAULT '[]',
    notes TEXT NOT NULL DEFAULT ''
  )
`;

const SQL_CREATE_ACTION_ITEM = `
  CREATE TABLE IF NOT EXISTS ${TABLE_ACTION_ITEM} (
    id TEXT PRIMARY KEY,
    meeting_id TEXT NOT NULL,
    content TEXT NOT NULL,
    owner TEXT NOT NULL DEFAULT '',
    deadline INTEGER NOT NULL DEFAULT 0,
    priority TEXT NOT NULL DEFAULT 'medium',
    status TEXT NOT NULL DEFAULT 'pending',
    "order" INTEGER NOT NULL DEFAULT 0,
    created_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL,
    FOREIGN KEY (meeting_id) REFERENCES ${TABLE_MEETING}(id) ON DELETE CASCADE
  )
`;

const SQL_INDEX_MEETING_STATUS = `CREATE INDEX IF NOT EXISTS idx_meeting_status ON ${TABLE_MEETING}(status)`;
const SQL_INDEX_MEETING_TIME = `CREATE INDEX IF NOT EXISTS idx_meeting_time ON ${TABLE_MEETING}(meeting_time DESC)`;
const SQL_INDEX_ACTION_MEETING = `CREATE INDEX IF NOT EXISTS idx_action_meeting ON ${TABLE_ACTION_ITEM}(meeting_id)`;
const SQL_INDEX_ACTION_STATUS = `CREATE INDEX IF NOT EXISTS idx_action_status ON ${TABLE_ACTION_ITEM}(status)`;

export async function initDb(context: Context): Promise<relationalStore.RdbStore> {
  if (rdbStore !== null) {
    return rdbStore;
  }
  const config: relationalStore.StoreConfig = {
    name: DB_NAME,
    securityLevel: relationalStore.SecurityLevel.S1,
    version: DB_VERSION,
  };
  rdbStore = await relationalStore.getRdbStore(context, config);
  await rdbStore.executeSql(SQL_CREATE_MEETING);
  await rdbStore.executeSql(SQL_CREATE_ACTION_ITEM);
  await rdbStore.executeSql(SQL_INDEX_MEETING_STATUS);
  await rdbStore.executeSql(SQL_INDEX_MEETING_TIME);
  await rdbStore.executeSql(SQL_INDEX_ACTION_MEETING);
  await rdbStore.executeSql(SQL_INDEX_ACTION_STATUS);
  // 启用外键约束（SQLite 默认关闭）
  await rdbStore.executeSql('PRAGMA foreign_keys = ON');
  return rdbStore;
}

export function getRdb(): relationalStore.RdbStore {
  if (rdbStore === null) {
    throw new Error('Database not initialized. Call initDb() in EntryAbility.onCreate().');
  }
  return rdbStore;
}

// 测试用：重置单例
export function _resetRdbForTest(): void {
  rdbStore = null;
}
