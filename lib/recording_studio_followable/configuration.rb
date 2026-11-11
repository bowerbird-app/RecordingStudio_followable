# frozen_string_literal: true

require "recording_studio/layout"

module RecordingStudioFollowable
  class Configuration
    DEFAULT_PAGE_SIZE = 25

    attr_accessor :allowed_parent_types, :followed_url, :current_root
    attr_reader :hooks, :layout, :page_size

    def initialize
      @allowed_parent_types = ["Workspace"]
      @followed_url = nil
      @current_root = nil
      @layout = nil
      @page_size = DEFAULT_PAGE_SIZE
      @hooks = RecordingStudio::Hooks.new
    end

    def layout=(value)
      @layout = RecordingStudio::Layout.accept(value)
    end

    def page_size=(value)
      size = Integer(value)
      raise ArgumentError, "page_size must be at least 1" if size < 1

      @page_size = size
    end

    def resolve_current_root(context)
      current_root&.call(context)
    end

    def to_h
      {
        allowed_parent_types: allowed_parent_types,
        page_size: page_size,
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
