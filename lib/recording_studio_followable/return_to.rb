# frozen_string_literal: true

require "uri"

module RecordingStudioFollowable
  module ReturnTo
    module_function

    def preferred(parent_url:, return_to:, canonical:, host:, allowed_origins:)
      [parent_url, return_to, canonical].each do |candidate|
        safe = safe_url(candidate, host: host, allowed_origins: allowed_origins)
        return safe if safe.present?
      end

      "/"
    end

    def safe_url(candidate, host:, allowed_origins:)
      text = candidate.to_s
      return if text.blank?
      return text if safe_path?(text)

      uri = URI.parse(text)
      return unless %w[http https].include?(uri.scheme)
      return unless allowed_host?(uri.host, host: host, allowed_origins: allowed_origins)

      text
    rescue URI::InvalidURIError
      nil
    end

    def safe_path?(text)
      text.start_with?("/") && !text.start_with?("//") && !text.start_with?("/\\") && !text.include?("\\")
    end

    def allowed_host?(candidate_host, host:, allowed_origins:)
      value = candidate_host.to_s.downcase
      return false if value.blank?
      return true if value == host.to_s.downcase

      Array(allowed_origins).map { |origin| origin.to_s.downcase }.include?(value)
    end
  end
end
