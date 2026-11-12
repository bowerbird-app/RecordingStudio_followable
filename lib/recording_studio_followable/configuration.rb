# frozen_string_literal: true

require "recording_studio/layout"
require "recording_studio_followable/button_appearance"

module RecordingStudioFollowable
  class Configuration
    DEFAULT_PAGE_SIZE = 25

    attr_accessor :allowed_parent_types, :followed_url, :current_root, :account_setup_url
    attr_reader :hooks, :layout, :page_size, :visibility_action, :allowed_return_origins, :button

    def initialize
      @allowed_parent_types = ["Workspace"]
      @followed_url = nil
      @current_root = nil
      @account_setup_url = nil
      @visibility_action = :"recording_studio_followable.see"
      @allowed_return_origins = []
      @layout = nil
      @page_size = DEFAULT_PAGE_SIZE
      @hooks = RecordingStudio::Hooks.new
      @button = {}.freeze
    end

    def button=(value)
      parsed = ButtonAppearance.parse(value)
      parsed.each_value(&:freeze)
      @button = parsed.freeze
    end

    def visibility_action=(value)
      @visibility_action = value.presence&.to_sym
    end

    def allowed_return_origins=(value)
      @allowed_return_origins = Array(value).filter_map { |origin| origin.to_s.downcase.presence }
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
