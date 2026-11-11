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
    @studio = RecordingStudio.root_recording_for(Workspace.create!(name: "Studio #{SecureRandom.hex(4)}"))
    @client = RecordingStudio.root_recording_for(Workspace.create!(name: "Client #{SecureRandom.hex(4)}"))
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
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @charlie)
    RecordingStudioFollowable.unfollow(target: @page_recording, root: @client, actor: @bob)

    assert_empty RecordingStudioFollowable.follows(root: @client, actor: @alice)
  end

  test "a stranger cannot follow into a root they cannot see" do
    assert_raises(RecordingStudioFollowable::NotAuthorized) do
      RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @stranger)
    end
  end

  test "view on the follow root is enough to follow a page in another root" do
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
    other_client = RecordingStudio.root_recording_for(Workspace.create!(name: "Other #{SecureRandom.hex(4)}"))
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

    actions = RecordingStudioApi.capability_actions_for("Page").map { |action| action.name.to_sym }
    assert_includes actions, :follow
    assert_includes actions, :unfollow
    assert_includes actions, :followers
    workspace_actions = RecordingStudioApi.capability_actions_for("Workspace").map { |action| action.name.to_sym }
    assert_includes workspace_actions, :follows
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

  private

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
