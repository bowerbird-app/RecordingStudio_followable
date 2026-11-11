# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowButtonComponent < ViewComponent::Base
    def self.frame_id(target:, root:)
      "follow-button-#{target.id}-#{root.id}"
    end

    def initialize(target:, root:, following:, follow_url:, unfollow_url:) # rubocop:disable Lint/MissingSuper
      @target = target
      @root = root
      @following = following
      @follow_url = follow_url
      @unfollow_url = unfollow_url
    end

    def frame_id
      self.class.frame_id(target: target, root: root)
    end

    private

    attr_reader :target, :root, :following, :follow_url, :unfollow_url

    def following?
      following
    end

    def request_url
      query = { target_id: target.id, root_id: root.id }.to_query
      separator = unfollow_url.include?("?") ? "&" : "?"
      "#{unfollow_url}#{separator}#{query}"
    end
  end
end
