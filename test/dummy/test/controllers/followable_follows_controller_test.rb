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
end
