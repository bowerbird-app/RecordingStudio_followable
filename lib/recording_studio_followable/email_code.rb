# frozen_string_literal: true

module RecordingStudioFollowable
  class EmailCode
    class Failed < Error; end

    def self.available?
      return false unless defined?(RecordingStudioUser)
      return false unless RecordingStudioUser.respond_to?(:config)

      RecordingStudioUser.config.otp_enabled?
    rescue StandardError
      false
    end

    def self.request!(email:, request:, session:)
      new(request: request, session: session).request!(email)
    end

    def self.verify!(code:, session:)
      new(request: nil, session: session).verify!(code)
    end

    def initialize(request:, session:)
      @request = request
      @session = session
    end

    def request!(email)
      raise Failed, I18n.t("recording_studio_followable.sign_in.users_required") unless self.class.available?

      normalized = normalize(email)
      raise Failed, I18n.t("recording_studio_followable.sign_in.email_invalid") if normalized.blank?

      issue!(normalized)
    end

    def verify!(code)
      raise Failed, users_required unless self.class.available?

      challenge_id, purpose = session_challenge
      raise Failed, code_mismatch if challenge_id.blank? || purpose.blank?

      settle!(verified_user(code, challenge_id, purpose), challenge_id)
    end

    private

    def issue!(email)
      result = request_code(email)
      raise Failed, wait_message if result.throttled?
      raise Failed, could_not_send unless result.issued?

      result
    rescue ActiveRecord::RecordNotUnique
      raise Failed, wait_message
    end

    def request_code(email)
      RecordingStudioUser.request_otp!(
        email: email,
        purpose: purpose_for(email),
        request: @request,
        session: @session
      )
    end

    def session_challenge
      [@session[:otp_challenge_id], @session[:otp_purpose]]
    end

    def verified_user(code, challenge_id, purpose)
      result = RecordingStudioUser.verify_otp!(
        challenge_id: challenge_id,
        code: code,
        purpose: purpose,
        session: @session
      )
      raise Failed, code_mismatch unless result.success?

      result.user
    end

    def users_required
      I18n.t("recording_studio_followable.sign_in.users_required")
    end

    def code_mismatch
      I18n.t("recording_studio_followable.sign_in.code_mismatch")
    end

    def wait_message
      I18n.t("recording_studio_followable.sign_in.wait")
    end

    def could_not_send
      I18n.t("recording_studio_followable.sign_in.could_not_send")
    end

    def purpose_for(email)
      user = find_user(email)
      return "login" if user&.confirmed? && user.active_for_authentication?

      "registration"
    end

    def find_user(email)
      user_class = RecordingStudioUser.config.user_class
      user_class.find_by(email: email) || user_class.where("LOWER(email) = ?", email).first
    end

    def settle!(user, challenge_id)
      RecordingStudioUser.complete_email_proof!(user: user, challenge_id: challenge_id)
      user.reload
    rescue ArgumentError
      raise Failed, I18n.t("recording_studio_followable.sign_in.code_mismatch") unless user.reload.confirmed?

      user
    end

    def normalize(email)
      text = email.to_s.strip.downcase
      return if text.blank? || !text.include?("@") || text.start_with?("@")

      text
    end
  end
end
