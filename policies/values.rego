# Validates clusters/<name>.yaml (spec/values ClusterValues).
# Catalog names come from data.catalog (cluster/values.yaml).
package values

allowed_providers := {"eks", "baremetal", "doks"}

secret_keys := {
	"onepasswordCredentials", "onepasswordToken", "kargoAdminPasswordHash",
	"kargoTokenSigningKey", "cloudflareApiToken", "githubToken", "digitaloceanToken",
	"argocdAgentCa", "argocdAgentCert", "argocdAgentKey", "argocdAgentJwtKey",
}

allowed_keys := {
	"clusterName", "provider", "kubernetesVersion", "apiServerHost", "apiServerPort",
	"domain", "region", "vpcId", "lbIpPool", "coreOnly", "disable", "enable", "defaultStorageClass", "secretRefs",
	"pullThroughCacheIp", "argocdAgent",
}

types := {
	"clusterName": "string", "provider": "string", "kubernetesVersion": "string",
	"apiServerHost": "string", "apiServerPort": "number", "domain": "string",
	"region": "string", "vpcId": "string", "lbIpPool": "array", "coreOnly": "boolean",
	"disable": "array", "enable": "array", "defaultStorageClass": "string", "secretRefs": "object",
	"pullThroughCacheIp": "string", "argocdAgent": "object",
}

disabled := {d | some d in object.get(input, "disable", [])}

enabled(name) if not name in disabled

has_domain if input.domain

# Catalog entries marked optional are on unless disabled; optIn entries are off unless enabled.
disableable contains e.name if {
	some e in data.catalog
	e.optional
}

enableable contains e.name if {
	some e in data.catalog
	e.optIn
}

enabled_opt_ins := {e | some e in object.get(input, "enable", [])}

required contains k if some k in {"clusterName", "provider", "kubernetesVersion"}

# Only Cilium uses the API server address, and DOKS manages its own Cilium.
required contains k if {
	input.provider in {"eks", "baremetal"}
	some k in {"apiServerHost", "apiServerPort"}
}

required contains "argocdAgent" if "argocd-agent" in enabled_opt_ins

required contains "region" if input.provider == "eks"

required contains "vpcId" if input.provider == "eks"

required contains "lbIpPool" if input.provider == "baremetal"

required contains "pullThroughCacheIp" if "zot" in enabled_opt_ins

required contains "defaultStorageClass" if {
	input.provider == "baremetal"
	not "rook" in enabled_opt_ins
	{"longhorn", "local-path-provisioner"} & disabled == {"longhorn", "local-path-provisioner"}
}

required_refs contains k if some k in {"onepasswordCredentials", "onepasswordToken"}

required_refs contains k if {
	enabled("kargo")
	some k in {"kargoAdminPasswordHash", "kargoTokenSigningKey"}
}

required_refs contains "cloudflareApiToken" if {
	has_domain
	input.provider == "baremetal"
}

required_refs contains "digitaloceanToken" if {
	has_domain
	input.provider == "doks"
}

required_refs contains k if {
	some role in {"argocd-agent", "argocd-agent-principal"}
	role in enabled_opt_ins
	some k in {"argocdAgentCa", "argocdAgentCert", "argocdAgentKey"}
}

required_refs contains "argocdAgentJwtKey" if "argocd-agent-principal" in enabled_opt_ins

required_refs contains "githubToken" if {
	has_domain
	enabled("kubechecks")
}

deny contains sprintf("missing required key: %s", [k]) if {
	some k in required
	not k in object.keys(input)
}

deny contains sprintf("missing required key: secretRefs.%s", [k]) if {
	some k in required_refs
	not k in object.keys(object.get(input, "secretRefs", {}))
}

deny contains sprintf("unknown key: %s", [k]) if {
	some k in object.keys(input)
	not k in allowed_keys
}

deny contains sprintf("unknown key: secretRefs.%s", [k]) if {
	some k in object.keys(object.get(input, "secretRefs", {}))
	not k in secret_keys
}

deny contains sprintf("wrong type for %s: expected %s", [k, t]) if {
	some k, v in input
	t := types[k]
	type_name(v) != t
}

deny contains sprintf("provider must be one of %v, got %v", [allowed_providers, input.provider]) if {
	"provider" in object.keys(input)
	not input.provider in allowed_providers
}

deny contains sprintf("secretRefs.%s must be an op:// reference", [k]) if {
	some k, v in object.get(input, "secretRefs", {})
	not startswith(v, "op://")
}

deny contains sprintf("disable: %s cannot be disabled; allowed: %v", [d, sort(disableable)]) if {
	some d in disabled
	not d in disableable
}

deny contains "defaultStorageClass is only allowed on baremetal without longhorn, local-path-provisioner, or rook" if {
	input.defaultStorageClass
	not "defaultStorageClass" in required
}

deny contains sprintf("enable: %s is not opt-in; allowed: %v", [e, sort(enableable)]) if {
	some e in enabled_opt_ins
	not e in enableable
}

deny contains "rook replaces longhorn as the default StorageClass; add longhorn to disable" if {
	input.provider == "baremetal"
	"rook" in enabled_opt_ins
	enabled("longhorn")
}

deny contains "pullThroughCacheIp is only allowed when zot is enabled" if {
	input.pullThroughCacheIp
	not "zot" in enabled_opt_ins
}

deny contains "zot runs on baremetal only; on eks, use an ECR pull-through cache configured outside the cluster" if {
	"zot" in enabled_opt_ins
	input.provider == "eks"
}

deny contains "argocdAgent is only allowed when argocd-agent is enabled" if {
	input.argocdAgent
	not "argocd-agent" in enabled_opt_ins
}

deny contains "argocdAgent needs principalAddress (string) and principalPort (number)" if {
	"argocd-agent" in enabled_opt_ins
	a := object.get(input, "argocdAgent", {})
	not valid_agent(a)
}

valid_agent(a) if {
	is_string(a.principalAddress)
	is_number(a.principalPort)
}
