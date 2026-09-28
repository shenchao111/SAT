///|
test "variable, polarity and negation" {
  assert_eq(@sat.variable(3), 3)
  assert_eq(@sat.variable(-3), 3)
  assert_true(@sat.is_positive(3))
  assert_false(@sat.is_positive(-3))
  assert_eq(@sat.negate(3), -3)
  assert_eq(@sat.negate(-3), 3)
}

///|
test "dimacs parse and round-trip" {
  let text = "c a comment\np cnf 3 3\n1 -2 0\n2 3 0\n-1 -3 0\n"
  let cnf = @sat.parse(text)
  assert_eq(cnf.vars(), 3)
  assert_eq(cnf.num_clauses(), 3)
  assert_eq(cnf.to_dimacs(), "p cnf 3 3\n1 -2 0\n2 3 0\n-1 -3 0\n")
}

///|
test "dimacs ignores comments and header count" {
  let cnf = @sat.parse("c header\np cnf 2 2\n1 0\n-2 0\n")
  assert_eq(cnf.vars(), 2)
  assert_eq(cnf.num_clauses(), 2)
}

///|
test "dimacs result prints a satisfiable model" {
  let model = Array::make(3, 0)
  model[1] = 1
  model[2] = -1
  assert_eq(@sat.result(Some(model)), "s SATISFIABLE\nv 1 -2 0\n")
}

///|
test "dimacs result prints an unsatisfiable verdict" {
  assert_eq(@sat.result(None), "s UNSATISFIABLE\n")
}
