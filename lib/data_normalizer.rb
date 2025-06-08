# frozen_string_literal: true

module DataNormalizer
  # Returns the email address as a lowercased version with all whitespace padding removed
  def self.email(email_address)
    return if email_address.nil? || email_address.strip.empty?

    email_address.strip.downcase
  end

  # Returns the phone number in the 555-555-5555 format and drops leading 1's
  def self.phone(phone_number)
    return if phone_number.nil? || phone_number.strip.empty?

    matches = phone_number.gsub(/\D/, '').match(/^1?(\d{3})(\d{3})(\d{4})/)

    return unless matches&.size == 4

    "#{matches[1]}-#{matches[2]}-#{matches[3]}"
  end
end
