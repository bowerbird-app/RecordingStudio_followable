# frozen_string_literal: true

RecordingStudioFollowable.configure do |config|
  config.allowed_parent_types = ["Workspace"]
  # Optional. Return a path for a followed recording. Default is polymorphic_path on the recordable.
  # config.followed_url = ->(recording) { page_path(recording.recordable) }
end
