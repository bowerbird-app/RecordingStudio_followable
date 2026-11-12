# Development notes

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

1. Add `recording_studio_user` (tag `v0.27.2` in the dummy) and `recording_studio_attachable` (tag `v0.22.0`). Users profiles include Attachable, so the host must load it. Neither gem is a gemspec dependency. Run `bin/rails generate recording_studio_user:migrations`. Register `RecordingStudioUser::People`, `RecordingStudioUser::Profile`, and `RecordingStudioAttachable::Attachment` as recordable types.
2. Enable OTP, call `RecordingStudioUser::Engine.apply_otp_setup!(User)`, and register a Notifications email channel. Point `otp_registration_channels` and `otp_login_channels` at that channel.
3. Configure Accessible `action_audiences` for `config.visibility_action` (`:"recording_studio_followable.see"` by default) with `:public` allowed and default `:granted`.
4. Enable `:action_audiences` on recordable types that can be public, and set those recordings' audience to `:public`.
5. Optional: `config.account_setup_url` for people with no workspace, and `config.allowed_return_origins` for a third-party parent URL after an embedded sign-in.

HTTP follow of a private item the actor cannot see now fails. It previously succeeded when the actor could view the follow root only. API `follow` no longer requires a `:view` grant on the target beyond that seeable check. `followers` and `follows` still require `:view`.

## Requirements

- Ruby 3.3 or newer
- Rails 8.1 or newer
- Recording Studio 6.3 or newer (dummy GitHub tag `v6.6.0`)
- Accessible dummy tag `v0.27.0`
- Trashable dummy tag `v0.12.3`
- Notifications dummy tag `v0.14.9`
- Root Switchable dummy tag `v0.14.0`
- Metrics dummy tag `v0.7.3`
- FlatPack dummy tag `v0.1.341`

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
