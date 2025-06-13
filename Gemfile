# frozen_string_literal: true

source 'https://rubygems.org'
ruby '>= 3.4' # keep in sync with .ruby-version

# Ruby 3.5 will not include benchmark in the stdlib
gem 'benchmark', require: false

gem 'pry'
gem 'rake'

# reline required to suppress a pry v0.15.2 deprecation warning for Ruby 3.5.0
# Pry PR tracking this issue: https://github.com/pry/pry/pull/2349
gem 'reline'

gem 'rubocop', require: false
gem 'rubocop-rspec', require: false

gem 'zeitwerk'

group :test do
  gem 'rspec'
  gem 'rspec-junklet'
  gem 'simplecov'
end
