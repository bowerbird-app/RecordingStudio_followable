# frozen_string_literal: true

RecordingStudioNotifications.configure do |config|
  config.actor_resolver = -> { Current.actor }
  config.current_root_resolver = lambda do |controller:|
    controller.send(:current_root_recording) if controller.respond_to?(:current_root_recording, true)
  end

  config.notification_types.register(
    :followed_update,
    label: "Followed page",
    category: :activity,
    description: "Something happened on a page this workspace follows.",
    icon: :bell,
    default_channels: [ :in_app ],
    available_channels: %i[in_app],
    allowed_cadences: [ :individual ],
    default_cadence: :individual,
    scope: :root
  )
end

RecordingStudioNotifications.channels.register(:email, RecordingStudioNotifications::Channels::InAppAdapter.new)
