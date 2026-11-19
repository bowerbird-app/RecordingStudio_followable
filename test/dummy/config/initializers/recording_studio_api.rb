# frozen_string_literal: true

# Users 0.32 registers PATCH users_update with scope_id: false and no required_role.
# API 1.21 rejects that at boot. Register the same endpoint first, with :edit,
# so Users sees it and skips its own registration. Users stays on v0.32.0.
if defined?(RecordingStudioApi) && defined?(RecordingStudioUser::Api)
  RecordingStudioApi.register_endpoint(
    RecordingStudioUser::Api::USERS_UPDATE_ENDPOINT,
    api: RecordingStudioUser::Api::USERS_API,
    http_verb: :patch,
    path: RecordingStudioUser::Api::USER_PATH,
    handler: RecordingStudioUser::Api::Update,
    openapi: {
      tags: ["Users"],
      summary: "Update a user",
      description: RecordingStudioUser::Api::Registration.update_description
    },
    input_contract: RecordingStudioUser::Api::Params.update_input_contract,
    scope_id: false,
    required_role: :edit
  )
end

if defined?(RecordingStudioApi)
  RecordingStudioApi.register_recordable_type_api(
    "Page",
    serializer: ->(page, **) { { title: page.title } },
    output_keys: %i[title],
    operations: %i[index show]
  )

  RecordingStudioApi.register_recordable_type_api(
    "Workspace",
    serializer: ->(workspace, **) { { name: workspace.name } },
    output_keys: %i[name],
    operations: %i[index show]
  )
end
