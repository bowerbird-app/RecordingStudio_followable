# frozen_string_literal: true

module RecordingStudioFollowable
  class Configuration
    attr_accessor :allowed_parent_types, :followed_url
    attr_reader :hooks

    def initialize
      @allowed_parent_types = ["Workspace"]
      @followed_url = nil
      @hooks = RecordingStudio::Hooks.new
    end

    def to_h
      {
        allowed_parent_types: allowed_parent_types,
        hooks_registered: hooks.instance_variable_get(:@registry).transform_values(&:size)
      }
    end

    def merge!(hash)
      return unless hash.respond_to?(:each)

      hash.each do |k, v|
        key = k.to_s
        setter = "#{key}="
        public_send(setter, v) if respond_to?(setter)
      end
    end
  end
end
