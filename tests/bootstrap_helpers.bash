# Shared setup for the bootstrap-*.bats files: scripts/bootstrap-cluster against stubbed kubectl/helm/op.
setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
  REAL_HELM=$(command -v helm)
  CALLS=$(mktemp)
  APPLIED=$(mktemp)
  export REAL_HELM CALLS APPLIED
  export PATH="$BATS_TEST_DIRNAME/stubs:$PATH" BOOTSTRAP_WAIT=0
  work=$(mktemp -d)
  mkdir -p "$work/clusters"
  cp tests/clusters/baremetal.yaml "$work/clusters/baremetal.yaml"
  yq '.clusterName = "eks"' tests/clusters/eks.yaml >"$work/clusters/eks.yaml"
}
teardown() { rm -rf "$CALLS" "$APPLIED" "$work"; }

calls() { cat "$CALLS"; }
# In bats a bare `! cmd` only fails the test on its last line; refute works anywhere.
refute() { ! "$@"; }
line_of() { grep -n -m1 -- "$1" "$CALLS" | cut -d: -f1; }
