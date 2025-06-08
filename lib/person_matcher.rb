# frozen_string_literal: true

class PersonMatcher
  def initialize(match_type, headers)
    @headers = headers
    @match_type = MatchType.new(match_type, @headers)
    @owner_header = @headers.first
    @id_gen = IdGenerator.new(prefix: 'person')
  end

  def check_ownership(record)
    reset_record(record)

    check_for_matching_records

    # puts normalized_phone, current_record[owner_header]
    # binding.pry if normalized_phone == '555-111-4444'
    current_record
  end

  private

  attr_reader :headers, :match_type, :current_record, :id_gen, :owner_header

  def check_for_matching_records
    if match_type.email? && match_type.phone?
      perform_email_or_phone_match
    elsif match_type.email?
      perform_email_match
    elsif match_type.phone?
      perform_phone_match
    end
  end

  # When matching on email, this checks ownership, and updates the record accordingly
  def perform_email_match
    current_record[owner_header] = @id_gen.unique_id(normalized_email, type: :email)
  end

  # When matching on phone, this checks ownership, and updates the record accordingly
  def perform_phone_match
    current_record[owner_header] = @id_gen.unique_id(normalized_phone, type: :phone)
  end

  def normalized_email
    return @normalized_email unless @normalized_email.nil?

    @normalized_email = DataNormalizer.email(current_record[match_type.email_header])
  end

  def normalized_phone
    return @normalized_phone unless @normalized_phone.nil?

    @normalized_phone = DataNormalizer.phone(current_record[match_type.phone_header])
  end

  # rubocop:disable Metrics/AbcSize
  # Looks for matches on email and phone to identify who the owner of the record is, and any transitive ownership
  def perform_email_or_phone_match
    return unless current_record[owner_header].empty?

    if !existing_owner_ids[:email].nil? && existing_owner_ids[:phone].nil?
      # if the email has an owner and the phone does not, this and the phone go to the email owner
      assign_email_owner(existing_owner_ids[:email])
    elsif !existing_owner_ids[:phone].nil?
      # if the phone has an owner, this and the email go to the phone owner
      assign_phone_owner(existing_owner_ids[:phone])
    else
      take_ownership
    end
  end
  # rubocop:enable Metrics/AbcSize

  # rubocop:disable Metrics/AbcSize
  def take_ownership
    if normalized_email.nil? && normalized_phone.nil?
      # data does not exist in either email or phone
      current_record[owner_header] = id_gen.unique_id(nil, type: :email)
    elsif !normalized_email.nil? && normalized_phone.nil?
      # data exists in email but not phone
      current_record[owner_header] = id_gen.unique_id(normalized_email, type: :email)
    elsif normalized_email.nil? && !normalized_phone.nil?
      # data exists in phone but not email
      current_record[owner_header] = id_gen.unique_id(normalized_phone, type: :phone)
    else
      # data exists in email and phone
      current_record[owner_header] = id_gen.unique_id(normalized_email, type: :email)
      id_gen.save_existing_id(normalized_phone, current_record[owner_header], type: :phone)
    end
  end
  # rubocop:enable Metrics/AbcSize

  def existing_owner_ids
    return @existing_owner_ids unless @existing_owner_ids.nil?

    @existing_owner_ids = {
      email: id_gen.existing_id(normalized_email, type: :email),
      phone: id_gen.existing_id(normalized_phone, type: :phone)
    }
  end

  def assign_email_owner(email_owner_id)
    id_gen.save_existing_id(normalized_phone, email_owner_id, type: :phone)
    current_record[owner_header] = email_owner_id
  end

  def assign_phone_owner(phone_owner_id)
    id_gen.save_existing_id(normalized_email, phone_owner_id, type: :email)
    current_record[owner_header] = phone_owner_id
  end

  def reset_record(record = nil)
    @current_record = record

    @existing_owner_ids = nil
    @normalized_email = nil
    @normalized_phone = nil
  end
end
