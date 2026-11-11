# frozen_string_literal: true

module RecordingStudio
  module Capabilities
    module Followable
      def self.to(**)
        RecordingStudio::Capabilities.include_for(:followable, **)
      end
    end
  end
end
