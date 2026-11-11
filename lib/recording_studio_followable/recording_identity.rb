# frozen_string_literal: true

module RecordingStudioFollowable
  module RecordingIdentity
    module_function

    def recording_for(value)
      return value if value.is_a?(RecordingStudio::Recording)
      raise InvalidFollow, "a recording is required" if value.blank?

      RecordingStudio::Recording.find_by!(recordable: value)
    end

    def follow_root_for(value)
      recording = recording_for(value)
      return recording if recording.parent_recording_id.nil?

      recording.root_recording
    end
  end
end
