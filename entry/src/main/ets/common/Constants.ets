// common/Constants.ets
// 共享常量：数据库名、版本、表格字段、UI 颜色等。

export const DB_NAME = 'pdca_recorder.db';
export const DB_VERSION = 1;

// 表格名
export const TABLE_MEETING = 'meeting';
export const TABLE_ACTION_ITEM = 'action_item';

// JSON 备份文件相关
export const EXPORT_VERSION = '1.0';
export const EXPORT_FILE_PREFIX = 'pdca-backup-';
export const FILE_TYPE_JSON = 'json';

// 页面路径（用于 router 跳转）
export const ROUTE_HOME = 'pages/HomePage';
export const ROUTE_MEETING_EDIT = 'pages/MeetingEditPage';
export const ROUTE_MEETING_DETAIL = 'pages/MeetingDetailPage';
export const ROUTE_ACTION_ITEM_EDIT = 'pages/ActionItemEditPage';
export const ROUTE_SETTINGS = 'pages/SettingsPage';

// UI 颜色（与 StatusBadge / PriorityBadge 配套）
export const COLOR_STATUS_IN_PROGRESS = '#FFA500';
export const COLOR_STATUS_COMPLETED = '#4CAF50';
export const COLOR_STATUS_PENDING = '#9E9E9E';
export const COLOR_STATUS_DELAYED = '#F44336';
export const COLOR_PRIORITY_HIGH = '#F44336';
export const COLOR_PRIORITY_MEDIUM = '#FFA500';
export const COLOR_PRIORITY_LOW = '#9E9E9E';
