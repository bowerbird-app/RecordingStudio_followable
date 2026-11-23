# frozen_string_literal: true

module RecordingStudioFollowable
  module McpCopy
    # Public snake_case tool names, and which recordable types have opted in.
    module Naming
      module_function

      def tool_name(action, type_name)
        ::RecordingStudioMcp::ToolName.call(type_name, action)
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
    end
  end
end
