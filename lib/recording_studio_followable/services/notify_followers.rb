# frozen_string_literal: true

module RecordingStudioFollowable
  module Services
    class NotifyFollowers
      def self.call(...)
        new(...).call
      end

      def initialize(recording, title:, body:, url:, event_key:, notification_type: :followed_update, actor: nil, **opts) # rubocop:disable Metrics/ParameterLists,Layout/LineLength
        @recording = RecordingIdentity.recording_for(recording)
        @title = title
        @body = body
        @url = url
        @event_key = event_key.to_s
        @notification_type = notification_type
        @actor = actor
        @opts = opts
      end

      def call
        raise InvalidFollow, "event_key is required" if @event_key.blank?
        raise InvalidFollow, "title is required" if @title.to_s.blank?

        FollowQuery.for_target(@recording).flat_map do |follow_recording|
          notify_follow(follow_recording)
        end
      end

      private

      def notify_follow(follow_recording)
        recipients_for(follow_recording.root_recording).map do |recipient|
          RecordingStudioNotifications.notify(**notification_attributes(follow_recording, recipient))
        end
      end

      def notification_attributes(follow_recording, recipient)
        follow_root = follow_recording.root_recording
        {
          notification_type: @notification_type, recipient: recipient, actor: @actor,
          title: @title, body: @body, url: @url, metadata: follow_metadata,
          notifiable: follow_root.recordable, recording: follow_recording, root_recording: follow_root,
          idempotency_key: idempotency_key_for(follow_recording)
        }.merge(notify_opts)
      end

      def recipients_for(follow_root)
        return [] unless defined?(RecordingStudioAccessible::AccessGrantList)

        RecordingStudioAccessible::AccessGrantList.rows_for(follow_root)
                                                  .reject(&:inherited)
                                                  .map(&:actor)
                                                  .compact
                                                  .uniq { |actor| [actor.class.name, actor.id] }
      end

      def follow_metadata
        {
          "followed_recording_id" => @recording.id,
          "followed_recordable_type" => @recording.recordable_type
        }
      end

      def idempotency_key_for(follow_recording)
        [
          "followable",
          follow_recording.root_recording_id,
          @recording.id,
          @event_key
        ].join("/")
      end

      def notify_opts
        @opts.slice(:channels, :deliver_later, :inbox)
      end
    end
  end
end
