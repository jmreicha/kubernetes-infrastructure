# scripts/bootstrap-cluster: install order and secret seeding (spec/bootstrap).
# shellcheck source=bootstrap_helpers.bash
source "$BATS_TEST_DIRNAME/bootstrap_helpers.bash"

@test "installs cilium, then seeds secrets and argo-cd, then applies the bootstrap layer" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  c=$(line_of 'helm upgrade --install cilium')
  a=$(line_of 'helm upgrade --install argo-cd')
  s=$(line_of 'op read')
  b=$(grep -n 'kubectl apply -f -' "$CALLS" | tail -1 | cut -d: -f1)
  [ -n "$c" ] && [ -n "$a" ] && [ "$c" -lt "$a" ] && [ "$s" -lt "$a" ] && [ "$a" -lt "$b" ]
  grep -q 'kind: AppProject' "$APPLIED"
  grep -q 'name: cluster' "$APPLIED"
  grep -q 'helm upgrade --install cilium cilium --repo https://helm.cilium.io --version 1.20.2' "$CALLS"
}

@test "seeds every secret the cluster needs" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  for s in op-credentials onepassword-token kargo-admin cloudflare-api-token kubechecks-tokens keycloak; do
    grep -q "name: $s" "$APPLIED" || {
      echo "missing $s"
      return 1
    }
  done
}

@test "no secret value ever appears in a command line or in output" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  refute grep -qE 'SECRET-VALUE|ARGO-TOKEN-VALUE|ADMIN-PW-VALUE' "$CALLS"
  refute grep -qE 'SECRET-VALUE|ARGO-TOKEN-VALUE|ADMIN-PW-VALUE' <<<"$output"
}

@test "existing secrets are left alone on a re-run" {
  STUB_EXISTING_SECRETS="op-credentials onepassword-token kargo-admin cloudflare-api-token kubechecks-tokens keycloak" \
    run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  refute grep -q '^op read' "$CALLS"
  refute grep -q 'exec' "$CALLS"
}

@test "seeds each enabled identity add-on's secret and no others" {
  run scripts/bootstrap-cluster "$work/clusters/eks.yaml"
  [ "$status" -eq 0 ]
  secrets=$(yq 'select(.kind == "Secret") | .metadata.name' "$APPLIED")
  grep -qx authentik <<<"$secrets"
  grep -qx oauth2-proxy <<<"$secrets"
  refute grep -q keycloak <<<"$secrets"
}

@test "eks: removes the VPC CNI and skips the cloudflare secret" {
  run scripts/bootstrap-cluster "$work/clusters/eks.yaml"
  [ "$status" -eq 0 ]
  grep -q 'kubectl -n kube-system delete daemonset aws-node' "$CALLS"
  refute grep -q 'name: cloudflare-api-token' "$APPLIED"
}

@test "talos: Cilium already installed by Talos is left for Argo CD to adopt" {
  STUB_CILIUM_PRESENT=1 run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  refute grep -q 'helm upgrade --install cilium' "$CALLS"
  grep -q 'helm upgrade --install argo-cd' "$CALLS"
  [[ "$output" == *"Cilium is already installed"* ]]
}
