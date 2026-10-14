# scripts/talos-cilium-patch renders the Talos machine-config patch that installs the catalog's Cilium.
setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
}

@test "patch removes Talos's Flannel CNI and kube-proxy (Talos 1.14 documents)" {
  run scripts/talos-cilium-patch examples/baremetal.yaml
  [ "$status" -eq 0 ]
  [ "$(yq -N 'select(.kind == "KubeFlannelCNIConfig") | ."$patch"' <<<"$output")" = delete ]
  [ "$(yq -N 'select(.kind == "KubeProxyConfig") | .enabled' <<<"$output")" = false ]
}

@test "patch inlines the catalog's Cilium chart, version, and values" {
  run scripts/talos-cilium-patch examples/baremetal.yaml
  [ "$status" -eq 0 ]
  [ "$(yq -N 'select(.kind == "KubeInlineManifestConfig") | .name' <<<"$output")" = cilium ]
  manifests=$(yq -N 'select(.kind == "KubeInlineManifestConfig") | .manifest' <<<"$output")
  grep -q 'kind: DaemonSet' <<<"$manifests"
  grep -q 'helm.sh/chart: cilium-1.20.2' <<<"$manifests"
  grep -A1 'name: KUBERNETES_SERVICE_HOST' <<<"$manifests" | grep -q 'value: "localhost"'
  grep -q 'enable-wireguard: "true"' <<<"$manifests"
}

@test "patch is only for baremetal clusters" {
  run scripts/talos-cilium-patch examples/eks.yaml
  [ "$status" -ne 0 ]
  [[ "$output" == *baremetal* ]]
}

zot_values() {
  yq '.enable = ["zot"] | .pullThroughCacheIp = "10.10.0.5"' examples/baremetal.yaml >"$BATS_TEST_TMPDIR/zot.yaml"
  echo "$BATS_TEST_TMPDIR/zot.yaml"
}

@test "registry patch mirrors every cached registry through zot" {
  run scripts/talos-registry-patch "$(zot_values)"
  [ "$status" -eq 0 ]
  [ "$(yq -N 'select(.kind == "RegistryMirrorConfig") | .name' <<<"$output" | sort | xargs)" = "docker.io gcr.io ghcr.io public.ecr.aws quay.io registry.k8s.io" ]
}

@test "registry patch points at zot's path for the registry and keeps the path" {
  run scripts/talos-registry-patch "$(zot_values)"
  [ "$status" -eq 0 ]
  [ "$(yq -N 'select(.name == "docker.io") | .endpoints[0].url' <<<"$output")" = "http://10.10.0.5:5000/v2/docker.io" ]
  [ "$(yq -N 'select(.name == "docker.io") | .endpoints[0].overridePath' <<<"$output")" = true ]
}

@test "registry patch needs zot enabled" {
  run scripts/talos-registry-patch examples/baremetal-minimal.yaml
  [ "$status" -ne 0 ]
  [[ "$output" == *"enable: [zot]"* ]]
}

# Applies a patch to a freshly generated Talos config and validates it, offline.
talos_accepts() { # patch-file
  local t=$BATS_TEST_TMPDIR
  talosctl gen config test https://127.0.0.1:6443 --output-types controlplane -o "$t/cp.yaml" --force >/dev/null
  talosctl machineconfig patch "$t/cp.yaml" --patch "@$1" -o "$t/patched.yaml"
  talosctl validate --config "$t/patched.yaml" --mode metal
}

@test "Talos accepts the Cilium patch" {
  scripts/talos-cilium-patch examples/baremetal.yaml >"$BATS_TEST_TMPDIR/cilium.yaml"
  run talos_accepts "$BATS_TEST_TMPDIR/cilium.yaml"
  [ "$status" -eq 0 ]
}

@test "Talos accepts the registry mirror patch" {
  scripts/talos-registry-patch "$(zot_values)" >"$BATS_TEST_TMPDIR/registry.yaml"
  run talos_accepts "$BATS_TEST_TMPDIR/registry.yaml"
  [ "$status" -eq 0 ]
}

@test "talosctl validate rejects a malformed patch" {
  printf 'cluster:\n  network:\n    cni:\n      name: bogus-cni\n' >"$BATS_TEST_TMPDIR/bad.yaml"
  run talos_accepts "$BATS_TEST_TMPDIR/bad.yaml"
  [ "$status" -ne 0 ]
}
