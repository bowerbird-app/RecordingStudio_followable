# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowQuery
    module_function

    def kept_follow_recordings
      RecordingStudio::Recording.where(RecordingStudio::Recording.recording_studio_trashable_kept_sql)
                                .of_type("RecordingStudioFollowable::Follow")
    end

    def active_for(root:, target:)
      kept_follow_recordings
        .where(root_recording_id: root.id, parent_recording_id: root.id, recordable_id: follow_ids_for(target))
        .first
    end

    def for_root(root)
      kept_follow_recordings.where(root_recording_id: root.id, parent_recording_id: root.id)
                            .order(created_at: :desc)
    end

    def for_target(target)
      kept_follow_recordings.where(recordable_id: follow_ids_for(target))
                            .order(created_at: :desc)
    end

    def follow_ids_for(target)
      Follow.where(target_recording_id: target.id).select(:id)
    end
  end
end
