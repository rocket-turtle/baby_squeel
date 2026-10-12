# Decisions

Proposals that keep coming up in reviews, and why they were not taken.
Reopen one only with a new argument. The regression baseline is
3.0.0.internal3, the version in production; behaviour that was already
the same there is not a regression.

## Rejected

**Build outer joins with Active Record's `left_joins` instead of the outer
marker.** It would drop the `make_constraints` override and fix the pending
limitation, but it changes the SQL: outer joins move behind every inner
join, aliases swap where a table is joined inner and outer, and an inner
and an outer join of one association merge into one. The consumer has
hand-written table names in its views and permission scopes stored in the
database, which cannot be checked in advance. One
prototype silently lost a join for `of(A)` next to `of(B)` on the same
association. It saves almost no lines. Needs an explicit decision.

**Let Active Record's own `JoinDependency#build` handle `BabySqueel::Join`
keys through a `find_reflection` override.** The copy of a polymorphic
reflection would have to claim `polymorphic? == false` and skip
`check_validity!`; without that, 8.0 and 8.1 raise
`InverseOfAssociationNotFoundError` when the class joined lacks the
association `inverse_of` names. Two hidden overrides for
about 20 lines, and a Rails version that reads `polymorphic?` somewhere new
would produce wrong SQL without an error.

**Skip `scope_roots` when the scope has no joins.** Saves 5–15 µs, only for
`where.has` on a scope that does not join yet. The consumer calls `where.has`
after `joining` or `joins` almost everywhere, so the fast path would rarely
run; it adds a branch tied to another Active Record detail.

**Cache the polymorphic reflection copy per reflection and class.** 10–14%
faster for `.of`. Not that sharing one copy would let separate join trees
merge: `JoinAssociation#match?` compares reflections with
`MacroReflection#==`, which looks at name, options and model, so copies for
different classes already compare equal. What stands against it is a global
cache for a gain limited to `.of` joins, which must not keep reloaded
classes alive in development (it would need a weak map). Worth reopening if
`.of` joins show up in a profile.

**A subclass of `JoinAssociation` instead of the outer marker.**
`JoinPart#match?` compares classes, so an outer join would no longer merge
with the matching inner or `left_joins` join.

**`Nodes::Attribute` without `extend`.** A subclass breaks the Struct `==`
that `rewhere` and `merge` rely on; without the extension, Arel's
`in(relation)` loads the records instead of building a subquery; a prepend
on Arel's attribute would change Arel for the whole application. The
`extend` costs about 0.5 µs per attribute.

**Resolve an alias with one join dependency, without looking in the scope's
own joins first.** Brings back the wrong alias for a chain the scope joins
with `left_joins` next to another join of the same table, for a chain past
joins merged in from another model, and for a chain past an inner join of
the same association; three specs fail.

**Resolve without copying the join trees merged in from another model.**
Active Record writes each join's table into those trees, which the scope
holds, so a join added after `where.has` would get the wrong ON clause.

**Shorten `WhereChain#rejected`.** Saves about eight lines but makes the
errors worse: inspecting an array or attribute prints every node or the
whole table. The messages are specified.

**Remove `VersionHelper`.** CLAUDE.md puts version branches there; it can go
once Active Record 8.0 support ends.

**Trim the upstream history in CHANGELOG.md.** Documentation only; the
history explains where features and removals came from.

**Resolve `alias_attribute` names as bare methods (`headline`).** Only `[]`
resolves them, as in internal3. It would be a new feature.

**Resolve chains inside association scopes against the outer query's
aliases.** A scope is built before the outer query aliases its joins, so a
chain whose table the outer query joins as well stays on the outer join.
Active Record's own `where(authors: ...)` in that scope does the same; the
gem would have to compute aliases by hand. Documented in the README instead.

**Drop the default `= []` on `DSL#find_alias` or the guard in `DSL#_joins`.**
Cosmetic; the guard would change an internal return value from nil to `{}`.

**Resolve aliases without building the scope's join constraints.** On
a scope with several joins, `where.has` spends about three quarters of its
time in Active Record's `JoinDependency#join_constraints`, about as long as
the scope's own `arel`; internal3 assigned the tables of the whole tree
without building ON clauses and was faster there (about +60 µs, +20%, for
a filter on a scope with six joins). Active Record assigns an alias and
builds the ON clause in the same step, so skipping the ON clauses means
computing aliases by hand. Over all consumer query shapes internal6 is
about 15–20% faster than internal3.

**Replace the `NoMethodError` for a through association whose `through`
names no association.** Raised when the block names the association, as
in internal3; it only happens with a misdeclared model, which Active
Record rejects on first use as well.

**Drop the `raise` in `DSL#resolve`.** No spec and no fuzz run over 454
join combinations reaches it: the second lookup joins the chain to the
scope, so the chain is always there. Kept, so that a Rails version that
builds the tree differently raises `BabySqueel::Error` naming the
association instead of `NoMethodError` on nil.

**Keep the scope's join trees across `where.has` blocks.** Saves 40–150 µs
for each further block, depending on the scope's joins; the consumer runs
at most three blocks on one set of joins, in one of its filters, and the
trees would be state on the relation that `spawn` copies.

**Compare the class in `DSL#child?` for every association, not only a
polymorphic one.** One condition less with the same result, since both
classes of a non-polymorphic association come from the same reflection;
the condition as it is says that the class matters only for a
polymorphic one. Cosmetic.

**Copy only the join trees merged in from another model.** The stashed
dependency Active Record builds afresh for `joins` next to `left_joins`
needs no copy; skipping it saves 1–3% for that combination. The merged
dependencies can be told apart by identity, since they are the objects in
`joins_values` and `left_outer_joins_values`, but an extra check for that
gain is not worth it.

**`[x].flatten` instead of `Array.wrap(x).flatten` in `joining`, or
`Symbol#name` instead of `to_s`.** The same result; `[x].flatten` saves
about 0.4 µs and four allocations for a single table but is slower for an
array, `name` saves one allocation per name; under 1% of `to_sql`.

**Trim `.gitignore` and `bin/console`.** Upstream leftovers without any
effect on the gem.

## Adopted after first being rejected

**A boolean `outer` instead of an Arel join class.** Cosmetic on its own;
taken together with the immutable `Association`, where it removed the clone
and the protected writers.
