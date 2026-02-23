require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

Rake::ExtensionTask.new("poker_odds") do |ext|
  ext.lib_dir = "lib/poker_odds"
end

task default: [:compile, :spec]
