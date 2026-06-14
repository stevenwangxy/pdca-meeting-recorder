# 会议 PDCA 记录 - 元服务设计文档

- **日期**: 2026-06-13
- **作者**: MiniMax-M3
- **状态**: 已批准，待实施

## 1. 目标

在 HarmonyOS 6.1 系统上提供一个鸿蒙元服务（Atomic Service），用于在会议过程中记录 PDCA（Plan-Do-Check-Act）四要素以及从会议中产生的行动项（Action Item），支持本地存储与 JSON 备份还原。

## 2. 范围

### 包含
- 鸿蒙元服务形态的 PDCA 记录工具
- ArkTS + Stage 模型 + HarmonyOS SDK 6.1
- 本地关系型数据库（RDB / SQLite）
- JSON 文件导入/导出
- 会中快速记录 + 会后编辑补全两种使用模式

### 不包含
- 云同步
- 多人协作
- 推送通知 / 提醒
- 附件、图片
- 账号体系

## 3. 技术栈

| 项 | 选型 |
|---|---|
| 应用形态 | HarmonyOS Atomic Service（鸿蒙元服务） |
| 开发语言 | ArkTS |
| 架构模型 | Stage 模型 |
| UI 框架 | ArkUI 声明式 UI |
| 本地数据库 | @ohos.data.relationalStore（RDB / SQLite） |
| 文件 IO | @ohos.file.picker + @ohos.file.fs |
| 标识符生成 | util.UUID + cryptoFramework（生成 UUID v4） |
| 目标 API | HarmonyOS 6.1 配套 API（DevEco Studio 6.1+） |

## 4. 整体架构

```
┌─────────────────────────────────────────┐
│  鸿蒙元服务 (PDCA Recorder)             │
├─────────────────────────────────────────┤
│  页面层 (Pages)                         │
│   - HomePage (会议列表)                 │
│   - MeetingEditPage (新建/编辑会议)     │
│   - MeetingDetailPage (PDCA + 行动项)   │
│   - ActionItemEditPage (行动项编辑)     │
│   - SettingsPage (导入/导出)            │
├─────────────────────────────────────────┤
│  组件层 (Components)                    │
│   - MeetingCard (会议列表卡片)          │
│   - PdcaSegmentCard (P/D/C/A 段卡)      │
│   - ActionItemCard (行动项卡片)         │
│   - StatusBadge / PriorityBadge (徽章)  │
│   - EmptyState (空状态)                 │
├─────────────────────────────────────────┤
│  数据层 (Repository)                    │
│   - MeetingRepo (会议 CRUD)             │
│   - ActionItemRepo (行动项 CRUD)        │
│   - ExportService (JSON 导入导出)       │
├─────────────────────────────────────────┤
│  存储层                                 │
│   - RDB (SQLite) 本地数据库             │
└─────────────────────────────────────────┘
```

## 5. 数据模型

### 5.1 表 `meeting`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | TEXT | PK | UUID v4 |
| title | TEXT | NOT NULL | 会议主题 |
| meeting_time | INTEGER | NOT NULL | 会议时间（毫秒时间戳） |
| created_at | INTEGER | NOT NULL | 记录创建时间（系统字段） |
| updated_at | INTEGER | NOT NULL | 记录更新时间（系统字段） |
| status | TEXT | NOT NULL | `in_progress` / `completed` |
| plan | TEXT | NOT NULL DEFAULT '' | Plan 计划内容 |
| do_content | TEXT | NOT NULL DEFAULT '' | Do 执行情况 |
| check_content | TEXT | NOT NULL DEFAULT '' | Check 检查结果 |
| act_content | TEXT | NOT NULL DEFAULT '' | Act 改进措施 |
| tags | TEXT | NOT NULL DEFAULT '[]' | 标签（JSON 数组字符串） |
| notes | TEXT | DEFAULT '' | 备注 |

索引：`idx_meeting_status`(status)、`idx_meeting_time`(meeting_time DESC)

### 5.2 表 `action_item`

