# frozen_string_literal: true

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"
require "devise/test/integration_helpers"

module ConfirmPasswordUsersOnSignIn
  def sign_in(resource, ...)
    resource.confirm_for_password_sign_in! if resource.respond_to?(:confirm_for_password_sign_in!)
    super
  end
end

Devise::Test::IntegrationHelpers.prepend(ConfirmPasswordUsersOnSignIn)
