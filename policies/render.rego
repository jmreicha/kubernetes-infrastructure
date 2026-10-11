# Render-tier policies over one fixture's bundle (spec/verification Verification.Render).
# input: {cluster, apps, repo: [cluster/ chart docs], charts: {app: [docs]}, unstable: {app: [{kind, name}]}, platformClusterKinds}
package render

repo_url := "kubernetes-infrastructure"

waves := {"bootstrap": {"0"}, "core": {"1", "2"}, "platform": {"3", "4"}}

projects := {"bootstrap": "core", "core": "core", "platform": "platform"}

# Namespaces that need host access on Talos (spec/core, spec/platform).
privileged := {"falco", "longhorn", "local-path-provisioner", "kubevirt", "cdi"}

catalog_apps contains a if {
	some a in input.apps
	not contains(a.spec.source.repoURL, repo_url)
}

deny contains sprintf("%s: targetRevision %q is not an exact version", [a.metadata.name, a.spec.source.targetRevision]) if {
	some a in catalog_apps
	not exact_version(a.spec.source)
}

exact_version(src) if regex.match(`^v?[0-9]+\.[0-9]+\.[0-9]+$`, src.targetRevision)

# A git source whose upstream publishes no releases may pin a full commit SHA.
exact_version(src) if {
	src.path
	regex.match(`^[0-9a-f]{40}$`, src.targetRevision)
}

deny contains sprintf("%s: sync-wave %v is not allowed for layer %s", [a.metadata.name, w, l]) if {
	some a in catalog_apps
	l := a.metadata.labels.layer
	w := object.get(a.metadata, ["annotations", "argocd.argoproj.io/sync-wave"], "missing")
	not w in waves[l]
}

deny contains sprintf("%s: AppProject %s, want %s", [a.metadata.name, a.spec.project, projects[a.metadata.labels.layer]]) if {
	some a in catalog_apps
	a.spec.project != projects[a.metadata.labels.layer]
}

sync_checks := {
	"automated prune": ["automated", "prune"],
	"automated selfHeal": ["automated", "selfHeal"],
	"retry": ["retry"],
}

deny contains sprintf("%s: syncPolicy is missing %s", [a.metadata.name, k]) if {
	some a in input.apps
	some k, path in sync_checks
	not object.get(a.spec.syncPolicy, path, false)
}

deny contains sprintf("%s: syncOptions is missing %s", [a.metadata.name, o]) if {
	some a in input.apps
	some o in {"CreateNamespace=true", "ServerSideApply=true"}
	not o in object.get(a.spec.syncPolicy, "syncOptions", [])
}

deny contains sprintf("%s: missing finalizer", [a.metadata.name]) if {
	some a in input.apps
	not "resources-finalizer.argocd.argoproj.io" in object.get(a.metadata, "finalizers", [])
}

deny contains sprintf("%s: baremetal namespace needs the privileged PSA label", [a.metadata.name]) if {
	input.cluster.provider == "baremetal"
	some a in input.apps
	a.metadata.name in privileged
	object.get(a.spec.syncPolicy, ["managedNamespaceMetadata", "labels", "pod-security.kubernetes.io/enforce"], "") != "privileged"
}

deny contains sprintf("%s: ServiceAccount %s has an IRSA role annotation; use Pod Identity", [name, d.metadata.name]) if {
	input.cluster.provider == "eks"
	some name, docs in input.charts
	some d in docs
	d.kind == "ServiceAccount"
	object.get(d.metadata, ["annotations", "eks.amazonaws.com/role-arn"], "") != ""
}

has_data(d) if {
	some k in {"data", "stringData"}
	is_object(d[k])
	count(d[k]) > 0
}

deny contains sprintf("the cluster/ chart renders Secret %s with inline data", [d.metadata.name]) if {
	some d in input.repo
	d.kind == "Secret"
	has_data(d)
}

ignored(a, r) if {
	some ig in object.get(a.spec, "ignoreDifferences", [])
	ig.kind == r.kind
	ig.name == r.name
}

# input.unstable lists resources that differ between two renders of the same chart
# (generated certs, keys, caBundles); unignored, the Application never reports Synced.
deny contains sprintf(
	"%s: %s %s changes on every render and needs ignoreDifferences, or the Application never reports Synced",
	[name, r.kind, r.name],
) if {
	some name, rs in object.get(input, "unstable", {})
	some r in rs
	not r.hook # Argo CD runs hooks but leaves them out of sync status.
	some a in input.apps
	a.metadata.name == name
	not ignored(a, r)
}

