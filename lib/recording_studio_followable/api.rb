# frozen_string_literal: true

begin
  require "recording_studio_api"
rescue LoadError
  # Hosts may load Followable without Recording Studio API.
end

require "recording_studio_followable/api/actions"

module RecordingStudioFollowable
  module Api
    ACTION_VERSION = "1.0.0"

    module_function

    def register! # rubocop:disable Metrics/MethodLength
      return unless defined?(RecordingStudioApi)
      return unless RecordingStudioApi.respond_to?(:register_capability_action)

      register_action(
        :follow,
        capability: :followable,
        http_verb: :post,
        handler: Actions::Follow,
        input_contract: {
          reject_unknown: true,
          fields: {
            root_id: { type: :string, required: true }
          }
        },
        openapi: {
          summary: "Follow this item from a workspace",
          request_body: {
            required: true,
            content: {
              "application/json" => {
                schema: {
                  type: "object",
                  required: ["root_id"],
                  properties: {
                    root_id: { type: "string", description: "Workspace to keep the follow in" }
                  }
                }
              }
            }
          }
        }
      )

      register_action(
        :unfollow,
        capability: :followable,
        http_verb: :post,
        handler: Actions::Unfollow,
        input_contract: {
          reject_unknown: true,
          fields: {
            root_id: { type: :string, required: true }
          }
        },
        openapi: {
          summary: "Stop following this item from a workspace"
        }
      )

      relax_target_role!("follow")
      relax_target_role!("unfollow")

      register_action(
        :followers,
        capability: :followable,
        http_verb: :get,
        handler: Actions::Followers,
        input_contract: { reject_unknown: true, fields: {} },
        openapi: {
          summary: "List follows that point at this item"
        }
      )

      register_action(
        :follows,
        capability: :follow_parent,
        http_verb: :get,
        handler: Actions::Follows,
        input_contract: { reject_unknown: true, fields: {} },
        openapi: {
          summary: "List follows stored in this workspace"
        }
      )
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
