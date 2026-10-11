package render_test

import data.render

app(name, layer, wave, rev) := {
	"kind": "Application",
	"metadata": {"name": name, "labels": {"layer": layer}, "annotations": {"argocd.argoproj.io/sync-wave": wave}, "finalizers": ["resources-finalizer.argocd.argoproj.io"]},
	"spec": {
		"project": {"bootstrap": "core", "core": "core", "platform": "platform"}[layer],
		"source": {"repoURL": "https://charts.example.com", "chart": name, "targetRevision": rev},
		"syncPolicy": {
			"automated": {"prune": true, "selfHeal": true},
			"retry": {"limit": 5},
			"syncOptions": ["CreateNamespace=true", "ServerSideApply=true"],
		},
	},
}

good := {
	"cluster": {"provider": "eks"},
	"apps": [app("cert-manager", "core", "1", "v1.2.3"), app("keda", "platform", "4", "2.21.0")],
	"repo": [],
	"charts": {"cert-manager": [], "keda": []},
	"platformClusterKinds": [{"group": "rbac.authorization.k8s.io", "kind": "ClusterRole"}],
}

with_app(i, patch) := object.union(good, {"apps": array.flatten([
	array.slice(good.apps, 0, i),
	[object.union(good.apps[i], patch)],
	array.slice(good.apps, i + 1, count(good.apps)),
])})

test_good_passes if count(render.deny) == 0 with input as good

test_range_version_denied if {
	some m in render.deny with input as with_app(0, {"spec": object.union(good.apps[0].spec, {"source": object.union(good.apps[0].spec.source, {"targetRevision": "1.x"})})})
	contains(m, "exact version")
}

test_repo_root_may_track_branch if {
	root := object.union(app("root-core", "core", "1", "main"), {"spec": object.union(good.apps[0].spec, {"source": {"repoURL": "https://github.com/jmreicha/kubernetes-infrastructure.git", "path": "apps", "targetRevision": "main"}})})
	count(render.deny) == 0 with input as object.union(good, {"apps": array.concat(good.apps, [root])})
}

test_wave_outside_layer_denied if {
	some m in render.deny with input as with_app(1, {"metadata": object.union(good.apps[1].metadata, {"annotations": {"argocd.argoproj.io/sync-wave": "1"}})})
	contains(m, "sync-wave")
}

test_wrong_project_denied if {
	some m in render.deny with input as with_app(1, {"spec": object.union(good.apps[1].spec, {"project": "core"})})
	contains(m, "AppProject")
}

test_missing_self_heal_denied if {
	bad := json.patch(good.apps[0], [{"op": "remove", "path": "/spec/syncPolicy/automated/selfHeal"}])
	some m in render.deny with input as object.union(good, {"apps": [bad, good.apps[1]]})
	contains(m, "selfHeal")
}

test_missing_retry_denied if {
	bad := json.patch(good.apps[0], [{"op": "remove", "path": "/spec/syncPolicy/retry"}])
	some m in render.deny with input as object.union(good, {"apps": [bad, good.apps[1]]})
	contains(m, "retry")
}

test_missing_server_side_apply_denied if {
	some m in render.deny with input as with_app(0, {"spec": object.union(good.apps[0].spec, {"syncPolicy": object.union(good.apps[0].spec.syncPolicy, {"syncOptions": ["CreateNamespace=true"]})})})
	contains(m, "ServerSideApply")
}

test_baremetal_privileged_label_required if {
	bm := object.union(good, {"cluster": {"provider": "baremetal"}, "apps": [app("falco", "core", "2", "9.2.0")], "charts": {"falco": []}})
	some m in render.deny with input as bm
	contains(m, "privileged")
}

test_irsa_annotation_denied_on_eks if {
	sa := {"kind": "ServiceAccount", "metadata": {"name": "x", "annotations": {"eks.amazonaws.com/role-arn": "arn:aws:iam::1:role/x"}}}
	some m in render.deny with input as object.union(good, {"charts": {"cert-manager": [sa], "keda": []}})
	contains(m, "IRSA")
}

