# scripts/bootstrap-cluster: waiting on and reporting each layer (spec/bootstrap).
# shellcheck source=bootstrap_helpers.bash
source "$BATS_TEST_DIRNAME/bootstrap_helpers.bash"

@test "waits for core then platform and reports success" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  c=$(line_of 'wait application/root-core')
  p=$(line_of 'wait application/root-platform')
  [ -n "$c" ] && [ -n "$p" ] && [ "$c" -lt "$p" ]
  [[ "$output" == *"Synced and Healthy"* ]]
}

@test "a core layer timeout names the failing Applications and skips the platform wait" {
  STUB_UNHEALTHY_ROOT=root-core STUB_UNHEALTHY_APPS="falco Degraded" run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *"core layer"* && "$output" == *falco* ]]
  refute grep -q 'wait application/root-platform' "$CALLS"
}

@test "coreOnly skips the platform wait" {
  yq -i '.coreOnly = true' "$work/clusters/baremetal.yaml"
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  refute grep -q 'wait application/root-platform' "$CALLS"
}

@test "--no-wait returns after handover" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml" --no-wait
  [ "$status" -eq 0 ]
  refute grep -q 'wait application/root-core' "$CALLS"
}
