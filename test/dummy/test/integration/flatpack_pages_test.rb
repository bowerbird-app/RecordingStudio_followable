# frozen_string_literal: true

require "test_helper"
require "devise/test/integration_helpers"

class FlatpackPagesTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    user = User.find_or_create_by!(email: "flatpack-pages@example.com") do |record|
      record.password = "Password123!"
      record.password_confirmation = "Password123!"
    end
    sign_in user
  end

  test "signed-in dummy home renders after the flatpack bump" do
    get root_path

    assert_response :success
  end
end
