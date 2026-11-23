# frozen_string_literal: true

return unless defined?(RecordingStudioMcp)

Rails.application.config.to_prepare do
  names = RecordingStudioFollowable::McpCopy.tool_names
  next unless names.all? { |name| RecordingStudioMcp.configuration.tool(name) }

  RecordingStudioMcp.register_server(:public, api: :public) do
    include_tools(*names)
  end
end
