# frozen_string_literal: true

# Tracks data using a keyed hash, generated unique ids (when applicable),
# and returns existing ids for matching data.
class IdGenerator
  def initialize(prefix: 'record')
    @prefix = prefix

    reset
  end

  def unique_id(string_key, type:)
    return id_with_prefix(string_key, type) if matched?(string_key, type: type)

    increment_id

    if string_key.nil? || string_key.empty?
      "#{@prefix}#{current_id}"
    else
      capture_data(current_id, string_key, type)

      id_with_prefix(string_key, type)
    end
  end

  def save_existing_id(string_key, existing_id_string, type:)
    return if string_key.nil? || string_key.empty?

    @hash[type] = {} unless @hash.key?(type)

    existing_id = extract_id(existing_id_string)

    capture_data(existing_id, string_key, type)
  end

  def extract_id(existing_id_string)
    return existing_id_string unless existing_id_string.start_with?(@prefix.to_s)

    existing_id_string.delete_prefix(@prefix.to_s).to_i
  end

  def matched?(string_key, type:)
    return false unless @hash.key?(type)

    @hash[type].key?(string_key)
  end

  def existing_id(string_key, type:)
    return nil unless matched?(string_key, type: type)

    id_with_prefix(string_key, type)
  end

  def reset
    @hash = {}
    @tracking_id = 0
  end

  private

  def current_id
    @tracking_id
  end

  def increment_id
    @tracking_id += 1
  end

  def capture_data(id, string_key, type)
    @hash[type] = {} unless @hash.key?(type)

    @hash[type][string_key] = id
  end

  def id_with_prefix(string_key, type)
    "#{@prefix}#{@hash[type][string_key]}"
  end
end
