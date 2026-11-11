# frozen_string_literal: true

require "recording_studio"
require "recording_studio_accessible"
require "recording_studio_trashable"
require "recording_studio_notifications"
require "recording_studio_followable/version"
require "recording_studio_followable/engine"
require "recording_studio_followable/configuration"
require "recording_studio_followable/errors"
require "recording_studio_followable/recording_identity"
require "recording_studio_followable/authorization"
require "recording_studio_followable/follow_query"
require "recording_studio_followable/services/follow"
require "recording_studio_followable/services/unfollow"
require "recording_studio_followable/services/list_follows"
require "recording_studio_followable/services/list_followers"
require "recording_studio_followable/services/notify_followers"
require "recording_studio_followable/capabilities/followable"
require "recording_studio_followable/capabilities/follow_parent"
require "recording_studio_followable/api"

module RecordingStudioFollowable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end

    def follow(target:, root:, actor:)
      Services::Follow.call(target: target, root: root, actor: actor)
    end

    def unfollow(target:, root:, actor:)
      Services::Unfollow.call(target: target, root: root, actor: actor)
    end

    def follows(root:, actor:, limit: nil, cursor: nil)
      Services::ListFollows.call(root: root, actor: actor, limit: limit, cursor: cursor)
    end

    def followers(recording:, actor:)
      Services::ListFollowers.call(recording: recording, actor: actor)
    end

    def notify_followers(recording, title:, body:, url:, **)
      Services::NotifyFollowers.call(recording, title: title, body: body, url: url, **)
    end
  end
end

RecordingStudio.register_capability(:followable, source: "recording_studio_followable")
RecordingStudio.register_capability(:follow_parent, source: "recording_studio_followable")
