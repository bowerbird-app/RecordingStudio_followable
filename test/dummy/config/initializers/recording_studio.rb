# frozen_string_literal: true

RecordingStudioFollowable.configure do |config|
  config.allowed_parent_types = [ "Workspace" ]
end

RecordingStudio.configure do |config|
  config.recordable_types = [
    "Workspace",
    "Folder",
    "Page",
    "RecordingStudioFollowable::Follow",
    "RecordingStudioUser::People",
    "RecordingStudioUser::Profile",
    "RecordingStudioAttachable::Attachment"
  ]

  config.require_recordable_declarations = true

  config.app_name = "Followable" if config.respond_to?(:app_name=)

  config.actor = -> { Current.actor }

  config.event_notifications_enabled = true

  config.idempotency_mode = :return_existing

  config.recordable_dup_strategy = :dup

  config.authorize_write = lambda do |actor:, recordable:, parent_recording:, **|
    next false if actor.blank?
    next true if parent_recording.nil?
    next true unless defined?(RecordingStudioAccessible)

    role = recordable.is_a?(RecordingStudioFollowable::Follow) ? :view : :edit
    next true if RecordingStudioAccessible.authorized?(actor: actor, recording: parent_recording, role: role)

    RecordingStudioAccessible::AccessGrantList.rows_for(parent_recording).none?
  end
end
