///|
/// Graph-coloring-to-SAT encoding. Deciding whether an undirected graph on `n`
/// vertices can be colored with `k` colors (adjacent vertices differ) is
/// translated to a CNF formula with `n*k` variables (`v(i,c)` = "vertex i has
/// color c"), solved, and decoded back to a color per vertex.

/// Variable index for "vertex i has color c", with c in 0..<k. The result is
/// 1-based.
pub fn color_var(k : Int, i : Int, c : Int) -> Int {
  i * k + c + 1
}

/// Encode the k-coloring problem. `edges` lists undirected vertex pairs, each
/// pair an `(Int, Int)` of 0-based vertex indices.
pub fn encode_coloring(n : Int, edges : Array[(Int, Int)], k : Int) -> CNF {
  let cnf = CNF::new(n * k)
  // each vertex has at least one color
  for i = 0; i < n; i = i + 1 {
    let at_least : Array[Int] = []
    for c = 0; c < k; c = c + 1 {
      at_least.push(color_var(k, i, c))
    }
    cnf.add_clause(at_least)
  }
  // each vertex has at most one color
  for i = 0; i < n; i = i + 1 {
    for c1 = 0; c1 < k; c1 = c1 + 1 {
      for c2 = c1 + 1; c2 < k; c2 = c2 + 1 {
        cnf.add_clause([negate(color_var(k, i, c1)), negate(color_var(k, i, c2))])
      }
    }
  }
  // adjacent vertices must not share a color
  for e in edges {
    let i = e.0
    let j = e.1
    for c = 0; c < k; c = c + 1 {
      cnf.add_clause([negate(color_var(k, i, c)), negate(color_var(k, j, c))])
    }
  }
  cnf
}

/// Decode a satisfying assignment into the color of each vertex (`result[i]`
/// is a color in 0..<k).
pub fn decode_coloring(n : Int, k : Int, model : Array[Int]) -> Array[Int] {
  let colors : Array[Int] = []
  for i = 0; i < n; i = i + 1 {
    let mut color = 0
    for c = 0; c < k; c = c + 1 {
      if model[color_var(k, i, c)] == 1 {
        color = c
      }
    }
    colors.push(color)
  }
  colors
}

/// Encode, solve and decode the k-coloring problem; `None` when the graph is
/// not k-colorable.
pub fn solve_coloring(n : Int, edges : Array[(Int, Int)], k : Int) -> Array[Int]? {
  let cnf = encode_coloring(n, edges, k)
  match solve(cnf) {
    Some(model) => Some(decode_coloring(n, k, model))
    None => None
  }
}
