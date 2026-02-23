use holdem_hand_evaluator::Hand;
use magnus::{function, prelude::*, Error, RHash, Ruby, Symbol};

// ---------------------------------------------------------------------------
// Card helpers
// ---------------------------------------------------------------------------

/// Parse a card string (with or without spaces) into a list of card IDs 0-51.
/// Card IDs: rank_id * 4 + suit_id
///   rank: 2=0, 3=1, ..., 9=7, T=8, J=9, Q=10, K=11, A=12
///   suit: c=0, d=1, h=2, s=3
fn parse_card_ids(s: &str) -> Result<Vec<usize>, String> {
    let s = s.replace(' ', "");
    if s.is_empty() {
        return Ok(vec![]);
    }
    if s.len() % 2 != 0 {
        return Err(format!("Invalid card string (odd length): '{}'", s));
    }
    s.as_bytes()
        .chunks(2)
        .map(|chunk| {
            let rank_id = match (chunk[0] as char).to_ascii_uppercase() {
                '2' => Ok(0),
                '3' => Ok(1),
                '4' => Ok(2),
                '5' => Ok(3),
                '6' => Ok(4),
                '7' => Ok(5),
                '8' => Ok(6),
                '9' => Ok(7),
                'T' => Ok(8),
                'J' => Ok(9),
                'Q' => Ok(10),
                'K' => Ok(11),
                'A' => Ok(12),
                c => Err(format!("Invalid rank char: '{}'", c)),
            }?;
            let suit_id = match (chunk[1] as char).to_ascii_lowercase() {
                'c' => Ok(0),
                'd' => Ok(1),
                'h' => Ok(2),
                's' => Ok(3),
                c => Err(format!("Invalid suit char: '{}'", c)),
            }?;
            Ok(rank_id * 4 + suit_id)
        })
        .collect()
}

fn card_id_to_string(id: usize) -> String {
    const RANKS: &[char] = &['2', '3', '4', '5', '6', '7', '8', '9', 'T', 'J', 'Q', 'K', 'A'];
    const SUITS: &[char] = &['c', 'd', 'h', 's'];
    format!("{}{}", RANKS[id / 4], SUITS[id % 4])
}

/// Build remaining deck excluding the given card IDs.
/// Uses a 52-element bool array instead of HashSet for efficiency.
fn build_deck(excluded: &[usize]) -> Vec<usize> {
    let mut used = [false; 52];
    for &id in excluded {
        used[id] = true;
    }
    (0..52).filter(|&i| !used[i]).collect()
}

// ---------------------------------------------------------------------------
// Hand evaluation
// ---------------------------------------------------------------------------

fn evaluate_players(player_ids: &[Vec<usize>], board_ids: &[usize]) -> Vec<u16> {
    player_ids
        .iter()
        .map(|hole| {
            let all: Vec<usize> = hole.iter().chain(board_ids.iter()).copied().collect();
            Hand::from_slice(&all).evaluate()
        })
        .collect()
}

// ---------------------------------------------------------------------------
// Win/loss/tie counting
// ---------------------------------------------------------------------------

fn compute_outcomes(all_scores: &[Vec<u16>], n: usize) -> (Vec<u32>, Vec<u32>, Vec<u32>) {
    let mut wins = vec![0u32; n];
    let mut losses = vec![0u32; n];
    let mut ties = vec![0u32; n];

    for scores in all_scores {
        let max = match scores.iter().max() {
            Some(&v) => v,
            None => continue,
        };
        let winner_count = scores.iter().filter(|&&s| s == max).count();
        for (i, &score) in scores.iter().enumerate() {
            if score == max {
                if winner_count == 1 {
                    wins[i] += 1;
                } else {
                    ties[i] += 1;
                }
            } else {
                losses[i] += 1;
            }
        }
    }

    (wins, losses, ties)
}

// ---------------------------------------------------------------------------
// Common result hash helper
// ---------------------------------------------------------------------------

fn make_stats_hash(win_rate: f64, lose_rate: f64, tie_rate: f64) -> Result<RHash, Error> {
    let inner = RHash::new();
    inner.aset(Symbol::new("win_rate"), win_rate)?;
    inner.aset(Symbol::new("lose_rate"), lose_rate)?;
    inner.aset(Symbol::new("tie_rate"), tie_rate)?;
    Ok(inner)
}

// ---------------------------------------------------------------------------
// Exposed Ruby functions
// ---------------------------------------------------------------------------

