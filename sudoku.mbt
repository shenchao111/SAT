///|
/// Sudoku-to-SAT encoding. A 9×9 Sudoku is translated to a CNF formula with
/// 729 variables (`v(r,c,d)` = "cell (r,c) holds digit d+1"), solved, and the
/// assignment decoded back into a 9×9 grid of digits 1–9.

/// Variable index for "row r, column c holds digit d", with r, c, d in 0..=8.
/// The result is 1-based.
pub fn cell_var(r : Int, c : Int, d : Int) -> Int {
  (r * 9 + c) * 9 + d + 1
}

/// Encode a 9×9 Sudoku puzzle. `givens` is a 9×9 grid of digits 1–9, with 0
/// marking empty cells.
pub fn encode(givens : Array[Array[Int]]) -> CNF {
  let cnf = CNF::new(729)
  // exactly one digit per cell
  for r = 0; r < 9; r = r + 1 {
    for c = 0; c < 9; c = c + 1 {
      let at_least : Array[Int] = []
      for d = 0; d < 9; d = d + 1 {
        at_least.push(cell_var(r, c, d))
      }
      cnf.add_clause(at_least)
      for d1 = 0; d1 < 9; d1 = d1 + 1 {
        for d2 = d1 + 1; d2 < 9; d2 = d2 + 1 {
          cnf.add_clause([negate(cell_var(r, c, d1)), negate(cell_var(r, c, d2))])
        }
      }
    }
  }
  // each row, column and 3×3 box contains each digit exactly once
  for d = 0; d < 9; d = d + 1 {
    // rows
    for r = 0; r < 9; r = r + 1 {
      let at_least : Array[Int] = []
      for c = 0; c < 9; c = c + 1 {
        at_least.push(cell_var(r, c, d))
      }
      cnf.add_clause(at_least)
      for c1 = 0; c1 < 9; c1 = c1 + 1 {
        for c2 = c1 + 1; c2 < 9; c2 = c2 + 1 {
          cnf.add_clause([negate(cell_var(r, c1, d)), negate(cell_var(r, c2, d))])
        }
      }
    }
    // columns
    for c = 0; c < 9; c = c + 1 {
      let at_least : Array[Int] = []
      for r = 0; r < 9; r = r + 1 {
        at_least.push(cell_var(r, c, d))
      }
      cnf.add_clause(at_least)
      for r1 = 0; r1 < 9; r1 = r1 + 1 {
        for r2 = r1 + 1; r2 < 9; r2 = r2 + 1 {
          cnf.add_clause([negate(cell_var(r1, c, d)), negate(cell_var(r2, c, d))])
        }
      }
    }
    // 3×3 boxes
    for br = 0; br < 3; br = br + 1 {
      for bc = 0; bc < 3; bc = bc + 1 {
        let at_least : Array[Int] = []
        let cells : Array[Int] = []
        for i = 0; i < 3; i = i + 1 {
          for j = 0; j < 3; j = j + 1 {
            let v = cell_var(br * 3 + i, bc * 3 + j, d)
            at_least.push(v)
            cells.push(v)
          }
        }
        cnf.add_clause(at_least)
        for a = 0; a < 9; a = a + 1 {
          for b = a + 1; b < 9; b = b + 1 {
            cnf.add_clause([negate(cells[a]), negate(cells[b])])
          }
        }
      }
    }
  }
  // givens as unit clauses
  for r = 0; r < 9; r = r + 1 {
    for c = 0; c < 9; c = c + 1 {
      let g = givens[r][c]
      if g != 0 {
        cnf.add_unit(cell_var(r, c, g - 1))
      }
    }
  }
  cnf
}

/// Decode a satisfying assignment into a 9×9 grid of digits 1–9.
pub fn decode(model : Array[Int]) -> Array[Array[Int]] {
  let grid : Array[Array[Int]] = []
  for r = 0; r < 9; r = r + 1 {
    let row : Array[Int] = []
    for c = 0; c < 9; c = c + 1 {
      let mut digit = 0
      for d = 0; d < 9; d = d + 1 {
        if model[cell_var(r, c, d)] == 1 {
          digit = d + 1
        }
      }
      row.push(digit)
    }
    grid.push(row)
  }
  grid
}

/// Encode, solve and decode a puzzle; `None` when the puzzle is unsatisfiable.
pub fn solve_puzzle(givens : Array[Array[Int]]) -> Array[Array[Int]]? {
  let cnf = encode(givens)
  match solve(cnf) {
    Some(model) => Some(decode(model))
    None => None
  }
}
