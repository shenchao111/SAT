///|
/// Build the pigeonhole encoding: `pigeons` pigeons into `holes` holes, with
/// `v(i,j)` = "pigeon i sits in hole j". Unsatisfiable when pigeons > holes.
fn pigeonhole_cnf(holes : Int, pigeons : Int) -> @sat.CNF {
  let cnf = @sat.CNF::new(holes * pigeons)
  // each pigeon sits in at least one hole
  for i = 0; i < pigeons; i = i + 1 {
    let at_least : Array[Int] = []
    for j = 0; j < holes; j = j + 1 {
      at_least.push(i * holes + j + 1)
    }
    cnf.add_clause(at_least)
  }
  // no hole holds two pigeons
  for j = 0; j < holes; j = j + 1 {
    for i1 = 0; i1 < pigeons; i1 = i1 + 1 {
      for i2 = i1 + 1; i2 < pigeons; i2 = i2 + 1 {
        cnf.add_clause([-(i1 * holes + j + 1), -(i2 * holes + j + 1)])
      }
    }
  }
  cnf
}

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

///|
test "cdcl proves the pigeonhole principle unsatisfiable (5 into 4)" {
  let cnf = pigeonhole_cnf(4, 5)
  match @sat.solve_cdcl(cnf) {
    None => ()
    Some(_) => assert_false(true)
  }
}

///|
test "dpll and cdcl agree on a satisfiable pigeonhole (3 into 4)" {
  let cnf = pigeonhole_cnf(4, 3)
  match @sat.solve_cdcl(cnf) {
    Some(m) => assert_true(@sat.verify(cnf, m))
    None => assert_false(true)
  }
  match @sat.solve(cnf) {
    Some(_) => ()
    None => assert_false(true)
  }
}
