# API tier catches what only a real kube-apiserver rejects (slow: starts kwok in Docker).
setup() {
  cd "$BATS_TEST_DIRNAME/../.." || exit
  d=$(mktemp -d)
  mkdir -p "$d/bad/charts" "$d/bad/apps"
  echo '{"kubernetesVersion": "1.34"}' >"$d/bad/cluster.json"
  echo '{}' >"$d/bad/bundle.json"
  echo '[{"metadata": {"name": "demo", "annotations": {"argocd.argoproj.io/sync-wave": "2"}}, "spec": {"source": {"repoURL": "https://charts.example.com"}, "destination": {"namespace": "demo"}}}]' >"$d/bad/apps.json"
  for l in cluster core platform; do : >"$d/bad/apps/$l.yaml"; done
}
teardown() { rm -rf "$d"; }

@test "an invalid Deployment fails the API tier" {
  cat >"$d/bad/charts/demo.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: demo}
spec:
  selector: {matchLabels: {app: demo}}
  template:
    metadata: {labels: {app: other}}
    spec: {containers: [{name: c, image: busybox}]}
YAML
  run scripts/verify-api "$d"
  [ "$status" -ne 0 ]
  [[ "$output" == *"selector"* ]]
}

@test "a valid Deployment passes the API tier" {
  cat >"$d/bad/charts/demo.yaml" <<'YAML'
apiVersion: apps/v1
kind: Deployment
metadata: {name: demo}
spec:
  selector: {matchLabels: {app: demo}}
  template:
    metadata: {labels: {app: demo}}
    spec: {containers: [{name: c, image: busybox}]}
YAML
  run scripts/verify-api "$d"
  [ "$status" -eq 0 ]
}
