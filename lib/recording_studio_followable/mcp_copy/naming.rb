# frozen_string_literal: true

module RecordingStudioFollowable
  module McpCopy
    # Public snake_case tool names, and which recordable types have opted in.
    module Naming
      module_function

      def tool_name(action, type_name)
        return ::RecordingStudioMcp::ToolName.call(type_name, action) if defined?(::RecordingStudioMcp::ToolName)

        "#{action}_#{type_snake(type_name)}"
      end

      def types_for(capability)
        return [] unless defined?(::RecordingStudio)

        config = ::RecordingStudio.configuration
        return [] unless config.respond_to?(:enabled_recordable_types_for)

        config.enabled_recordable_types_for(capability)
      end

      def warm_recordables
        return unless defined?(::RecordingStudio)

        config = ::RecordingStudio.configuration
        return unless config.respond_to?(:recordable_types)

        Array(config.recordable_types).each { |type_name| type_name.to_s.safe_constantize }
      end

      def type_snake(type_name)
        public_type_name(type_name).underscore.singularize
      end

      def public_type_name(type_name)
        registered = registered_public_name(type_name)
        return registered if registered.present?

        type_name.to_s.demodulize
      end

      def registered_public_name(type_name)
        return unless defined?(::RecordingStudioApi)
        return unless ::RecordingStudioApi.respond_to?(:recordable_registration_for)

        ::RecordingStudioApi.recordable_registration_for(type_name, api: :public)&.public_name
      end
    end
  end
end
