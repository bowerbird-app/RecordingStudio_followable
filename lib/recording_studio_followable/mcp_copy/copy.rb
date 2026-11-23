# frozen_string_literal: true

module RecordingStudioFollowable
  module McpCopy
    # Agent-facing titles and descriptions. HTTP OpenAPI copy lives on the
    # API specs. A host override_openapi still replaces both for that type.
    module Copy
      TITLES = {
        follow: "Follow",
        unfollow: "Unfollow",
        followers: "Followers"
      }.freeze
      DESCRIPTIONS = {
        follow:
          "A follow is a record under a workspace that points at this recording, so people in that " \
          "workspace can keep up with it. Run this on the recording you want to follow, not on a follow. " \
          "The recording must already exist and not be in the trash. Pass root_id as the workspace id " \
          "that should hold the follow. Use that workspace's id from list or show, or the id returned " \
          "when the workspace was created. A missing or trashed root_id is rejected as not found. A " \
          "blank root_id is rejected. You cannot follow a follow. If this recording is not visible to " \
          "you, the call is rejected. If that workspace already follows this recording, the call " \
          "succeeds and nothing changes. Returns the follow, with id, type, root_id, parent_id, and " \
          "target_id.",
        unfollow:
          "Unfollowing trashes the follow under that workspace that points at this recording. The " \
          "recording itself stays. Run this on the recording you followed, not on the follow. Pass " \
          "root_id as the workspace id that holds the follow. Use that workspace's id from list or " \
          "show, or the id returned when the workspace was created. A missing or trashed root_id is " \
          "rejected as not found. A blank root_id is rejected. If that workspace is not following " \
          "this recording, the call succeeds and returns unfollowed true. If it is following, the " \
          "follow is trashed and the call returns that follow, with id, type, root_id, parent_id, " \
          "and target_id.",
        followers:
          "Each item is a follow stored under a workspace that points at this recording. Run this on " \
          "the recording whose follows you want. The recording must already exist. Calling again " \
          "returns the current list. When nobody is following, the list is empty. Returns an array " \
          "of follows, each with id, type, root_id, parent_id, and target_id."
      }.freeze
      ROOT_ID =
        "The id of the workspace that holds this follow. " \
        "Use that workspace's id from list or show, or the id returned when the workspace was created. " \
        "A recording under a workspace is accepted and the follow is stored on that workspace. " \
        "A missing or trashed id is rejected as not found."

      module_function

      def for(action, type_name)
        overlay = Api::OpenapiOverrides.fetch(type_name, action)
        return { title: overlay.fetch(:title), description: overlay.fetch(:description) } if overlay

        { title: TITLES.fetch(action), description: DESCRIPTIONS.fetch(action) }
      end
    end
  end
end
