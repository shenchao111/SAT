///|
/// N-queens-to-SAT encoding. The problem of placing `n` non-attacking queens on
/// an `n`×`n` board is translated to a CNF formula with `n*n` variables
/// (`v(r,c)` = "a queen sits at row r, column c"), solved, and decoded back to
/// the column of the queen in each row.

/// Variable index for "a queen at row r, column c", with r, c in 0..<n. The
/// result is 1-based.
pub fn queen_var(n : Int, r : Int, c : Int) -> Int {
  r * n + c + 1
}

/// Encode the N-queens problem over an `n`×`n` board: exactly one queen per
/// column, and at most one per row and per diagonal (both directions).
pub fn encode_queens(n : Int) -> CNF {
  let cnf = CNF::new(n * n)
  // exactly one queen per column
  for c = 0; c < n; c = c + 1 {
    let at_least : Array[Int] = []
    for r = 0; r < n; r = r + 1 {
      at_least.push(queen_var(n, r, c))
    }
    cnf.add_clause(at_least)
    for r1 = 0; r1 < n; r1 = r1 + 1 {
      for r2 = r1 + 1; r2 < n; r2 = r2 + 1 {
        cnf.add_clause([negate(queen_var(n, r1, c)), negate(queen_var(n, r2, c))])
      }
    }
  }
  // at most one queen per row
  for r = 0; r < n; r = r + 1 {
    for c1 = 0; c1 < n; c1 = c1 + 1 {
      for c2 = c1 + 1; c2 < n; c2 = c2 + 1 {
        cnf.add_clause([negate(queen_var(n, r, c1)), negate(queen_var(n, r, c2))])
      }
    }
  }
  // at most one queen per diagonal: each pair of cells on a shared diagonal
  // (|r1-r2| == |c1-c2|) is forbidden together.
  for r1 = 0; r1 < n; r1 = r1 + 1 {
    for c1 = 0; c1 < n; c1 = c1 + 1 {
      for r2 = r1 + 1; r2 < n; r2 = r2 + 1 {
        let d = r2 - r1
        if c1 + d < n {
          cnf.add_clause([negate(queen_var(n, r1, c1)), negate(queen_var(n, r2, c1 + d))])
        }
        if c1 - d >= 0 {
          cnf.add_clause([negate(queen_var(n, r1, c1)), negate(queen_var(n, r2, c1 - d))])
        }
      }
    }
  }
  cnf
}

/// Decode a satisfying assignment into the column of the queen in each row
/// (`result[r]` is the column, 0-based).
pub fn decode_queens(n : Int, model : Array[Int]) -> Array[Int] {
  let cols : Array[Int] = []
  for r = 0; r < n; r = r + 1 {
    let mut col = 0
    for c = 0; c < n; c = c + 1 {
      if model[queen_var(n, r, c)] == 1 {
        col = c
      }
    }
    cols.push(col)
  }
  cols
}

/// Encode, solve and decode the N-queens problem; `None` when it has no
/// solution (e.g. `n = 2` or `n = 3`).
pub fn solve_queens(n : Int) -> Array[Int]? {
  let cnf = encode_queens(n)
  match solve(cnf) {
    Some(model) => Some(decode_queens(n, model))
    None => None
  }
}
