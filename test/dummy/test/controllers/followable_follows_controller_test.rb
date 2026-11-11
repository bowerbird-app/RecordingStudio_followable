# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FollowableFollowsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    @stranger = User.find_or_create_by!(email: "stranger@example.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    sign_in @admin
    Current.actor = @admin
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
  end

  teardown do
    Current.actor = nil
  end

  test "html follow creates a follow and redirects back" do
    post recording_studio_followable.follows_path,
         params: { target_id: @page_recording.id, root_id: @client.id },
         headers: { "HTTP_REFERER" => "/" }

    assert_redirected_to "/"
    assert RecordingStudioFollowable::FollowQuery.active_for(root: @client, target: @page_recording)
  end

  test "html unfollow removes the follow and redirects back" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)
    delete recording_studio_followable.follows_path,
           params: { target_id: @page_recording.id, root_id: @client.id },
           headers: { "HTTP_REFERER" => "/" }

    assert_redirected_to "/"
    assert_nil RecordingStudioFollowable::FollowQuery.active_for(root: @client, target: @page_recording)
  end

  test "unauthorized html follow redirects with an alert" do
    sign_in @stranger
    Current.actor = @stranger
    post recording_studio_followable.follows_path,
         params: { target_id: @page_recording.id, root_id: @client.id },
         headers: { "HTTP_REFERER" => "/" }

    assert_redirected_to "/"
    assert_equal I18n.t("recording_studio_followable.follows.unauthorized"), flash[:alert]
    assert_nil RecordingStudioFollowable::FollowQuery.active_for(root: @client, target: @page_recording)
  end

  test "unauthorized turbo_stream follow is forbidden" do
    sign_in @stranger
    Current.actor = @stranger
    post recording_studio_followable.follows_path,
         params: { target_id: @page_recording.id, root_id: @client.id },
         as: :turbo_stream

    assert_response :forbidden
  end

  test "turbo_stream follow replaces the button with Following" do
    post recording_studio_followable.follows_path,
         params: { target_id: @page_recording.id, root_id: @client.id },
         as: :turbo_stream

    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_includes response.body, 'action="replace"'
    assert_includes response.body, "Following"
    assert_includes response.body, "check-circle"
    assert_includes response.body, "Unfollow"
  end

  test "turbo_stream unfollow replaces the button with Follow" do
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)
    delete recording_studio_followable.follows_path,
           params: { target_id: @page_recording.id, root_id: @client.id },
           as: :turbo_stream

    assert_response :success
    assert_equal Mime[:turbo_stream], response.media_type
    assert_includes response.body, "Follow"
    assert_includes response.body, "plus-circle"
    refute_includes response.body, "Unfollow"
  end

  test "index lists follows for the current root" do
    switch_to_client_workspace
    RecordingStudioFollowable.follow(target: @page_recording, root: @client, actor: @admin)

    get recording_studio_followable.follows_path

    assert_response :success
    assert_includes response.body, "Following"
    assert_includes response.body, "Getting Started"
    assert_includes response.body, "/pages/#{@page.id}"
    assert_includes response.body, "Unfollow"
    refute_includes response.body, "Pages this workspace is watching."
    assert_equal 1, response.body.scan(/<h1[\s>]/i).length
  end

  test "index is empty when the current root follows nothing" do
    private_root = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Private Workspace"))
    switch_to_workspace(private_root)

    get recording_studio_followable.follows_path

    assert_response :success
    assert_includes response.body, I18n.t("recording_studio_followable.follows.empty")
    refute_includes response.body, "Load more"
  end

  test "unauthorized html index redirects with an alert" do
    sign_in @stranger
    Current.actor = @stranger
    get recording_studio_followable.follows_path, headers: { "HTTP_REFERER" => "/" }

    assert_redirected_to "/"
    assert_equal I18n.t("recording_studio_followable.follows.unauthorized"), flash[:alert]
  end

  test "unauthorized turbo_stream index is forbidden" do
    sign_in @stranger
    Current.actor = @stranger
    get recording_studio_followable.follows_path, as: :turbo_stream

    assert_response :forbidden
  end

  test "index paginates newest first and the next frame returns the rest" do
    list_root = RecordingStudio.root_recording_for(Workspace.create!(name: "Follow list #{SecureRandom.hex(4)}"))
    RecordingStudioAccessible.bootstrap_owner_access!(recording: list_root, actor: @admin)
    switch_to_workspace(list_root)
    studio = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Studio Workspace"))
    titles = %w[Alpha Bravo Charlie]
    titles.each do |title|
      page = Page.create!(title: title)
      recording = RecordingStudio.record!(
        action: "created",
        recordable: page,
        root_recording: studio,
        parent_recording: studio
      ).recording
      RecordingStudioFollowable.follow(target: recording, root: list_root, actor: @admin)
    end
    RecordingStudioFollowable.configuration.page_size = 2

    get recording_studio_followable.follows_path

    assert_response :success
    assert_includes response.body, "Charlie"
    assert_includes response.body, "Bravo"
    refute_includes response.body, "Alpha"
    assert_includes response.body, "Load more"
    assert_includes response.body, 'loading="lazy"'
    cursor = CGI.unescape(CGI.unescapeHTML(response.body[/cursor=([^"&]+)/, 1].to_s))
    assert cursor.present?

    get recording_studio_followable.follows_path(cursor: cursor),
        headers: { "Turbo-Frame" => "follows-page-#{cursor}" }

    assert_response :success
    assert_includes response.body, "Alpha"
    refute_includes response.body, "Charlie"
    refute_includes response.body, "Load more"
    refute_includes response.body, 'loading="lazy"'
  ensure
    RecordingStudioFollowable.configuration.page_size = RecordingStudioFollowable::Configuration::DEFAULT_PAGE_SIZE
  end

  private

  def switch_to_client_workspace
    switch_to_workspace(@client)
  end

  def switch_to_workspace(root)
    return unless defined?(RecordingStudioRootSwitchable)

    patch "/recording_studio_root_switchable/v1/root_switch", params: {
      scope: "all_workspaces",
      root_switch: {
        root_recording_id: root.id,
        return_to: "/"
      }
    }
    assert_response :redirect
    follow_redirect!
  end
end
