# sat

A dependency-free **SAT solver** for MoonBit: two complete engines (DPLL and
conflict-driven clause learning), DIMACS CNF parsing and printing, and a
Sudoku encoder. No dependency beyond the MoonBit core — `moon add`-able and
compiles to wasm.

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
| DPLL | `solve(cnf)` | unit propagation, decision branching, chronological backtracking |
| CDCL | `solve_cdcl(cnf)` | first-UIP clause learning, VSIDS branching, non-chronological backtracking |

`verify(cnf, model)` checks whether a model satisfies every clause, which is
handy for pinning solver output in tests.

## DIMACS CNF

`parse(text)` reads the standard exchange format (comments, `p cnf` header,
0-terminated clauses) and `cnf.to_dimacs()` renders a formula back to text:

```moonbit
let cnf = @sat.parse("p cnf 2 2\n1 2 0\n-1 -2 0\n")
let text = cnf.to_dimacs() // "p cnf 2 2\n1 2 0\n-1 -2 0\n"
```

## Sudoku

A 9×9 Sudoku is encoded as a 729-variable CNF (`v(r,c,d)` = "cell (r,c) holds
digit d+1"), solved, and decoded back into a grid:

- `cell_var(r, c, d)` — the variable index for a row/column/digit
- `encode(givens)` — `givens` is a 9×9 grid of digits 1–9 with 0 for empty
- `decode(model)` — turn a model back into a 9×9 grid
- `solve_puzzle(givens)` — encode, solve and decode in one call

## Command line

`examples/` ships a runnable demo. `moon run examples` solves a satisfiable
and an unsatisfiable DIMACS formula with both engines, then solves a Sudoku
puzzle and prints the grid.

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
moon test   # 15 tests, all passing
```

The tests pin the literal algebra, DIMACS round-tripping, satisfiable and
unsatisfiable instances, the Sudoku encoding, and agreement between the DPLL
and CDCL engines.

## Benchmarks

`moon bench` times the engines in isolation (measured on this machine; order of
magnitude only):

| Routine | Time |
|---------|------|
| `dpll_solve` (3-var formula) | ~0.28 µs |
| `cdcl_solve` (3-var formula) | ~0.60 µs |
| `dimacs_parse` | ~6.2 µs |
| `sudoku_solve` (9×9) | ~1.6 ms |

## License

Apache-2.0, see [LICENSE](LICENSE).