test_repo_secret_with_data_denied if {
	s := {"kind": "Secret", "metadata": {"name": "leak"}, "data": {"k": "dg=="}}
	some m in render.deny with input as object.union(good, {"repo": [s]})
	contains(m, "leak")
}

test_unstable_resource_needs_ignore_differences if {
	some m in render.deny with input as object.union(good, {"unstable": {"cert-manager": [{"kind": "Secret", "name": "gen-cert"}]}})
	contains(m, "ignoreDifferences")
}

test_unstable_resource_covered_by_ignore_differences_passes if {
	ig := {"spec": object.union(good.apps[0].spec, {"ignoreDifferences": [{"kind": "Secret", "name": "gen-cert", "jsonPointers": ["/data"]}]})}
	count(render.deny) == 0 with input as object.union(with_app(0, ig), {"unstable": {"cert-manager": [{"kind": "Secret", "name": "gen-cert"}]}})
}

test_unstable_webhook_needs_ignore_differences if {
	some m in render.deny with input as object.union(good, {"unstable": {"keda": [{"kind": "ValidatingWebhookConfiguration", "name": "keda-admission"}]}})
	contains(m, "keda-admission")
}

test_stable_chart_secret_with_data_passes if {
	s := {"kind": "Secret", "metadata": {"name": "values-dump"}, "stringData": {"values.yaml": "a: 1"}}
	count(render.deny) == 0 with input as object.union(good, {"charts": {"cert-manager": [s], "keda": []}})
}

test_gateway_crd_outside_envoy_gateway_denied if {
	crd := {"kind": "CustomResourceDefinition", "metadata": {"name": "gateways.gateway.networking.k8s.io"}, "spec": {"group": "gateway.networking.k8s.io", "scope": "Namespaced"}}
	some m in render.deny with input as object.union(good, {"charts": {"cert-manager": [crd], "keda": []}})
	contains(m, "Gateway API")
}

test_platform_cluster_kind_outside_allowlist_denied if {
	pc := {"apiVersion": "scheduling.k8s.io/v1", "kind": "PriorityClass", "metadata": {"name": "high"}}
	some m in render.deny with input as object.union(good, {"charts": {"cert-manager": [], "keda": [pc]}})
	contains(m, "PriorityClass")
}

test_platform_namespaced_kind_without_namespace_allowed if {
	cm := {"apiVersion": "v1", "kind": "ConfigMap", "metadata": {"name": "x"}}
	count(render.deny) == 0 with input as object.union(good, {"charts": {"cert-manager": [], "keda": [cm]}})
}

test_platform_cluster_scoped_cr_from_rendered_crd_denied if {
	crd := {"kind": "CustomResourceDefinition", "metadata": {"name": "cdis.cdi.kubevirt.io"}, "spec": {"group": "cdi.kubevirt.io", "scope": "Cluster", "names": {"kind": "CDI"}}}
	cr := {"apiVersion": "cdi.kubevirt.io/v1beta1", "kind": "CDI", "metadata": {"name": "cdi"}}
	some m in render.deny with input as object.union(good, {"charts": {"cert-manager": [], "keda": [crd, cr]}, "platformClusterKinds": array.concat(good.platformClusterKinds, [{"group": "apiextensions.k8s.io", "kind": "CustomResourceDefinition"}])})
	contains(m, "CDI")
}

test_unstable_hook_is_ignored if {
	count(render.deny) == 0 with input as object.union(good, {"unstable": {"cert-manager": [{"kind": "Job", "name": "cleanup-1234", "hook": true}]}})
}

deploy(spec) := {"kind": "Deployment", "metadata": {"name": "w"}, "spec": {"template": {"spec": spec}}}

ns_app(name, ns, layer) := json.patch(app(name, layer, "2", "1.0.0"), [{"op": "add", "path": "/spec/destination", "value": {"namespace": ns}}])

host_case(spec, ns) := object.union(good, {
	"apps": [ns_app("x", ns, "core")],
	"charts": {"x": [deploy(spec)]},
	"privilegedNamespaces": ["falco", "kube-system"],
})

test_privileged_container_in_baseline_namespace_denied if {
	some m in render.deny with input as host_case({"containers": [{"name": "c", "securityContext": {"privileged": true}}]}, "x")
	contains(m, "privileged")
}

