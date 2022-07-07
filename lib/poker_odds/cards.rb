module PokerOdds
  class Cards < Array
    include Comparable
    DeleteError = Class.new(StandardError)

    STRAIGHT_PATTERNS = (6..14).to_a.reverse.map { |i| (0..4).map {|j| i - j }  }.push([5,4,3,2,14]).map { |a| /#{a[0]}.+#{a[1]}.+#{a[2]}.+#{a[3]}.+#{a[4]}/ }.freeze

    class << self
      def new_deck
        new(Card::RANKS.flat_map do |rank|
          Card::SUITS.map do |suit|
            Card.new(suit: suit, rank: rank)
          end
        end)
      end

      def string_parse(string)
        a = string.split.map do |s|
          Card.new(rank: s[0], suit: s[1])
        end

        new(a)
      end

      def json_parse(json)
        h = JSON.parse(json)

        b = h.map { |a| Card.new(rank: a['rank'].to_sym, suit: a['suit'].to_sym) }

        Hands.new(b)
      end
    end

    def delete_card!(card)
      i = index(card)
      raise DeleteError if i.nil?

      delete_at(i)
      self
    end

    def delete_card(card)
      i = index(card)
      raise DeleteError if i.nil?

      clone_cards = clone
      clone_cards.delete_at(i)

      clone_cards
    end

    def delete_cards!(cards)
      cards.each { |t| delete_card!(t) }
      self
    end

    def delete_cards(cards)
      clone_cards = clone
      cards.each { |t| clone_cards.delete_card!(t) }
      clone_cards
    end

    def add_card(card)
      clone_cards = clone
      clone_cards.push(card)
    end

    def add_card!(card)
      push(card)
    end

    def add_cards(cards)
      clone_cards = clone

      cards.each { |card| clone_cards.add_card!(card) }
      clone_cards
    end

    def add_cards!(cards)
      cards.each { |card| add_card!(card) }
      self
    end

    def sort_by_suit
      @sort_by_suit ||= self.class.new(sort_by { |card| [card.suit, card.rank_value] }.reverse)
    end

    def sort_by_rank
      @sort_by_rank ||= self.class.new(sort_by { |card| [card.rank_value, card.suit] }.reverse)
    rescue => e
      binding.pry
    end

    def to_s
      map { |c| "#{c.rank}#{c.suit}" }.join(' ')
    end

    def to_s_rank_value
      map(&:rank_value).join(' ')
    end

    def group_by_suit
      @group_by_suit ||= group_by(&:suit).each_with_object({}) { |(k, v), h| h[k] = self.class.new(v).sort_by_rank }
    end

    def royal_flush_rate
      [10, 0,0,0,0,0] if /A(.) K\1 Q\1 J\1 T\1/.match?(sort_by_suit.to_s)
    end

    def straight_flush_rate
      group_by_suit.each do |k, v|
        next if v.size < 5

        a = v.straight_rate
        if a
          return [9, a[1], a[2], a[3], a[4], a[5]]
        end
      end
      nil
    end

    def four_of_a_kind_rate
      a = sort_by_rank.to_s.match(/(.). \1. \1. \1./)

      if a
        b = (a.pre_match + a.post_match).match(/(\S)/).to_s

        [8, PokerOdds::Card::RANK_VALUE[a[1]], PokerOdds::Card::RANK_VALUE[b.to_s], 0, 0,0]
      end
    end

    def full_house_rate
      case sort_by_rank.to_s
      when /(.). \1. \1. (.*)(.). \3./
        [7, PokerOdds::Card::RANK_VALUE[$1], PokerOdds::Card::RANK_VALUE[$3], 0, 0,0]
      when /((.). \2.) (.*)((.). \5. \5.)/
        [7, PokerOdds::Card::RANK_VALUE[$5], PokerOdds::Card::RANK_VALUE[$2], 0, 0,0]
      else
        nil
      end
    end

    def flush_rate
      group_by_suit.each do |k, v|
        next if v.size < 5

        return [6, v[0].rank_value, v[1].rank_value, v[2].rank_value, v[3].rank_value, v[4].rank_value]
      end

      nil
    end

    def straight_rate
      a = sort_by_rank.to_s.match(/(?<_A>A.+K.+Q.+J.+T)|(?<_K>K.+Q.+J.+T.+9)|(?<_Q>Q.+J.+T.+9.+8)|(?<_J>J.+T.+9.+8.+7)|(?<_T>T.+9.+8.+7.+6)|(?<_9>9.+8.+7.+6.+5)|(?<_8>8.+7.+6.+5.+4)|(?<_7>7.+6.+5.+4.+3)|(?<_6>6.+5.+4.+3.+2)|(?<_5>A.+5.+4.+3.+2)/)
      if a
        case k
        when :_A
          [5, *PokerOdds::Card::RANK_VALUE.values_at('A', 'K', 'Q','J', 'T')]
        when :_K
          [5, *PokerOdds::Card::RANK_VALUE.values_at('K', 'Q', 'J','T', '9')]
        when :_Q
          [5, *PokerOdds::Card::RANK_VALUE.values_at('Q', 'J', 'T','9', '8')]
        when :_J
          [5, *PokerOdds::Card::RANK_VALUE.values_at('J', 'T', '9','8', '7')]
        when :_T
          [5, *PokerOdds::Card::RANK_VALUE.values_at('T', '9', '8','7', '6')]
        when :_9
          [5, *PokerOdds::Card::RANK_VALUE.values_at('9', '8', '7','6', '5')]
        when :_8
          [5, *PokerOdds::Card::RANK_VALUE.values_at('8', '7', '6','5', '4')]
        when :_7
          [5, *PokerOdds::Card::RANK_VALUE.values_at('7', '6', '5','4', '3')]
        when :_6
          [5, *PokerOdds::Card::RANK_VALUE.values_at('6', '5', '4','3', '2')]
        when :_5
          [5, *PokerOdds::Card::RANK_VALUE.values_at('5', '4', '3','2', 'A')]
        end
      else
        nil
      end
    end

    def three_of_a_kind_rate
      md = sort_by_rank.to_s.match(/(.). \1. \1./)

      if md
        arranged_hand = (md.pre_match + md.post_match).strip.squeeze(" ")

        [4, PokerOdds::Card::RANK_VALUE[md[1]], PokerOdds::Card::RANK_VALUE[arranged_hand[0]], PokerOdds::Card::RANK_VALUE[arranged_hand[3]], 0, 0]
      else
        nil
      end
    end

    def two_pair_rate
      md = sort_by_rank.to_s.match(/(.). \1.(.*?) (.). \3./)

      if md
        arranged_hand = (md.pre_match + ' ' + md[2] + ' ' + md.post_match).strip.squeeze(" ")
        [3, PokerOdds::Card::RANK_VALUE[md[1]], PokerOdds::Card::RANK_VALUE[md[3]], PokerOdds::Card::RANK_VALUE[arranged_hand[0]], 0, 0]
      else
        nil
      end
    end

    def one_pair_rate
      md = sort_by_rank.to_s.match(/(.). \1./)

      if md
        arranged_hand = (md.pre_match + ' ' + md.post_match).strip.squeeze(" ")

        [2, PokerOdds::Card::RANK_VALUE[md[1]], PokerOdds::Card::RANK_VALUE[arranged_hand[0]], PokerOdds::Card::RANK_VALUE[arranged_hand[3]], PokerOdds::Card::RANK_VALUE[arranged_hand[6]], 0]
      else
        nil
      end
    end

    def high_card_rate
      arranged_hand = sort_by_rank.to_s

      [1, PokerOdds::Card::RANK_VALUE[arranged_hand[0]], PokerOdds::Card::RANK_VALUE[arranged_hand[3]], PokerOdds::Card::RANK_VALUE[arranged_hand[6]], PokerOdds::Card::RANK_VALUE[arranged_hand[9]], PokerOdds::Card::RANK_VALUE[arranged_hand[12]]]
    end

    def score
      @score ||= royal_flush_rate || straight_flush_rate || four_of_a_kind_rate || full_house_rate || flush_rate || straight_flush_rate || three_of_a_kind_rate || two_pair_rate || one_pair_rate || high_card_rate
    end

    def <=>(other_cards)
      score <=> other_cards.score
    end
  end
end
