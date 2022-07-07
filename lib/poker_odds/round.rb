module PokerOdds
  class Round < Hash
    include Hashie::Extensions::Coercion
    include Hashie::Extensions::MergeInitializer
    include Hashie::Extensions::MethodAccess

    coerce_key :hands, Array
    coerce_key :flop_cards, PokerOdds::Cards
    coerce_key :turn_card, PokerOdds::Card
    coerce_key :river_card, PokerOdds::Card

    coerce_key :expose_cards, PokerOdds::Cards

    # class << self
    #   def flop =(h)

    #   end
    # end

    def initialize(**arg)
      self.flop=arg[:flop] if arg[:flop]
      self.turn=arg[:turn] if arg[:turn]
      self.river=arg[:river] if arg[:river]

      self[:hands] ||= []
      self[:expose_cards] ||= PokerOdds::Cards.new
      self[:flop_cards] ||= PokerOdds::Cards.new
      self[:turn_card] ||= PokerOdds::Card.new
      self[:river_card] ||= PokerOdds::Card.new
    end

    def add_hand(s)
      self[:hands] << PokerOdds::Cards.string_parse(s)
      self
    end

    def flop=(s)
      self[:flop_cards] = PokerOdds::Cards.string_parse(s)
      self
    end

    def turn=(s)
      self[:turn_card] = PokerOdds::Card.string_parse(s)
      self
    end

    def river=(s)
      self[:river_cards] = PokerOdds::Card.string_parse(s)
      self
    end

    def equities
      z = deck.each_with_object({}) do |card, a|
        scores = hands.each_with_object({}) do |hand, h|
          cards = hand
          cards = cards.add_cards(flop_cards)
          cards = cards.add_card(turn_card)
          cards = cards.add_card(card)

          if h[cards.score].present?
            h[cards.score] << hand
          else
            h[cards.score] = [hand]
          end
        end

        a[card] = {}
        if scores.keys.size == 1
          a[card][:tie_hands] = hands
        else
          mk = scores.keys.max
          a[card][:win_hands] = scores[mk]
          a[card][:lose_hands] = scores.each_with_object([]) do |(k,v), a|
            next if k == mk

            a.concat(v)
          end
        end
      end

      s = z.size.to_f

      hands.each_with_object({}) do |hand, h|
        win_hands = z.select { |a,b| b[:win_hands]&.include?(hand) }
        win_rate = win_hands.size / s
        h[hand] = {}
        h[hand][:win_rate] = win_rate
        h[hand][:lose_rate] = z.count { |a,b| b[:lose_hands]&.include?(hand) } / s
        h[hand][:tie_rate] = z.count { |a,b| b[:tie_hands]&.include?(hand) } / s
        h[hand][:outs] = win_hands.keys if win_rate < 0.5
      end
    end

    def deck
      cards = Cards.new_deck
      cards.delete_cards!(expose_cards) if expose_cards
      hands.each do |hand|
        cards.delete_cards!(hand)
      end
      cards.delete_cards!(flop_cards) if flop_cards.present?
      cards.delete_card!(turn_card) if turn_card.present?
      cards.delete_card!(river_card) if river_card.present?

      cards
    end
  end
end
