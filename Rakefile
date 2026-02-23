# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new("poker_odds") do |ext|
  ext.lib_dir = "lib/poker_odds"
end

RuboCop::RakeTask.new

task default: %i[compile spec rubocop]