/// equities(player_hands, board_str, expose_str) -> Hash
///
/// board_str = flop + turn concatenated (4 cards, e.g. "Ah9hJd3d").
/// River card is unknown; all remaining deck cards are exhausted.
/// outs: winning river cards for each losing player (Vec<String>).
fn equities(
    player_hands: Vec<String>,
    board_str: String,
    expose_str: String,
) -> Result<RHash, Error> {
    let n = player_hands.len();

    let player_ids: Vec<Vec<usize>> = player_hands
        .iter()
        .map(|s| parse_card_ids(s).map_err(|e| Error::new(magnus::exception::arg_error(), e)))
        .collect::<Result<_, _>>()?;

    let board_ids = parse_card_ids(&board_str)
        .map_err(|e| Error::new(magnus::exception::arg_error(), e))?;
    let expose_ids = parse_card_ids(&expose_str)
        .map_err(|e| Error::new(magnus::exception::arg_error(), e))?;

    let mut excluded = board_ids.clone();
    for ids in &player_ids {
        excluded.extend_from_slice(ids);
    }
    excluded.extend_from_slice(&expose_ids);

    let deck = build_deck(&excluded);

    let mut all_scores: Vec<Vec<u16>> = Vec::with_capacity(deck.len());
    // outs[player] = list of single river cards that make them win outright
    let mut outs: Vec<Vec<usize>> = vec![Vec::new(); n];

    // Reuse board buffer to avoid per-iteration allocation
    let mut board = board_ids.clone();
    board.push(0);
    let river_slot = board.len() - 1;

    for &river in &deck {
        board[river_slot] = river;
        let scores = evaluate_players(&player_ids, &board);

        let max = scores.iter().copied().max().unwrap_or(0);
        let winner_count = scores.iter().filter(|&&s| s == max).count();
        for (i, &score) in scores.iter().enumerate() {
            if score == max && winner_count == 1 {
                outs[i].push(river);
            }
        }

        all_scores.push(scores);
    }

    let total = all_scores.len() as f64;
    let (wins, losses, ties) = compute_outcomes(&all_scores, n);

    let result = RHash::new();
    for (i, hand_str) in player_hands.iter().enumerate() {
        let win_rate = wins[i] as f64 / total;
        let inner = make_stats_hash(win_rate, losses[i] as f64 / total, ties[i] as f64 / total)?;
        if win_rate < 0.5 {
            let outs_strs: Vec<String> = outs[i].iter().map(|&id| card_id_to_string(id)).collect();
            inner.aset(Symbol::new("outs"), outs_strs)?;
        }
        result.aset(hand_str.clone(), inner)?;
    }
    Ok(result)
}

/// flop_equities(player_hands, flop_str, expose_str) -> Hash
///
/// flop_str = 3 flop cards (e.g. "Ah9hJd").
/// Turn and river are both unknown; all C(deck, 2) combinations are exhausted.
/// outs: winning [turn, river] pairs for each losing player (Vec<Vec<String>>).
fn flop_equities(
    player_hands: Vec<String>,
    flop_str: String,
    expose_str: String,
) -> Result<RHash, Error> {
    let n = player_hands.len();

    let player_ids: Vec<Vec<usize>> = player_hands
        .iter()
        .map(|s| parse_card_ids(s).map_err(|e| Error::new(magnus::exception::arg_error(), e)))
        .collect::<Result<_, _>>()?;

    let flop_ids = parse_card_ids(&flop_str)
        .map_err(|e| Error::new(magnus::exception::arg_error(), e))?;
    let expose_ids = parse_card_ids(&expose_str)
        .map_err(|e| Error::new(magnus::exception::arg_error(), e))?;

    let mut excluded = flop_ids.clone();
    for ids in &player_ids {
        excluded.extend_from_slice(ids);
    }
    excluded.extend_from_slice(&expose_ids);

    let deck = build_deck(&excluded);
    let d = deck.len();

    let combo_count = d * (d - 1) / 2;
    let mut all_scores: Vec<Vec<u16>> = Vec::with_capacity(combo_count);
    // outs[player] = list of (turn, river) pairs that make them win outright
    let mut outs: Vec<Vec<(usize, usize)>> = vec![Vec::new(); n];

    // Reuse board buffer to avoid per-combination allocation
    let mut board = flop_ids.clone();
    board.push(0);
    board.push(0);
    let turn_slot = board.len() - 2;
    let river_slot = board.len() - 1;

    for i in 0..d {
        for j in (i + 1)..d {
            board[turn_slot] = deck[i];
            board[river_slot] = deck[j];
            let scores = evaluate_players(&player_ids, &board);

            let max = scores.iter().copied().max().unwrap_or(0);
            let winner_count = scores.iter().filter(|&&s| s == max).count();
            for (p, &score) in scores.iter().enumerate() {
                if score == max && winner_count == 1 {
                    outs[p].push((deck[i], deck[j]));
                }
            }

            all_scores.push(scores);
        }
    }

    let total = all_scores.len() as f64;
    let (wins, losses, ties) = compute_outcomes(&all_scores, n);

    let result = RHash::new();
    for (i, hand_str) in player_hands.iter().enumerate() {
        let win_rate = wins[i] as f64 / total;
        let inner = make_stats_hash(win_rate, losses[i] as f64 / total, ties[i] as f64 / total)?;
        if win_rate < 0.5 {
            let outs_pairs: Vec<Vec<String>> = outs[i]
                .iter()
                .map(|&(t, r)| vec![card_id_to_string(t), card_id_to_string(r)])
                .collect();
            inner.aset(Symbol::new("outs"), outs_pairs)?;
        }
        result.aset(hand_str.clone(), inner)?;
    }
    Ok(result)
}

