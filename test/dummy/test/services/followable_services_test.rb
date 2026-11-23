# frozen_string_literal: true

require "test_helper"

class FollowableServicesTest < ActiveSupport::TestCase
  setup do
    @admin = users("admin@admin.com")
    @alice = users("alice@example.com")
    @bob = users("bob@example.com")
    @charlie = users("charlie@example.com")
    @stranger = users("stranger@example.com")

    Current.actor = @admin
    @studio = RecordingStudio.create_root_recording!(Workspace.create!(name: "Studio #{SecureRandom.hex(4)}"), actor: @admin)
    @client = RecordingStudio.create_root_recording!(Workspace.create!(name: "Client #{SecureRandom.hex(4)}"), actor: @admin)
    bootstrap(@studio, @admin)
    bootstrap(@client, @admin)
    grant(@client, @alice, :admin)
    grant(@client, @bob, :edit)
    grant(@client, @charlie, :view)
    grant(@studio, @alice, :view)

    @page = Page.create!(title: "Kit #{SecureRandom.hex(4)}")
    @page_recording = RecordingStudio.record!(
      action: "created",
      recordable: @page,
      root_recording: @studio,
      parent_recording: @studio
    ).recording
  end

  teardown do
    Current.actor = nil
  end

  test "a trashed target is not returned and cannot be followed through the API root lookup" do
    follow_recording = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    RecordingStudioTrashable.void_recording!(@page_recording)

    assert_nil follow_recording.recordable.target_recording

    context = Struct.new(:recording, :access_grant, :actor, :params).new(
      @page_recording,
      nil,
      @alice,
      { root_id: @client.id }
    )
    RecordingStudioTrashable.void_recording!(@client)

    assert_raises(ActiveRecord::RecordNotFound) do
      RecordingStudioFollowable::Api::Actions::Follow.call(context)
    end
  end

  test "follow stores a pointer under the follow root for a target in another root" do
    follow_recording = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)

    assert_equal @client, follow_recording.root_recording
    assert_equal @client, follow_recording.parent_recording
    assert_equal @page_recording.id, follow_recording.recordable.target_recording_id
    assert_equal @studio, @page_recording.root_recording
    refute_equal @studio.id, follow_recording.root_recording_id
  end

  test "follow is idempotent for the same root and target" do
    first = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    second = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)

    assert_equal first.id, second.id
    assert_equal 1, RecordingStudioFollowable.follows(root: @client, actor: @alice).count
  end

  test "unfollow then follow again creates a kept follow" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    RecordingStudioFollowable.unfollow(target: @page_recording, root: @client, actor: @alice)

    assert_empty RecordingStudioFollowable.follows(root: @client, actor: @alice)

    again = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    refute again.recording_studio_trashable_trashed?
    assert_equal 1, RecordingStudioFollowable.follows(root: @client, actor: @alice).count
  end

  test "anyone with access to the follow root can follow and unfollow" do
    publish(@page_recording)
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @charlie)
    RecordingStudioFollowable.unfollow(target: @page_recording, root: @client, actor: @bob)

    assert_empty RecordingStudioFollowable.follows(root: @client, actor: @alice)
  end

  test "a private page without access is refused" do
    assert_raises(RecordingStudioFollowable::NotAuthorized) do
      RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @charlie)
    end

    assert_empty RecordingStudioFollowable.follows(root: @client, actor: @alice)
  end

  test "a public page can be followed without a grant on that page" do
    RecordingStudioAccessible.set_audience!(
      recording: @page_recording,
      action: :"recording_studio_followable.see",
      audience: :public,
      actor: @admin
    )

    follow_recording = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @charlie)

    assert_equal @page_recording.id, follow_recording.recordable.target_recording_id
    assert_raises(RecordingStudioFollowable::NotAuthorized) do
      RecordingStudioFollowable.followers(recording: @page_recording, actor: @charlie)
    end
  end

  test "a stranger cannot follow into a root they cannot see" do
    assert_raises(RecordingStudioFollowable::NotAuthorized) do
      RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @stranger)
    end
  end

  test "a public page in another root is followed under the actor's workspace" do
    publish(@page_recording)
    follow_recording = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @charlie)

    assert_equal @client.id, follow_recording.root_recording_id
    assert_equal @page_recording.id, follow_recording.recordable.target_recording_id
  end

  test "followers lists follow recordings for a target" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    RecordingStudioFollowable.follow(target: @page_recording, root: @studio, actor: @admin)

    ids = RecordingStudioFollowable.followers(recording: @page_recording, actor: @admin).map(&:root_recording_id)
    assert_includes ids, @client.id
    assert_includes ids, @studio.id
  end

  test "follows with limit returns a page and a cursor for the rest" do
    %w[One Two Three].each do |title|
      page = Page.create!(title: "#{title} #{SecureRandom.hex(4)}")
      recording = RecordingStudio.record!(
        action: "created",
        recordable: page,
        root_recording: @studio,
        parent_recording: @studio
      ).recording
      RecordingStudioFollowable.follow(target: recording, root: @client, actor: @alice)
    end

    first = RecordingStudioFollowable.follows(root: @client, actor: @alice, limit: 2)
    rest = RecordingStudioFollowable.follows(root: @client, actor: @alice, limit: 2, cursor: first.next_cursor)

    assert_equal 2, first.records.size
    assert first.next_cursor.present?
    assert_equal 1, rest.records.size
    assert_nil rest.next_cursor
    refute_equal first.records.map(&:id), rest.records.map(&:id)
  end

  test "follows lists only the requested root" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    RecordingStudioFollowable.follow(target: @page_recording, root: @studio, actor: @admin)

    client_ids = RecordingStudioFollowable.follows(root: @client, actor: @alice).map(&:root_recording_id)
    assert_equal [ @client.id ], client_ids.uniq
  end

  test "notify_followers writes one inbox row per follow root and skips inherited-only people" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)

    notifications = RecordingStudioFollowable.notify_followers(
      @page_recording,
      title: "New kit",
      body: "A kit is ready.",
      url: "/pages/#{@page.id}",
      event_key: "kit-ready",
      actor: @admin,
      deliver_later: false
    ).compact

    recipients = notifications.map(&:recipient)
    assert_includes recipients, @admin
    assert_includes recipients, @alice
    assert_includes recipients, @bob
    assert_includes recipients, @charlie
    refute_includes recipients, @stranger

    sample = notifications.find { |row| row.recipient == @alice }
    follow_recording = RecordingStudioFollowable.follows(root: @client, actor: @alice).first
    assert_equal @client, sample.root_recording
    assert_equal follow_recording.id, sample.recording_id
    assert_equal @client.recordable_id, sample.notifiable_id
    assert_equal "Workspace", sample.notifiable_type
    assert RecordingStudioNotifications::Services::RootResolver.consistent?(
      root_recording: sample.root_recording,
      recording: sample.recording,
      recordable: sample.notifiable
    )
    refute_equal @page_recording.id, sample.recording_id
    assert_equal @page_recording.id, sample.metadata["followed_recording_id"]
    assert_equal "Page", sample.metadata["followed_recordable_type"]
    assert_equal "/pages/#{@page.id}", sample.url
    assert_equal "followable/#{@client.id}/#{@page_recording.id}/kit-ready", sample.idempotency_key
  end

  test "notify_followers is idempotent for the same event key and still separates two roots" do
    other_client = RecordingStudio.create_root_recording!(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"), actor: @admin)
    bootstrap(other_client, @admin)
    grant(other_client, @alice, :view)
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    RecordingStudioFollowable.follow(target: @page_recording, root: other_client, actor: @alice)

    args = {
      title: "Ping",
      body: "Once.",
      url: "/pages/#{@page.id}",
      event_key: "same-event",
      actor: @admin,
      deliver_later: false
    }

    first = RecordingStudioFollowable.notify_followers(@page_recording, **args).compact
    second = RecordingStudioFollowable.notify_followers(@page_recording, **args).compact

    alice_first = first.select { |row| row.recipient == @alice }
    alice_second = second.select { |row| row.recipient == @alice }
    assert_equal 2, alice_first.size
    assert_equal alice_first.map(&:id).sort, alice_second.map(&:id).sort
    assert_equal 2, alice_first.map(&:root_recording_id).uniq.size
  end

  test "API and MCP capability actions are registered" do
    %i[follow unfollow followers].each do |name|
      action = RecordingStudioApi.capability_action(name)
      assert action, "expected #{name} to be registered"
      assert_equal :followable, action.capability
      assert_equal :view, action.required_role
    end

    follows = RecordingStudioApi.capability_action(:follows)
    assert follows
    assert_equal :follow_parent, follows.capability
    assert_equal :view, follows.required_role

    follow = RecordingStudioApi.capability_action(:follow)
    assert_nil RecordingStudioApi.configuration.capability_action_role_for(
      action: follow,
      recording: @page_recording,
      api_client: nil,
      access_grant: nil
    )

    actions = RecordingStudioApi.capability_actions_for("Page").map { |action| action.name.to_sym }
    assert_includes actions, :follow
    assert_includes actions, :unfollow
    assert_includes actions, :followers
    workspace_actions = RecordingStudioApi.capability_actions_for("Workspace").map { |action| action.name.to_sym }
    assert_includes workspace_actions, :follows
  end

  test "follow unfollow followers and follows describe the HTTP API" do
    specs = RecordingStudioFollowable::Api::FOLLOWABLE_ACTION_SPECS.to_h { |spec| [ spec.fetch(:name), spec ] }
    mcp = RecordingStudioFollowable::McpCopy::Copy::DESCRIPTIONS

    follow = RecordingStudioApi.capability_action(:follow)
    follow_spec = specs.fetch(:follow)
    assert_equal "Follow a recording", follow.openapi.fetch(:title)
    assert_equal follow_spec.fetch(:summary), follow.openapi.fetch(:summary)
    assert_includes follow.openapi.fetch(:description), "POST /api/v1/{resource}/{id}/actions/follow"
    assert_includes follow.openapi.fetch(:description), "200 returns the follow"
    assert_includes follow.openapi.fetch(:description), "403 is error code forbidden"
    assert_includes follow.openapi.fetch(:description), "404 is error code not_found"
    assert_includes follow.openapi.fetch(:description), "422 is error code invalid_input"
    assert_includes follow.openapi.fetch(:description), "root_id is omitted, blank"
    refute_equal mcp.fetch(:follow), follow.openapi.fetch(:description)
    root_id = follow.input_contract.as_json.fetch(:fields).fetch(:root_id)
    assert_includes root_id.fetch(:description), "404 not_found"
    request_root = follow.openapi.dig(:request_body, :content, :"application/json", :schema, :properties, :root_id)
    assert_includes request_root.fetch(:description), "404 not_found"

    unfollow = RecordingStudioApi.capability_action(:unfollow)
    assert_equal "Unfollow a recording", unfollow.openapi.fetch(:title)
    assert_includes unfollow.openapi.fetch(:description), "unfollowed true"
    assert_includes unfollow.openapi.fetch(:description), "root_id is omitted, blank"
    assert_includes unfollow.openapi.fetch(:description), "POST /api/v1/{resource}/{id}/actions/unfollow"
    refute_equal mcp.fetch(:unfollow), unfollow.openapi.fetch(:description)

    followers = RecordingStudioApi.capability_action(:followers)
    assert_equal "List recording followers", followers.openapi.fetch(:title)
    assert_includes followers.openapi.fetch(:description), "GET /api/v1/{resource}/{id}/actions/followers"
    assert_includes followers.openapi.fetch(:description), "array is empty"
    refute_equal mcp.fetch(:followers), followers.openapi.fetch(:description)

    follows = RecordingStudioApi.capability_action(:follows)
    assert_equal "List workspace follows", follows.openapi.fetch(:title)
    assert_includes follows.openapi.fetch(:description), "GET /api/v1/{resource}/{id}/actions/follows"
    refute_includes follows.openapi.fetch(:description), "Run this on the workspace"

    [ follow, unfollow, followers, follows ].each do |action|
      fields = action.input_contract.as_json.fetch(:fields)
      blob = [
        action.openapi[:title],
        action.openapi[:summary],
        action.openapi[:description],
        fields.values.map { |field| field[:description] }
      ].join(" ")
      refute_includes blob, "Access"
      refute_includes blob, "role"
      refute_includes blob, ":edit"
      refute_includes blob, ":view"
      refute_includes blob, "Admin"
      refute_includes blob, "View"
      refute_includes blob, "permission"
      refute_includes blob, "Press Kit"
      refute_includes blob, "Press Center"
    end
  end

  test "API follow handler uses the same service as the UI" do
    grant = Struct.new(:actor) do
      def authorize!(recording:, role:)
        raise "denied" unless RecordingStudioAccessible.authorized?(actor: actor, recording: recording, role: role)
      end
    end.new(@alice)

    context = Struct.new(:recording, :access_grant, :actor, :params).new(
      @page_recording,
      grant,
      @alice,
      { root_id: @client.id }
    )
    payload = RecordingStudioFollowable::Api::Actions::Follow.call(context)

    assert_equal @page_recording.id, payload[:target_id]
    assert_equal @client.id, payload[:root_id]
  end

  test "API follow allows a public page when the grant would refuse view" do
    RecordingStudioAccessible.set_audience!(
      recording: @page_recording,
      action: :"recording_studio_followable.see",
      audience: :public,
      actor: @admin
    )
    grant = Struct.new(:actor) do
      def authorize!(*)
        raise "target view was required"
      end
    end.new(@charlie)

    context = Struct.new(:recording, :access_grant, :actor, :params).new(
      @page_recording,
      grant,
      @charlie,
      { root_id: @client.id }
    )
    payload = RecordingStudioFollowable::Api::Actions::Follow.call(context)

    assert_equal @page_recording.id, payload[:target_id]
  end

  test "follow and unfollow reject a blank root_id as invalid input" do
    follow = RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @alice)
    kept = RecordingStudioFollowable.follows(root: @client, actor: @alice).map(&:id)

    [
      RecordingStudioFollowable::Api::Actions::Follow,
      RecordingStudioFollowable::Api::Actions::Unfollow
    ].each do |action|
      blank_root_id_params.each do |params|
        assert_raises(RecordingStudioApi::InvalidActionInputError) do
          action.call(api_action_context(params))
        end
      end
    end

    assert_equal kept, RecordingStudioFollowable.follows(root: @client, actor: @alice).map(&:id)
    refute follow.recording_studio_trashable_trashed?

    params = { "root_id" => @client.id }
    first = RecordingStudioFollowable::Api::Actions::Follow.call(api_action_context(params))
    second = RecordingStudioFollowable::Api::Actions::Follow.call(api_action_context(params))
    assert_equal first[:id], second[:id]
    assert_equal follow.id, first[:id]

    trashed = RecordingStudioFollowable::Api::Actions::Unfollow.call(api_action_context(params))
    assert_equal follow.id, trashed[:id]
    again = RecordingStudioFollowable::Api::Actions::Unfollow.call(api_action_context(params))
    assert_equal({ unfollowed: true }, again)
    assert_empty RecordingStudioFollowable.follows(root: @client, actor: @alice)
  end

  private

  def blank_root_id_params
    [
      {},
      { root_id: "" },
      { "root_id" => "" },
      { root_id: "  " },
      { "root_id" => " \t" }
    ]
  end

  def api_action_context(params)
    Struct.new(:recording, :access_grant, :actor, :params).new(
      @page_recording,
      nil,
      @alice,
      params
    )
  end

  def users(email)
    User.find_or_create_by!(email: email) do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
  end

  def bootstrap(recording, actor)
    result = RecordingStudioAccessible.bootstrap_owner_access!(recording: recording, actor: actor)
    raise result.error if result.failure?
  end

  def publish(recording)
    RecordingStudioAccessible.set_audience!(
      recording: recording,
      action: :"recording_studio_followable.see",
      audience: :public,
      actor: @admin
    )
  end

  def grant(recording, actor, role)
    result = RecordingStudioAccessible.grant_access(
      recording: recording,
      actor: actor,
      role: role,
      manager_actor: @admin
    )
    raise result.error if result.failure?
  end
end
