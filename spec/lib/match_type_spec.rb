# frozen_string_literal: true

RSpec.describe MatchType do
  subject(:match_type) { described_class.new(type, headers) }

  let(:type) { 'email' }
  let(:headers) { %w[Email Phone] }

  describe 'SUPPORTED_MATCH_TYPES' do
    subject { described_class::SUPPORTED_MATCH_TYPES }

    let(:expected_values) { %w[email phone email_or_phone] }

    it { is_expected.to match_array(expected_values) }
  end

  describe 'initialize' do
    let(:type) { 'email' }
    let(:headers) { %w[Email Phone] }

    it 'calls validate! on the provided match type' do
      expect(described_class).to receive(:validate!).with(type).and_call_original

      described_class.new(type, headers)
    end

    context 'when no headers are provided' do
      let(:headers) { [] }
      let(:expected_error) { ArgumentError }
      let(:expected_message) { 'Headers cannot be empty' }

      it 'raises the expected error' do
        expect { match_type }.to raise_error(expected_error, expected_message)
      end
    end

    context 'when headers are not an array' do
      let(:headers) { 'Email' }
      let(:expected_error) { ArgumentError }
      let(:expected_message) { 'Headers must be an array' }

      it 'raises the expected error' do
        expect { match_type }.to raise_error(expected_error, expected_message)
      end
    end
  end

  describe '#email?' do
    context 'when the type is email' do
      let(:type) { 'email' }

      it { is_expected.to be_email }
    end

    context 'when the type is email_or_phone' do
      let(:type) { 'email_or_phone' }

      it { is_expected.to be_email }
    end

    context 'when the type is phone' do
      let(:type) { 'phone' }

      it { is_expected.not_to be_email }
    end
  end

  describe '#phone?' do
    context 'when the type is phone' do
      let(:type) { 'phone' }

      it { is_expected.to be_phone }
    end

    context 'when the type is email_or_phone' do
      let(:type) { 'email_or_phone' }

      it { is_expected.to be_phone }
    end

    context 'when the type is email' do
      let(:type) { 'email' }

      it { is_expected.not_to be_phone }
    end
  end

  describe '#email_header' do
    subject { match_type.email_header }

    let(:type) { 'email' }

    context 'when Email is in the headers' do
      let(:headers) { %w[Email] }

      it { is_expected.to eq 'Email' }
    end

    context 'when Email1 is in the headers and Email is not' do
      let(:headers) { %w[Email1] }

      it { is_expected.to eq 'Email1' }
    end

    context 'when Email1 and Email are in the headers' do
      let(:headers) { %w[Email1 Email] }

      it { is_expected.to eq 'Email' }
    end
  end

  describe '#phone_header' do
    subject { match_type.phone_header }

    let(:type) { 'phone' }

    context 'when Phone is in the headers' do
      let(:headers) { %w[Phone] }

      it { is_expected.to eq 'Phone' }
    end

    context 'when Phone1 is in the headers and Phone is not' do
      let(:headers) { %w[Phone1] }

      it { is_expected.to eq 'Phone1' }
    end

    context 'when Phone1 and Phone are in the headers' do
      let(:headers) { %w[Phone1 Phone] }

      it { is_expected.to eq 'Phone' }
    end
  end

  describe '.validate!' do
    context 'when the type is supported' do
      let(:type) { described_class::SUPPORTED_MATCH_TYPES.sample }

      it 'does not raise an error' do
        expect { described_class.validate!(type) }.not_to raise_error
      end
    end

    context 'when the type is not supported' do
      let(:type) { 125 }
      let(:expected_error) { described_class::UnsupportedError }
      let(:expected_message) { "#{type} is not supported" }

      it 'raises the expected error' do
        expect { described_class.validate!(type) }.to raise_error(expected_error, expected_message)
      end
    end
  end
end
