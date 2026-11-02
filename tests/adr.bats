# Decisions live in docs/adr (adrs tool), not in design.md, so the two can't drift.
bats_require_minimum_version 1.5.0

setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
}

@test "design.md has no decisions table and points at docs/adr" {
  run ! grep -qE '^\| *# *\| *Decision' docs/design.md
  grep -q '(adr/)' docs/design.md
}
