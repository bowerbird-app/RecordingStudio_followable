# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowsHelper
    def follows_next_frame_id(cursor)
      "follows-page-#{cursor}"
    end
  end
end
