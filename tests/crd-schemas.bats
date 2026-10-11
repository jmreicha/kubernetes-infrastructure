# Strict kubeconform schemas generated from rendered CRDs.
setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
  out=$(mktemp -d)
}
teardown() { rm -rf "$out"; }

@test "writes one schema per CRD version at the kubeconform path" {
  scripts/crd-schemas tests/fixtures/widget-crd.yaml "$out"
  [ -f "$out/example.com/widget_v1.json" ]
}

@test "schemas reject unknown fields but keep preserve-unknown-fields open" {
  scripts/crd-schemas tests/fixtures/widget-crd.yaml "$out"
  [ "$(jq '.properties.spec.additionalProperties' "$out/example.com/widget_v1.json")" = "false" ]
  [ "$(jq '.properties.spec.properties.extra.additionalProperties' "$out/example.com/widget_v1.json")" = "null" ]
}

@test "kubeconform with generated schemas rejects a typo'd field" {
  scripts/crd-schemas tests/fixtures/widget-crd.yaml "$out"
  bad='{"apiVersion":"example.com/v1","kind":"Widget","metadata":{"name":"w"},"spec":{"sise":1}}'
  run kubeconform -strict -schema-location "$out/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json" - <<<"$bad"
  [ "$status" -ne 0 ]
}
