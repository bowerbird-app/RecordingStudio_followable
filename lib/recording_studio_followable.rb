# frozen_string_literal: true

require "recording_studio"
require "recording_studio_followable/version"
require "recording_studio_followable/engine"
require "recording_studio_followable/configuration"

module RecordingStudioFollowable
  class << self
    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration) if block_given?
    end
  end
end
