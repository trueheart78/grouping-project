# frozen_string_literal: true

RSpec.describe 'RuboCop' do
  subject(:status) { system('rubocop --fail-fast --config .rubocop.yml >/dev/null 2>&1') }

  it 'passes' do
    expect(status).to be true
  end
end
