# frozen_string_literal: true

require "base64"

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
                            .order(created_at: :desc, id: :desc)
    end

    def page_for_root(root, limit:, cursor: nil)
      scope = after_cursor(for_root(root), cursor)
      records = scope.limit(limit + 1).to_a
      has_more = records.size > limit
      records = records.first(limit)
      next_cursor = has_more ? encode_cursor(records.last) : nil
      [records, next_cursor]
    end

    def for_target(target)
      kept_follow_recordings.where(recordable_id: follow_ids_for(target))
                            .order(created_at: :desc, id: :desc)
    end

    def follow_ids_for(target)
      Follow.where(target_recording_id: target.id).select(:id)
    end

    def encode_cursor(record)
      Base64.urlsafe_encode64("#{record.created_at.utc.iso8601(6)} #{record.id}", padding: false)
    end

    def decode_cursor(cursor)
      return if cursor.blank?

      stamp, id = Base64.urlsafe_decode64(cursor).split(" ", 2)
      return if stamp.blank? || id.blank?

      [Time.iso8601(stamp), id]
    rescue ArgumentError
      nil
    end

    def after_cursor(scope, cursor)
      decoded = decode_cursor(cursor)
      return scope if decoded.blank?

      created_at, id = decoded
      scope.where(
        "(created_at < ?) OR (created_at = ? AND id < ?)",
        created_at, created_at, id
      )
    end
  end
end
