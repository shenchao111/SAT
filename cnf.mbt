///|
/// Conjunctive normal form (CNF) formulas and literals.
///
/// A *literal* is a non-zero integer. For a variable `v` (1-based), the
/// literal `+v` asserts "v is true" and `-v` asserts "v is false". A *clause*
/// is a disjunction of literals, stored as an `Array[Int]`. A CNF *formula* is
/// a conjunction of clauses together with a variable count.

/// The variable of a literal, always positive (1-based).
pub fn variable(lit : Int) -> Int {
  if lit < 0 { -lit } else { lit }
}

/// Whether a literal is positive (asserts the variable is true).
pub fn is_positive(lit : Int) -> Bool {
  lit > 0
}

/// The complementary literal: `v` becomes `-v` and vice versa.
pub fn negate(lit : Int) -> Int {
  -lit
}

/// A formula in conjunctive normal form over `num_vars` variables.
pub struct CNF {
  num_vars : Int
  clauses : Array[Array[Int]]
}

/// An empty formula over `num_vars` variables.
pub fn CNF::new(num_vars : Int) -> CNF {
  let clauses : Array[Array[Int]] = []
  { num_vars, clauses }
}

/// The number of variables in the formula.
pub fn CNF::vars(self : CNF) -> Int {
  self.num_vars
}

/// The clauses of the formula.
pub fn CNF::clauses(self : CNF) -> Array[Array[Int]] {
  self.clauses
}

/// The number of clauses.
pub fn CNF::num_clauses(self : CNF) -> Int {
  self.clauses.length()
}

/// Add a clause (a disjunction of literals).
pub fn CNF::add_clause(self : CNF, lits : Array[Int]) -> Unit {
  self.clauses.push(lits)
}

/// Add a unit clause consisting of a single literal.
pub fn CNF::add_unit(self : CNF, lit : Int) -> Unit {
  self.clauses.push([lit])
}

/// Value of a literal under an assignment array: 1 (true), -1 (false) or 0.
/// `value` is indexed by variable; index 0 is unused.
fn lit_value(value : Array[Int], lit : Int) -> Int {
  let v = variable(lit)
  let val = value[v]
  if is_positive(lit) { val } else { -val }
}

/// Status of a clause under an assignment: 1 = satisfied, -1 = falsified
/// (conflict), 0 = undecided.
fn clause_status(value : Array[Int], clause : Array[Int]) -> Int {
  let mut undecided = false
  for lit in clause {
    match lit_value(value, lit) {
      1 => return 1
      0 => undecided = true
      _ => ()
    }
  }
  if undecided { 0 } else { -1 }
}

/// The single unassigned literal of an undecided clause whose other literals
/// are all falsified; 0 if the clause is not unit.
fn unit_literal(value : Array[Int], clause : Array[Int]) -> Int {
  let mut unit = 0
  for lit in clause {
    match lit_value(value, lit) {
      0 => {
        if unit != 0 {
          return 0
        }
        unit = lit
      }
      1 => return 0
      _ => ()
    }
  }
  unit
}
