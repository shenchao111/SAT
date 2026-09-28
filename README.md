# sat

A dependency-free **SAT solver** for MoonBit: two complete engines (DPLL with
pure-literal elimination, and conflict-driven clause learning with geometric
restarts), DIMACS CNF parsing and printing, model enumeration, assumption-based
solving, and Sudoku, N-queens and graph-coloring encoders. No dependency beyond
the MoonBit core — `moon add`-able and compiles to wasm.

## A worked example

The formula `(x1) ∧ (¬x1 ∨ x2) ∧ (¬x2 ∨ x3)` is satisfiable only when all
three variables are true:

```moonbit
let cnf = @sat.CNF::new(3)
cnf.add_unit(1)             // (x1)
cnf.add_clause([-1, 2])     // (¬x1 ∨ x2)
cnf.add_clause([-2, 3])     // (¬x2 ∨ x3)

match @sat.solve(cnf) {
  Some(model) => {
    // model[1] == 1, model[2] == 1, model[3] == 1
    @sat.verify(cnf, model) // true
  }
  None => ()
}
```

## Literals and clauses

A *literal* is a non-zero integer: `+v` asserts variable `v` is true, `-v`
asserts it is false (variables are 1-based). A *clause* is a disjunction of
literals, stored as an `Array[Int]`. A CNF *formula* is a conjunction of
clauses together with a variable count.

- `variable(lit)` — the 1-based variable of a literal, always positive
- `is_positive(lit)` / `negate(lit)` — polarity and complement
- `CNF::new(vars)` — an empty formula over `vars` variables
- `cnf.add_clause(lits)` / `cnf.add_unit(lit)`
- `cnf.vars()` / `cnf.num_clauses()` / `cnf.clauses()`

## Solving

Both engines return the same kind of model: an `Array[Int]` where `model[v]`
is `1` (true) or `-1` (false), index 0 unused, or `None` when the formula is
unsatisfiable.

| Engine | Function | How it works |
|--------|----------|--------------|
| DPLL | `solve(cnf)` | unit propagation, pure-literal elimination, decision branching, chronological backtracking |
| CDCL | `solve_cdcl(cnf)` | first-UIP clause learning, VSIDS branching, non-chronological backtracking, geometric restarts |

`verify(cnf, model)` checks whether a model satisfies every clause, which is
handy for pinning solver output in tests.

### Enumerating models

`solve_upto(cnf, limit)` returns up to `limit` satisfying assignments (each a
model array), found by repeatedly solving and blocking the assignment just
found; `-1` means no limit, and `solve_all(cnf)` returns every model. The cost
is exponential in the number of free variables, so reserve it for counting or
for tightly-constrained instances.

### Solving under assumptions

`solve_assumptions(cnf, assumptions)` solves the formula with extra literals
forced true, without mutating the input — the returned model satisfies both the
formula and every assumption, or is `None` if they conflict.

## DIMACS CNF

`parse(text)` reads the standard exchange format (comments, `p cnf` header,
0-terminated clauses) and `cnf.to_dimacs()` renders a formula back to text:

```moonbit
let cnf = @sat.parse("p cnf 2 2\n1 2 0\n-1 -2 0\n")
let text = cnf.to_dimacs() // "p cnf 2 2\n1 2 0\n-1 -2 0\n"
```

`result(model)` renders a solver verdict in the standard DIMACS solution
format: an `s SATISFIABLE` / `s UNSATISFIABLE` status line and, when
satisfiable, a 0-terminated `v` line listing the model literals.

## Sudoku

A 9×9 Sudoku is encoded as a 729-variable CNF (`v(r,c,d)` = "cell (r,c) holds
digit d+1"), solved, and decoded back into a grid:

- `cell_var(r, c, d)` — the variable index for a row/column/digit
- `encode(givens)` — `givens` is a 9×9 grid of digits 1–9 with 0 for empty
- `decode(model)` — turn a model back into a 9×9 grid
- `solve_puzzle(givens)` — encode, solve and decode in one call
- `count_solutions(givens)` — the number of distinct solutions
- `is_unique(givens)` — whether the puzzle has exactly one solution

## N-queens

The N-queens problem is encoded the same way: `v(r,c)` = "a queen sits at row
r, column c", with exactly one queen per column and at most one per row and
per diagonal.

- `queen_var(n, r, c)` — the variable index for a queen at (r, c)
- `encode_queens(n)` — the CNF encoding of an `n`×`n` board
- `decode_queens(n, model)` — turn a model into the column of each row's queen
- `solve_queens(n)` — encode, solve and decode in one call (`None` for n=2, 3)

## Graph coloring

Whether an undirected graph is `k`-colorable is encoded as `v(i,c)` = "vertex i
has color c", with every vertex taking exactly one color and adjacent vertices
differing:

- `color_var(k, i, c)` — the variable index for a vertex/color
- `encode_coloring(n, edges, k)` — the CNF encoding; `edges` lists `(Int, Int)`
  vertex pairs
- `decode_coloring(n, k, model)` — turn a model into the color of each vertex
- `solve_coloring(n, edges, k)` — encode, solve and decode in one call

## Command line

`examples/` ships a runnable demo. `moon run examples` solves a satisfiable
and an unsatisfiable DIMACS formula with both engines, prints their DIMACS
results, then solves a Sudoku puzzle, the 4- and 8-queens problems, a graph
coloring, and an assumption-constrained solve.

## Use as a library

```sh
moon add shenchao111/STA
```

```moonbit
// moon.pkg — alias the package however you like:
import { "shenchao111/STA" @sat }

fn main {
  let cnf = @sat.CNF::new(2)
  cnf.add_clause([1, 2])
  cnf.add_clause([-1, 2])
  match @sat.solve_cdcl(cnf) {
    Some(model) => println("satisfiable")
    None => println("unsatisfiable")
  }
}
```

## Tests

```sh
moon test   # 40 tests, all passing
```

The tests pin the literal algebra, DIMACS round-tripping and result output,
satisfiable and unsatisfiable instances (including the pigeonhole principle),
model enumeration, pure-literal elimination, assumption-based solving, the
Sudoku, N-queens and graph-coloring encodings, and agreement between the DPLL
and CDCL engines.

## Benchmarks

`moon bench` times the engines in isolation (measured on this machine; order of
magnitude only):

| Routine | Time |
|---------|------|
| `dpll_solve` (3-var formula) | ~0.57 µs |
| `cdcl_solve` (3-var formula) | ~0.60 µs |
| `dimacs_parse` | ~6.7 µs |
| `sudoku_solve` (9×9) | ~1.6 ms |
| `nqueens_solve_8` | ~1.6 ms |
| `coloring_c5` (5-cycle, 3 colors) | ~8.2 µs |

## License

Apache-2.0, see [LICENSE](LICENSE).
