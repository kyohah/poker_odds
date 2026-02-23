# frozen_string_literal: true

RSpec.describe PokerOdds do
  it "has a version number" do
    expect(PokerOdds::VERSION).not_to be_nil
  end

  describe PokerOdds::Hand do
    describe "#equities" do
      it "returns win/lose/tie rates that sum to ~1.0" do
        round = described_class.new
        round.flop   = "Ah 9h Jd"
        round.turn   = "3d"
        round.player = "9d 9c, Kd Kc"

        result = round.equities
        expect(result.keys).to match_array(%w[9d9c KdKc])

        result.each_value do |stats|
          total = stats[:win_rate] + stats[:lose_rate] + stats[:tie_rate]
          expect(total).to be_within(0.001).of(1.0)
        end
      end

      it "gives the set a dominant win rate" do
        round = described_class.new
        round.flop   = "Ah 9h Jd"
        round.turn   = "3d"
        round.player = "9d 9c, Kd Kc"

        result = round.equities
        expect(result["9d9c"][:win_rate]).to be > 0.9
        expect(result["KdKc"][:win_rate]).to be < 0.1
      end

      it "returns outs for the losing hand" do
        round = described_class.new
        round.flop   = "Ah 9h Jd"
        round.turn   = "3d"
        round.player = "9d 9c, Kd Kc"

        result = round.equities
        expect(result["KdKc"][:outs]).to match_array(%w[Kh Ks])
      end
    end

    describe "#flop_equities" do
      it "returns win/lose/tie rates that sum to ~1.0" do
        round = described_class.new
        round.flop   = "Ah 9h Jd"
        round.player = "9d 9c, Kd Kc"

        result = round.flop_equities
        result.each_value do |stats|
          total = stats[:win_rate] + stats[:lose_rate] + stats[:tie_rate]
          expect(total).to be_within(0.001).of(1.0)
        end
      end

      it "returns outs as [turn, river] pairs for the losing hand" do
        round = described_class.new
        round.flop   = "Ah 9h Jd"
        round.player = "9d 9c, Kd Kc"

        result = round.flop_equities
        outs = result["KdKc"][:outs]
        expect(outs).to be_an(Array)
        expect(outs).not_to be_empty
        expect(outs.first).to be_an(Array)
        expect(outs.first.size).to eq(2)
        expect(outs.first).to all(match(/\A[2-9TJQKA][cdhs]\z/))
      end
    end

    describe "#preflop_equities" do
      it "correctly ranks pocket kings over pocket nines preflop" do
        round = described_class.new
        round.player = "9d 9c, Kd Kc"

        result = round.preflop_equities
        expect(result["KdKc"][:win_rate]).to be > result["9d9c"][:win_rate]
      end

      it "returns outs as 5-card boards for the losing hand" do
        round = described_class.new
        round.player = "9d 9c, Kd Kc"

        result = round.preflop_equities
        outs = result["9d9c"][:outs]
        expect(outs).to be_an(Array)
        expect(outs.first).to be_an(Array)
        expect(outs.first.size).to eq(5)
      end

      it "works with 3 players" do
        round = described_class.new
        round.player = "9d 9c, Kd Kc, 2h 2s"

        result = round.preflop_equities
        expect(result.keys).to match_array(%w[9d9c KdKc 2h2s])
        result.each_value do |stats|
          total = stats[:win_rate] + stats[:lose_rate] + stats[:tie_rate]
          expect(total).to be_within(0.001).of(1.0)
        end
        expect(result["KdKc"][:win_rate]).to be > result["9d9c"][:win_rate]
        expect(result["KdKc"][:win_rate]).to be > result["2h2s"][:win_rate]
      end
    end
  end
end
