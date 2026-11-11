# frozen_string_literal: true

RecordingStudioTrashable.configure do |config|
  config.current_actor_resolver = lambda do |controller: nil, **|
    Current.actor
  end

  config.authorization_resolver = lambda do |actor:, recording:, **|
    next unless recording&.recordable_type == "RecordingStudioFollowable::Follow"
    next false if actor.blank?

    RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: :view)
  end
end
