# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.2.0] - 2026-11-11

### Added
- `RecordingStudioFollowable::Follow` recordable. It stores `target_recording_id` under a host root.
- `follow`, `unfollow`, `follows`, and `followers` services, plus matching API capability actions (`:followable` on the target, `:follow_parent` on the root). MCP uses the same actions.
- `RecordingStudioFollowable.notify_followers` (Ruby only). Notifications set `recording` to the Follow, `root_recording` to the Follow's root, and `notifiable` to that root's recordable. Recipients are direct Accessible grants on that root.
- Dummy ping action and Notifications inbox, using the gem `follow_button` helper.
- `follow_target_url(recording)` plus optional `config.followed_url`. Default is `polymorphic_path` on the followed recordable.
- Engine `follows` routes and `follow_button(recording)`. Follow is a Flatpack button with `plus-circle`. Following is a Flatpack dropdown with `check-circle` and Unfollow (`minus-circle`). Turbo Stream replaces the button. HTML redirects back.
- Engine Following page at `GET /follows`. One `FlatPack::List` with `FlatPack::Link` titles and `follow_button` on each row. Keyset pages (`config.page_size`, default 25) load through `FlatPack::PaginationInfinite`. `RecordingStudioFollowable.follows` accepts optional `limit` and `cursor`. `config.current_root` supplies the open workspace.

### Changed
- Requires Recording Studio 6.3 or newer and pins Notifications `~> 0.14.9`.
- Dummy home keeps one page title. Dummy Following is the mounted engine page. Dummy skips unused `RecordingStudioApi::AdminApi` so CI eager-load declaration checks pass.

### Upgrade notes
- Bump to `0.2.0`. Run the followable and notifications migrations.
- Add `RecordingStudioFollowable::Follow` to `recordable_types`.
- Include `Followable` on types people follow and `FollowParent` on roots that store follows.
- Register a `:root` notification type before calling `notify_followers`.
- Point `authorize_write` (and Follow trash) at Accessible `:view` on the follow root if anyone with access should manage Follows.
- Mount the engine and call `follow_button(recording)` for the turnkey button. The Following page is `GET …/follows` on that mount.
- Set `config.current_root` so the engine can read the open workspace (dummy uses `current_root_recording`).
- Optional `config.followed_url` when `follow_target_url` cannot use `polymorphic_path`.
- Optional `config.page_size` (default 25) for the Following page.
- Do not call `notify_followers` over the API. It is host Ruby only.
- Inherited Accessible grants are not notified in v1.
- Keep `title` and `body` free of secrets. Inbox access is the Follow root, not the followed item.

## [0.1.0] - 2026-11-11

### Added
- Initial `recording_studio_followable` engine copied from RecordingStudio_gem_template and renamed.
- Dummy host app for Recording Studio, Devise, and FlatPack wiring.

### Notes
- Follow features are coming soon. This version does not ship a follow API, models, or public helpers.

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_followable/releases/tag/v0.1.0
