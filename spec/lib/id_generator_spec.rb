# frozen_string_literal: true

RSpec.describe IdGenerator do
  let(:id_generator) { described_class.new }
  let(:type) { :test }

  after { id_generator.reset }

  describe '#matched?' do
    subject(:matched) { id_generator.matched?(string, type: type) }

    context 'when the string and type combo have been seen' do
      let(:string) { 'test' }

      before do
        id_generator.unique_id(string, type: type)
      end

      it { is_expected.to be true }
    end

    context 'when the string and type combo have not been seen' do
      let(:string) { 'test' }

      it { is_expected.to be false }
    end
  end

  describe '#save_existing_id' do
    let(:existing_id) { 'existing_id' }
    let(:string) { 'email@example.com' }
    let(:type) { :test_for_saving_existing_id }
    let(:hash_instance) { id_generator.instance_variable_get(:@hash) }

    before do
      id_generator.save_existing_id(string, existing_id, type: type)
    end

    it 'creates the hash to track the passed type' do
      expect(hash_instance[type]).to be_a Hash
    end

    it 'caches the expected data' do
      expect(hash_instance[type]).to have_key(string)
      expect(hash_instance[type][string]).to eq existing_id
    end
  end

  describe '#unique_id' do
    subject(:unique_id) { id_generator.unique_id(string, type: type) }

    context 'when passed a string it has not seen' do
      let(:string) { 'new-string' }
      let(:expected_value) { 'record1' }

      it 'returns the unique id for the new string' do
        expect(unique_id).to eq(expected_value)
      end
    end

    context 'when passed a string it has already seen' do
      let(:string) { 'new-string' }
      let(:filler_strings) { ['sample', 'test', string, 'values'] }
      let(:expected_value) { 'record3' }

      before do
        filler_strings.each {|s| id_generator.unique_id(s, type: type) }
      end

      it 'returns the unique id assigned to said string' do
        expect(unique_id).to eq(expected_value)
      end
    end

    context 'when provided a record prefix' do
      let(:id_generator) { described_class.new(prefix: prefix) }
      let(:prefix) { 'test_prefix' }
      let(:string) { 'new-string' }
      let(:expected_value) { "#{prefix}1" }

      it 'includes the prefix as part of the unique id' do
        expect(unique_id).to eq(expected_value)
      end
    end

    context 'when passed an empty string' do
      let(:string) { '' }
      let(:expected_value) { 'record1' }

      it 'returns a unique id' do
        expect(unique_id).to eq expected_value
      end
    end

    context 'when passed a nil value' do
      let(:string) { nil }
      let(:expected_value) { 'record1' }

      it 'returns a unique id' do
        expect(unique_id).to eq expected_value
      end
    end
  end
end
