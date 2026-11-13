# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.1] - 2026-11-13

### Changed
- 0.x addon bounds stay open through the next major. `recording_studio_accessible` is `>= 0.18.0, < 1.0`. `recording_studio_notifications` is `>= 0.14.9, < 1.0`, so `0.15.0` resolves. `recording_studio_trashable` is `>= 0.12.0, < 1.0`.
- `recording_studio` is `~> 6.0` with a floor of `>= 6.3.0`.
- Development and dummy Gemfiles pin Notifications `v0.15.0` and Flatpack `v0.1.356`. Notifications `0.15.0` requires Flatpack `>= 0.1.353`.

### Upgrade notes
- Bump to `0.5.1`. No migration.
- A host pinned to Notifications `~> 0.14.9` can use `>= 0.14.9, < 1.0`. Notifications `0.15.0` needs Flatpack `>= 0.1.353`.

## [0.5.0] - 2026-11-12

### Changed
- Signed-out Follow stays in a modal and uses Recording Studio Users 0.28.1 inline OTP. The email posts to `POST /users/otp/start`. The code step is `RecordingStudioUser::OtpCodeForm`.
- `recording_studio_user:signed_in` carries `csrf_param` and `csrf_token`. The open page posts that token to `POST /follow_sign_in` and follows once.
- The page to follow is a url-safe signed `intent` on the Users `return_to` (purpose `recording_studio_followable.follow`, 15 minutes). Users rotates the session on sign-in, so the target is not stored there.
- Finish checks Accessible `:view` on the workspace root, then `RecordingStudioFollowable.follow`. A public target still needs to be seeable. It does not need its own `:view` grant.

### Added
- `GET /follow_sign_in/setup` when the signed-in person has no usable workspace.

### Removed
- Followable's own code screen, `EmailCode`, and `GET`/`POST /follow_sign_in/verify`.
- `POST /follow_sign_in` no longer accepts an email. It finishes a follow for someone who is already signed in.

### Upgrade notes
- Breaking. Bump to `0.5.0` and pin `recording_studio_user` at tag `v0.28.1`.
- Draw Users OTP routes `otp/start`, `otp/challenge`, and `otp/resend`. `recording_studio_user_auth_for` draws them when you are not using `devise_for` for sessions. A host that already has `devise_for :users` should add those three routes beside it.
- `GET /follow_sign_in` stays open. `POST /follow_sign_in` requires a signed-in person. Drop any host links to `/follow_sign_in/verify`.
- A new address with pending Terms must tick the checkbox in the Users code box (`accept_terms=1`). Verify does not sign them in without it. An existing login does not see the box.
- Signed-in-only hosts can still skip Users. The signed-out button stays hidden when OTP start is not routed.

## [0.4.0] - 2026-11-12

### Added
- `config.button` and `follow_button(recording, follow:, following:)` set the FlatPack style, icon, and label for Follow and for Following. Omit a key to keep that part of the default. An explicit label wins over I18n. Unknown keys raise `ArgumentError`.
- Button labels are translated at `recording_studio_followable.follow_button.follow`, `.following`, and `.unfollow`.

### Changed
- Follow and the signed-out link use FlatPack style `:default`. Following stays `:secondary`.

### Upgrade notes
- Bump to `0.4.0`. Follow no longer uses the primary button, so it no longer competes with the host's main action.
- To restore the 0.3.0 primary Follow button, set `config.button = { follow: { style: :primary } }`.
- Icons stay `plus-circle`, `check-circle`, and `minus-circle` when you set nothing. Unfollow stays on `minus-circle`.
- A per-call override is posted with follow and unfollow, so a Turbo Stream replace keeps it. The signed-out link uses the Follow look.

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

[Unreleased]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.5.1...HEAD
[0.5.1]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.5.0...v0.5.1
[0.5.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.4.0...v0.5.0
[0.4.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.3.0...v0.4.0
[0.3.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bowerbird-app/RecordingStudio_followable/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bowerbird-app/RecordingStudio_followable/releases/tag/v0.1.0
