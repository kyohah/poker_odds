module PokerOdds
  class Hand
    include Virtus.model

    attribute :player_hands, Array, default: []
    attribute :flop_cards, PokerTrump::Cards
    attribute :turn_card, PokerTrump::Card
    attribute :river_card, PokerTrump::Card

    attribute :expose_cards, PokerTrump::Cards

    def player=(str)
      self.player_hands = str.split(',').map do |s|
        PokerTrump::Cards.from_string(s.lstrip)
      end
      self
    end

    def flop=(str)
      self.flop_cards = PokerTrump::Cards.from_string(str)
      self
    end

    def turn=(str)
      self.turn_card = PokerTrump::Card.from_string(str)
      self
    end

    def river=(s)
      self.river_cards = PokerTrump::Card.from_string(str)
      self
    end

    def equities
      z = deck.each_with_object({}) do |card, a|
        scores = player_hands.each_with_object({}) do |player_hand, h|
          cards = player_hand
          cards = cards.add_cards(flop_cards)
          cards = cards.add_card(turn_card)
          cards = cards.add_card(card)

          h[cards.score] ||= []
          h[cards.score] << player_hand
        end

        a[card] = {}
        if scores.keys.size == 1
          a[card][:tie_hands] = player_hands
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

      player_hands.each_with_object({}) do |player_hand, h|
        win_hands = z.select { |a,b| b[:win_hands]&.include?(player_hand) }
        win_rate = win_hands.size / s
        h[player_hand] = {}
        h[player_hand][:win_rate] = win_rate
        h[player_hand][:lose_rate] = z.count { |a,b| b[:lose_hands]&.include?(player_hand) } / s
        h[player_hand][:tie_rate] = z.count { |a,b| b[:tie_hands]&.include?(player_hand) } / s
        h[player_hand][:outs] = win_hands.keys if win_rate < 0.5
      end
    end

    def flop_equities
      z = deck.combination(2).each_with_object({}) do |cs, a|
        scores = player_hands.each_with_object({}) do |player_hand, h|
          cards = player_hand
          cards = cards.add_cards(flop_cards)

          cs.each { |c| cards = cards.add_card(c) }

          h[cards.score] ||= []
          h[cards.score] << player_hand
        end

        a[cs] = {}
        if scores.keys.size == 1
          a[cs][:tie_hands] = player_hands
        else
          mk = scores.keys.max
          a[cs][:win_hands] = scores[mk]
          a[cs][:lose_hands] = scores.each_with_object([]) do |(k,v), a|
            next if k == mk

            a.concat(v)
          end
        end
      end

      s = z.size.to_f

      player_hands.each_with_object({}) do |player_hand, h|
        win_hands = z.select { |a,b| b[:win_hands]&.include?(player_hand) }
        win_rate = win_hands.size / s
        h[player_hand] = {}
        h[player_hand][:win_rate] = win_rate
        h[player_hand][:lose_rate] = z.count { |a,b| b[:lose_hands]&.include?(player_hand) } / s
        h[player_hand][:tie_rate] = z.count { |a,b| b[:tie_hands]&.include?(player_hand) } / s
        h[player_hand][:outs] = win_hands.keys if win_rate < 0.5
      end
    end

    def preflop_equities
      ran = deck.combination(5).to_a
      z = 10000.times.with_object({}) do |i, a|
        cs = ran.sample
        scores = player_hands.each_with_object({}) do |player_hand, h|
          cards = player_hand

          cs.each { |c| cards = cards.add_card(c) }

          h[cards.score] ||= []
          h[cards.score] << player_hand
        end

        a[cs] = {}
        if scores.keys.size == 1
          a[cs][:tie_hands] = player_hands
        else
          mk = scores.keys.max
          a[cs][:win_hands] = scores[mk]
          a[cs][:lose_hands] = scores.each_with_object([]) do |(k,v), a|
            next if k == mk

            a.concat(v)
          end
        end
      end

      s = z.size.to_f

      player_hands.each_with_object({}) do |player_hand, h|
        win_hands = z.select { |a,b| b[:win_hands]&.include?(player_hand) }
        win_rate = win_hands.size / s
        h[player_hand] = {}
        h[player_hand][:win_rate] = win_rate
        h[player_hand][:lose_rate] = z.count { |a,b| b[:lose_hands]&.include?(player_hand) } / s
        h[player_hand][:tie_rate] = z.count { |a,b| b[:tie_hands]&.include?(player_hand) } / s
        h[player_hand][:outs] = win_hands.keys if win_rate < 0.5
      end
    end

    def deck
      cards = PokerTrump::Cards.new_deck
      cards.delete_cards!(expose_cards) unless expose_cards.size == 0
      player_hands.each do |player_hand|
        cards.delete_cards!(player_hand)
      end
      cards.delete_cards!(flop_cards) unless flop_cards.size == 0
      cards.delete_card!(turn_card) if !!turn_card
      cards.delete_card!(river_card) if !!river_card

      cards
    end
  end
end
