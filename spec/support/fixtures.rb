# frozen_string_literal: true

module Support::Fixtures
  def fixture_lines(filename)
    File.readlines fixture_path(filename)
  end

  def fixture_content(filename)
    File.read fixture_path(filename)
  end

  def fixture_path(filename)
    [
      File.expand_path('..', __dir__),
      '/fixtures/',
      filename
    ].join
  end
end
