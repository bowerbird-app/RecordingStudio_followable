# frozen_string_literal: true

module RecordingStudioFollowable
  class FollowButtonComponent < ViewComponent::Base
    # ViewComponent::Base does not require super for keyword attrs.
    def initialize(target:, root:, following:, follow_url:, unfollow_url:) # rubocop:disable Lint/MissingSuper
      @target = target
      @root = root
      @following = following
      @follow_url = follow_url
      @unfollow_url = unfollow_url
    end

    private

    attr_reader :target, :root, :following, :follow_url, :unfollow_url

    def following?
      following
    end
  end
end
