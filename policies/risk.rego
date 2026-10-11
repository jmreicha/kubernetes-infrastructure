# Classifies changes between the base and head renders (spec/verification Verification.Risk).
# input: {base: [doc], head: [doc]}, each doc tagged with `renderedBy`, the Application that renders it.
package risk

key(d) := sprintf("%s/%s/%s/%s", [d.renderedBy, d.kind, object.get(d.metadata, "namespace", ""), d.metadata.name])

base[key(d)] := d if some d in input.base

head[key(d)] := d if some d in input.head

removed contains k if {
	some k, _ in base
	not head[k]
}

changed contains k if {
	some k, d in base
	head[k]
	head[k] != d
}

deny contains sprintf("deletes %s", [k]) if {
	some k in removed
	base[k].kind in {"CustomResourceDefinition", "PersistentVolumeClaim", "StorageClass"}
}

served(d) := {v.name |
	some v in d.spec.versions
	v.served
}

deny contains sprintf("%s drops served version %s", [k, v]) if {
	some k in changed
	base[k].kind == "CustomResourceDefinition"
	some v in (served(base[k]) - served(head[k]))
}

deny contains sprintf("%s changes volumeClaimTemplates", [k]) if {
	some k in changed
	base[k].kind == "StatefulSet"
	object.get(base[k].spec, "volumeClaimTemplates", []) != object.get(head[k].spec, "volumeClaimTemplates", [])
}

deny contains sprintf("%s changes a StorageClass", [k]) if {
	some k in changed
	base[k].kind == "StorageClass"
}

deny contains sprintf(
	"%s changes its destination namespace from %s to %s",
	[k, base[k].spec.destination.namespace, head[k].spec.destination.namespace],
) if {
	some k in changed
	base[k].kind == "Application"
	base[k].spec.destination.namespace != head[k].spec.destination.namespace
}

warn contains sprintf("deletes %s", [k]) if {
	some k in removed
	not base[k].kind in {"CustomResourceDefinition", "PersistentVolumeClaim", "StorageClass"}
}

warn contains sprintf("changes %s", [k]) if {
	some k in changed
	base[k].kind in {"AppProject", "MutatingWebhookConfiguration", "ValidatingWebhookConfiguration"}
}
