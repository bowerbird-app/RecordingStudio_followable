# Development notes

## Host upgrade to 0.10.2

No Followable migration. The gemspec does not depend on Recording Studio MCP.

`recording_studio_followable.register_api` runs before `:run_prepare_callbacks`, which runs before `:finisher_hook`. `Api.register!` registers the API actions and, when MCP is loaded, tools only for types that include Followable: `follow_<type>`, `unfollow_<type>`, and `followers_<type>`. The suffix is the type's public snake_case name. The Follow recordable gets no tools. FollowParent roots get no `follows_<type>` tool, because that action lists Follow records. Typeless `follow`, `unfollow`, `followers`, and `follows` are not registered. A name that is already present is skipped. `to_prepare` registers again once recordable classes are loaded. Press Centers registers `follow_press_center` and `unfollow_press_center` for the same type and action. Whichever gem registers that name first keeps the slot; the later call with the same type and action updates copy, and a call that finds the name already present skips it. A host `to_prepare` block can include the tool names.

Include `RecordingStudioFollowable::McpCopy.tool_names` on the MCP server. Pin MCP `~> 0.45.2`. Leave `capability_action` off that server when these named tools cover the follow actions. `notify_followers` stays off HTTP and MCP.

`override_openapi` still sets the OpenAPI title and description for one type. MCP describe reads `openapi_for`. That type's named tool uses the same title and description.

Development Gemfiles pin API `v1.21.3` and MCP `v0.45.2`. The dummy also pins Oauth `v0.25.1` and Site Settings `v0.6.0`. Dummy security pins are Puma `>= 8.1.2`, net-ssh `>= 7.3.10`, rack-protection `>= 4.2.2`, Brakeman `8.1.1`, and Ruby `3.3.14`.

## Host upgrade to 0.10.1

No Followable migration. The engine registers Followable API capability actions (`RecordingStudioFollowable::Api.register!`) from `recording_studio_followable.register_api` before `:finisher_hook`. That runs before Rails `after_initialize` callbacks, including Recording Studio MCP catalog `validate!`. Calling `register!` more than once is a no-op for actions already present.

## Host upgrade to 0.10.0

No Followable migration. Gemspec floors are unchanged.

Hosts MUST run the Recording Studio 7.4, 7.5 and 7.7 migrations if they have not.

flat_pack 0.2.0 is supported; hosts moving to 0.2 must remove the manual `flat_pack/heroicons` importmap pin and any `flat-pack--icon` controller registration.

Development Gemfiles pin Recording Studio `v7.8.0`, Flatpack `v0.2.0`, Accessible `v0.58.0`, API `v1.21.2`, Icons `v0.5.0`, Logs `v0.9.0`, Metrics `v0.10.0`, Moveable `v6.1.0`, Notifications `v0.21.0`, and Trashable `v1.3.0`. The dummy also pins Admin `v2.20.0`, Attachable `v0.34.0`, Cache `v0.8.0`, and Root Switchable `v0.17.0`. Users stays `v0.32.0`.

## Host upgrade to 0.9.0

No Followable migration. The Recording Studio API pin stays `v1.2.1`.

Call `RecordingStudioFollowable::Api.override_openapi(type:, action:, title:, description:)` to set the OpenAPI title and description for `follow`, `unfollow`, or `followers` on one recordable type. Pass the recordable class name MCP sends as `recordable_type`, for example `RecordingStudioPressCenters::PressCenter`. MCP 0.36.5 reads the override from `openapi_for(type:, action:)`. Shared titles stay Follow, Unfollow, and Followers when that type has no override. An unknown action name raises `ArgumentError`. `notify_followers` stays off HTTP and MCP.

## Host upgrade to 0.8.1

No Followable migration. MCP and OpenAPI text for `follow`, `unfollow`, and `followers` changed. Action names and fields did not.

## Host upgrade to 0.7.0

Breaking. No Followable migration. Require Recording Studio `>= 7.0, < 8.0`, Accessible `>= 0.44.0`, Notifications `>= 0.18.0`, and Trashable `>= 0.17.0`.

`RecordingStudio.root_recording_for` only finds a root and returns `nil` when there is none. Create a root with `RecordingStudio.create_root_recording!(recordable, actor:)`. A later call returns that root and does not append another event.

Set `config.authorize_write`. Do not set `allow_unauthorized_writes`. Root creation calls that callback with `parent_recording: nil`. The dummy callback allows that when an actor is present, and it still treats a Follow create as Accessible `:view` on the follow root.

Follow access is unchanged. The actor needs `:view` on the follow root. The target must be seeable. Lookups use `Recording.kept`.

Users 0.30 defaults `minimum_password_length` to 12. The dummy sets it to 6 so the seeded password still signs in. Attachable stays at `v0.23.0`.

## Host upgrade to 0.6.1

No migration. `recording_studio` is `>= 6.14.0, < 8.0`. This release does not require core 7. Development lockfiles stay on Recording Studio `v6.14.0`.

## Host upgrade to 0.6.0

No Followable migration. Require Recording Studio `>= 6.14.0`, Trashable `>= 0.16.0`, and Accessible `>= 0.42.0`. Follow lookups use `Recording.kept`. A trashed target or follow root cannot be followed. `Follow#target_recording` is nil when the target is trashed, and the Following page skips that row.

Accessible 0.36 requires `config.access_management_actor_scope`. The dummy sets it to `User.order(:email)`.

