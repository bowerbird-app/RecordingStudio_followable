# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowButtonComponent < ViewComponent::Base
    def self.frame_id(target:, root:)
      "follow-button-#{target.id}-#{root&.id || 'guest'}"
    end

    def initialize(target:, root:, following:, follow_url:, unfollow_url:, sign_in_url: nil, embedded: false) # rubocop:disable Lint/MissingSuper, Metrics/ParameterLists
      @target = target
      @root = root
      @following = following
      @follow_url = follow_url
      @unfollow_url = unfollow_url
      @sign_in_url = sign_in_url
      @embedded = embedded
    end

    def frame_id
      self.class.frame_id(target: target, root: root)
    end

    private

    attr_reader :target, :root, :following, :follow_url, :unfollow_url, :sign_in_url, :embedded

    def following?
      following
    end

    def sign_in?
      sign_in_url.present? && !following?
    end

    def embedded?
      embedded
    end

    def request_url
      query = { target_id: target.id, root_id: root.id }.to_query
      separator = unfollow_url.include?("?") ? "&" : "?"
      "#{unfollow_url}#{separator}#{query}"
    end
  end
end
