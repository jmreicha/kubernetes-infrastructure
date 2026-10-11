# scripts/verify-risk end to end: a real base/head pair in a throwaway repo (slow tier).
# shellcheck source=helpers.bash
source "$BATS_TEST_DIRNAME/helpers.bash"

setup() {
  make_repo
}

@test "an unchanged tree passes" {
  run "$repo/scripts/verify-risk" HEAD "$BATS_TEST_TMPDIR/out"
  [ "$status" -eq 0 ]
}

@test "dropping cert-manager fails on its deleted CRDs" {
  yq -i 'del(.catalog[] | select(.name == "cert-manager"))' "$repo/cluster/values.yaml"
  run "$repo/scripts/verify-risk" HEAD "$BATS_TEST_TMPDIR/out"
  [ "$status" -ne 0 ]
  echo "$output" >"$BATS_TEST_TMPDIR/log"
  grep -E "FAIL.*deletes cert-manager/CustomResourceDefinition/" "$BATS_TEST_TMPDIR/log"
}
