# frozen_string_literal: true

module RecordingStudioFollowable
  class Error < StandardError; end
  class NotAuthorized < Error; end
  class InvalidFollow < Error; end
end
