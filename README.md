# Recording Studio Followable

`recording_studio_followable` lets a workspace follow an item that lives anywhere in Recording Studio. A Follow is a Recording Studio item stored under that workspace. It only points at the followed item. People with access to the workspace can add, change, or remove Follows. Accessible owns those grants. This gem does not add a second permission system.

Host code decides when followers should hear about something. Call `notify_followers` from Ruby. That method is not on the HTTP API or MCP.

## Install

Add the gem and a compatible Notifications pin:

```ruby
gem "recording_studio_followable", github: "bowerbird-app/RecordingStudio_followable"
gem "recording_studio_notifications", github: "bowerbird-app/RecordingStudio_notifications", tag: "v0.14.9"
```

Then:

```bash
bundle install
bin/rails generate recording_studio_followable:install
bin/rails generate recording_studio_followable:migrations
bin/rails generate recording_studio_notifications:migrations
bin/rails db:migrate
```

Requires Recording Studio 6.3 or newer.

## Host setup

1. Set `allowed_parent_types` to the root types that store follows (usually `Workspace`).
2. Add `RecordingStudioFollowable::Follow` to `RecordingStudio.configuration.recordable_types`.
3. On types people can follow:

```ruby
include RecordingStudio::Capabilities::Followable.to
```

4. On roots that store follows:

```ruby
include RecordingStudio::Capabilities::FollowParent.to
```

5. Let Accessible `:view` on the follow root create and trash Follows. Dummy `authorize_write` treats Follow creates as `:view`. Trashable on Follow also uses `:view`.
6. Mount the engine (`generate recording_studio_followable:install` does this). Then render `follow_button(recording)` on a host page. The helper uses the current root and actor, and the button updates in place over Turbo. Without JavaScript it redirects back. The Following page is `GET` on the mount's `/follows`. Set `config.current_root` to the open workspace (dummy uses `current_root_recording`). `follow_target_url(recording)` is the path for a followed item. It uses `polymorphic_path` on the recordable. Set `config.followed_url` when the host path is different. `config.page_size` (default 25) is the Following page slice. `FlatPack::PaginationInfinite` fetches the next slice as you scroll. See Button look to change the style, icon, or label.
7. Register a Notifications type with `scope: :root` before you call `notify_followers`. Dummy registers `:followed_update`.
8. Register the followed type and the root type with Recording Studio API so `follow`, `unfollow`, `followers`, and `follows` appear. Do not register `notify_followers`. Recording Studio MCP exposes the same capability actions once the host pins a MCP gem that accepts your API version. MCP 0.28.0 still requires API `< 0.18`, so this dummy pins API 0.19 without MCP.

## Follow API

```ruby
RecordingStudioFollowable.follow(target: page_recording, root: workspace_recording, actor: current_user)
RecordingStudioFollowable.unfollow(target: page_recording, root: workspace_recording, actor: current_user)
RecordingStudioFollowable.follows(root: workspace_recording, actor: current_user)
RecordingStudioFollowable.follows(root: workspace_recording, actor: current_user, limit: 25, cursor: next_cursor)
RecordingStudioFollowable.followers(recording: page_recording, actor: current_user)
```

`target` and `root` can be a Recording Studio recording or the recordable it wraps. The Follow always sits under the root, like a list. Follow and unfollow are idempotent. One kept Follow exists per root and target.

Without `limit`, `follows` returns the full relation, newest first (`created_at`, then `id`). With `limit`, it returns a `FollowsPage` of that slice plus `next_cursor` for the next keyset page.

The actor needs Accessible `:view` on the follow root to create, list, or remove Follows. Listing a recording's followers also needs `:view` on that recording. Listing follows needs `:view` on the follow root.

Following the item itself uses a seeable check. A kept Accessible `:view` grant counts. A public page also counts, with no grant, when Accessible's audience for `config.visibility_action` (default `:"recording_studio_followable.see"`) is `:public`. A private item the actor cannot see is refused. The same check is used by `follow_button`, the HTTP follow action, and the API/MCP `follow` handler. `followers` and `follows` stay on `:view`. The API gem still only routes a member action to a recording inside the credential's accessible scope. The handler no longer adds a second `:view` grant check on the target. `unfollow` still needs `:view` on the follow root only.

## Button look

Follow uses FlatPack style `:default`, icon `plus-circle`, and the label Follow. Following uses style `:secondary`, icon `check-circle`, and the label Following. Unfollow stays `minus-circle`. The signed-out link uses that same Follow look. A Turbo Stream replace uses it too.

Set a global default, a per-call override, or both. Omit a key to keep that part of the default. A label you pass wins over the translation. Unknown keys raise `ArgumentError`.

```ruby
RecordingStudioFollowable.configure do |config|
  config.button = {
    follow: { style: :ghost, icon: "plus-circle", label: "Watch" },
    following: { style: :ghost, icon: "check-circle", label: "Watching" }
  }
end
```

```ruby
follow_button(recording, root: workspace, follow: { style: :primary }, following: { label: "Saved" })
```

Translations are `recording_studio_followable.follow_button.follow`, `.following`, and `.unfollow`.

To restore the 0.3.0 primary Follow button:

```ruby
config.button = { follow: { style: :primary } }
```

