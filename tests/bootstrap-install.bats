# scripts/bootstrap-cluster: install order and secret seeding (docs/spec/bootstrap).
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
  for s in op-credentials onepassword-token kargo-admin cloudflare-api-token kubechecks-tokens keycloak democratic-csi-driver-config grafana; do
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
  STUB_EXISTING_SECRETS="op-credentials onepassword-token kargo-admin cloudflare-api-token kubechecks-tokens keycloak democratic-csi-driver-config grafana" \
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

@test "seeds grafana's admin Secret in monitoring when grafana is enabled" {
  run scripts/bootstrap-cluster "$work/clusters/eks.yaml"
  [ "$status" -eq 0 ]
  grep -q 'kubectl create secret generic grafana -n monitoring --from-file=admin-user=.* --from-file=admin-password=' "$CALLS"
}

@test "skips grafana's admin Secret when grafana is not enabled" {
  STUB_DEFAULT_SCS=do-block-storage run scripts/bootstrap-cluster "$work/clusters/doks.yaml"
  [ "$status" -eq 0 ]
  refute grep -q 'name: grafana' "$APPLIED"
}

@test "seeds arc's GitHub App Secret in arc-runners when arc is enabled" {
  STUB_DEFAULT_SCS=do-block-storage run scripts/bootstrap-cluster "$work/clusters/doks.yaml"
  [ "$status" -eq 0 ]
  grep -q 'kubectl create secret generic arc-github-app -n arc-runners --from-file=github_app_id=.* --from-file=github_app_installation_id=.* --from-file=github_app_private_key=' "$CALLS"
}

@test "installs cilium and argo-cd without their monitors, which Argo CD adds on adoption" {
  run scripts/bootstrap-cluster "$work/clusters/baremetal.yaml"
  [ "$status" -eq 0 ]
  [ -s "$CALLS.cilium.values" ] && [ -s "$CALLS.argo-cd.values" ]
  refute grep -qi 'servicemonitor' "$CALLS.cilium.values" "$CALLS.argo-cd.values"
}

@test "seeds openbao's seal key without a trailing newline, which OpenBao doesn't trim" {
  run scripts/bootstrap-cluster "$work/clusters/eks.yaml"
  [ "$status" -eq 0 ]
  grep -q '^op read --no-newline op://infra/eks-openbao/seal-key$' "$CALLS"
  grep -q 'kubectl create secret generic openbao-seal -n openbao --from-file=key=' "$CALLS"
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
