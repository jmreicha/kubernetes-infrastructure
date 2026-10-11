# Every pin is reachable by a Renovate regex manager (GitOpsConventions: Renovate owns versions).
setup() { cd "$BATS_TEST_DIRNAME/.." || exit; }

matches() { # file -> one "depName packageName currentValue" line per match, all custom managers
  node -e '
    const fs = require("fs");
    const cfg = eval("(" + fs.readFileSync(".github/renovate.json5", "utf8") + ")");
    const file = process.argv[1], text = fs.readFileSync(file, "utf8");
    for (const m of cfg.customManagers) {
      if (!m.managerFilePatterns.some(p => new RegExp(p.slice(1, -1)).test(file))) continue;
      for (const s of m.matchStrings) for (const x of text.matchAll(new RegExp(s, "g")))
        console.log([x.groups.depName || m.depNameTemplate, x.groups.packageName || x.groups.registryUrl || m.packageNameTemplate || x.groups.depName, x.groups.currentValue || x.groups.currentDigest, m.datasourceTemplate || x.groups.datasource].join(" "));
    }' "$1"
}

@test "every catalog version and pinned image is matched exactly once" {
  want=$(($(yq '.catalog | length' cluster/values.yaml) + $(grep -c '# renovate: datasource=' cluster/values.yaml)))
  [ "$(matches cluster/values.yaml | wc -l | tr -d ' ')" = "$want" ]
}

@test "OCI, https, and git entries each resolve to the right package" {
  out=$(matches cluster/values.yaml)
  grep -qx 'kargo ghcr.io/akuity/kargo-charts 1.12.3 docker' <<<"$out"
  grep -qx 'cilium https://helm.cilium.io 1.20.2 helm' <<<"$out"
  grep -qx 'local-path-provisioner https://github.com/rancher/local-path-provisioner.git v0.0.37 git-tags' <<<"$out"
}

@test "commit-pinned git entries resolve to a digest, not a tag" {
  out=$(matches cluster/values.yaml)
  grep -qx 'gatekeeper-templates-psp https://github.com/open-policy-agent/gatekeeper-library.git f8e3b4e9ab3b7d1a28092da75c2c5e71aedfd4b9 git-refs' <<<"$out"
}

@test "image tags pinned in chart values resolve to their image" {
  out=$(matches cluster/values.yaml)
  grep -qx 'yonahdissen/kor yonahdissen/kor v0.6.9 docker' <<<"$out"
  grep -qx 'ghcr.io/zapier/kubechecks ghcr.io/zapier/kubechecks v3.5.0 docker' <<<"$out"
}

@test "the CRD catalog tag is pinned and matched" {
  run matches tests/tool-versions.env
  [[ "$output" =~ CustomResourceDefinition/catalog\ v[0-9]+\.[0-9]+\.[0-9]+\ github-tags ]]
}

@test "CI's prek version matches mise.toml and Renovate bumps both together" {
  want=$(yq -p toml -oy '.tools.prek' mise.toml)
  [ -n "$want" ]
  [ "$(grep -c "prek-version: $want" .github/workflows/ci.yaml)" = 2 ]
  run matches .github/workflows/ci.yaml
  [[ "$output" == *"j178/prek j178/prek $want github-releases"* ]]
  node -e '
    const cfg = eval("(" + require("fs").readFileSync(".github/renovate.json5", "utf8") + ")");
    const rule = (cfg.packageRules || []).find(r => r.groupName === "prek");
    if (!rule || !["prek", "j178/prek"].every(n => rule.matchPackageNames.includes(n))) process.exit(1);'
}
