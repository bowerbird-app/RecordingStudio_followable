# frozen_string_literal: true

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
