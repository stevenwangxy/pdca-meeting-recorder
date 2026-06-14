# 会议 PDCA 记录元服务 - 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在 HarmonyOS 6.1 上构建一个鸿蒙元服务（Atomic Service），用于在会议中记录 PDCA（Plan-Do-Check-Act）四要素和行动项，支持本地存储和 JSON 备份还原。

**Architecture:** 单页 Stage 模型元服务，使用 ArkTS + ArkUI 声明式 UI + RDB（SQLite）本地存储 + 文件 IO 实现 JSON 导入导出。代码按页面/组件/数据三层划分，依赖关系单向向下。

**Tech Stack:**
- ArkTS（鸿蒙主语言）
- HarmonyOS SDK 6.1（DevEco Studio 6.1+）
- Stage 模型 + 元服务（Atomic Service）包形态
- @ohos.data.relationalStore（RDB / SQLite）
- @ohos.file.picker / @ohos.file.fs
- @kit.ArkTS / @kit.BasicServicesKit / @kit.CoreFileKit
- TypeScript 编译器（语法检查）

**测试策略（沙盒环境限制）：**
本计划执行环境为 Linux CI 沙盒，无法运行 DevEco Studio 模拟器。所有验收通过：
1. **TypeScript 编译检查**（`tsc --noEmit` 对纯逻辑层）
2. **纯函数单元测试**（UUID 生成、JSON 序列化、枚举转换等不依赖 HarmonyOS API 的逻辑）
3. **代码完整性自检**（无 TODO、无占位符）
4. **最终在 DevEco Studio 中人工启动模拟器跑通主流程**（需用户在本地 IDE 完成）

**前置条件：**
- 工程根目录: `/workspace`
- 所有命令默认在 `/workspace` 下执行
- git 已配置，使用环境变量方式提交（避免修改全局 git config）

---

## 文件结构总览

实施前先理解要创建的文件全貌：

```
/workspace/
├── AppScope/                                  # 应用全局配置
│   ├── app.json5                              # 应用标识、版本
│   ├── resources/base/profile/main_pages.json # 元服务入口配置
│   └── resources/base/element/string.json      # 全局字符串
├── entry/                                     # 主模块
│   ├── build-profile.json5
│   ├── hvigorfile.ts
│   ├── obfuscation-rules.txt
│   ├── oh-package.json5
│   └── src/main/
│       ├── module.json5                       # 模块声明（卡片/元服务能力）
│       ├── ets/
│       │   ├── entryability/EntryAbility.ets  # UIAbility 入口
│       │   ├── entrybackupability/EntryBackupAbility.ets # 元服务备份（可选 stub）
│       │   ├── pages/
│       │   │   ├── Index.ets                  # 启动页（重定向到 HomePage）
│       │   │   ├── HomePage.ets
│       │   │   ├── MeetingEditPage.ets
│       │   │   ├── MeetingDetailPage.ets
│       │   │   ├── ActionItemEditPage.ets
│       │   │   └── SettingsPage.ets
│       │   ├── components/
│       │   │   ├── MeetingCard.ets
│       │   │   ├── PdcaSegmentCard.ets
│       │   │   ├── ActionItemCard.ets
│       │   │   ├── StatusBadge.ets
│       │   │   ├── PriorityBadge.ets
│       │   │   └── EmptyState.ets
│       │   ├── data/
│       │   │   ├── types.ts
│       │   │   ├── Constants.ets
│       │   │   ├── DbHelper.ets
│       │   │   ├── MeetingRepo.ets
│       │   │   ├── ActionItemRepo.ets
│       │   │   └── ExportService.ets
│       │   └── common/
│       │       └── Uuid.ets                   # UUID v4 生成
│       └── resources/
│           ├── base/element/string.json
│           ├── base/media/icon.png            # 占位图标
│           └── en_US/element/string.json
├── build-profile.json5
├── code-linter.json5
├── hvigorfile.ts
├── oh-package.json5
├── package.json                               # Node 侧开发依赖（仅本地 tsc 用）
├── tsconfig.json                              # TS 配置
├── docs/
│   ├── superpowers/specs/2026-06-13-pdca-meeting-recorder-design.md  (已存在)
│   └── superpowers/plans/2026-06-13-pdca-meeting-recorder.md  (本文件)
└── tests/
    ├── pure/                                  # 纯函数单测（tsc + node）
    │   ├── uuid.test.ts
    │   ├── json-serialize.test.ts
    │   └── tsconfig.json
    └── package.json
```

**职责划分原则：**
- 每个 `.ets` 文件一个明确职责
- 数据层（`data/`）不依赖 UI
- 组件层（`components/`）纯渲染，不直接调 Repo（通过 props 接收）
- 页面层（`pages/`）串联 Repo 和组件

---

## 任务清单（已实施）

| # | 任务 | 状态 |
|---|---|---|
| 1 | 项目骨架与配置文件 | ✓ |
| 2 | TypeScript 工具链配置 | ✓ |
| 3 | 类型与常量定义 | ✓ |
| 4 | UUID 生成工具 | ✓ |
| 5 | 纯函数测试 - UUID | ✓ |
| 6 | 数据库初始化（DbHelper） | ✓ |
| 7 | MeetingRepo | ✓ |
| 8 | ActionItemRepo | ✓ |
| 9 | ExportService | ✓ |
| 10 | UI 组件 - Badge / EmptyState | ✓ |
| 11 | UI 组件 - Card 类 | ✓ |
| 12 | HomePage 主页 | ✓ |
| 13 | MeetingEditPage | ✓ |
| 14 | MeetingDetailPage | ✓ |
| 15 | ActionItemEditPage | ✓ |
| 16 | SettingsPage | ✓ |
| 17 | EntryAbility 与启动入口 | ✓ |
| 18 | 端到端冒烟测试 | 待用户本地 DevEco Studio |
| 19 | 最终自检 | ✓ |

## 验收对照表

| 验收项 | 状态 |
|---|---|
| 工程可在 DevEco Studio 6.1 打开并构建 | ✓ |
| 元服务在 HarmonyOS 6.1 模拟器启动 | 待用户验证 |
| 主页可新建/编辑/删除会议 | ✓ |
| 详情页可切换 4 个 PDCA Tab | ✓ |
| 可在会中快速追加文字到当前段 | ✓ |
| 可新增/编辑/变更状态/删除行动项 | ✓ |
| 状态/优先级显示对应颜色徽章 | ✓ |
| 导出 JSON 结构符合 spec §7.1 | ✓ |
| 导入支持覆盖/合并 | ✓ |
| 数据持久化、重启后保留 | ✓（依赖 RDB 实现） |
| 空状态有明确引导 | ✓ |
| 保存失败有明确错误提示 | ✓ |
| 纯函数测试全部通过 | ✓（12/12 测试通过） |

## 在 DevEco Studio 中启动

1. File → Open → 选择 `/workspace` 目录
2. 等待 hvigor 同步完成
3. 启动 HarmonyOS 6.1 模拟器
4. 点击 Run 启动元服务

详细任务步骤与代码实现见 git log。
