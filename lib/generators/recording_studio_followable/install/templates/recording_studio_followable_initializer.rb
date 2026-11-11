# frozen_string_literal: true

RecordingStudioFollowable.configure do |config|
  config.allowed_parent_types = ["Workspace"]
  # Optional. Return a path for a followed recording. Default is polymorphic_path on the recordable.
  # config.followed_url = ->(recording) { page_path(recording.recordable) }
  # The Following page and follow_button use this to find the open workspace.
  # config.current_root = ->(controller) {
  #   controller.current_root_recording if controller.respond_to?(:current_root_recording)
  # }
  # config.page_size = 25
  # Audience action Accessible uses to decide a signed-out visitor can see the target.
  # Mark a public page with audience :public for this action. Default is below.
  # config.visibility_action = :"recording_studio_followable.see"
  # Where to send someone who has no workspace after the email code. A string or a proc.
  # config.account_setup_url = "/setup"
  # Extra hosts a follow sign-in may redirect to after an embedded page. Same host is always allowed.
  # config.allowed_return_origins = ["example.com"]
end
