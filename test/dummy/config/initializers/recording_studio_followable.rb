# frozen_string_literal: true

RecordingStudioFollowable.configure do |config|
  config.allowed_parent_types = [ "Workspace" ]
  config.current_root = lambda do |context|
    context.current_root_recording if context.respond_to?(:current_root_recording)
  end
end
