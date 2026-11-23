# frozen_string_literal: true

module RecordingStudioFollowable
  # Named MCP tools for the follow actions. This gem does not depend on
  # Recording Studio MCP. Hosts that skip MCP keep the UI and API.
  #
  # The tools are typeless: follow, unfollow, followers, and follows. The
  # caller passes type and id. They are not follow_<type>, because the
  # actions apply to whatever the host marks followable or follow_parent.
  # A host gem that owns one type can still register its own tool, such as
  # follow_press_center. That name does not clash with follow.
  #
  # override_openapi still changes OpenAPI and openapi_for for one type.
  # MCP describe reads that per-type copy. These named tools keep the shared
  # description, because one tool serves every followable type.
  module McpCopy
    ACTIONS = %i[follow unfollow followers follows].freeze
    TARGET_ACTIONS = %i[follow unfollow followers].freeze
    TARGET_TYPE = "Type of the recording this action runs on. Use the type from list or show."
    TARGET_ID = "Recording id of that recording. Take it from list or show. The recording must already exist."
    WORKSPACE_TYPE = "Type of the workspace that stores follows. Use the type from list or show."
    WORKSPACE_ID = "Recording id of that workspace. Take it from list or show. The workspace must already exist."
    OUTPUTS = {
      follow:
        "The follow, with id, type, root_id, parent_id, and target_id. " \
        "If this workspace already follows the recording, that same follow comes back.",
      unfollow:
        "The trashed follow, with id, type, root_id, parent_id, and target_id. " \
        "When this workspace is not following, unfollowed is true.",
      followers:
        "An array of follows that point at this recording. Each has id, type, root_id, " \
        "parent_id, and target_id. The array is empty when nobody is following.",
      follows:
        "An array of follows stored in this workspace. Each has id, type, root_id, " \
        "parent_id, and target_id. The array is empty when this workspace follows nothing."
    }.freeze

    module_function

    def mcp_available?
      defined?(::RecordingStudioMcp) && ::RecordingStudioMcp.respond_to?(:register_tool)
    end

    def mcp
      ::RecordingStudioMcp
    end

    def register!
      # Gem tests load this file without RecordingStudioMcp. Dummy and hosts
      # that include the gem already have it. Api.register! calls this before
      # Rails finisher, so the tools exist when MCP catalog validate! runs.
      # The same name, with the same action and no type, can be registered again.
      return unless mcp_available?

      ACTIONS.each { |action| register_action_tool(action) }
    end

    def tool_names
      ACTIONS.map(&:to_s)
    end

    def register_action_tool(action)
      mcp.register_tool(
        name: action.to_s,
        action: action,
        title: title_for(action),
        description: description_for(action),
        input: protocol_input(action),
        output: OUTPUTS.fetch(action)
      )
    end

    def title_for(action)
      spec = followable_spec(action)
      return spec.fetch(:title) if spec

      "Follows"
    end

    def description_for(action)
      spec = followable_spec(action)
      return spec.fetch(:description) if spec

      Api::FOLLOWS_DESCRIPTION
    end

    def protocol_input(action)
      if TARGET_ACTIONS.include?(action)
        { "type" => { description: TARGET_TYPE }, "id" => { description: TARGET_ID } }
      else
        { "type" => { description: WORKSPACE_TYPE }, "id" => { description: WORKSPACE_ID } }
      end
    end

    def followable_spec(action)
      Api::FOLLOWABLE_ACTION_SPECS.find { |spec| spec.fetch(:name) == action }
    end
  end
end
