# frozen_string_literal: true

require_relative "lib/poker_odds/version"

Gem::Specification.new do |spec|
  spec.name = "poker_odds"
  spec.version = PokerOdds::VERSION
  spec.authors = ["kyohah"]
  spec.email = ["kyohah@gmail.com"]

  spec.summary = "Fast poker hand equity calculator backed by a Rust native extension."
  spec.description = "Calculates win/lose/tie equity and outs for Texas Hold'em using " \
                     "exhaustive enumeration. Powered by holdem-hand-evaluator via a " \
                     "Magnus/rb-sys Rust extension (~1.2B evaluations/sec)."
  spec.homepage = "https://github.com/kyohah/poker_odds"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ Gemfile .gitignore .rspec spec/ .rubocop.yml tmp/])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = ["ext/poker_odds/extconf.rb"]

  spec.add_dependency "rb_sys", "~> 0.9"
end