deny contains sprintf("%s: renders Gateway API CRD %s; only envoy-gateway may", [name, d.metadata.name]) if {
	some name, docs in input.charts
	name != "envoy-gateway"
	some d in docs
	d.kind == "CustomResourceDefinition"
	d.spec.group == "gateway.networking.k8s.io"
}

builtin_cluster_kinds := {
	"Namespace", "ClusterRole", "ClusterRoleBinding", "CustomResourceDefinition", "APIService",
	"MutatingWebhookConfiguration", "ValidatingWebhookConfiguration", "PriorityClass", "StorageClass",
	"PersistentVolume", "CSIDriver", "IngressClass", "RuntimeClass", "ValidatingAdmissionPolicy",
	"ValidatingAdmissionPolicyBinding", "PodSecurityPolicy",
}

crd_cluster_kinds contains [d.spec.group, d.spec.names.kind] if {
	some docs in input.charts
	some d in docs
	d.kind == "CustomResourceDefinition"
	d.spec.scope == "Cluster"
}

group_of(d) := g if {
	contains(d.apiVersion, "/")
	g := split(d.apiVersion, "/")[0]
} else := ""

cluster_scoped(d) if d.kind in builtin_cluster_kinds

cluster_scoped(d) if [group_of(d), d.kind] in crd_cluster_kinds

allowed_platform(d) if {
	some k in input.platformClusterKinds
	k.kind == d.kind
	k.group == group_of(d)
}

allowed_platform(d) if {
	some k in input.platformClusterKinds
	k.kind == d.kind
	k.group == "*"
}

deny contains sprintf("%s: platform AppProject does not allow cluster-scoped %s/%s", [name, group_of(d), d.kind]) if {
	some a in catalog_apps
	a.metadata.labels.layer == "platform"
	name := a.metadata.name
	some d in input.charts[name]
	cluster_scoped(d)
	not allowed_platform(d)
}

# Pod Security baseline (spec/security): host access only in privileged namespaces.
baseline_caps := {
	"AUDIT_WRITE", "CHOWN", "DAC_OVERRIDE", "FOWNER", "FSETID", "KILL", "MKNOD",
	"NET_BIND_SERVICE", "SETFCAP", "SETGID", "SETPCAP", "SETUID", "SYS_CHROOT",
}

pod_spec(d) := d.spec if d.kind == "Pod"

pod_spec(d) := d.spec.template.spec if d.kind in {"Deployment", "StatefulSet", "DaemonSet", "ReplicaSet", "Job"}

pod_spec(d) := d.spec.jobTemplate.spec.template.spec if d.kind == "CronJob"

containers(spec) := array.concat(object.get(spec, "initContainers", []), object.get(spec, "containers", []))

host_access(spec) := (({"privileged" |
	some c in containers(spec)
	c.securityContext.privileged
} | {f |
	some f in {"hostNetwork", "hostPID", "hostIPC"}
	spec[f]
}) | ({"hostPath" |
	some v in object.get(spec, "volumes", [])
	v.hostPath
} | {"hostPort" |
	some c in containers(spec)
	some p in object.get(c, "ports", [])
	p.hostPort
})) | {sprintf("capability %s", [cap]) |
	some c in containers(spec)
	some cap in object.get(c, ["securityContext", "capabilities", "add"], [])
	not cap in baseline_caps
}

deny contains sprintf("%s: %s %s uses %s in baseline namespace %s", [a.metadata.name, d.kind, d.metadata.name, h, ns]) if {
	some a in catalog_apps
	some d in input.charts[a.metadata.name]
	ns := object.get(d.metadata, "namespace", a.spec.destination.namespace)
	not ns in object.get(input, "privilegedNamespaces", [])
	some h in host_access(pod_spec(d))
}

# Every image is pinned by tag or digest, and never to `latest` (spec/security).
image_tag(image) := t if {
	not contains(image, "@")
	parts := split(image, "/")
	last := parts[count(parts) - 1]
	contains(last, ":")
	t := split(last, ":")[1]
}

unpinned(image) if {
	not contains(image, "@")
	not image_tag(image)
}

unpinned(image) if image_tag(image) == "latest"

deny contains sprintf("%s: %s %s uses unpinned image %s", [a.metadata.name, d.kind, d.metadata.name, c.image]) if {
	some a in catalog_apps
	some d in input.charts[a.metadata.name]
	some c in containers(pod_spec(d))
	unpinned(c.image)
}
