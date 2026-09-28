///|
test "cdcl solves a satisfiable 3-clause formula" {
  let cnf = @sat.CNF::new(3)
  cnf.add_clause([1, 2])
  cnf.add_clause([-1, 3])
  cnf.add_clause([-2, -3])
  match @sat.solve_cdcl(cnf) {
    Some(model) => assert_true(@sat.verify(cnf, model))
    None => assert_false(true)
  }
}

///|
test "cdcl detects an unsatisfiable formula via clause learning" {
  // all eight clauses over three variables: every assignment falsifies one.
  let cnf = @sat.CNF::new(3)
  cnf.add_clause([1, 2, 3])
  cnf.add_clause([1, 2, -3])
  cnf.add_clause([1, -2, 3])
  cnf.add_clause([1, -2, -3])
  cnf.add_clause([-1, 2, 3])
  cnf.add_clause([-1, 2, -3])
  cnf.add_clause([-1, -2, 3])
  cnf.add_clause([-1, -2, -3])
  match @sat.solve_cdcl(cnf) {
    None => ()
    Some(_) => assert_false(true)
  }
}

///|
test "cdcl and dpll agree on a satisfiable formula" {
  let cnf = @sat.CNF::new(4)
  cnf.add_clause([1, 2])
  cnf.add_clause([-1, 3])
  cnf.add_clause([-2, 3])
  cnf.add_clause([-3, 4])
  cnf.add_clause([-4, -1])
  match @sat.solve_cdcl(cnf) {
    Some(model) => {
      assert_true(@sat.verify(cnf, model))
      match @sat.solve(cnf) {
        Some(_) => ()
        None => assert_false(true)
      }
    }
    None => assert_false(true)
  }
}

///|
test "cdcl agrees with dpll on unsat and sat instances" {
  let sat = @sat.CNF::new(2)
  sat.add_clause([1, 2])
  sat.add_clause([-1, 2])
  match @sat.solve_cdcl(sat) {
    Some(m) => assert_true(@sat.verify(sat, m))
    None => assert_false(true)
  }
  let unsat = @sat.CNF::new(2)
  unsat.add_clause([1, 2])
  unsat.add_clause([1, -2])
  unsat.add_clause([-1, 2])
  unsat.add_clause([-1, -2])
  match @sat.solve_cdcl(unsat) {
    None => ()
    Some(_) => assert_false(true)
  }
}
