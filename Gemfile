# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'danger', group: :danger_dependencies
gem 'fastlane', group: :fastlane_dependencies
gem 'jazzy'
gem 'json'
gem 'rubocop', '1.38', group: :rubocop_dependencies
gem 'sinatra', group: :sinatra_dependencies
gem 'slather'

eval_gemfile('fastlane/Pluginfile')

group :fastlane_dependencies do
  gem 'cocoapods'
  gem 'fastlane-plugin-lizard'
  gem 'plist'
  gem 'xcode-install'
  gem 'xctest_list'
end

group :sinatra_dependencies do
  gem 'puma'
  gem 'rackup'
  gem 'stream-chat-ruby', '3.0.0'
end

group :rubocop_dependencies do
  gem 'rubocop-performance'
  gem 'rubocop-require_tools'
end

group :danger_dependencies do
  gem 'danger-commit_lint'
end
