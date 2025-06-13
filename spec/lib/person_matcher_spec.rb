# frozen_string_literal: true

RSpec.describe PersonMatcher do
  let(:person_matcher) { described_class.new(match_type, headers) }

  let(:match_type) { :email }
  let(:headers) { gen_fake_record.keys }

  describe '#check_ownership' do
    context 'when there is only one record' do
      subject(:check_ownership) { person_matcher.check_ownership(sample_record) }

      let(:sample_record) { gen_fake_record }
      let(:expected_owner_id) { 'person1' }
      let(:expected_hash) do
        sample_record.dup.tap {|s| s['OwnerId'] = expected_owner_id }
      end

      it 'contains the original data and the owner id' do
        expect(check_ownership).to eq(expected_hash)
      end
    end

    context 'when there are multiple records without matching emails' do
      subject(:ownership_records) do
        sample_records.map {|r| person_matcher.check_ownership(r) }
      end

      let(:match_type) { :email }
      let(:sample_records) { [gen_fake_record, gen_fake_record, gen_fake_record] }
      let(:owner_ids) do
        ownership_records.map {|r| r['OwnerId'] }
      end
      let(:expected_owner_ids) { %w[person1 person2 person3] }

      it 'contains the expected owner ids' do
        expect(owner_ids).to eq(expected_owner_ids)
      end
    end

    context 'when there are multiple records with matching emails, matching on email' do
      subject(:ownership_records) do
        sample_records.map {|r| person_matcher.check_ownership(r) }
      end

      let(:match_type) { :email }
      let(:sample_records) do
        [
          gen_fake_record(email: shared_emails.first), # person1
          gen_fake_record(email: shared_emails.first), # person1
          gen_fake_record(email: shared_emails.first), # person1
          gen_fake_record(email: shared_emails.last), # person2
          gen_fake_record(email: shared_emails.last), # person2
          gen_fake_record(email: 'i.am.unique@example.com') # person3
        ]
      end
      let(:shared_emails) { %w[email.thief@example.com another.thief@example.com] }
      let(:owner_ids) do
        ownership_records.map {|r| r['OwnerId'] }
      end
      let(:expected_owner_ids) { %w[person1 person1 person1 person2 person2 person3] }

      it 'contains three unique owners' do
        expect(owner_ids).to eq(expected_owner_ids)
      end
    end

    context 'when there are multiple records with matching phones, matching on phone' do
      subject(:ownership_records) do
        sample_records.map {|r| person_matcher.check_ownership(r) }
      end

      let(:match_type) { :phone }
      let(:sample_records) do
        [
          gen_fake_record(phone: shared_phones.first), # person1
          gen_fake_record(phone: shared_phones.first), # person1
          gen_fake_record(phone: shared_phones.last), # person2
          gen_fake_record(phone: shared_phones.last), # person2
          gen_fake_record(phone: shared_phones.first), # person1
          gen_fake_record(phone: '555-111-4444') # person3
        ]
      end
      let(:shared_phones) { ['1 (123) 456-7890', '555.512.3456 ext 23'] }
      let(:owner_ids) do
        ownership_records.map {|r| r['OwnerId'] }
      end
      let(:expected_owner_ids) { %w[person1 person1 person2 person2 person1 person3] }

      it 'contains three unique owners' do
        expect(owner_ids).to eq(expected_owner_ids)
      end
    end

    context 'when there are multiple records with matching emails and phones, matching on email_or_phone' do
      subject(:ownership_records) do
        sample_records.map {|r| person_matcher.check_ownership(r) }
      end

      let(:match_type) { :email_or_phone }
      let(:sample_records) do
        [
          gen_fake_record(phone: shared_phones.first, email: shared_emails.first), # person1
          gen_fake_record(phone: shared_phones.first, email: shared_emails.last), # person1 via phone
          gen_fake_record(phone: shared_phones.last, email: shared_emails.first), # person1 via email
          gen_fake_record(phone: '555-111-1111', email: shared_emails.last), # person1 via transitive email
          gen_fake_record(phone: shared_phones.last, email: 'unique@example.com'), # person1 via transitive phone
          gen_fake_record(phone: '555-222-2222', email: 'i.am.unique@example.com'), # person2
          gen_fake_record, # person3
          gen_fake_record(email: 'mr.smith@example.com'), # person4
          gen_fake_record(phone: '555-333-3333') # person5
        ]
      end
      let(:shared_phones) { ['1 (123) 456-7890', '555.1234.5678'] }
      let(:shared_emails) { %w[email.thief@example.com another.thief@example.com] }
      let(:owner_ids) do
        ownership_records.map {|r| r['OwnerId'] }
      end
      let(:expected_owner_ids) { %w[person1 person1 person1 person1 person1 person2 person3 person4 person5] }

      it 'contains the three unique owner ids in the expected order' do
        expect(owner_ids).to eq(expected_owner_ids)
      end
    end
  end

  def gen_fake_record(owner_id: '', phone: '', email: '')
    {
      'OwnerId'   => owner_id,
      'FirstName' => 'John',
      'LastName'  => 'Doe',
      'Phone'     => phone,
      'Email'     => email,
      'Zip'       => rand(10_000..99_999).to_s
    }
  end
end
