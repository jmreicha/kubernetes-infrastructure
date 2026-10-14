# A throwaway git repo with this project's chart, scripts, policies, and one fixture,
# sharing the real .cache so charts aren't downloaded again.
make_repo() {
  real=$(cd "$BATS_TEST_DIRNAME/../.." && pwd)
  repo=$BATS_TEST_TMPDIR/repo
  mkdir -p "$repo/examples" "$repo/tests"
  cp -R "$real/cluster" "$real/scripts" "$real/policies" "$repo/"
  cp "$real/tests/tool-versions.env" "$repo/tests/"
  cp "$real/mise.toml" "$repo/"
  cp "$real/examples/eks-minimal.yaml" "$repo/examples/"
  mkdir -p "$real/.cache" && ln -s "$real/.cache" "$repo/.cache"
  printf '.cache\n' >"$repo/.gitignore"
  git -C "$repo" init -q && git -C "$repo" add -A
  git -C "$repo" -c user.email=t@t -c user.name=t commit -qm base
  export CHART_CACHE="$real/.cache/charts"
}
