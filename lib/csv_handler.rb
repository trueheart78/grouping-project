# frozen_string_literal: true

class CsvHandler
  class FileReadError < StandardError; end

  attr_reader :output_file

  def initialize(match_type, csv_filename)
    validate_csv_filename!(csv_filename)
    validate_match_type!(match_type)

    @match_type = match_type
    @csv_filename = csv_filename
    @output_file = ''
    @parsed = false

    compose_export_filename
  end

  def parse
    return @output_file if @parsed

    open_files
    load_headers
    walk_input_csv_file
    close_files

    @parsed = true

    @output_file
  ensure
    close_files
  end

  private

  attr_accessor :current_record

  def compose_export_filename
    return @output_file unless @output_file.empty?

    base_name = File.basename(@csv_filename, '.csv')
    match_string = @match_type.to_s.gsub('_', '-')

    @output_file = File.expand_path("output/matched-#{match_string}-#{base_name}.csv")
  end

  def validate_csv_filename!(csv_filename)
    return if File.readable?(csv_filename)

    raise FileReadError, "#{csv_filename} is not readable"
  end

  def validate_match_type!(match_type)
    MatchType.validate!(match_type)
  end

  # Task: consider extracting, as it looks and feels like an initializer
  def open_files
    @headers = []
    @data_matches = {}
    @input_file_pointer = File.open(@csv_filename, 'r')

    prepare_output_file
  end

  # Removes any pre-existing outfile, and opens a fresh version for appending
  def prepare_output_file
    FileUtils.rm_f(@output_file)

    @output_file_pointer = File.open(@output_file, 'w+')
  end

  # Loads the headers from the input file and saves them to the output file
  def load_headers
    @headers = capture_line(@input_file_pointer.readline, lead_value: 'OwnerId')
    @person_matcher = PersonMatcher.new(@match_type, @headers)
    export_data(@headers)
  end

  # Writes data to the output file
  def export_data(record)
    @output_file_pointer.write(record.join(','), "\n")
  end

  # Traverses the input file, performs matching, and exports the updated record
  def walk_input_csv_file
    @input_file_pointer.each_line do |line|
      capture_record(line).tap do |record|
        record_w_ownership = @person_matcher.check_ownership(record)
        export_data(record_w_ownership.values)
      end
    end
  end

  # Closes the open input and output files
  def close_files
    @input_file_pointer.close
    @output_file_pointer.close
  end

  # Transform the line, and shifts the lead_value into the first position.
  def capture_line(line, lead_value: '')
    line.chomp.split(',').unshift(lead_value)
  end

  # Transform the line, and shifts the lead_value into the first position.
  def capture_record(line, lead_value: '')
    fields = capture_line(line, lead_value: lead_value)

    @headers.zip(fields).to_h
  end
end
