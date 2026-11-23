# frozen_string_literal: true

module RecordingStudioFollowable
  module McpCopy
    # Registers an MCP type only when another gem has not already described it.
    module Types
      module_function

      def api_actions_ready?
        return true unless defined?(::RecordingStudioMcp)
        return true unless McpCopy.mcp.equal?(::RecordingStudioMcp)
        return true unless defined?(::RecordingStudioApi)
        return true unless ::RecordingStudioApi.respond_to?(:capability_action)

        !::RecordingStudioApi.capability_action(:follow).nil?
      end

      def register_type_for(type_name)
        return unless McpCopy.mcp.respond_to?(:register_type)
        return if type_taken?(type_name)

        McpCopy.mcp.register_type(type: type_name, description: type_description(type_name))
      end

      def type_taken?(type_name)
        return false unless McpCopy.mcp.respond_to?(:configuration)

        config = McpCopy.mcp.configuration
        return false unless config.respond_to?(:type)

        !config.type(type_name).nil?
      end

      def type_description(type_name)
        label = Naming.public_type_name(type_name)
        snake = Naming.type_snake(type_name)
        "#{label} can be followed. follow_#{snake} starts a follow from a workspace."
      end
    end
  end
end