/// preflop_equities(player_hands, expose_str) -> Hash
///
/// No community cards known. Exhaustively iterates all C(deck, 5) boards.
/// outs: winning 5-card boards for each losing player (Vec<Vec<String>>).
fn preflop_equities(player_hands: Vec<String>, expose_str: String) -> Result<RHash, Error> {
    let n = player_hands.len();

    let player_ids: Vec<Vec<usize>> = player_hands
        .iter()
        .map(|s| parse_card_ids(s).map_err(|e| Error::new(magnus::exception::arg_error(), e)))
        .collect::<Result<_, _>>()?;

    let expose_ids = parse_card_ids(&expose_str)
        .map_err(|e| Error::new(magnus::exception::arg_error(), e))?;

    let mut excluded = Vec::new();
    for ids in &player_ids {
        excluded.extend_from_slice(ids);
    }
    excluded.extend_from_slice(&expose_ids);

    let deck = build_deck(&excluded);
    let d = deck.len();

    let mut all_scores: Vec<Vec<u16>> = Vec::new();
    // outs[player] = list of 5-card boards that make them win outright
    let mut outs: Vec<Vec<[usize; 5]>> = vec![Vec::new(); n];

    for i0 in 0..d {
        let flop1 = deck[i0];
        for i1 in (i0 + 1)..d {
            let flop2 = deck[i1];
            for i2 in (i1 + 1)..d {
                let flop3 = deck[i2];
                for i3 in (i2 + 1)..d {
                    let turn = deck[i3];
                    for i4 in (i3 + 1)..d {
                        let river = deck[i4];
                        let board = [flop1, flop2, flop3, turn, river];
                        let scores = evaluate_players(&player_ids, &board);

                        let max = scores.iter().copied().max().unwrap_or(0);
                        let winner_count = scores.iter().filter(|&&s| s == max).count();
                        for (p, &score) in scores.iter().enumerate() {
                            if score == max && winner_count == 1 {
                                outs[p].push(board);
                            }
                        }

                        all_scores.push(scores);
                    }
                }
            }
        }
    }

    let total = all_scores.len() as f64;
    let (wins, losses, ties) = compute_outcomes(&all_scores, n);

    let result = RHash::new();
    for (i, hand_str) in player_hands.iter().enumerate() {
        let win_rate = wins[i] as f64 / total;
        let inner = make_stats_hash(win_rate, losses[i] as f64 / total, ties[i] as f64 / total)?;
        if win_rate < 0.5 {
            let outs_boards: Vec<Vec<String>> = outs[i]
                .iter()
                .map(|board| board.iter().map(|&id| card_id_to_string(id)).collect())
                .collect();
            inner.aset(Symbol::new("outs"), outs_boards)?;
        }
        result.aset(hand_str.clone(), inner)?;
    }
    Ok(result)
}

// ---------------------------------------------------------------------------
// Entry point
// ---------------------------------------------------------------------------

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("PokerOdds")?;
    let evaluator = module.define_module("Evaluator")?;
    evaluator.define_module_function("equities", function!(equities, 3))?;
    evaluator.define_module_function("flop_equities", function!(flop_equities, 3))?;
    evaluator.define_module_function("preflop_equities", function!(preflop_equities, 2))?;
    Ok(())
}
