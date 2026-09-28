///|
/// DIMACS CNF text parsing and printing — the standard exchange format for
/// SAT solvers: an optional `c` comment, a `p cnf <vars> <clauses>` header,
/// then 0-terminated clauses.

fn is_space(c : Char) -> Bool {
  c == ' ' || c == '\t' || c == '\n' || c == '\r'
}

/// Split the input into whitespace-separated tokens, dropping comment lines
/// (lines starting with `c`).
fn tokens(text : String) -> Array[String] {
  let chars = text.to_array()
  let n = chars.length()
  let out : Array[String] = []
  let mut i = 0
  let mut line_start = true
  while i < n {
    let c = chars[i]
    if c == '\n' {
      line_start = true
      i = i + 1
      continue
    }
    if is_space(c) {
      i = i + 1
      continue
    }
    // a `c` at the start of a line introduces a comment that runs to end of line
    if line_start && c == 'c' {
      while i < n && chars[i] != '\n' {
        i = i + 1
      }
      continue
    }
    line_start = false
    let buf : Array[Char] = []
    while i < n && !is_space(chars[i]) {
      buf.push(chars[i])
      i = i + 1
    }
    out.push(String::from_iter(buf.iter()))
  }
  out
}

/// Parse a decimal integer token, with an optional leading `-`.
fn parse_int(s : String) -> Int {
  let cs = s.to_array()
  let n = cs.length()
  let mut i = 0
  let mut negative = false
  if n > 0 && cs[0] == '-' {
    negative = true
    i = 1
  }
  let mut acc = 0
  while i < n {
    acc = acc * 10 + (cs[i].to_int() - '0'.to_int())
    i = i + 1
  }
  if negative { -acc } else { acc }
}

/// Parse a formula from DIMACS CNF text.
pub fn parse(text : String) -> CNF {
  let ts = tokens(text)
  let mut k = 0
  let mut num_vars = 0
  let mut num_clauses = 0
  // header: "p" "cnf" <vars> <clauses>
  if ts.length() > k && ts[k] == "p" {
    k = k + 1
    if ts.length() > k && ts[k] == "cnf" {
      k = k + 1
      if ts.length() > k {
        num_vars = parse_int(ts[k])
        k = k + 1
      }
      if ts.length() > k {
        num_clauses = parse_int(ts[k])
        k = k + 1
      }
    }
  }
  let cnf = CNF::new(num_vars)
  let mut clause : Array[Int] = []
  let mut added = 0
  let mut i = k
  while i < ts.length() && added < num_clauses {
    let lit = parse_int(ts[i])
    i = i + 1
    if lit == 0 {
      cnf.add_clause(clause)
      clause = []
      added = added + 1
    } else {
      clause.push(lit)
    }
  }
  cnf
}

/// Render a formula as DIMACS CNF text.
pub fn CNF::to_dimacs(self : CNF) -> String {
  let mut out = "p cnf " + self.num_vars.to_string() + " " + self.clauses.length().to_string() + "\n"
  for clause in self.clauses {
    let mut line = ""
    for lit in clause {
      line = line + lit.to_string() + " "
    }
    out = out + line + "0\n"
  }
  out
}

/// Render a solver result in the standard DIMACS solution format: an `s` status
/// line (`s SATISFIABLE` / `s UNSATISFIABLE`) and, when satisfiable, a 0-
/// terminated `v` line listing the model literals (positive = true).
pub fn result(model : Array[Int]?) -> String {
  match model {
    None => "s UNSATISFIABLE\n"
    Some(m) => {
      let mut out = "s SATISFIABLE\nv "
      for v = 1; v < m.length(); v = v + 1 {
        let lit = if m[v] == 1 { v } else { -v }
        out = out + lit.to_string() + " "
      }
      out + "0\n"
    }
  }
}
