# Deprecated or removed Kubernetes APIs fail the render tier (pluto).
setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
  d=$(mktemp -d)
}
teardown() { rm -rf "$d"; }

@test "an API removed in the target version fails" {
  cp tests/fixtures/removed-api.yaml "$d/"
  run scripts/check-apis "$d" 1.34
  [ "$status" -ne 0 ]
  [[ "$output" == *PodDisruptionBudget* ]]
}

@test "current APIs pass" {
  cp tests/fixtures/widget-crd.yaml "$d/"
  run scripts/check-apis "$d" 1.34
  [ "$status" -eq 0 ]
}

@test "report-only mode prints a removed API but does not fail" {
  cp tests/fixtures/removed-api.yaml "$d/"
  run scripts/check-apis --report-only "$d" 1.34
  [ "$status" -eq 0 ]
  [[ "$output" == *PodDisruptionBudget* ]]
}
