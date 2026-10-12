# The spec's Catalog table (root.yass.yaml) and the chart's catalog (cluster/values.yaml) agree.
setup() {
  cd "$BATS_TEST_DIRNAME/.." || exit
}

# "name repoURL namespace layer providers wave" per entry, sorted; providers comma-joined and sorted.
spec_rows() {
  yq 'select(.design == "Catalog") | .content' root.yass.yaml \
    | awk 'NR == 1 { next } NF == 0 { exit } { print $1, $3, $4, $5, $6, $7 }' \
    | while read -r name url ns layer providers wave; do
      echo "$name $url $ns $layer $(tr , '\n' <<<"$providers" | sort | paste -sd, -) $wave"
    done | sort
}
values_rows() {
  yq -r '.catalog[] | [.name, .repoURL, .namespace, .layer, (.providers | sort | join(",")), .wave] | join(" ")' cluster/values.yaml | sort
}

@test "every catalog entry matches the spec's Catalog table" {
  diff <(spec_rows) <(values_rows)
}
