# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.3.0] - 2026-11-11

### Added
- Signed-out `follow_button` on a publicly seeable item. The button matches Follow (`plus-circle`) and starts an email-code sign-in.
- Email-code routes under the engine mount. The code uses Recording Studio Users (`request_otp!`, `verify_otp!`, `complete_email_proof!`) and Devise/Warden. Messages is not a dependency.
- `config.visibility_action` (default `:"recording_studio_followable.see"`), `config.account_setup_url`, and `config.allowed_return_origins`.
- Setup state when the signed-in person has no usable workspace. No Follow is created, and the host can redirect with `account_setup_url`.
- Iframe sign-in opens in a new tab. A same-origin Turbo frame breaks out to the top window.

### Changed
- Follow allows any target the actor can see. A `:view` grant still counts. A public Accessible audience for `visibility_action` counts with no grant. A private target without access is refused on the helper, the HTTP follow action, and the API/MCP `follow` handler.
- API `follow` and `unfollow` no longer pre-authorize `:view` on the target. `followers` and `follows` still require `:view`.

### Upgrade notes
- Bump to `0.3.0`. Signed-in follow of an item the actor can already see stays the same.
- To show Follow to signed-out visitors, add `recording_studio_user`, enable OTP, configure the Accessible audience action, enable `:action_audiences` on public types, and set those recordings to audience `:public`.
- Set `config.account_setup_url` when a new account should leave the setup page for the host's own setup flow.
- Set `config.allowed_return_origins` when an embedded follow should return to a third-party parent URL. Same-host return URLs work without that list.
- Do not call `notify_followers` over HTTP, the API, or MCP.

## [0.2.0] - 2026-11-11

### Added
- `RecordingStudioFollowable::Follow` recordable. It stores `target_recording_id` under a host root.
- `follow`, `unfollow`, `follows`, and `followers` services, plus matching API capability actions (`:followable` on the target, `:follow_parent` on the root). MCP uses the same actions.
- `RecordingStudioFollowable.notify_followers` (Ruby only). Notifications set `recording` to the Follow, `root_recording` to the Follow's root, and `notifiable` to that root's recordable. Recipients are direct Accessible grants on that root.
- Dummy ping action and Notifications inbox, using the gem `follow_button` helper.
- `follow_target_url(recording)` plus optional `config.followed_url`. Default is `polymorphic_path` on the followed recordable.
- Engine `follows` routes and `follow_button(recording)`. Follow is a Flatpack button with `plus-circle`. Following is a Flatpack dropdown with `check-circle` and Unfollow (`minus-circle`). Turbo Stream replaces the button. HTML redirects back.
- Engine Following page at `GET /follows`. One divided `FlatPack::List` with `FlatPack::Link` titles and `follow_button` on each row. Keyset pages (`config.page_size`, default 25) load through `FlatPack::PaginationInfinite`. `RecordingStudioFollowable.follows` accepts optional `limit` and `cursor`. `config.current_root` supplies the open workspace.

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_followable/releases/tag/v0.1.0
