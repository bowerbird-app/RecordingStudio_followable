RecordingStudioFollowable install complete.

Next steps:

1. Review config/initializers/recording_studio_followable.rb. Set `allowed_parent_types` to the root types that can store follows.
2. Add `RecordingStudioFollowable::Follow` to `RecordingStudio.configuration.recordable_types`.
3. Include `RecordingStudio::Capabilities::Followable.to` on types people can follow.
4. Include `RecordingStudio::Capabilities::FollowParent.to` on roots that store follows.
5. Run `bin/rails generate recording_studio_followable:migrations` then `bin/rails db:migrate`.
6. Mount is already in `config/routes.rb`. On a host page, render `follow_button(recording)`. The helper uses the current workspace and signed-in person. Follow and Unfollow update the button in place. Without JavaScript they redirect back. The Following page is `GET` `/follows` on the mount. Set `config.current_root` to the open workspace. `follow_target_url(recording)` uses `polymorphic_path` on the recordable. Set `config.followed_url` when that is not the host path. `config.page_size` defaults to 25. The list uses a divided `FlatPack::List` and `FlatPack::PaginationInfinite`. Optional `config.button`, or `follow:` and `following:` on the helper, set the FlatPack style, icon, and label. The default Follow style is `:default`. Set `config.button = { follow: { style: :primary } }` to restore the old primary Follow button.
7. Pin `recording_studio_notifications` at v0.14.9 (or compatible) and register a `:root` notification type before calling `notify_followers`.
8. Register Page (or your followed types) and your root type with Recording Studio API so `follow`, `unfollow`, `followers`, and `follows` appear. Recording Studio MCP 0.28.0 pins `recording_studio_api >= 0.17, < 0.18`, so hosts cannot load MCP next to API 0.19 today. The HTTP actions still ship. MCP can wrap them after MCP allows API 0.19.
