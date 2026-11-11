# frozen_string_literal: true

module RecordingStudioFollowable
  class Follow < ActiveRecord::Base
    self.table_name = "recording_studio_follows"

    recording_studio_recordable label: "Follow",
                                plural_label: "Follows",
                                root: false,
                                allowed_parent_types: RecordingStudioFollowable.configuration.allowed_parent_types

    include RecordingStudio::Capabilities::Trashable.to

    def target_recording
      RecordingStudio::Recording.find_by(id: target_recording_id)
    end
  end
end
