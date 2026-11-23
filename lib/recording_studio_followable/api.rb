# frozen_string_literal: true

begin
  require "recording_studio_api"
rescue LoadError
  # Hosts may load Followable without Recording Studio API.
end

require "recording_studio_followable/api/actions"
require "recording_studio_followable/api/followable_action_specs"
require "recording_studio_followable/api/openapi_overrides"
require "recording_studio_followable/mcp_copy"

module RecordingStudioFollowable
  module Api
    ACTION_VERSION = "1.0.0"

    module_function

    def register! # rubocop:disable Metrics/MethodLength
      return unless defined?(RecordingStudioApi)
      return unless RecordingStudioApi.respond_to?(:register_capability_action)

      FOLLOWABLE_ACTION_SPECS.each { |spec| register_followable_action(spec) }

      relax_target_role!("follow")
      relax_target_role!("unfollow")

      register_action(
        :follows,
        capability: :follow_parent,
        http_verb: :get,
        handler: Actions::Follows,
        input_contract: { reject_unknown: true, fields: {} },
        openapi: {
          summary: "List follows stored in this workspace",
          description: FOLLOWS_DESCRIPTION
        }
      )

      McpCopy.register!
    end

    def register_followable_action(spec)
      register_action(
        spec.fetch(:name),
        capability: :followable,
        http_verb: spec.fetch(:http_verb),
        handler: spec.fetch(:handler),
        input_contract: { reject_unknown: true, fields: spec.fetch(:fields) },
        openapi: followable_openapi(spec),
        openapi_for: ->(type:, action:) { OpenapiOverrides.fetch(type, spec_for!(action).fetch(:name)) }
      )
    end

    def override_openapi(type:, action:, title:, description:)
      OpenapiOverrides.store(type: type, action: action, title: title, description: description)
    end

    def openapi_for(type:, action:)
      spec = spec_for!(action)
      base = followable_openapi(spec)
      overlay = OpenapiOverrides.fetch(type, spec.fetch(:name))
      overlay ? base.merge(overlay) : base
    end

    def spec_for!(action)
      name = OpenapiOverrides.known_action!(action)
      FOLLOWABLE_ACTION_SPECS.find { |spec| spec.fetch(:name) == name }
    end

    def followable_openapi(spec)
      openapi = {
        title: spec.fetch(:title),
        summary: spec.fetch(:summary),
        description: spec.fetch(:description)
      }
      fields = spec.fetch(:fields)
      openapi[:request_body] = followable_request_body(fields) if fields.any?
      openapi
    end

    def followable_request_body(fields)
      {
        required: true,
        content: {
          "application/json" => { schema: followable_request_schema(fields) }
        }
      }
    end

    def followable_request_schema(fields)
      {
        type: "object",
        required: fields.select { |_name, field| field[:required] }.keys.map(&:to_s),
        properties: fields.transform_values { |field| { type: "string", description: field[:description] } }
      }
    end

    def relax_target_role!(name)
      return unless defined?(RecordingStudioApi)

      config = RecordingStudioApi.configuration
      return if config.capability_action_role_resolver.respond_to?(:call)

      roles = config.capability_action_roles
      return if roles.key?(name) || roles.key?(name.to_sym)

      roles[name] = nil
    end

    def register_action(name, **)
      return if RecordingStudioApi.capability_action(name)

      RecordingStudioApi.register_capability_action(
        name,
        version: ACTION_VERSION,
        required_role: :view,
        scope: :member,
        serializer: ->(payload, **) { payload },
        **
      )
    end
  end
end
