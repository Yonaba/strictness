CHANGELOG
=========

###0.2.0 (releasedate)
* `strictness` no longer create globals. It returns a local table of library functions.
* `strictness` can now create (or convert) strict/sloppy tables (or environnements).
* Strict/sloppy rules are now applied per table (or environnement).
* Strict mode enforces variable declarations and complain on undefined fields access/assignment.
* Tables (or environnements) already existing metatables are preserved, including `__index` and `__newindex` fields.
* Added `strictness.strict` to convert a normal table (or environnement) to a strict one.
* Added `strictness.sloppy` to convert a strict table (or environnement) to a normal one.
* Added `strictness.is_strict` to check if a table (or environnement) is strict.
* Added `strictness.strictf` to wrap a normal function into a sloppy function.
* Added `strictness.sloppyf` to wrap a normal function into a strict function.
* Added `strictness.run_strictf` to run a normal function in strict mode.
* Added `strictness.run_sloppyf` to run a normal function in sloppy mode.
* Made compliant with Lua 5.2 new _ENV scheme (although striclty speaking there are no globals in Lua 5.2).

###0.1.0 (10/05/13)
* Initial release