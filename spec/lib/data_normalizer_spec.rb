# frozen_string_literal: true

RSpec.describe DataNormalizer do
  describe '.email' do
    subject(:normalize) { described_class.email(email_address) }

    context 'when given a whitespace padded string with capital letters' do
      let(:email_address) { ' Test@example.com ' }
      let(:expected_value) { 'test@example.com' }

      it 'returns the expected normalized value' do
        expect(normalize).to eq(expected_value)
      end
    end

    context 'when given an empty string' do
      let(:email_address) { '' }

      it { is_expected.to be_nil }
    end

    context 'when given whitespace only' do
      let(:email_address) { '     ' }

      it { is_expected.to be_nil }
    end

    context 'when given an nil' do
      let(:email_address) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '.phone' do
    subject(:normalize) { described_class.phone(phone_number) }

    context 'when given a valid phone number' do
      context 'when the phone number is just digits' do
        let(:phone_number) { '+15551234567' }
        let(:expected_value) { '555-123-4567' }

        it { is_expected.to eq expected_value }
      end

      context 'when the phone number uses periods for separators' do
        let(:phone_number) { '555.123.4567' }
        let(:expected_value) { '555-123-4567' }

        it { is_expected.to eq expected_value }
      end

      context 'when the phone number includes a leading 1' do
        let(:phone_number) { '1 (555) 123-4567' }
        let(:expected_value) { '555-123-4567' }

        it { is_expected.to eq expected_value }
      end

      context 'when the phone number includes an extension' do
        let(:phone_number) { '(555) 123-4567 ext: 23' }
        let(:expected_value) { '555-123-4567' }

        it { is_expected.to eq expected_value }
      end
    end

    context 'when given an invalid phone number' do
      context 'when the phone number has less than 10 digits' do
        let(:phone_number) { '(555) 123-456' }

        it { is_expected.to be_nil }
      end

      context 'when the phone number is an empty string' do
        let(:phone_number) { '' }

        it { is_expected.to be_nil }
      end

      context 'when the phone number is whitespace' do
        let(:phone_number) { '   ' }

        it { is_expected.to be_nil }
      end

      context 'when the phone number is nil' do
        let(:phone_number) { nil }

        it { is_expected.to be_nil }
      end
    end
  end
end
