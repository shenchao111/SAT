///|
test "sudoku puzzle encodes and solves to a valid grid" {
  let givens : Array[Array[Int]] = [
    [5, 3, 0, 0, 7, 0, 0, 0, 0],
    [6, 0, 0, 1, 9, 5, 0, 0, 0],
    [0, 9, 8, 0, 0, 0, 0, 6, 0],
    [8, 0, 0, 0, 6, 0, 0, 0, 3],
    [4, 0, 0, 8, 0, 3, 0, 0, 1],
    [7, 0, 0, 0, 2, 0, 0, 0, 6],
    [0, 6, 0, 0, 0, 0, 2, 8, 0],
    [0, 0, 0, 4, 1, 9, 0, 0, 5],
    [0, 0, 0, 0, 8, 0, 0, 7, 9],
  ]
  let cnf = @sat.encode(givens)
  match @sat.solve(cnf) {
    Some(model) => {
      assert_true(@sat.verify(cnf, model))
      let grid = @sat.decode(model)
      for r = 0; r < 9; r = r + 1 {
        for c = 0; c < 9; c = c + 1 {
          if givens[r][c] != 0 {
            assert_eq(grid[r][c], givens[r][c])
          }
        }
      }
    }
    None => assert_false(true)
  }
}

///|
test "sudoku cell variable indexing is 1-based and distinct" {
  assert_eq(@sat.cell_var(0, 0, 0), 1)
  assert_eq(@sat.cell_var(0, 0, 1), 2)
  assert_eq(@sat.cell_var(0, 1, 0), 10)
  assert_eq(@sat.cell_var(8, 8, 8), 729)
}
