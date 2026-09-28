///|
/// Check that a decoded k-coloring assigns each adjacent pair different colors
/// and stays within the palette.

fn valid_coloring(edges : Array[(Int, Int)], colors : Array[Int], k : Int) -> Bool {
  for e in edges {
    if colors[e.0] == colors[e.1] {
      return false
    }
    if colors[e.0] < 0 || colors[e.0] >= k {
      return false
    }
    if colors[e.1] < 0 || colors[e.1] >= k {
      return false
    }
  }
  true
}

///|
test "coloring cell variable indexing is 1-based and distinct" {
  assert_eq(@sat.color_var(2, 0, 0), 1)
  assert_eq(@sat.color_var(2, 0, 1), 2)
  assert_eq(@sat.color_var(2, 1, 0), 3)
  assert_eq(@sat.color_var(2, 2, 1), 6)
}

///|
test "a triangle is 3-colorable" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  match @sat.solve_coloring(3, edges, 3) {
    Some(colors) => {
      assert_eq(colors.length(), 3)
      assert_true(valid_coloring(edges, colors, 3))
    }
    None => assert_false(true)
  }
}

///|
test "a triangle is not 2-colorable" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 0)]
  match @sat.solve_coloring(3, edges, 2) {
    None => ()
    Some(_) => assert_false(true)
  }
}

///|
test "a path is 2-colorable" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2)]
  match @sat.solve_coloring(3, edges, 2) {
    Some(colors) => assert_true(valid_coloring(edges, colors, 2))
    None => assert_false(true)
  }
}

///|
test "a five-cycle is not 2-colorable" {
  let edges : Array[(Int, Int)] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)]
  match @sat.solve_coloring(5, edges, 2) {
    None => ()
    Some(_) => assert_false(true)
  }
}
