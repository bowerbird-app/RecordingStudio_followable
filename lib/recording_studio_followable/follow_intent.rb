# frozen_string_literal: true

module RecordingStudioFollowable
  module FollowIntent
    PURPOSE = "recording_studio_followable.follow"
    LIFETIME = 15.minutes

    Intent = Data.define(:target_id, :page, :parent_url, :button)
    Request = Data.define(:target_id, :page, :parent_url, :button, :host, :allowed_origins)

    class << self
      def issue(request)
        id = request.target_id.to_s
        return if id.blank?

        verifier.generate(payload(request, id), expires_in: LIFETIME, purpose: PURPOSE)
      end

      def read(token)
        intent_from(verified_payload(token))
      rescue ActiveSupport::MessageVerifier::InvalidSignature
        nil
      end

      private

      def payload(request, id)
        {
          "target_id" => id,
          "page" => safe_page(request.page),
          "parent_url" => safe_parent(request),
          "button" => button_payload(request.button)
        }
      end

      def verified_payload(token)
        return if token.blank?

        payload = verifier.verified(token.to_s, purpose: PURPOSE)
        payload.to_h.stringify_keys if payload.present?
      end

      def intent_from(data)
        return if data.blank?

        id = data["target_id"].to_s.presence
        return if id.blank?

        Intent.new(
          target_id: id,
          page: data["page"].presence,
          parent_url: data["parent_url"].presence,
          button: button_hash(data["button"])
        )
      end

      def verifier
        Rails.application.message_verifier(PURPOSE)
      end

      def safe_page(page)
        ReturnTo.safe_url(page, host: nil, allowed_origins: [])
      end

      def safe_parent(request)
        ReturnTo.safe_url(
          request.parent_url,
          host: request.host,
          allowed_origins: request.allowed_origins
        )
      end

      def button_payload(button)
        return {} unless button.respond_to?(:to_h)

        button.to_h.deep_stringify_keys
      end

      def button_hash(value)
        return {} unless value.is_a?(Hash)

        value
      end
    end
  end
end
