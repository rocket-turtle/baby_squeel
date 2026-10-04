# baby_squeel (internal fork)

- Two public methods, `joining {}` and `where.has {}`. Everything else was removed on purpose; do not add features back.
- `AR` selects the Active Record version: `AR='~> 8.0.4'`, `AR='~> 8.1.1'`, `AR=main`. Unset, the gemspec's newest allowed version. `bin/setup` deletes `Gemfile.lock` and installs for `$AR`; a lock left on `AR=main` breaks plain `bundle exec` until `unset AR; bin/setup`.
- Run `AR=... bundle exec rspec` and `bundle exec rubocop` before every commit, against 8.0 and 8.1.
- Snapshots live in `spec/**/__snapshots__/*.yaml`, keyed by example description. `variants: ["8.1", "8.2"]` adds a per-version suffix; 8.0 uses the plain key. A missing key raises; record with `UPDATE_SNAPSHOTS=1` per version. `rake snapshots:prune` removes orphaned keys. Prefer `produce_sql(<plain Active Record relation>)` over a snapshot.
- Aliases come from Active Record's own join dependency (`Table#find_alias`), never computed by hand. Version branches go into `active_record/version_helper.rb` only.
- Known limitation, pending spec in `spec/integration/joining_spec.rb`: an outer join of an association Active Record already inner joins is added, not merged.
- Consumer: one application, which also builds its permission scopes on `joining` and `where.has`. Before removing a feature, `grep -rE 'joining|where\.has'` its code and run its specs that touch the gem.
- Release: version in `lib/baby_squeel/version.rb`, dated CHANGELOG section, commit only those two files, `gem build`, upload to the gemserver. `.ruby-version`, `.ruby-gemset` and built gems are git-ignored.
