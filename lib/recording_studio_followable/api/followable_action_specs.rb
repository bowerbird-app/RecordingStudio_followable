# frozen_string_literal: true

module RecordingStudioFollowable
  module Api
    ROOT_ID_FIELD = {
      type: :string,
      required: true,
      description:
        "Recording id of the workspace that stores the follow. " \
        "A recording under that workspace is accepted and the follow is stored on the workspace. " \
        "A missing or trashed id is 404 not_found."
    }.freeze

    FOLLOWABLE_ACTION_SPECS = [
      {
        name: :follow,
        http_verb: :post,
        handler: Actions::Follow,
        title: "Follow a recording",
        summary: "Create a follow from a workspace.",
        description:
          "POST /api/v1/{resource}/{id}/actions/follow. Path id is the recording. " \
          "JSON body requires root_id, the workspace recording id that stores the follow. " \
          "200 returns the follow as id, type, root_id, parent_id, and target_id, " \
          "including when that workspace already follows it. " \
          "403 is error code forbidden when the caller cannot see the recording. " \
          "404 is error code not_found when the path id or root_id is missing or trashed. " \
          "422 is error code invalid_input when root_id is omitted, blank, or the body has an unknown field.",
        fields: { root_id: ROOT_ID_FIELD }
      },
      {
        name: :unfollow,
        http_verb: :post,
        handler: Actions::Unfollow,
        title: "Unfollow a recording",
        summary: "Trash the follow from a workspace.",
        description:
          "POST /api/v1/{resource}/{id}/actions/unfollow. Path id is the followed recording. " \
          "JSON body requires root_id, the workspace recording id that holds the follow. " \
          "200 returns the trashed follow as id, type, root_id, parent_id, and target_id, " \
          "or unfollowed true when that workspace is not following. " \
          "403 is error code forbidden when the caller cannot see the recording. " \
          "404 is error code not_found when the path id or root_id is missing or trashed. " \
          "422 is error code invalid_input when root_id is omitted, blank, or the body has an unknown field.",
        fields: { root_id: ROOT_ID_FIELD }
      },
      {
        name: :followers,
        http_verb: :get,
        handler: Actions::Followers,
        title: "List recording followers",
        summary: "List follows that point at a recording.",
        description:
          "GET /api/v1/{resource}/{id}/actions/followers. Path id is the recording. No request body. " \
          "200 returns an array of follows that point at it, each with id, type, root_id, parent_id, and target_id. " \
          "The array is empty when nobody is following. " \
          "403 is error code forbidden when the caller cannot see the recording. " \
          "404 is error code not_found when the path id is missing or trashed. " \
          "422 is error code invalid_input when the request has an unknown field.",
        fields: {}
      }
    ].freeze

    # HTTP description for the follows action. MCP does not register this action.
    FOLLOWS_DESCRIPTION =
      "GET /api/v1/{resource}/{id}/actions/follows. Path id is the workspace. No request body. " \
      "200 returns an array of follows stored there, each with id, type, root_id, parent_id, and target_id. " \
      "The array is empty when the workspace follows nothing. " \
      "403 is error code forbidden when the caller cannot see the workspace. " \
      "404 is error code not_found when the path id is missing or trashed. " \
      "422 is error code invalid_input when the request has an unknown field."
    FOLLOWS_TITLE = "List workspace follows"
    FOLLOWS_SUMMARY = "List follows stored on a workspace."
  end
end