test_host_network_in_baseline_namespace_denied if {
	some m in render.deny with input as host_case({"hostNetwork": true, "containers": [{"name": "c"}]}, "x")
	contains(m, "hostNetwork")
}

test_host_path_in_baseline_namespace_denied if {
	some m in render.deny with input as host_case({"volumes": [{"name": "v", "hostPath": {"path": "/"}}], "containers": [{"name": "c"}]}, "x")
	contains(m, "hostPath")
}

test_host_port_in_baseline_namespace_denied if {
	some m in render.deny with input as host_case({"containers": [{"name": "c", "ports": [{"containerPort": 80, "hostPort": 80}]}]}, "x")
	contains(m, "hostPort")
}

test_extra_capability_in_baseline_namespace_denied if {
	some m in render.deny with input as host_case({"containers": [{"name": "c", "securityContext": {"capabilities": {"add": ["SYS_ADMIN"]}}}]}, "x")
	contains(m, "SYS_ADMIN")
}

test_baseline_capability_allowed if {
	count(render.deny) == 0 with input as host_case({"containers": [{"name": "c", "securityContext": {"capabilities": {"add": ["NET_BIND_SERVICE"]}}}]}, "x")
}

test_host_access_in_privileged_namespace_allowed if {
	count(render.deny) == 0 with input as host_case({"hostNetwork": true, "containers": [{"name": "c", "securityContext": {"privileged": true}}]}, "falco")
}

test_explicit_namespace_overrides_destination if {
	d := json.patch(deploy({"hostNetwork": true, "containers": [{"name": "c"}]}), [{"op": "add", "path": "/metadata/namespace", "value": "kube-system"}])
	count(render.deny) == 0 with input as object.union(host_case({}, "x"), {"charts": {"x": [d]}})
}

test_cronjob_pod_template_checked if {
	cj := {"kind": "CronJob", "metadata": {"name": "j"}, "spec": {"jobTemplate": {"spec": {"template": {"spec": {"hostPID": true, "containers": [{"name": "c"}]}}}}}}
	some m in render.deny with input as object.union(host_case({}, "x"), {"charts": {"x": [cj]}})
	contains(m, "hostPID")
}

git_app(rev) := json.patch(app("lib", "core", "2", rev), [
	{"op": "replace", "path": "/spec/source", "value": {"repoURL": "https://github.com/o/lib.git", "path": "library", "targetRevision": rev}},
])

test_commit_pin_allowed_for_git_source if {
	count(render.deny) == 0 with input as object.union(good, {"apps": [git_app("f8e3b4e9ab3b7d1a28092da75c2c5e71aedfd4b9")], "charts": {"lib": []}})
}

test_branch_denied_for_git_source if {
	some m in render.deny with input as object.union(good, {"apps": [git_app("master")], "charts": {"lib": []}})
	contains(m, "exact version")
}

image_case(image) := object.union(good, {
	"apps": [ns_app("x", "x", "core")],
	"charts": {"x": [deploy({"containers": [{"name": "c", "image": image}]})]},
})

test_latest_image_denied if {
	some m in render.deny with input as image_case("nginx:latest")
	contains(m, "nginx:latest")
}

test_untagged_image_denied if {
	some m in render.deny with input as image_case("ghcr.io/org/app")
	contains(m, "ghcr.io/org/app")
}

test_registry_port_is_not_a_tag if {
	some m in render.deny with input as image_case("registry.local:5000/org/app")
	contains(m, "registry.local:5000/org/app")
}

test_tagged_image_allowed if count(render.deny) == 0 with input as image_case("registry.local:5000/org/app:1.2.3")

test_digest_pinned_image_allowed if {
	count(render.deny) == 0 with input as image_case("quay.io/org/app@sha256:0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef")
}

test_init_container_image_checked if {
	d := deploy({"initContainers": [{"name": "i", "image": "busybox"}], "containers": [{"name": "c", "image": "app:1.0"}]})
	some m in render.deny with input as object.union(image_case("app:1.0"), {"charts": {"x": [d]}})
	contains(m, "busybox")
}
