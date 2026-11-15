# Development notes

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

## Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 6.14 or newer (dummy GitHub tag `v6.14.0`)
- Accessible dummy tag `v0.42.0`
- Trashable dummy tag `v0.16.0` (`Recording.kept`)
- Notifications dummy tag `v0.15.0`
- Root Switchable dummy tag `v0.15.0` (mounted switch page needs Accessible `:view` on the current root)
- Metrics dummy tag `v0.8.0`
- FlatPack dummy tag `v0.1.356`

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
