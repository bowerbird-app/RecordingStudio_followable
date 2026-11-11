# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module FollowParent
      def self.to(**)
        RecordingStudio::Capabilities.include_for(:follow_parent, **)
      end
    end
  end
end
