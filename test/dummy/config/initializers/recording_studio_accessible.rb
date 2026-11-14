# frozen_string_literal: true

RecordingStudioAccessible.configure do |config|
  config.access_actor_types = [ "User" ]
  config.access_management_actor_scope = ->(_controller) { User.order(:email) }
  config.action_audiences[:"recording_studio_followable.see"] = {
    allowed: %i[public signed_in granted],
    default: :granted,
    granted_roles: %i[view],
    granted_override: true
  }
end