Hosts that are not already on Recording Studio 6.9 need core migration `20261114090000_add_root_recording_id_to_recording_studio_events` before writing events.

## Host upgrade to 0.5.1

Runtime bounds for the 0.x addons are open through `< 1.0`. Notifications accepts `>= 0.14.9, < 1.0`. No migration. Notifications `0.15.0` needs Flatpack `>= 0.1.353` (dummy pins `v0.1.356`).

## Host upgrade to 0.5.0

Signed-out Follow no longer has its own code screen. Pin `recording_studio_user` at tag `v0.28.1`. The `v0.27.2` pin in the 0.3.0 notes is out of date.

1. Draw the Users inline OTP routes. If `devise_for :users` already owns sign-in, add these beside it. Do not replace Devise.

```ruby
scope module: "recording_studio_user/auth", path: "users" do
  post "otp/start", to: "otp_challenges#create", as: :recording_studio_user_otp_start
  get "otp/challenge", to: "otp_challenges#show", as: :recording_studio_user_otp_challenge
  post "otp/challenge", to: "otp_challenges#submit"
  post "otp/resend", to: "otp_challenges#resend", as: :recording_studio_user_otp_resend
end

scope module: "recording_studio_user/auth", path: "auth" do
  post "otp/challenge", to: "otp_challenges#submit"
  post "otp/resend", to: "otp_challenges#resend"
end
```

The email form posts to `/users/otp/start`. The code box is rendered by the Users controller, and that render uses the engine paths `/auth/otp/challenge` and `/auth/otp/resend`. Draw both. `recording_studio_user_auth_for` draws the `/users` routes when it owns sign-in. It does not draw the `/auth` posts. Add those beside it.

2. Remove bookmarks and links to `GET` or `POST /follow_sign_in/verify`. `POST /follow_sign_in` now finishes a follow. It does not accept an email.
3. Leave `authenticate_user!` off for `GET /follow_sign_in`. The engine already skips it. Keep the filter on `POST /follow_sign_in`.
4. A new email with pending Terms sees the Users checkbox. The host does not add that box. Verify fails closed until the form sends `accept_terms=1`.
5. `config.allowed_return_origins` and `config.account_setup_url` stay. An iframe still opens sign-in in a new tab.

## Host upgrade to 0.4.0

Follow and the signed-out link use FlatPack style `:default`. Following stays `:secondary`. Icons are unchanged. To restore the 0.3.0 primary Follow button:

```ruby
RecordingStudioFollowable.configure do |config|
  config.button = { follow: { style: :primary } }
end
```

Per-call overrides use the same keys. `follow_button(recording, follow: { style:, icon:, label: }, following: { style:, icon:, label: })`. A label you pass wins over `recording_studio_followable.follow_button`. Unknown keys raise `ArgumentError`.

## Host upgrade to 0.3.0

Signed-in follow of an item the person can already see does not change. Hosts that want signed-out Follow on a public page need to:

1. Add `recording_studio_user` (tag `v0.28.1` in the dummy) and `recording_studio_attachable` (tag `v0.23.0`). Users profiles include Attachable, so the host must load it. Neither gem is a gemspec dependency. Run `bin/rails generate recording_studio_user:migrations`. Register `RecordingStudioUser::People`, `RecordingStudioUser::Profile`, and `RecordingStudioAttachable::Attachment` as recordable types.
2. Enable OTP, call `RecordingStudioUser::Engine.apply_otp_setup!(User)`, and register a Notifications email channel. Point `otp_registration_channels` and `otp_login_channels` at that channel.
3. Configure Accessible `action_audiences` for `config.visibility_action` (`:"recording_studio_followable.see"` by default) with `:public` allowed and default `:granted`.
4. Enable `:action_audiences` on recordable types that can be public, and set those recordings' audience to `:public`.
5. Optional: `config.account_setup_url` for people with no workspace, and `config.allowed_return_origins` for a third-party parent URL after an embedded sign-in.

HTTP follow of a private item the actor cannot see now fails. It previously succeeded when the actor could view the follow root only. API `follow` no longer requires a `:view` grant on the target beyond that seeable check. `followers` and `follows` still require `:view`.

## Dummy password accounts

Users 0.31 refuses password sign-in until the account is confirmed. Seeded password users are confirmed so `admin@admin.com` / `Password` still signs in. One-time-code sign-up stays unconfirmed until the code step.

## Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 7 (dummy GitHub tag `v7.8.0`)
- Accessible dummy tag `v0.58.0`
- Trashable dummy tag `v1.3.0` (`Recording.kept`)
- Notifications dummy tag `v0.21.0`
- Root Switchable dummy tag `v0.17.0` (mounted switch page needs Accessible `:view` on the current root)
- Metrics dummy tag `v0.10.0`
- Logs dummy tag `v0.9.0`
- Cache dummy tag `v0.8.0`
- Icons dummy tag `v0.5.0`
- Moveable dummy tag `v6.1.0`
- Attachable dummy tag `v0.34.0`
- API dummy tag `v1.21.2`
- Admin dummy tag `v2.20.0`
- Users dummy tag `v0.32.0` (signed-out follow)
- FlatPack dummy tag `v0.2.0`

## Verification

```bash
bundle install
BUNDLE_GEMFILE=test/dummy/Gemfile bundle install
bundle exec rake test:all
```

Run the dummy host from `test/dummy`:

```bash
cd test/dummy
bin/dev
```
