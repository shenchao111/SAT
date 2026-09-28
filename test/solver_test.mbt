///|
test "empty formula is satisfiable" {
  let cnf = @sat.CNF::new(3)
  match @sat.solve(cnf) {
    Some(model) => assert_true(@sat.verify(cnf, model))
    None => assert_false(true)
  }
}

///|
test "unit clause forces a variable" {
  let cnf = @sat.CNF::new(1)
  cnf.add_unit(1)
  match @sat.solve(cnf) {
    Some(model) => {
      assert_eq(model[1], 1)
      assert_true(@sat.verify(cnf, model))
    }
    None => assert_false(true)
  }
}

///|
test "a variable and its negation is unsatisfiable" {
  let cnf = @sat.CNF::new(1)
  cnf.add_unit(1)
  cnf.add_unit(-1)
  match @sat.solve(cnf) {
    None => ()
    Some(_) => assert_false(true)
  }
}

///|
test "a three-clause formula has a known model" {
  // (x1) ∧ (¬x1 ∨ x2) ∧ (¬x2 ∨ x3)
  let cnf = @sat.CNF::new(3)
  cnf.add_unit(1)
  cnf.add_clause([-1, 2])
  cnf.add_clause([-2, 3])
  match @sat.solve(cnf) {
    Some(model) => {
      assert_eq(model[1], 1)
      assert_eq(model[2], 1)
      assert_eq(model[3], 1)
      assert_true(@sat.verify(cnf, model))
    }
    None => assert_false(true)
  }
}

///|
test "verify rejects an assignment that breaks a clause" {
  let cnf = @sat.CNF::new(2)
  cnf.add_clause([1, 2])
  // model[1] = -1, model[2] = -1 falsifies (x1 ∨ x2)
  let model = Array::make(3, 0)
  model[1] = -1
  model[2] = -1
  assert_false(@sat.verify(cnf, model))
}

///|
test "all literals of a clause must be respected" {
  // (¬x1 ∨ ¬x2) is satisfied iff not both true
  let cnf = @sat.CNF::new(2)
  cnf.add_clause([-1, -2])
  let model = Array::make(3, 0)
  model[1] = 1
  model[2] = 1
  assert_false(@sat.verify(cnf, model))
  model[1] = -1
  assert_true(@sat.verify(cnf, model))
}
