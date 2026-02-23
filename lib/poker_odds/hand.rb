module PokerOdds
  class Hand
    def initialize(**opts)
      @player_hands = []
      @flop_cards   = ""
      @turn_card    = nil
      @river_card   = nil
      @expose_cards = ""
      opts.each { |k, v| send(:"#{k}=", v) }
    end

    # Getters — return normalized (spaceless) internal representation
    def player  = @player_hands
    def flop    = @flop_cards
    def turn    = @turn_card
    def river   = @river_card
    def expose  = @expose_cards

    # "9d 9c, Kd Kc" -> ["9d9c", "KdKc"]
    def player=(str)
      @player_hands = str.split(",").map { |s| s.strip.delete(" ") }
      self
    end

    # "Ah 9h Jd" -> "Ah9hJd"
    def flop=(str)
      @flop_cards = str.delete(" ")
      self
    end

    # "3d" -> "3d"
    def turn=(str)
      @turn_card = str.strip
      self
    end

    # "Xx" -> "Xx"
    def river=(str)
      @river_card = str.strip
      self
    end

    # "Ah Kd" -> "AhKd"
    def expose=(str)
      @expose_cards = str.delete(" ")
      self
    end

    # Flop + turn known (4 cards). Exhaustively iterates all possible river cards.
    # Returns: { "9d9c" => { win_rate:, lose_rate:, tie_rate:, outs: [...] }, ... }
    def equities
      board = [@flop_cards, @turn_card].join
      PokerOdds::Evaluator.equities(@player_hands, board, @expose_cards)
    end

    # Flop known (3 cards). Exhaustively iterates all turn+river combinations.
    # Returns: { "9d9c" => { win_rate:, lose_rate:, tie_rate: }, ... }
    def flop_equities
      PokerOdds::Evaluator.flop_equities(@player_hands, @flop_cards, @expose_cards)
    end

    # No community cards. Exhaustively iterates all C(deck, 5) boards.
    # Returns: { "9d9c" => { win_rate:, lose_rate:, tie_rate:, outs: [[...], ...] }, ... }
    def preflop_equities
      PokerOdds::Evaluator.preflop_equities(@player_hands, @expose_cards)
    end
  end
end
