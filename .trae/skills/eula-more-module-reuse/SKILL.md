---
name: "eula-more-module-reuse"
description: "Reuse the SwiftUI More card module in one step. Use when users request More-module reuse, home-card migration, or fast rollout of the same UI in a new project."
---

# Eula More Module Reuse Skill

## Goal
Quickly migrate the More card section from the Eula home page into any SwiftUI project while keeping it compilable, previewable, and extensible.

## When To Use
- The user requests "reuse the More module"
- The user requests "migrate the home card section to a new project"
- The user requests "quickly generate a card grid with likes, detail navigation, and author blocking"

## Execution Rules
1. First verify the target project is SwiftUI-based (there are view files with `import SwiftUI`).
2. Create the following directories by default if they do not exist:
   - `UI/Home/Components`
   - `UI/Home/Models`
   - `UI/Home`
   - `Utils`
3. Output a standalone runnable version; do not depend on private types from the source repository. If same-named types already exist, reuse existing implementations first to avoid duplication.
4. Always run two validations after generation:
   - Compile-level validation (at minimum, check Swift diagnostics)
   - Preview-level validation (ensure `PreviewProvider` renders correctly)

## Code To Generate Or Complete
Implement the following capabilities (can be split into multiple files):

- `MoreModuleView` + `MoreCardsGridView`
  - Two-column `LazyVGrid`
  - Header (More / View all)
  - Card tap navigates to detail page
  - Filter authors based on `BlockedUsersStore`

- `MoreCardView`
  - Background image
  - Like button (local toggle state + number animation)
  - Bottom glass-style information layer
  - Top-right more button (triggers ban user action)

- Supporting types (create if missing in the target project)
  - `MoreCardItem` (or a compatible alias)
  - `BanUserTarget`
  - `BlockedUsersStore`
  - `EnvironmentValues.banUserAction`
  - `Color(hexString:)`
  - `MoreCardDetailView` (minimal runnable detail page)
  - Mock content generation (title and followers copy)

## Asset Conventions
Use the following asset names by default. If any are missing in the target project, automatically fall back to solid-color placeholders while preserving layout:
- `more_card_1`, `more_card_2`, `more_card_3`, `more_card_4`
- `more_icon_dots`, `more_icon_heart`, `more_icon_arrow`, `heart_select`

## Integration Requirements
Ensure the parent view injects:
- `.environmentObject(BlockedUsersStore())`
- `.environment(\.banUserAction, ...)` (a no-op implementation can be injected first)

## Output Standards
- Follow the existing code style of the target repository
- Do not add unrelated comments
- Ensure each new file is self-readable when opened alone
- Provide a final report with "new files list + injection locations + validation results"
