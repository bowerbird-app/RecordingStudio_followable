# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class PublicFollowSignInTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @admin = User.find_or_create_by!(email: "admin@admin.com") do |user|
      user.password = "Password"
      user.password_confirmation = "Password"
    end
    Current.actor = @admin
    load Rails.root.join("db/seeds.rb")
    @page = Page.find_by!(title: "Getting Started")
    @page_recording = RecordingStudio::Recording.find_by!(recordable: @page)
    @client = RecordingStudio.root_recording_for(Workspace.find_by!(name: "Client Workspace"))
    @alice = User.find_by!(email: "alice@example.com")
  end

  teardown do
    Current.actor = nil
    RecordingStudioFollowable.configuration.account_setup_url = nil
  end

  test "signed-out visitors see Follow on a public page" do
    get public_sample_path

    assert_response :success
    assert_includes response.body, "Follow"
    assert_includes response.body, "plus-circle"
    assert_includes response.body, "follow_sign_in"
  end

  test "an embedded public page opens sign-in in a new tab" do
    get public_sample_path, headers: { "Sec-Fetch-Dest" => "iframe" }

    assert_response :success
    assert_includes response.body, 'target="_blank"'
    assert_includes response.body, "follow_sign_in"
  end

  test "email code signs the visitor in, follows, and returns to the page" do
    destination = public_sample_path
    get destination
    post recording_studio_followable.follow_sign_in_path, params: {
      target_id: @page_recording.id,
      return_to: destination,
      email: @alice.email
    }

    assert_response :redirect
    follow_redirect!
    assert_response :success
    assert_includes response.body, "Enter your code"

    post recording_studio_followable.follow_sign_in_verify_path, params: { code: otp_code }

    assert_redirected_to destination
    assert RecordingStudioFollowable::FollowQuery.active_for(root: @client, target: @page_recording)

    follow_redirect!
    assert_response :success
    assert_includes response.body, "Following"
  end

  test "a new account with no workspace sees setup and does not follow" do
    email = "new-#{SecureRandom.hex(4)}@example.com"
    before = RecordingStudioFollowable::Follow.count

    post recording_studio_followable.follow_sign_in_path, params: {
      target_id: @page_recording.id,
      return_to: public_sample_path,
      email: email
    }
    assert_response :redirect
    post recording_studio_followable.follow_sign_in_verify_path, params: { code: otp_code }

    assert_response :success
    assert_includes response.body, "Finish setting up your account first"
    assert_equal before, RecordingStudioFollowable::Follow.count
    assert User.find_by!(email: email).confirmed?
  end

  test "a host setup url redirects instead of the setup page" do
    RecordingStudioFollowable.configuration.account_setup_url = "/welcome"
    email = "setup-#{SecureRandom.hex(4)}@example.com"
    before = RecordingStudioFollowable::Follow.count

    post recording_studio_followable.follow_sign_in_path, params: {
      target_id: @page_recording.id,
      email: email
    }
    post recording_studio_followable.follow_sign_in_verify_path, params: { code: otp_code }

    assert_redirected_to "/welcome"
    assert_equal before, RecordingStudioFollowable::Follow.count
  end

  private

  def otp_code
    challenge = RecordingStudioUser::OtpChallenge.order(created_at: :desc).first
    RecordingStudioUser.otp_message(challenge.id).fetch(:body)[/\d{6}/]
  end
end
