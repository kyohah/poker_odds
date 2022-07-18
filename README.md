# PokerOdds

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/poker_odds`. To experiment with that code, run `bin/console` for an interactive prompt.

ポーカーのエクイティが分かる

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'poker_odds'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install poker_odds

## Usage

```
round = PokerOdds::Hand.new(flop: 'Ah 9h Jd', turn: '3d')
round.player='9d 9c, Kd Kc'

round.equities
# =>
{[#<PokerTrump::Card:0x00007fedc3889ab0 @rank="9", @suit=:d>, #<PokerTrump::Card:0x00007fedc38898f8 @rank="9", @suit=:c>]=>{:win_rate=>0.9545454545454546, :lose_rate=>0.045454545454545456, :tie_rate=>0.0},
 [#<PokerTrump::Card:0x00007fedc3889650 @rank="K", @suit=:d>, #<PokerTrump::Card:0x00007fedc38894e8 @rank="K", @suit=:c>]=>
  {:win_rate=>0.045454545454545456, :lose_rate=>0.9545454545454546, :tie_rate=>0.0, :outs=>[#<PokerTrump::Card:0x00007feda08a3208 @rank="K", @suit=:s>, #<PokerTrump::Card:0x00007feda08a2bc8 @rank="K", @suit=:h>]}}

```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/poker_odds. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [Contributor Covenant](http://contributor-covenant.org) code of conduct.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PokerOdds project’s codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/[USERNAME]/poker_odds/blob/master/CODE_OF_CONDUCT.md).
