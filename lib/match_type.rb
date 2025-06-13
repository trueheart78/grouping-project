# frozen_string_literal: true

class MatchType
  SUPPORTED_MATCH_TYPES = %w[email phone email_or_phone].freeze

  class UnsupportedError < StandardError; end

  def initialize(match_type, headers)
    self.class.validate!(match_type)
    validate_headers!(headers)

    @match_type = match_type.to_sym
    @headers = headers
  end

  def email?
    @match_type == :email || @match_type == :email_or_phone
  end

  def phone?
    @match_type == :phone || @match_type == :email_or_phone
  end

  # Returns the email-related header field, if available
  def email_header
    return nil unless email?
    return @email_header unless @email_header.nil?

    @email_header = @headers.select {|i| i.start_with?('Email') }.min
  end

  # Returns the phone-related header field, if available
  def phone_header
    return nil unless phone?
    return @phone_header unless @phone_header.nil?

    @phone_header = @headers.select {|i| i.start_with?('Phone') }.min
  end

  def self.validate!(match_type)
    return if SUPPORTED_MATCH_TYPES.include?(match_type.to_s)

    raise UnsupportedError, "#{match_type} is not supported"
  end

  private

  def validate_headers!(headers)
    raise ArgumentError, 'Headers must be an array' unless headers.is_a?(Array)
    raise ArgumentError, 'Headers cannot be empty' unless headers.any?
  end
end