A per-call override is sent with the follow and unfollow request, so the Turbo Stream replace keeps it.

## Signed-out follow

`follow_button` renders for a signed-out visitor when the target is publicly seeable. The button looks like Follow (`plus-circle`) and opens an email-code sign-in. The code path uses Recording Studio Users (`request_otp!`, `verify_otp!`, `complete_email_proof!`) and then Devise/Warden. This gem does not depend on Recording Studio Messages.

Add the Users gem in the host app. It is not a dependency of this gemspec, so signed-in-only hosts can skip it. Users profiles include Attachable, so the host also needs that gem. This gemspec does not depend on either one.

```ruby
gem "recording_studio_attachable", github: "bowerbird-app/RecordingStudio_attachable", tag: "v0.22.0"
gem "recording_studio_user", github: "bowerbird-app/RecordingStudio_users", tag: "v0.27.2"
```

Then:

```bash
bin/rails generate recording_studio_user:migrations
bin/rails db:migrate
```

```ruby
RecordingStudioUser.configure do |config|
  config.otp_enabled = true
  config.otp_registration_channels = %i[email]
  config.otp_login_channels = %i[email]
end

RecordingStudioNotifications.channels.register(:email, email_adapter)

Rails.application.config.to_prepare do
  RecordingStudioUser::Engine.apply_otp_setup!(User)
end

RecordingStudioAccessible.configuration.action_audiences[:"recording_studio_followable.see"] = {
  allowed: %i[public signed_in granted],
  default: :granted,
  granted_roles: %i[view],
  granted_override: true
}
```

Enable `:action_audiences` on types that can be public, and mark those recordings with audience `:public` for `config.visibility_action`. A page with no audience rule stays at the default, which is a `:view` grant.

Register `RecordingStudioUser::People`, `RecordingStudioUser::Profile`, and `RecordingStudioAttachable::Attachment` in `recordable_types`. OTP delivery needs a registered email channel. The code itself is stored on the Users challenge. The email adapter only has to deliver the notification.

The follow is stored on `config.current_root` after sign-in. That is the workspace the person is signed into. A new account with no usable workspace does not get a Follow. The engine renders "Finish setting up your account first", or redirects to `config.account_setup_url` when that is set.

Inside a third-party iframe (`Sec-Fetch-Dest: iframe`) the button opens sign-in in a new tab (`target="_blank"`) so the code step can set a first-party cookie. A same-origin Turbo frame uses `data-turbo-frame="_top"`. After sign-in the visitor returns to an allowlisted parent URL (`config.allowed_return_origins`), otherwise the page they were on, otherwise the canonical followed URL. Same-host URLs are allowed. Other absolute URLs are not.

Routes, mounted with the engine:

- `GET /follow_sign_in`
- `POST /follow_sign_in`
- `GET /follow_sign_in/verify`
- `POST /follow_sign_in/verify`

Skip the host's signed-in filter on those routes. The engine skips `authenticate_user!` when the host defines it.

## notify_followers

Ruby only:

```ruby
RecordingStudioFollowable.notify_followers(
  page_recording,
  title: "New kit",
  body: "A kit is up.",
  url: published_kit_path,
  event_key: "kit-created-#{kit.id}",
  actor: current_user,
  deliver_later: true
)
```

For each kept Follow of that item, this gem calls `RecordingStudioNotifications.notify` with `recording` set to the Follow, `root_recording` set to the Follow's root, and `notifiable` set to that root's recordable. Pointing `recording` or `notifiable` at the followed item fails `RootResolver.consistent?` when the item lives in another workspace. Passing the Follow recording as `notifiable` also fails, because Notifications treats `notifiable` as a recordable and Follow is not a root. The followed item is only in `url:` and in metadata (`followed_recording_id`, `followed_recordable_type`). The inbox keys off the Follow root.

Recipients are actors with a **direct** Accessible grant on the Follow's root. Inherited grants are out of scope for v1.

The idempotency key is `followable/{follow_root_id}/{followed_recording_id}/{event_key}`. Notifications already unique that key per recipient. Two workspaces following the same item keep two inbox rows.

`title` and `body` must not be sensitive. Inbox visibility only checks access to the Follow's root. Someone with workspace access can read the notice even if they cannot open the followed item.

## Dummy host app

`test/dummy` signs in at `/users/sign_in` with `admin@admin.com` / `Password`.

Dummy screenshots from this version:

![Follow](docs/screenshots/follow-button.png)
![Following](docs/screenshots/following-button.png)
![Watching, ghost style on a page](docs/screenshots/follow-button-override.png)
![Following list](docs/screenshots/follows-list.png)
![Inbox notice](docs/screenshots/notification-inbox.png)

- Home: one title and `follow_button` for Getting Started, using the default look
- A page show uses `follow: { style: :ghost, label: "Watch" }` and `following: { style: :ghost, label: "Watching" }`
- Following dropdown: Unfollow with `minus-circle`
- `/recording_studio_followable/follows`: engine Following page, one divided `FlatPack::List`, titles link, each row uses `follow_button`, `PaginationInfinite` as you scroll
- `/notifications`: inbox from Recording Studio Notifications

Alice (`alice@example.com`), Bob, and Charlie share Client Workspace. Getting Started lives in Studio Workspace.

## Version

The gem version is `0.4.0`.
