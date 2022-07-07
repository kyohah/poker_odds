module PokerOdds
  class Card < Hash
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::MethodAccess

    RANKS = %w[A 2 3 4 5 6 7 8 9 T J Q K].freeze
    SUITS = %i[s h d c].freeze

    RANK_VALUE = {
      '2' => 2,
      '3' => 3,
      '4' => 4,
      '5' => 5,
      '6' => 6,
      '7' => 7,
      '8' => 8,
      '9' => 9,
      'T' => 10,
      'J' => 11,
      'Q' => 12,
      'K' => 13,
      'A' => 14
    }

    coerce_key :rank, String
    coerce_key :suit, Symbol

    class << self
      def string_parse(string)
        Card.new(rank: string[0], suit: string[1])
      end
    end

    def rank_value
      RANK_VALUE[rank]
    end
  end
end
