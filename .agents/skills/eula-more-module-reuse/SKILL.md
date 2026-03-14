---
name: "eula-more-module-reuse"
description: "一键复用 SwiftUI 的 More 卡片模块。用户提到复用 More 模块、迁移首页卡片区块或在新项目快速落地同款 UI 时调用。"
---

# Eula More 模块复用技能

## 目标
将 Eula 首页的 More 卡片区块快速迁移到任意 SwiftUI 项目，并保证可编译、可预览、可扩展。

## 何时调用
- 用户要求“复用 More 模块”
- 用户要求“把首页卡片区块迁移到新项目”
- 用户要求“快速生成带 Like/详情跳转/屏蔽作者的卡片网格”

## 执行规则
1. 先检查目标项目是否是 SwiftUI（存在 `import SwiftUI` 的页面文件）。
2. 默认创建以下目录（不存在则新建）：
   - `UI/Home/Components`
   - `UI/Home/Models`
   - `UI/Home`
   - `Utils`
3. 输出“可独立运行版本”，不要依赖原仓库私有类型；若项目已有同名类型，优先复用已有实现，避免重复定义。
4. 生成后必须做两步校验：
   - 编译层校验（至少检查 Swift 诊断）
   - 预览层校验（确保 `PreviewProvider` 可渲染）

## 需要生成/补齐的代码
按下列能力补齐实现（可拆分到多个文件）：

- `MoreModuleView` + `MoreCardsGridView`
  - 双列 `LazyVGrid`
  - Header（More / View all）
  - 卡片点击进入详情页
  - 根据 `BlockedUsersStore` 过滤作者

- `MoreCardView`
  - 背景图
  - Like 按钮（本地切换态 + 数字动画）
  - 底部玻璃拟态信息层
  - 右上角更多按钮（触发 ban user action）

- 支撑类型（若项目不存在则创建）
  - `MoreCardItem`（或兼容别名）
  - `BanUserTarget`
  - `BlockedUsersStore`
  - `EnvironmentValues.banUserAction`
  - `Color(hexString:)`
  - `MoreCardDetailView`（最小可运行详情页）
  - mock 内容生成（标题、followers 文案）

## 资源约定
默认资源名如下，若目标项目缺失则自动降级到纯色占位并保持布局不变：
- `more_card_1`, `more_card_2`, `more_card_3`, `more_card_4`
- `more_icon_dots`, `more_icon_heart`, `more_icon_arrow`, `heart_select`

## 接入要求
在上层页面确保注入：
- `.environmentObject(BlockedUsersStore())`
- `.environment(\.banUserAction, ...)`（可先注入空实现）

## 输出标准
- 代码风格遵循目标仓库现有风格
- 不添加无关注释
- 所有新增文件可单独打开即读
- 最终给出“新增文件清单 + 注入位置 + 校验结果”
