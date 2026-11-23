# frozen_string_literal: true

module RecordingStudioFollowable
  module McpCopy
    # Reads RecordingStudioMcp.configuration.tools, the public tool registry.
    module Registry
      module_function

      def action_registered?(entry)
        matching_tools(entry).any?
      end

      def owned_by_another_tool?(entry)
        matching_tools(entry).any? { |tool| tool.name.to_s != entry.fetch(:name) }
      end

      def matching_tools(entry)
        registered_tools.select { |tool| same_type_and_action?(tool, entry) }
      end

      def registered_tools
        return [] unless McpCopy.mcp.respond_to?(:configuration)

        config = McpCopy.mcp.configuration
        return [] unless config.respond_to?(:tools)

        tools = config.tools
        return [] unless tools.respond_to?(:each_value)

        tools.each_value.select { |tool| tool.respond_to?(:target) }
      end

      def same_type_and_action?(tool, entry)
        target = tool.target
        return false unless target.respond_to?(:action?) && target.action?

        tool.type.to_s == entry.fetch(:type).to_s && target.value.to_sym == entry.fetch(:action).to_sym
      end
    end
  end
end
