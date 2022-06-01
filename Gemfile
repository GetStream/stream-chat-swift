# frozen_string_literal: true

source 'https://rubygems.org'

git_source(:github) { |repo_name| "https://github.com/#{repo_name}" }

gem 'cocoapods'
gem 'danger'
gem 'danger-commit_lint'
gem 'fastlane'
gem 'fastlane-plugin-lizard'
gem 'jazzy'
gem 'json'
gem 'plist'
gem 'slather'
gem 'xcode-install'
gem 'xctest_list'

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
