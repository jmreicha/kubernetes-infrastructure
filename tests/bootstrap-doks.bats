# scripts/bootstrap-cluster on DOKS and with argocd-agent (spec/bootstrap, spec/core Core.Doks).
# shellcheck source=bootstrap_helpers.bash
source "$BATS_TEST_DIRNAME/bootstrap_helpers.bash"

@test "doks: never installs or waits on Cilium, which DigitalOcean manages" {
  STUB_DEFAULT_SCS=do-block-storage run scripts/bootstrap-cluster "$work/clusters/doks.yaml"
  [ "$status" -eq 0 ]
  refute grep -q 'helm upgrade --install cilium' "$CALLS"
  refute grep -q 'application/cilium' "$CALLS"
  grep -q 'helm upgrade --install argo-cd' "$CALLS"
}

@test "doks: fails before installing anything unless do-block-storage is the only default" {
  STUB_DEFAULT_SCS="do-block-storage standard" run scripts/bootstrap-cluster "$work/clusters/doks.yaml"
  [ "$status" -ne 0 ]
  [[ "$output" == *do-block-storage* ]]
  refute grep -q '^helm upgrade' "$CALLS"
}

@test "doks: seeds the DigitalOcean DNS token and the agent's client certificate" {
  STUB_DEFAULT_SCS=do-block-storage run scripts/bootstrap-cluster "$work/clusters/doks.yaml"
  [ "$status" -eq 0 ]
  for s in digitalocean-api-token argocd-agent-ca argocd-agent-client-tls; do
    grep -q "name: $s" "$APPLIED" || {
      echo "missing $s"
      return 1
    }
  done
  refute grep -q 'name: argocd-agent-jwt' "$APPLIED"
}

@test "principal: seeds its CA, server certificates, and JWT key" {
  run scripts/bootstrap-cluster "$work/clusters/eks.yaml"
  [ "$status" -eq 0 ]
  for s in argocd-agent-ca argocd-agent-principal-tls argocd-agent-resource-proxy-tls argocd-redis-proxy-tls argocd-agent-jwt; do
    grep -q "name: $s" "$APPLIED" || {
      echo "missing $s"
      return 1
    }
  done
  refute grep -q 'name: argocd-agent-client-tls' "$APPLIED"
}
