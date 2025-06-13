# frozen_string_literal: true

RSpec.describe CsvHandler do
  let(:csv_handler) { described_class.new(match_type, csv_filename) }

  describe '#initialize' do
    let(:match_type) { :email }
    let(:csv_filename) { fixture_path('input1.csv') }

    context 'when the csv_filename does is not readable' do
      let(:csv_filename) { '/a/non/existent/file.csv' }
      let(:expected_error) { CsvHandler::FileReadError }
      let(:expected_message) { "#{csv_filename} is not readable" }

      it 'raises the expected file read error' do
        expect { csv_handler }.to raise_error(expected_error, expected_message)
      end
    end

    context 'when the match type is not supported' do
      let(:match_type) { 123_567 }
      let(:expected_error) { MatchType::UnsupportedError }
      let(:expected_message) { "#{match_type} is not supported" }

      it 'raises the expected match type error' do
        expect { csv_handler }.to raise_error(expected_error, expected_message)
      end
    end
  end

  describe '#parse_file' do
    subject(:parse_file) { csv_handler.parse }

    let(:match_type) { :email }
    let(:csv_filename) { fixture_path('input1.csv') }
    let(:output_file) { csv_handler.output_file }
    let(:fake_record) do
      {
        'OwnerId'   => '',
        'FirstName' => 'Test',
        'LastName'  => 'Test',
        'Phone'     => '(555) 555-5555',
        'Email'     => 'sample@example.com',
        'Zip'       => '99999'
      }
    end
    let(:fake_record_w_id) do
      fake_record.dup.tap {|r| r['OwnerId'] = 'person1' }
    end
    let(:fake_headers) { fake_record.keys }
    let(:person_matcher) { instance_double(PersonMatcher) }

    # Stub out the matcher and the relevant methods
    before do
      allow(PersonMatcher).to receive(:new).with(match_type, fake_headers)
                                           .and_return(person_matcher)
      allow(person_matcher).to receive(:check_ownership).and_return(fake_record_w_id)
    end

    # Remove the output file
    after { FileUtils.rm_f(csv_handler.output_file) }

    it 'returns the output file' do
      expect(parse_file).to eq(output_file)
    end

    it 'opens the input and output files' do
      expect(csv_handler).to receive(:open_files).and_call_original
      parse_file
    end

    it 'runs once when called twice' do
      expect(csv_handler).to receive(:open_files).and_call_original.once
      csv_handler.parse
      csv_handler.parse
    end
  end
end