| 字段 | 类型 | 约束 | 说明 |
|---|---|---|---|
| id | TEXT | PK | UUID v4 |
| meeting_id | TEXT | FK→meeting.id ON DELETE CASCADE | 所属会议 |
| content | TEXT | NOT NULL | 待办内容 |
| owner | TEXT | NOT NULL DEFAULT '' | 负责人 |
| deadline | INTEGER | NOT NULL DEFAULT 0 | 截止时间戳（0 表示未设） |
| priority | TEXT | NOT NULL DEFAULT 'medium' | `high` / `medium` / `low` |
| status | TEXT | NOT NULL DEFAULT 'pending' | `pending` / `in_progress` / `completed` / `delayed` |
| order | INTEGER | NOT NULL DEFAULT 0 | 排序序号 |
| created_at | INTEGER | NOT NULL | 创建时间 |
| updated_at | INTEGER | NOT NULL | 更新时间 |

索引：`idx_action_meeting`(meeting_id)、`idx_action_status`(status)

### 5.3 关系
- 一个 Meeting 对应多个 ActionItem
- 删除 Meeting 时级联删除其 ActionItem

## 6. 页面流程

```
启动
  ↓
[HomePage 主页]
  ├─ 顶部: 标题"会议 PDCA"
  ├─ 状态筛选 Tab: 全部 / 进行中 / 已完成
  ├─ 中部: 会议卡片列表（按 meeting_time DESC）
  │    每张卡片显示: 标题、会议时间、状态徽章、行动项统计(如"3 项待办")
  ├─ 设置图标（右上角）
  └─ FAB: ➕ 新建会议
        ↓
[MeetingEditPage 新建/编辑会议]
  ├─ 标题输入
  ├─ 会议时间选择器
  ├─ PDCA 四段文本域（可折叠，默认展开 Plan）
  ├─ 标签输入（逗号分隔转 JSON 数组）
  ├─ 备注
  └─ 底部按钮: 保存 / 标记完成

[HomePage] ──点击卡片──→ [MeetingDetailPage 会议详情]
                          ├─ 顶部: 标题 + 状态徽章 + 右上角编辑/完成
                          ├─ Tab 切换: P / D / C / A / 行动项(N)
                          │   - P/D/C/A Tab: 显示对应字段文本（可点击编辑）
                          │   - 行动项 Tab: 行动项列表（按 order 排序）
                          └─ FAB: ➕ 快速添加
                                - 在 P/D/C/A Tab: 添加一段文字到当前段
                                - 在行动项 Tab: 跳转 ActionItemEditPage

[MeetingDetailPage] ──行动项 FAB 或列表点击──→ [ActionItemEditPage]
                                                    ├─ 内容
                                                    ├─ 负责人
                                                    ├─ 截止日期
                                                    ├─ 优先级 (高/中/低)
                                                    ├─ 状态 (待办/进行中/完成/延期)
                                                    └─ 保存 / 删除

[HomePage] ──设置──→ [SettingsPage]
                      ├─ 导出数据 (JSON, 选保存位置)
                      ├─ 导入数据 (JSON, 选文件 + 策略)
                      └─ 关于
```

### 6.1 核心交互
- **会中快速记录**: 详情页 FAB 在 PDCA 任一 Tab 上 → 弹出小输入框，输入文字后追加到当前段（保留原有内容，换行分隔），不离开当前页
- **会后编辑**: 详情页右上角"编辑"或长按文本 → 跳转 MeetingEditPage 全量编辑
- **会中行动项**: 行动项 Tab FAB → 跳转 ActionItemEditPage

## 7. 导入/导出

### 7.1 导出
- 触发位置: SettingsPage → 导出数据
- 流程: `picker` 选择保存目录 → 生成文件名 `pdca-backup-YYYYMMDD-HHmmss.json` → 序列化数据 → 写文件 → Toast 提示
- 序列化内容:
  ```json
  {
    "version": "1.0",
    "exportedAt": 1718234567890,
    "meetings": [ ... ],
    "actionItems": [ ... ]
  }
  ```
- 每个 meeting/actionItem 字段与表字段一一对应（毫秒时间戳、status/priority/status 枚举值不变）

### 7.2 导入
- 触发位置: SettingsPage → 导入数据
- 流程: `picker` 选 `.json` 文件 → 解析 → 校验 → 选择策略（弹窗）
  - **覆盖**: 清空 meeting 和 action_item 表 → 批量插入
  - **合并**: 按 id 去重，跳过冲突，新增剩余
- 校验:
  - 必须含 `version` 字段
  - 必须含 `meetings` 和 `actionItems` 数组
  - 不通过则 Toast 报错并终止
