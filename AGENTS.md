# Agent instructions

## Specs (yass)

The specs are the contract the code is built against: [`root.yass.yaml`](root.yass.yaml) at the
root (the yass project marker, so it stays there) and the per-area files in `docs/spec/`. yass is
pinned in `mise.toml` and read-only; it reads and checks specs but never writes them.

- Change the spec first, then a failing test, then the code. A behaviour change with no spec
  change is incomplete.
- Read before you change anything; `yass` resolves references, so prefer it over grepping:

  ```bash
  mise exec -- yass list                       # every spec and design document
  mise exec -- yass query docs/spec/core@Core  # one document, references resolved
  mise exec -- yass find "pull-through"        # search obligations and design content
  mise exec -- yass refs root@Catalog          # what points at a document, and what it points at
  ```

- Before writing or restructuring a spec, read the carried guides: `yass docs guidance` and
  `yass docs reference` (`yass docs brainstorming` for a new area with no spec yet). Implementing
  against an existing spec needs neither.
- References are `path@Name::SLOT`, with paths from the project root (`docs/spec/values@ClusterValues`).
  Relative paths count from the referring file (`../../root@...` from `docs/spec/`).
- The Catalog table in `root.yass.yaml` must match `cluster/values.yaml` entry for entry
  (`tests/catalog.bats`); update both together.
- The pre-commit hook runs `yass validate && yass lint` on any `*.yass.yaml` change; both must be
  clean.

## Architecture decisions

Decisions are ADRs in `docs/adr/`, managed with [adrs](https://github.com/joshrotenberg/adrs)
(pinned in `mise.toml`, configured in `adrs.toml`: MADR format, YAML frontmatter, no editor).

- Write an ADR when a change picks one approach over a real alternative: adding, replacing, or
  dropping a project; changing a layer, provider, or optionality rule; or adopting a tool. Routine
  version bumps and fixes don't need one.
- Create it with the tool so numbering and frontmatter stay consistent, then fill in every section:

  ```bash
  mise exec -- adrs new -t <category>[,<category>] "Short title without colons"
  ```

  Tags are the catalog categories: storage, compute, security, networking, observability, data,
  system. Avoid `:` in titles; adrs writes them into YAML unquoted.

- Fill in Context, Considered Options (the chosen option plus what was rejected), and Decision
  Outcome (the choice and why). Don't leave template placeholders; `adrs doctor` fails on them,
  and it treats a literal `...` anywhere as one (reporting it against Decision Outcome).
- Never rewrite an accepted ADR's decision. Replace it with `adrs new --supersedes <N> ...`, or
  record a narrower change with `adrs link <new> Amends <old>`.
- The pre-commit hook runs `adrs doctor` on any change under `docs/adr/`; run it directly with
  `mise exec -- adrs doctor`.
