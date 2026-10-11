package risk_test

import data.risk

crd(versions) := {"renderedBy": "a", "kind": "CustomResourceDefinition", "metadata": {"name": "widgets.example.com"}, "spec": {"versions": [{"name": v, "served": true} | some v in versions]}}

pvc := {"renderedBy": "a", "kind": "PersistentVolumeClaim", "metadata": {"name": "data", "namespace": "a"}, "spec": {"resources": {"requests": {"storage": "1Gi"}}}}

sts(size) := {"renderedBy": "a", "kind": "StatefulSet", "metadata": {"name": "db", "namespace": "a"}, "spec": {"volumeClaimTemplates": [{"metadata": {"name": "d"}, "spec": {"resources": {"requests": {"storage": size}}}}]}}

sc(param) := {"renderedBy": "a", "kind": "StorageClass", "metadata": {"name": "fast"}, "parameters": {"type": param}}

app(ns) := {"renderedBy": "root", "kind": "Application", "metadata": {"name": "a"}, "spec": {"destination": {"namespace": ns}}}

cm(v) := {"renderedBy": "a", "kind": "ConfigMap", "metadata": {"name": "c", "namespace": "a"}, "data": {"k": v}}

test_no_change_passes if {
	count(risk.deny) == 0 with input as {"base": [pvc, crd(["v1"])], "head": [pvc, crd(["v1"])]}
}

test_crd_deleted_fails if {
	some m in risk.deny with input as {"base": [crd(["v1"])], "head": []}
	contains(m, "CustomResourceDefinition")
}

test_crd_served_version_dropped_fails if {
	some m in risk.deny with input as {"base": [crd(["v1", "v1beta1"])], "head": [crd(["v1"])]}
	contains(m, "v1beta1")
}

test_crd_version_added_passes if {
	count(risk.deny) == 0 with input as {"base": [crd(["v1"])], "head": [crd(["v1", "v2"])]}
}

test_pvc_deleted_fails if {
	some m in risk.deny with input as {"base": [pvc], "head": []}
	contains(m, "PersistentVolumeClaim")
}

test_volume_claim_templates_changed_fails if {
	some m in risk.deny with input as {"base": [sts("1Gi")], "head": [sts("2Gi")]}
	contains(m, "volumeClaimTemplates")
}

test_storage_class_changed_fails if {
	some m in risk.deny with input as {"base": [sc("gp2")], "head": [sc("gp3")]}
	contains(m, "StorageClass")
}

test_destination_namespace_changed_fails if {
	some m in risk.deny with input as {"base": [app("a")], "head": [app("b")]}
	contains(m, "destination namespace")
}

test_other_deletion_warns_only if {
	inp := {"base": [cm("x")], "head": []}
	count(risk.deny) == 0 with input as inp
	some m in risk.warn with input as inp
	contains(m, "ConfigMap")
}

test_appproject_change_warns if {
	p := {"renderedBy": "root", "kind": "AppProject", "metadata": {"name": "core"}, "spec": {"sourceRepos": ["*"]}}
	q := json.patch(p, [{"op": "replace", "path": "/spec/sourceRepos", "value": ["x"]}])
	some m in risk.warn with input as {"base": [p], "head": [q]}
	contains(m, "AppProject")
}

test_webhook_change_warns if {
	w := {"renderedBy": "a", "kind": "ValidatingWebhookConfiguration", "metadata": {"name": "v"}, "webhooks": [{"name": "a"}]}
	x := json.patch(w, [{"op": "replace", "path": "/webhooks/0/name", "value": "b"}])
	some m in risk.warn with input as {"base": [w], "head": [x]}
	contains(m, "ValidatingWebhookConfiguration")
}

test_plain_change_is_silent if {
	inp := {"base": [cm("x")], "head": [cm("y")]}
	count(risk.deny) == 0 with input as inp
	count(risk.warn) == 0 with input as inp
}
