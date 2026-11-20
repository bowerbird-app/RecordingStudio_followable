# frozen_string_literal: true

require "test_helper"

class ApiRegisterTest < Minitest::Test
  FOLLOWABLE_ACTIONS = %i[follow unfollow followers follows].freeze

  def test_register_twice_is_harmless
    skip unless defined?(RecordingStudioApi) && RecordingStudioApi.respond_to?(:register_capability_action)

    RecordingStudioFollowable::Api.register!
    first = FOLLOWABLE_ACTIONS.to_h { |name| [name, RecordingStudioApi.capability_action(name)] }

    FOLLOWABLE_ACTIONS.each do |name|
      assert first[name], "missing #{name} after first register!"
    end

    RecordingStudioFollowable::Api.register!
    second = FOLLOWABLE_ACTIONS.to_h { |name| [name, RecordingStudioApi.capability_action(name)] }

    assert_equal first, second
  end
end
