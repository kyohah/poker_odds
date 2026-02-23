# PokerOdds

Texas Hold'em のポーカーハンドエクイティ計算 Ruby gem です。
内部に Rust ネイティブ拡張を持ち、完全探索によって高速にエクイティ・アウツを算出します。

## 特徴

- **高速**: Rust 製ハンド評価エンジン [holdem-hand-evaluator](https://github.com/b-inary/holdem-hand-evaluator) を採用（〜12億評価/秒）
- **完全探索**: モンテカルロではなく全残余カードの組み合わせを網羅
- **プリコンパイル済みバイナリ配布**: 主要プラットフォーム向けにコンパイル済みgemを提供するため、利用時に Rust は不要
- **アウツ計算**: 負けているハンドが逆転できるカード（アウツ）を返す

## インストール

```ruby
gem "poker_odds"
```

```sh
bundle install
# または
gem install poker_odds
```

## 使い方

### equities — ターン後（残りリバーを全探索）

```ruby
round = PokerOdds::Hand.new
round.flop   = "Ah 9h Jd"
round.turn   = "3d"
round.player = "9d 9c, Kd Kc"

result = round.equities
# => {
#   "9d9c" => { win_rate: 0.954, lose_rate: 0.045, tie_rate: 0.0, outs: [] },
#   "KdKc" => { win_rate: 0.045, lose_rate: 0.954, tie_rate: 0.0, outs: ["Kh", "Ks"] }
# }
```

`outs` は負けているハンドが勝てるリバーカードの配列です。

### flop_equities — フロップ後（ターン+リバーの全組み合わせを探索）

```ruby
round = PokerOdds::Hand.new
round.flop   = "Ah 9h Jd"
round.player = "9d 9c, Kd Kc"

result = round.flop_equities
# => {
#   "9d9c" => { win_rate: 0.87, lose_rate: 0.12, tie_rate: 0.0, outs: [] },
#   "KdKc" => { win_rate: 0.12, lose_rate: 0.87, tie_rate: 0.0,
#               outs: [["Kh", "2c"], ["Ks", "7d"], ...] }
# }
```

`outs` は `[turn, river]` のペア配列です。

### preflop_equities — プリフロップ（ボード5枚の全組み合わせを探索）

```ruby
round = PokerOdds::Hand.new
round.player = "9d 9c, Kd Kc"

result = round.preflop_equities
# => {
#   "KdKc" => { win_rate: 0.77, lose_rate: 0.22, tie_rate: 0.0, outs: [] },
#   "9d9c" => { win_rate: 0.22, lose_rate: 0.77, tie_rate: 0.0,
#               outs: [["9h", "9s", "2c", "3d", "7h"], ...] }
# }
```

`outs` は `[flop1, flop2, flop3, turn, river]` の5枚ボード配列です。

### 3人以上のプレイヤー

```ruby
round = PokerOdds::Hand.new
round.player = "9d 9c, Kd Kc, 2h 2s"

result = round.preflop_equities
result.each do |hand, stats|
  puts "#{hand}: win=#{stats[:win_rate].round(3)}"
end
```

### expose（公開済みカードの指定）

デッキから除外したいカード（バーンカードなど）を指定できます:

```ruby
round = PokerOdds::Hand.new
round.flop   = "Ah 9h Jd"
round.turn   = "3d"
round.expose = "2c 7s"   # デッキに存在しないカードとして扱う
round.player = "9d 9c, Kd Kc"
result = round.equities
```

## 開発

```sh
# 依存パッケージのインストール（Rust も必要）
bin/setup

# テスト実行
bundle exec rspec

# ネイティブ拡張のコンパイル
bundle exec rake compile

# 全タスク（compile + spec + rubocop）
bundle exec rake
```

## ライセンス

このgemは [MIT License](https://opensource.org/licenses/MIT) のもとで公開されています。

### サードパーティライセンス

このgemは以下のOSSを内部で使用しています:

| ライブラリ | 作者 | ライセンス | 用途 |
|---|---|---|---|
| [holdem-hand-evaluator](https://github.com/b-inary/holdem-hand-evaluator) | Wataru Inariba (b-inary) | MIT | Rust製ポーカーハンド評価エンジン |

holdem-hand-evaluator の著作権表示:

```
MIT License

Copyright (c) 2020 Wataru Inariba

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
