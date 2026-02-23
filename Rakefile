# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rb_sys/extensiontask"
require "rubocop/rake_task"

RSpec::Core::RakeTask.new(:spec)

GEMSPEC = Gem::Specification.load("poker_odds.gemspec")

RbSys::ExtensionTask.new("poker_odds", GEMSPEC) do |ext|
  ext.lib_dir = "lib/poker_odds"
  ext.cross_compile = true
  ext.cross_platform = %w[
    x86_64-linux
    aarch64-linux
    x86_64-darwin
    arm64-darwin
    x86_64-mingw-ucrt
  ]
end

RuboCop::RakeTask.new

task default: %i[compile spec rubocop]
