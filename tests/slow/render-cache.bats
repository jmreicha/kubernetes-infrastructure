# Concurrent renders against a cold cache don't race on fetching charts (slow tier).
setup() {
  cd "$BATS_TEST_DIRNAME/../.." || exit
  export CHART_CACHE=$BATS_TEST_TMPDIR/charts GIT_CACHE=$BATS_TEST_TMPDIR/git
}

@test "four parallel renders of git- and Helm-sourced charts all succeed from a cold cache" {
  for i in 1 2 3 4; do
    scripts/render "$PWD/tests/clusters/eks-minimal.yaml" "$BATS_TEST_TMPDIR/out$i" >/dev/null 2>&1 || touch "$BATS_TEST_TMPDIR/failed$i" &
  done
  wait
  [ -z "$(ls "$BATS_TEST_TMPDIR"/failed* 2>/dev/null)" ]
  [ -s "$BATS_TEST_TMPDIR/out1/charts/gatekeeper-templates-psp.yaml" ]
}