- 完成后 Toast 报告"成功导入 X 个会议，Y 个行动项；跳过 Z 条冲突"（合并模式）

## 8. 错误处理

| 场景 | 处理 |
|---|---|
| 数据库读写失败 | Toast 提示"保存失败，请重试"，自动重试 1 次 |
| 数据库未初始化 | 启动时检测，失败时降级到内存模式（仅本次会话）并提示"数据将不会持久化" |
| 导出写文件失败 | Toast 提示"导出失败" + 错误描述 |
| 导入 JSON 解析失败 | Toast 提示"文件格式错误" |
| 导入缺少 `version` | Toast 提示"不兼容的备份版本" |
| 导入 ID 冲突（合并） | 跳过该条，累计到报告数字 |
| 标题/内容为空 | 禁用保存按钮，输入框下方红字提示 |
| 截止日期早于今天 | 不阻止，黄色警告文字"截止日期已过" |

## 9. 边界场景 / 空状态

- **首启动空状态**: 主页无会议 → 中部显示 EmptyState（插画 + 提示"还没有会议，点击 ➕ 创建第一个" + 引导按钮）
- **行动项空状态**: 详情页行动项 Tab 无数据 → 显示 EmptyState"暂无行动项"
- **导入合并后为空**: 兼容情况，正常显示
- **跨午夜会议时间**: 允许 meeting_time 任意值，不做范围限制
- **删除会议**: 弹窗确认 → 级联删除其行动项 → Toast 提示

## 10. 测试方案

- **数据层单元测试**（如具备 ohos Test 框架）:
  - MeetingRepo: 增删改查、按状态筛选、按时间排序
  - ActionItemRepo: 增删改查、按会议 id 查询、级联删除验证
  - ExportService: 导出 → 解析 → 字段一致
  - 导入覆盖 / 合并 / 异常格式
- **手动 UI 验证**（在 DevEco Studio 中）:
  - 创建会议 → 填写 PDCA → 添加行动项 → 标记完成
  - 详情页 PDCA Tab 切换 → 快速添加文字到对应段
  - 行动项状态切换
  - 导出 → 删除全部数据 → 导入 → 数据完整恢复
  - 合并导入 → 验证跳过冲突、新增剩余

## 11. 目录结构

```
PdcaRecorder/
├── AppScope/
│   ├── app.json5
│   └── resources/
├── entry/                          # 主模块
│   ├── src/main/ets/
│   │   ├── entryability/EntryAbility.ets
│   │   ├── pages/
│   │   │   ├── HomePage.ets
│   │   │   ├── MeetingEditPage.ets
│   │   │   ├── MeetingDetailPage.ets
│   │   │   ├── ActionItemEditPage.ets
│   │   │   └── SettingsPage.ets
│   │   ├── components/
│   │   │   ├── MeetingCard.ets
│   │   │   ├── PdcaSegmentCard.ets
│   │   │   ├── ActionItemCard.ets
│   │   │   ├── StatusBadge.ets
│   │   │   ├── PriorityBadge.ets
│   │   │   └── EmptyState.ets
│   │   ├── data/
│   │   │   ├── DbHelper.ets
│   │   │   ├── MeetingRepo.ets
│   │   │   ├── ActionItemRepo.ets
│   │   │   ├── ExportService.ets
│   │   │   └── types.ts
│   │   └── common/
│   │       └── Constants.ets
│   ├── src/main/resources/
│   └── src/ohosTest/                # 测试（如有）
└── build-profile.json5
```

## 12. 后续可扩展项（YAGNI，本次不实现）

- 多设备云同步
- 富文本（行动项 / PDCA 段落）
- 附件、图片
- 提醒 / 通知
- 多人协作
- 行动项重复 / 模板
- 数据统计图表

## 13. 验收标准

- 元服务可在 HarmonyOS 6.1 设备上运行
- 主页可创建 / 编辑 / 删除会议
- 会议详情可在 4 个 PDCA Tab 间切换并查看 / 追加内容
- 可在会中添加、编辑、删除、变更状态的行动项
- 状态 / 优先级 / 标签显示对应徽章颜色
- 导出 JSON 文件结构与 §7.1 一致
- 导入支持覆盖 / 合并两种策略
- 数据持久化在本地数据库，重启后保留
- 所有空状态有明确引导
- 所有保存失败有明确错误提示
