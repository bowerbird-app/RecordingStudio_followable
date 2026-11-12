# frozen_string_literal: true

module RecordingStudioFollowable
  module ButtonSettings
    KEYS = %i[style icon label].freeze
    NAME_PATTERN = /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/
    LABEL_LIMIT = 80

    module_function

    def parse(value)
      return {} if value.nil? || (value.respond_to?(:empty?) && value.empty?)

      hash_from(value, "button settings").each_with_object({}) do |(state, settings), parsed|
        state_name = state.to_sym
        raise ArgumentError, "unknown button state: #{state}" unless ButtonAppearance::STATES.include?(state_name)

        parsed[state_name] = parse_face(state_name, settings)
      end
    end

    def parse_face(state, settings)
      hash_from(settings, "#{state} button settings").each_with_object({}) do |(key, raw), face|
        name = key.to_sym
        raise ArgumentError, "unknown #{state} button setting: #{key}" unless KEYS.include?(name)

        face[name] = cast(state, name, raw)
      end
    end

    def cast(state, name, raw)
      case name
      when :style then cast_style(state, raw)
      when :icon then cast_icon(state, raw)
      when :label then cast_label(state, raw)
      end
    end

    def cast_style(state, raw)
      style = cast_name(state, :style, raw)
      return style unless defined?(FlatPack::Button::StyleRegistry)
      return style if FlatPack::Button::StyleRegistry.known?(style)

      raise ArgumentError, "#{state} style is not a FlatPack button style: #{style}"
    end

    # FlatPack treats an icon string that looks like SVG as HTML.
    # The follow form sends the icon back, so only a plain icon name is accepted.
    def cast_icon(state, raw)
      cast_name(state, :icon, raw)
    end

    def cast_name(state, name, raw)
      raise ArgumentError, "#{state} #{name} must be a name" unless raw.is_a?(String) || raw.is_a?(Symbol)

      text = raw.to_s
      raise ArgumentError, "#{state} #{name} must be a name" unless text.match?(NAME_PATTERN)

      name == :style ? text.to_sym : text
    end

    def cast_label(state, raw)
      raise ArgumentError, "#{state} label must be text" unless raw.is_a?(String) || raw.is_a?(Symbol)

      text = raw.to_s.strip
      raise ArgumentError, "#{state} label is blank" if text.empty?
      raise ArgumentError, "#{state} label is too long" if text.length > LABEL_LIMIT

      text
    end

    def hash_from(value, label)
      raise ArgumentError, "#{label} must be a Hash" unless value.respond_to?(:to_hash)

      value.to_hash
    end
  end
  private_constant :ButtonSettings

  class ButtonAppearance
    STATES = %i[follow following].freeze
    PARAM_KEY = :follow_button
    DEFAULTS = {
      follow: { style: :default, icon: "plus-circle" }.freeze,
      following: { style: :secondary, icon: "check-circle" }.freeze
    }.freeze
    UNFOLLOW_ICON = "minus-circle"
    LABELS = { follow: "Follow", following: "Following", unfollow: "Unfollow" }.freeze

    Face = Data.define(:style, :icon, :label)
    Resolved = Data.define(:follow, :following, :unfollow_label, :unfollow_icon, :carry) do
      def fields
        carry.flat_map do |state, settings|
          settings.map { |key, value| ["#{PARAM_KEY}[#{state}][#{key}]", value] }
        end
      end
    end

    class << self
      def permit_shape
        STATES.index_with { ButtonSettings::KEYS.dup }
      end

      def parse(value)
        ButtonSettings.parse(value)
      end

      def resolve(config:, follow: nil, following: nil)
        stored = config || {}
        per_call = per_call_faces(follow: follow, following: following)
        Resolved.new(
          follow: face_for(:follow, stored, per_call),
          following: face_for(:following, stored, per_call),
          unfollow_label: translate(:unfollow),
          unfollow_icon: UNFOLLOW_ICON,
          carry: stringify(per_call)
        )
      end

      private

      def per_call_faces(follow:, following:)
        faces = {}
        faces[:follow] = ButtonSettings.parse_face(:follow, follow) unless follow.nil?
        faces[:following] = ButtonSettings.parse_face(:following, following) unless following.nil?
        faces
      end

      def face_for(state, stored, per_call)
        merged = DEFAULTS.fetch(state).merge(stored[state] || {}).merge(per_call[state] || {})
        Face.new(style: merged.fetch(:style), icon: merged.fetch(:icon), label: merged[:label] || translate(state))
      end

      def translate(state)
        I18n.t("recording_studio_followable.follow_button.#{state}", default: LABELS.fetch(state))
      end

      def stringify(per_call)
        per_call.each_with_object({}) do |(state, settings), copy|
          copy[state] = settings.transform_values(&:to_s).freeze
        end.freeze
      end
    end
  end
end
