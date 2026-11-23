# frozen_string_literal: true

require_relative "mcp_copy/naming"
require_relative "mcp_copy/types"

module RecordingStudioFollowable
  # Named MCP tools for the follow actions. This gem does not depend on
  # Recording Studio MCP. Hosts that skip MCP keep the UI and API.
  #
  # Each tool is per type: follow_<type>, unfollow_<type>, and
  # followers_<type> for types that include Followable. The suffix is the
  # public snake_case name from that type's API registration (Recording
  # Studio MCP ToolName). The Follow recordable gets no tools. FollowParent
  # roots get no follows_<type> tool: that action lists Follow records.
  # Typeless follow, unfollow, followers, and follows are not registered.
  #
  # A name another gem already registered is left alone. Press Centers
  # registers follow_press_center and unfollow_press_center for PressCenter
  # on to_prepare, after this gem's early register. That later register is
  # the same type and action, so Press Centers keeps its copy. This gem
  # does not register again afterwards, and a second call here skips a name
  # that is already present.
  #
  # override_openapi changes the title and description of that type's tool.
  # notify_followers stays off MCP.
  module McpCopy
    TARGET_ACTIONS = %i[follow unfollow followers].freeze
    FOLLOW_RECORDABLE = "RecordingStudioFollowable::Follow"
    TYPELESS_NAMES = %w[follow unfollow followers follows].freeze
    TARGET_ID = "Recording id of that recording. Take it from list or show. The recording must already exist."
    OUTPUTS = {
      follow:
        "The follow, with id, type, root_id, parent_id, and target_id. " \
        "If this workspace already follows the recording, that same follow comes back.",
      unfollow:
        "The trashed follow, with id, type, root_id, parent_id, and target_id. " \
        "When this workspace is not following, unfollowed is true.",
      followers:
        "An array of follows that point at this recording. Each has id, type, root_id, " \
        "parent_id, and target_id. The array is empty when nobody is following."
    }.freeze

    module_function

    def mcp_available?
      defined?(::RecordingStudioMcp) && ::RecordingStudioMcp.respond_to?(:register_tool)
    end

    def mcp
      ::RecordingStudioMcp
    end

    def register!
      return unless mcp_available?
      return unless Types.api_actions_ready?

      Naming.warm_recordables
      tool_entries.each { |entry| register_entry(entry) }
    end

    def register_entry(entry)
      Types.register_type_for(entry.fetch(:type))
      return if tool_taken?(entry.fetch(:name))

      mcp.register_tool(**tool_registration(entry))
    end

    def tool_names
      tool_entries.map { |entry| entry.fetch(:name) }
    end

    def tool_entries
      followable_entries
    end

    def followable_entries
      followable_types.flat_map do |type_name|
        TARGET_ACTIONS.map { |action| entry_for(action, type_name) }
      end
    end

    def followable_types
      Naming.types_for(:followable).reject { |type_name| type_name == FOLLOW_RECORDABLE }
    end

    def entry_for(action, type_name)
      {
        name: Naming.tool_name(action, type_name),
        type: type_name,
        action: action
      }
    end

    def tool_name(action, type_name)
      Naming.tool_name(action, type_name)
    end

    def tool_registration(entry)
      action = entry.fetch(:action)
      copy = copy_for(action, entry.fetch(:type))
      entry.merge(registration_copy(action, copy))
    end

    def registration_copy(action, copy)
      {
        title: copy.fetch(:title),
        description: copy.fetch(:description),
        input: protocol_input(action),
        output: OUTPUTS.fetch(action)
      }
    end

    def tool_taken?(name)
      return false unless mcp.respond_to?(:configuration)

      config = mcp.configuration
      return false unless config.respond_to?(:tool)

      !config.tool(name).nil?
    end

    def copy_for(action, type_name)
      openapi = Api.openapi_for(type: type_name, action: action)
      { title: openapi.fetch(:title), description: openapi.fetch(:description) }
    end

    def protocol_input(action)
      input = { "id" => { description: TARGET_ID } }
      field = followable_spec(action)&.dig(:fields, :root_id)
      input["root_id"] = { description: field.fetch(:description) } if field
      input
    end

    def followable_spec(action)
      Api::FOLLOWABLE_ACTION_SPECS.find { |spec| spec.fetch(:name) == action }
    end
  end
end
