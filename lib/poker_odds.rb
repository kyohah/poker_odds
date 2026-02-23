# frozen_string_literal: true

require "poker_odds/poker_odds" # native Rust extension
require_relative "poker_odds/version"
require_relative "poker_odds/hand"

module PokerOdds
  class Error < StandardError; end
end
