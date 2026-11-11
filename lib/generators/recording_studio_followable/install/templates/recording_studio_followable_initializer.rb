# frozen_string_literal: true

RecordingStudioFollowable.configure do |config|
  config.allowed_parent_types = ["Workspace"]
  # Optional. Return a path for a followed recording. Default is polymorphic_path on the recordable.
  # config.followed_url = ->(recording) { page_path(recording.recordable) }
  # The Following page and follow_button use this to find the open workspace.
  # config.current_root = ->(controller) { controller.current_root_recording if controller.respond_to?(:current_root_recording) }
  # config.page_size = 25
end
