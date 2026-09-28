///|
/// Benchmarks for the SAT engines. Run with `moon bench`.

///|
test "bench DPLL solve" (it : @bench.T) {
  let cnf = @sat.CNF::new(3)
  cnf.add_clause([1, 2])
  cnf.add_clause([-1, 3])
  cnf.add_clause([-2, -3])
  it.bench(name="dpll_solve", fn() { it.keep(@sat.solve(cnf)) })
}

///|
test "bench CDCL solve" (it : @bench.T) {
  let cnf = @sat.CNF::new(3)
  cnf.add_clause([1, 2])
  cnf.add_clause([-1, 3])
  cnf.add_clause([-2, -3])
  it.bench(name="cdcl_solve", fn() { it.keep(@sat.solve_cdcl(cnf)) })
}

///|
test "bench DIMACS parse" (it : @bench.T) {
  let text = "p cnf 3 3\n1 -2 0\n2 3 0\n-1 -3 0\n"
  it.bench(name="dimacs_parse", fn() { it.keep(@sat.parse(text)) })
}

///|
test "bench Sudoku solve" (it : @bench.T) {
  let puzzle : Array[Array[Int]] = [
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
  it.bench(name="sudoku_solve", fn() { it.keep(@sat.solve_puzzle(puzzle)) })
}
