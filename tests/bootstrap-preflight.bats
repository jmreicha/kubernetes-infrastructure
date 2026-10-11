# scripts/bootstrap-cluster: validation and preflight checks (spec/bootstrap).
# shellcheck source=bootstrap_helpers.bash
source "$BATS_TEST_DIRNAME/bootstrap_helpers.bash"

@test "invalid values fail before any cluster change" {
  yq -i '.provider = "gke"' "$work/clusters/baremetal.yaml"
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *provider* ]]
  refute grep -qE '^(kubectl|helm)' "$CALLS"
}

@test "clusterName must match the file name" {
  yq -i '.clusterName = "other"' "$work/clusters/baremetal.yaml"
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *other* && "$output" == *baremetal* ]]
}

@test "baremetal: kube-proxy on a node fails before installing cilium, naming the node" {
  STUB_KUBE_PROXY_NODES=node-a run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *node-a* ]]
  refute grep -q '^helm upgrade --install cilium' "$CALLS"
}

@test "bring-your-own StorageClass must exist and be the only default before anything installs" {
  yq -i '.disable = ["longhorn", "local-path-provisioner"] | .defaultStorageClass = "nfs"' "$work/clusters/baremetal.yaml"
  STUB_DEFAULT_SCS="standard" run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *nfs* ]]
  refute grep -q '^helm upgrade' "$CALLS"
}

@test "bring-your-own StorageClass that is the only default passes" {
  yq -i '.disable = ["longhorn", "local-path-provisioner"] | .defaultStorageClass = "nfs"' "$work/clusters/baremetal.yaml"
  STUB_DEFAULT_SCS="nfs" run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
}

@test "op read failure stops before argo-cd and names the reference" {
  STUB_OP_FAIL=1 run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *op://infra/lab-connect/* ]]
  refute grep -q 'helm upgrade --install argo-cd' "$CALLS"
}
