///|
/// A complete DPLL SAT solver: unit propagation, decision branching and
/// chronological backtracking.
///
/// `solve` returns `Some(model)` with a satisfying assignment — `model[v]` is
/// `1` (true) or `-1` (false), index 0 unused — or `None` when the formula is
/// unsatisfiable.

/// Mutable search state: the partial assignment and the assignment trail (the
/// literals set so far, in order).
priv struct State {
  value : Array[Int]
  trail : Array[Int]
}

fn State::new(num_vars : Int) -> State {
  let value = Array::make(num_vars + 1, 0)
  let trail : Array[Int] = []
  { value, trail }
}

fn assign(st : State, lit : Int) -> Unit {
  let v = variable(lit)
  st.value[v] = if is_positive(lit) { 1 } else { -1 }
  st.trail.push(lit)
}

/// Unwind the trail back to `mark`, clearing the undone variables.
fn undo(st : State, mark : Int) -> Unit {
  while st.trail.length() > mark {
    match st.trail.pop() {
      Some(lit) => st.value[variable(lit)] = 0
      None => ()
    }
  }
}

/// Unit propagation: keep assigning forced literals until a fixpoint or a
/// conflict. Returns false on conflict.
fn propagate(st : State, clauses : Array[Array[Int]]) -> Bool {
  let mut progress = true
  while progress {
    progress = false
    for clause in clauses {
      match clause_status(st.value, clause) {
        -1 => return false
        0 => {
          let u = unit_literal(st.value, clause)
          if u != 0 {
            assign(st, u)
            progress = true
          }
        }
        _ => ()
      }
    }
  }
  true
}

/// The first unassigned variable, or 0 when everything is assigned.
fn pick_branch(st : State) -> Int {
  let n = st.value.length() - 1
  for v = 1; v <= n; v = v + 1 {
    if st.value[v] == 0 {
      return v
    }
  }
  0
}

/// Assign every pure literal — a variable whose complement appears nowhere in
/// the still-undecided clauses — to its only polarity. A pure literal can never
/// exclude a solution, so this is the second classic DPLL simplification,
/// alongside unit propagation. Repeated to a fixpoint: satisfying a clause can
/// expose further pure literals.
fn assign_pure(st : State, clauses : Array[Array[Int]]) -> Unit {
  let n = st.value.length() - 1
  let mut progress = true
  while progress {
    progress = false
    let pos = Array::make(n + 1, 0)
    let neg = Array::make(n + 1, 0)
    for clause in clauses {
      if clause_status(st.value, clause) == 0 {
        for lit in clause {
          let v = variable(lit)
          if st.value[v] == 0 {
            if is_positive(lit) {
              pos[v] = pos[v] + 1
            } else {
              neg[v] = neg[v] + 1
            }
          }
        }
      }
    }
    for v = 1; v <= n; v = v + 1 {
      if st.value[v] == 0 {
        if pos[v] > 0 && neg[v] == 0 {
          assign(st, v)
          progress = true
        } else if neg[v] > 0 && pos[v] == 0 {
          assign(st, -v)
          progress = true
        }
      }
    }
  }
}

fn search(st : State, clauses : Array[Array[Int]]) -> Bool {
  if !propagate(st, clauses) {
    return false
  }
  assign_pure(st, clauses)
  let v = pick_branch(st)
  if v == 0 {
    return true
  }
  let mark = st.trail.length()
  assign(st, v)
  if search(st, clauses) {
    return true
  }
  undo(st, mark)
  assign(st, -v)
  if search(st, clauses) {
    return true
  }
  undo(st, mark)
  false
}

/// Solve a CNF formula. Returns `Some(model)` with a satisfying assignment —
/// `model[v]` is `1` (true) or `-1` (false), index 0 unused — or `None` if the
/// formula is unsatisfiable.
pub fn solve(cnf : CNF) -> Array[Int]? {
  let st = State::new(cnf.vars())
  let clauses = cnf.clauses()
  if search(st, clauses) {
    Some(st.value)
  } else {
    None
  }
}

/// Enumerate up to `limit` satisfying assignments (each a model array, index 0
/// unused). A `limit` of `-1` means no limit. Models are found by repeatedly
/// solving and blocking the assignment just found, so the cost is exponential
/// in the number of free variables — use it for counting or on small,
/// tightly-constrained instances.
pub fn solve_upto(cnf : CNF, limit : Int) -> Array[Array[Int]] {
  // Work on a copy: blocking clauses must not leak into the caller's formula.
  let formula = CNF::new(cnf.vars())
  for clause in cnf.clauses() {
    formula.add_clause(clause)
  }
  let n = cnf.vars()
  let out : Array[Array[Int]] = []
  while true {
    match solve(formula) {
      None => break
      Some(model) => {
        out.push(model)
        if limit >= 0 && out.length() >= limit {
          break
        }
        // Block this exact assignment: falsified only by `model` itself.
        let block : Array[Int] = []
        for v = 1; v <= n; v = v + 1 {
          if model[v] == 1 {
            block.push(-v)
          } else {
            block.push(v)
          }
        }
        formula.add_clause(block)
      }
    }
  }
  out
}

/// Enumerate every satisfying assignment of `cnf` (see `solve_upto`).
pub fn solve_all(cnf : CNF) -> Array[Array[Int]] {
  solve_upto(cnf, -1)
}

/// Solve `cnf` under a set of assumptions — literals forced to true as extra
/// unit clauses. The input formula is left untouched; the returned model
/// satisfies both the formula and every assumption, or `None` if the two are
/// inconsistent.
pub fn solve_assumptions(cnf : CNF, assumptions : Array[Int]) -> Array[Int]? {
  let formula = CNF::new(cnf.vars())
  for clause in cnf.clauses() {
    formula.add_clause(clause)
  }
  for lit in assumptions {
    formula.add_unit(lit)
  }
  solve(formula)
}

/// Check whether `model` satisfies every clause of `cnf`.
pub fn verify(cnf : CNF, model : Array[Int]) -> Bool {
  for clause in cnf.clauses() {
    let mut satisfied = false
    for lit in clause {
      let v = variable(lit)
      let val = if is_positive(lit) { model[v] } else { -model[v] }
      if val == 1 {
        satisfied = true
      }
    }
    if !satisfied {
      return false
    }
  }
  true
}
