///|
/// Command-line demo: solve DIMACS CNF formulas and a Sudoku puzzle with the
/// local SAT solver. Run with `moon run examples`.

fn print_grid(grid : Array[Array[Int]]) -> Unit {
  for r = 0; r < 9; r = r + 1 {
    let mut line = ""
    for c = 0; c < 9; c = c + 1 {
      let v = grid[r][c]
      line = line + (if v == 0 { "." } else { v.to_string() }) + " "
    }
    println(line)
  }
}

fn main {
  println("== DIMACS CNF ==")
  let sat_text = "c x1 and (x1 -> x2) and (x2 -> x3)\np cnf 3 3\n1 0\n-1 2 0\n-2 3 0\n"
  let sat_cnf = @sat.parse(sat_text)
  match @sat.solve(sat_cnf) {
    Some(model) =>
      println("DPLL  x1=" + model[1].to_string() + " x2=" + model[2].to_string() + " x3=" + model[3].to_string())
    None => println("UNSAT (unexpected)")
  }
  match @sat.solve_cdcl(sat_cnf) {
    Some(model) =>
      println("CDCL  x1=" + model[1].to_string() + " x2=" + model[2].to_string() + " x3=" + model[3].to_string())
    None => println("UNSAT (unexpected)")
  }

  let unsat_text = "c (x1) and (not x1)\np cnf 1 2\n1 0\n-1 0\n"
  let unsat_cnf = @sat.parse(unsat_text)
  match @sat.solve_cdcl(unsat_cnf) {
    None => println("UNSAT as expected")
    Some(_) => println("SAT (unexpected)")
  }

  println("")
  println("== Sudoku ==")
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
  println("puzzle:")
  print_grid(puzzle)
  println("solution:")
  match @sat.solve_puzzle(puzzle) {
    Some(grid) => print_grid(grid)
    None => println("no solution")
  }
}
