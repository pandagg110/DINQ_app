---
name: mobile-only-migration
description: Migrate code from @.example/DINQ_client-main into the current project for mobile platforms only. Use when the user asks for code migration and requires iOS/Android support while keeping PC/Web/Desktop code untouched.
disable-model-invocation: true
---

# Mobile-Only Migration

## Goal

When migrating from `@.example/DINQ_client-main`, only migrate code that is required for mobile runtime (`Android` and `iOS`). Do not modify PC/Web/Desktop implementation.

## Source And Target

- Source project: `@.example/DINQ_client-main`
- Target project: current workspace root

## Hard Rules

1. Only migrate code that is platform-agnostic (`lib/`) or mobile-specific (`android/`, `ios/`).
2. Do not add, edit, or delete desktop/web implementation in target project.
3. If source logic mixes mobile and desktop concerns in the same file, split and migrate mobile-safe parts only.
4. If a requested migration strictly depends on desktop/web behavior, stop and ask user for confirmation before proceeding.

## Allowed Migration Scope

- `lib/` business logic usable on mobile
- `lib/` UI pages/components intended for phone layout
- `android/` config required by migrated mobile plugins/features
- `ios/` config required by migrated mobile plugins/features
- `pubspec.yaml` dependencies needed by migrated mobile code

## Forbidden Migration Scope

- `windows/`
- `linux/`
- `macos/`
- `web/`
- Desktop-specific branches guarded by `Platform.isWindows`, `Platform.isLinux`, `Platform.isMacOS`
- Desktop-only plugins and build settings

## Migration Workflow

Use this checklist for every migration task:

- [ ] Identify requested feature/module in source `@.example/DINQ_client-main`
- [ ] Classify each change as mobile-safe, shared, or desktop/web-only
- [ ] Migrate shared + mobile-safe code only
- [ ] Verify no changes were made under `windows/`, `linux/`, `macos/`, `web/`
- [ ] Verify desktop branches were not introduced into target `lib/`
- [ ] Report what was migrated and what was intentionally excluded

## Decision Rules

- If a dependency supports mobile and desktop, keep usage mobile-scoped in code paths.
- If a file contains both mobile and desktop logic, keep only mobile path and remove desktop entry points from migrated snippet.
- If there is uncertainty whether code is desktop-related, treat it as out-of-scope and ask user.

## Response Format

When finishing migration work, always summarize with:

1. Migrated mobile/shared files
2. Excluded desktop/web files or code paths
3. Any blockers requiring user decision
