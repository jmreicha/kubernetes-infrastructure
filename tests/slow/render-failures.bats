# scripts/verify-render fails on what it should, end to end (slow tier).
# shellcheck source=helpers.bash
source "$BATS_TEST_DIRNAME/helpers.bash"

setup() {
  make_repo
}

@test "a clean tree passes" {
  run "$repo/scripts/verify-render" "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
}

@test "a chart pinned to a missing version fails" {
  yq -i '(.catalog[] | select(.name == "kor") | .version) = "99.9.9"' "$repo/cluster/values.yaml"
  run "$repo/scripts/verify-render" "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"cannot pull kor"* ]]
}

@test "host access outside a privileged namespace fails" {
  yq -i '.privilegedNamespaces -= ["falco"]' "$repo/cluster/values.yaml"
  yq -i '.enable = ["falco"]' "$repo/tests/clusters/eks-minimal.yaml"
  run "$repo/scripts/verify-render" "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  [[ "$output" == *"in baseline namespace falco"* ]]
}
