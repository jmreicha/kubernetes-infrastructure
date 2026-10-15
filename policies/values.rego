# Validates clusters/<name>.yaml (spec/values ClusterValues).
# Catalog names come from data.catalog (cluster/values.yaml).
package values

allowed_providers := {"eks", "baremetal", "doks"}

secret_keys := {
	"onepasswordCredentials", "onepasswordToken", "kargoAdminPasswordHash",
	"kargoTokenSigningKey", "cloudflareApiToken", "githubToken", "digitaloceanToken",
	"argocdAgentCa", "argocdAgentCert", "argocdAgentKey", "argocdAgentJwtKey",
	"authentikSecretKey", "authentikPostgresPassword", "keycloakAdminPassword", "keycloakPostgresPassword",
	"oauth2ProxyClientId", "oauth2ProxyClientSecret", "oauth2ProxyCookieSecret", "democraticCsiConfig",
}

allowed_keys := {
	"clusterName", "provider", "kubernetesVersion", "apiServerHost", "apiServerPort",
	"domain", "region", "vpcId", "lbIpPool", "coreOnly", "disable", "enable", "defaultStorageClass", "secretRefs",
	"pullThroughCacheIp", "argocdAgent", "authentik", "keycloak", "oauth2Proxy", "nfs", "democraticCsi",
}

types := {
	"clusterName": "string", "provider": "string", "kubernetesVersion": "string",
	"apiServerHost": "string", "apiServerPort": "number", "domain": "string",
	"region": "string", "vpcId": "string", "lbIpPool": "array", "coreOnly": "boolean",
	"disable": "array", "enable": "array", "defaultStorageClass": "string", "secretRefs": "object",
	"pullThroughCacheIp": "string", "argocdAgent": "object",
	"authentik": "object", "keycloak": "object", "oauth2Proxy": "object", "nfs": "object", "democraticCsi": "object",
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

# Each identity add-on's settings key, keyed by catalog name.
identity := {"authentik": "authentik", "keycloak": "keycloak", "oauth2-proxy": "oauth2Proxy"}

required contains k if {
	some name, k in identity
	name in enabled_opt_ins
}

# Each baremetal CSI driver's settings key, keyed by catalog name.
csi := {"csi-driver-nfs": "nfs", "democratic-csi": "democraticCsi"}

required contains k if {
	input.provider == "baremetal"
	some name, k in csi
	name in enabled_opt_ins
}

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

identity_refs := {
	"authentik": {"authentikSecretKey", "authentikPostgresPassword"},
	"keycloak": {"keycloakAdminPassword", "keycloakPostgresPassword"},
	"oauth2-proxy": {"oauth2ProxyClientId", "oauth2ProxyClientSecret", "oauth2ProxyCookieSecret"},
}

required_refs contains k if {
	some name, refs in identity_refs
	name in enabled_opt_ins
	some k in refs
}

required_refs contains "democraticCsiConfig" if {
	input.provider == "baremetal"
	"democratic-csi" in enabled_opt_ins
}

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

deny contains sprintf("%s is only allowed when %s is enabled", [k, name]) if {
	some name, k in identity
	k in object.keys(input)
	not name in enabled_opt_ins
}

deny contains sprintf("%s needs postgresHost (string) and optionally postgresPort (number)", [k]) if {
	some k in {"authentik", "keycloak"}
	k in enabled_opt_ins
	not valid_postgres(object.get(input, k, {}))
}

valid_postgres(p) if {
	is_string(p.postgresHost)
	is_number(object.get(p, "postgresPort", 5432))
}

deny contains "oauth2Proxy needs issuerUrl (string)" if {
	"oauth2-proxy" in enabled_opt_ins
	not valid_proxy(object.get(input, "oauth2Proxy", {}))
}

valid_proxy(p) if is_string(p.issuerUrl)

deny contains sprintf("%s is only allowed when %s is enabled", [k, name]) if {
	some name, k in csi
	k in object.keys(input)
	not name in enabled_opt_ins
}

deny contains "nfs needs server and share (strings)" if {
	"nfs" in required
	not valid_nfs(object.get(input, "nfs", {}))
}

valid_nfs(n) if {
	is_string(n.server)
	is_string(n.share)
}

deny contains "democraticCsi needs driver (string), such as freenas-api-iscsi" if {
	"democraticCsi" in required
	not valid_democratic(object.get(input, "democraticCsi", {}))
}

valid_democratic(d) if is_string(d.driver)
