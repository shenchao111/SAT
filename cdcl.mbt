///|
/// A conflict-driven clause-learning (CDCL) SAT solver: unit propagation,
/// first-UIP clause learning, VSIDS branching and non-chronological
/// backtracking.
///
/// `solve_cdcl` returns the same kind of model as `solve` (`model[v]` is `1`
/// or `-1`, index 0 unused) or `None` when the formula is unsatisfiable.

/// Mutable CDCL state.
priv struct Solver {
  num_vars : Int
  clauses : Array[Array[Int]]
  value : Array[Int]
  level : Array[Int]
  reason : Array[Array[Int]?]
  trail : Array[Int]
  trail_lim : Array[Int]
  activity : Array[Double]
}

fn Solver::new(cnf : CNF) -> Solver {
  let n = cnf.vars()
  let value = Array::make(n + 1, 0)
  let level = Array::make(n + 1, 0)
  let reason : Array[Array[Int]?] = Array::make(n + 1, None)
  let trail : Array[Int] = []
  let trail_lim : Array[Int] = [0]
  let activity = Array::make(n + 1, 0.0)
  {
    num_vars: n,
    clauses: cnf.clauses(),
    value,
    level,
    reason,
    trail,
    trail_lim,
    activity,
  }
}

fn cdcl_current_level(s : Solver) -> Int {
  s.trail_lim.length() - 1
}

fn cdcl_new_level(s : Solver) -> Unit {
  s.trail_lim.push(s.trail.length())
}

fn cdcl_assign(s : Solver, lit : Int, reason : Array[Int]?) -> Unit {
  let v = variable(lit)
  s.value[v] = if is_positive(lit) { 1 } else { -1 }
  s.level[v] = cdcl_current_level(s)
  s.reason[v] = reason
  s.trail.push(lit)
}

/// Unwind the trail down to decision level `level`, clearing the undone
/// variables and their reasons.
fn cdcl_backtrack(s : Solver, level : Int) -> Unit {
  while s.trail_lim.length() - 1 > level {
    s.trail_lim.unsafe_pop_back()
  }
  let target = s.trail_lim[s.trail_lim.length() - 1]
  while s.trail.length() > target {
    match s.trail.pop() {
      Some(lit) => {
        let v = variable(lit)
        s.value[v] = 0
        s.level[v] = 0
        s.reason[v] = None
      }
      None => ()
    }
  }
}

/// Unit propagation. Returns the falsified clause on conflict, or `None` at a
/// fixpoint.
fn cdcl_propagate(s : Solver) -> Array[Int]? {
  let mut progress = true
  while progress {
    progress = false
    for clause in s.clauses {
      match clause_status(s.value, clause) {
        -1 => return Some(clause)
        0 => {
          let u = unit_literal(s.value, clause)
          if u != 0 {
            cdcl_assign(s, u, Some(clause))
            progress = true
          }
        }
        _ => ()
      }
    }
  }
  None
}

/// Pick an unassigned variable with the highest VSIDS activity.
fn cdcl_pick_decision(s : Solver) -> Int {
  let mut best = 0
  let mut best_act = -1.0
  for v = 1; v <= s.num_vars; v = v + 1 {
    if s.value[v] == 0 && s.activity[v] > best_act {
      best_act = s.activity[v]
      best = v
    }
  }
  best
}

/// First-UIP conflict analysis. Returns the backtrack level and the learned
/// clause, whose first literal is the asserting (unit) literal.
fn cdcl_analyze(s : Solver, conflict : Array[Int]) -> (Int, Array[Int]) {
  let learnt : Array[Int] = []
  let seen : Array[Bool] = Array::make(s.num_vars + 1, false)
  let mut path = 0
  let mut index = s.trail.length() - 1
  let mut p = 0
  let mut cl : Array[Int] = conflict
  while true {
    for q in cl {
      if q != p {
        let v = variable(q)
        if s.level[v] > 0 && !seen[v] {
          seen[v] = true
          if s.level[v] == cdcl_current_level(s) {
            path = path + 1
          } else {
            learnt.push(q)
          }
        }
      }
    }
    while !seen[variable(s.trail[index])] {
      index = index - 1
    }
    p = s.trail[index]
    match s.reason[variable(p)] {
      Some(r) => cl = r
      None => cl = []
    }
    seen[variable(p)] = false
    path = path - 1
    index = index - 1
    if path == 0 {
      break
    }
  }
  let learned : Array[Int] = [negate(p)]
  let mut bt = 0
  for q in learnt {
    learned.push(q)
    let v = variable(q)
    if s.level[v] > bt {
      bt = s.level[v]
    }
  }
  (bt, learned)
}

/// The decision loop: branch on an unassigned variable, propagate, and on
/// conflict learn a clause and backtrack. Recurse for the next decision.
fn cdcl_search(s : Solver) -> Array[Int]? {
  let v = cdcl_pick_decision(s)
  if v == 0 {
    return Some(s.value)
  }
  cdcl_new_level(s)
  cdcl_assign(s, v, None)
  while true {
    match cdcl_propagate(s) {
      None => break
      Some(conflict) => {
        if cdcl_current_level(s) == 0 {
          return None
        }
        let (bt, learned) = cdcl_analyze(s, conflict)
        cdcl_backtrack(s, bt)
        s.clauses.push(learned)
        for q in learned {
          s.activity[variable(q)] = s.activity[variable(q)] + 1.0
        }
        cdcl_assign(s, learned[0], Some(learned))
      }
    }
  }
  cdcl_search(s)
}

/// Solve a CNF formula with the CDCL engine.
pub fn solve_cdcl(cnf : CNF) -> Array[Int]? {
  let s = Solver::new(cnf)
  match cdcl_propagate(s) {
    Some(_) => return None
    None => ()
  }
  cdcl_search(s)
}
