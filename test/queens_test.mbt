///|
/// Check that a decoded N-queens solution places no two queens in the same
/// column or on a shared diagonal (rows are distinct by construction).

fn valid_queens(cols : Array[Int]) -> Bool {
  let n = cols.length()
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      if cols[i] == cols[j] {
        return false
      }
      let d = j - i
      if cols[j] == cols[i] + d || cols[j] == cols[i] - d {
        return false
      }
    }
  }
  true
}

///|
test "queens cell variable indexing is 1-based and distinct" {
  assert_eq(@sat.queen_var(4, 0, 0), 1)
  assert_eq(@sat.queen_var(4, 0, 3), 4)
  assert_eq(@sat.queen_var(4, 1, 0), 5)
  assert_eq(@sat.queen_var(8, 7, 7), 64)
}

///|
test "one queen is trivially placeable" {
  match @sat.solve_queens(1) {
    Some(cols) => {
      assert_eq(cols.length(), 1)
      assert_eq(cols[0], 0)
    }
    None => assert_false(true)
  }
}

///|
test "four queens has a valid solution" {
  match @sat.solve_queens(4) {
    Some(cols) => {
      assert_eq(cols.length(), 4)
      assert_true(valid_queens(cols))
    }
    None => assert_false(true)
  }
}

///|
test "two and three queens are unsatisfiable" {
  match @sat.solve_queens(2) {
    None => ()
    Some(_) => assert_false(true)
  }
  match @sat.solve_queens(3) {
    None => ()
    Some(_) => assert_false(true)
  }
}

///|
test "eight queens has a valid solution" {
  match @sat.solve_queens(8) {
    Some(cols) => {
      assert_eq(cols.length(), 8)
      assert_true(valid_queens(cols))
    }
    None => assert_false(true)
  }
}
