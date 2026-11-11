RecordingStudioFollowable install complete.

Next steps:

1. Review config/initializers/recording_studio_followable.rb. Set `allowed_parent_types` to the root types that can store follows.
2. Add `RecordingStudioFollowable::Follow` to `RecordingStudio.configuration.recordable_types`.
3. Include `RecordingStudio::Capabilities::Followable.to` on types people can follow.
4. Include `RecordingStudio::Capabilities::FollowParent.to` on roots that store follows.
5. Run `bin/rails generate recording_studio_followable:migrations` then `bin/rails db:migrate`.
6. Pin `recording_studio_notifications` at v0.14.9 (or compatible) and register a `:root` notification type before calling `notify_followers`.
7. Register Page (or your followed types) and your root type with Recording Studio API so `follow`, `unfollow`, `followers`, and `follows` appear. Recording Studio MCP 0.28.0 pins `recording_studio_api >= 0.17, < 0.18`, so hosts cannot load MCP next to API 0.19 today. The HTTP actions still ship. MCP can wrap them after MCP allows API 0.19.
