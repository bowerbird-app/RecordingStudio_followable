# frozen_string_literal: true

module RecordingStudioFollowable
  module Api
    module OpenapiOverrides
      module_function

      def store(type:, action:, title:, description:)
        type_name = required_type!(type)
        name = known_action!(action)
        required_copy!(title, description)

        entries[type_name] ||= {}
        entries[type_name][name] = { title: title, description: description }.freeze
        nil
      end

      def fetch(type, action)
        return if type.nil?

        entries.dig(type.to_s, action.to_sym)
      end

      def reset!
        @entries = {}
      end

      def entries
        @entries ||= {}
      end

      def required_type!(type)
        type_name = type.to_s
        raise ArgumentError, "type is required" if type_name.blank?

        type_name
      end

      def known_action!(action)
        name = action.to_sym
        return name if FOLLOWABLE_ACTION_SPECS.any? { |spec| spec.fetch(:name) == name }

        raise ArgumentError, "Unknown Followable action #{action.inspect}"
      end

      def required_copy!(title, description)
        raise ArgumentError, "title is required" if title.nil?
        raise ArgumentError, "description is required" if description.nil?
      end
    end
  end
end
