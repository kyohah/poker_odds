# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Install dependencies
bin/setup
# or
bundle install

# Run all tests
bundle exec rspec
# or
rake spec

# Run a single test file
bundle exec rspec spec/poker_odds_spec.rb

# Run a single example by line number
bundle exec rspec spec/poker_odds_spec.rb:10

# Interactive console with Pry
bundle exec bin/console

# Build gem
bundle exec rake build

# Install gem locally
bundle exec rake install
```

## Architecture

This is a Ruby gem (`poker_odds`) that calculates poker hand equity using Monte Carlo and combinatorial simulations.

### Core module: `PokerOdds::Hand` (`lib/poker_odds/hand.rb`)

The central class. Uses `virtus` gem for typed attributes and `poker_trump` gem for card representation and hand scoring.

**Attributes (set via Virtus or DSL setters):**
- `player_hands` — Array of player hole card pairs
- `flop_cards`, `turn_card`, `river_card` — Community cards
- `expose_cards` — Cards known to be out of the deck

**DSL setters** parse comma-separated card strings:
```ruby
round.player = '9d 9c, Kd Kc'  # sets player_hands
round.flop   = 'Ah 9h Jd'
round.turn   = '3d'
```

**Equity methods** — each returns a hash keyed by player hand, with `{ win_rate:, lose_rate:, tie_rate:, outs: }`:

| Method | Stage | Strategy |
|---|---|---|
| `equities` | Turn (river unknown) | Exhaustive iteration over remaining deck |
| `flop_equities` | Flop (turn+river unknown) | Exhaustive combinations of remaining deck |
| `preflop_equities` | Preflop | Monte Carlo (10,000 random samples) |

**`deck` method** computes remaining cards by removing all known cards (player hands, community cards, exposed cards) from a full 52-card deck.

### Known bug

`hand.rb` `river=` setter references `str` instead of the parameter `s` — calling `round.river = 'Xx'` will raise `NameError`.
