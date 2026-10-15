package values_test

import data.values

base_eks := {
	"clusterName": "a", "provider": "eks", "kubernetesVersion": "1.34",
	"apiServerHost": "x.eks.amazonaws.com", "apiServerPort": 443,
	"region": "us-west-2", "vpcId": "vpc-1",
	"secretRefs": {
		"onepasswordCredentials": "op://v/i/creds", "onepasswordToken": "op://v/i/token",
		"kargoAdminPasswordHash": "op://v/i/hash", "kargoTokenSigningKey": "op://v/i/key",
	},
}

base_bm := object.union(object.remove(base_eks, ["region", "vpcId"]), {
	"provider": "baremetal", "apiServerHost": "localhost", "apiServerPort": 7445,
	"lbIpPool": ["10.0.0.0/28"],
})

test_valid_eks_passes if count(values.deny) == 0 with data.catalog as catalog with input as base_eks

test_valid_baremetal_passes if count(values.deny) == 0 with data.catalog as catalog with input as base_bm

test_missing_provider_denied if {
	values.deny["missing required key: provider"] with data.catalog as catalog with input as object.remove(base_eks, ["provider"])
}

test_unknown_provider_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"provider": "gke"})
	contains(m, "provider")
}

test_eks_requires_region if {
	values.deny["missing required key: region"] with data.catalog as catalog with input as object.remove(base_eks, ["region"])
}

test_baremetal_requires_lb_pool if {
	values.deny["missing required key: lbIpPool"] with data.catalog as catalog with input as object.remove(base_bm, ["lbIpPool"])
}

test_unknown_key_denied if {
	values.deny["unknown key: color"] with data.catalog as catalog with input as object.union(base_eks, {"color": "red"})
}

test_secret_ref_must_be_op if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"secretRefs": object.union(base_eks.secretRefs, {"onepasswordToken": "hunter2"})})
	contains(m, "op://")
}

test_domain_on_baremetal_requires_cloudflare_ref if {
	values.deny["missing required key: secretRefs.cloudflareApiToken"] with data.catalog as catalog with input as object.union(base_bm, {"domain": "example.com", "disable": ["kubechecks"]})
}

test_domain_requires_github_ref_when_kubechecks_enabled if {
	values.deny["missing required key: secretRefs.githubToken"] with data.catalog as catalog with input as object.union(base_eks, {"domain": "example.com"})
}

test_kargo_refs_not_required_when_disabled if {
	inp := object.union(object.remove(base_eks, ["secretRefs"]), {
		"secretRefs": {"onepasswordCredentials": "op://v/i/c", "onepasswordToken": "op://v/i/t"},
		"disable": ["kargo"],
	})
	count(values.deny) == 0 with data.catalog as catalog with input as inp
}

test_disable_core_project_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"disable": ["cert-manager"]})
	contains(m, "cert-manager")
}

test_disable_longhorn_allowed if count(values.deny) == 0 with data.catalog as catalog with input as object.union(base_bm, {"disable": ["longhorn"]})

test_disable_unknown_name_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"disable": ["nope"]})
	contains(m, "nope")
}

test_both_storage_disabled_requires_default_sc if {
	values.deny["missing required key: defaultStorageClass"] with data.catalog as catalog with input as object.union(base_bm, {"disable": ["longhorn", "local-path-provisioner"]})
}

test_default_sc_with_longhorn_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_bm, {"defaultStorageClass": "nfs"})
	contains(m, "defaultStorageClass")
}

test_default_sc_on_eks_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"defaultStorageClass": "gp2"})
	contains(m, "defaultStorageClass")
}

test_byo_storage_passes if {
	count(values.deny) == 0 with data.catalog as catalog with input as object.union(base_bm, {"disable": ["longhorn", "local-path-provisioner"], "defaultStorageClass": "nfs"})
}

test_wrong_type_denied if {
	some m in values.deny with data.catalog as catalog with input as object.union(base_eks, {"apiServerPort": "443"})
	contains(m, "apiServerPort")
}

catalog := [
	{"name": "kargo", "layer": "platform", "optional": true}, {"name": "kubechecks", "layer": "platform", "optional": true},
	{"name": "kubevirt", "layer": "platform", "optional": true}, {"name": "cert-manager", "layer": "core"},
	{"name": "longhorn", "layer": "core", "optional": true}, {"name": "local-path-provisioner", "layer": "core", "optional": true},
]

optin_catalog := array.concat(catalog, [{"name": "zot", "layer": "core", "optIn": true, "providers": ["baremetal"]}])

test_enable_opt_in_component_passes if {
	count(values.deny) == 0 with data.catalog as optin_catalog with input as object.union(base_bm, {"enable": ["zot"], "pullThroughCacheIp": "10.0.0.5"})
}

test_enable_non_opt_in_component_denied if {
	some m in values.deny with data.catalog as optin_catalog with input as object.union(base_bm, {"enable": ["kargo"]})
	contains(m, "kargo")
}

test_disable_opt_in_component_denied if {
	some m in values.deny with data.catalog as optin_catalog with input as object.union(base_bm, {"disable": ["zot"]})
	contains(m, "zot")
}

test_zot_requires_cache_ip if {
	values.deny["missing required key: pullThroughCacheIp"] with data.catalog as optin_catalog with input as object.union(base_bm, {"enable": ["zot"]})
}

test_cache_ip_without_zot_denied if {
	some m in values.deny with data.catalog as optin_catalog with input as object.union(base_bm, {"pullThroughCacheIp": "10.0.0.5"})
	contains(m, "pullThroughCacheIp")
}

test_zot_on_eks_denied if {
	some m in values.deny with data.catalog as optin_catalog with input as object.union(base_eks, {"enable": ["zot"], "pullThroughCacheIp": "10.0.0.5"})
	contains(m, "ECR")
}

base_doks := object.union(object.remove(base_eks, ["region", "vpcId", "apiServerHost", "apiServerPort"]), {"provider": "doks"})

agent_catalog := array.concat(catalog, [
	{"name": "argocd-agent", "layer": "core", "optIn": true, "providers": ["eks", "baremetal", "doks"]},
	{"name": "argocd-agent-principal", "layer": "core", "optIn": true, "providers": ["eks", "baremetal", "doks"]},
])

agent_refs := {
	"argocdAgentCa": "op://v/agent/ca", "argocdAgentCert": "op://v/agent/cert",
	"argocdAgentKey": "op://v/agent/key",
}

test_valid_doks_passes if count(values.deny) == 0 with data.catalog as catalog with input as base_doks

test_eks_still_requires_api_server if {
	values.deny["missing required key: apiServerHost"] with data.catalog as catalog with input as object.remove(base_eks, ["apiServerHost"])
}

test_doks_domain_requires_digitalocean_token if {
	values.deny["missing required key: secretRefs.digitaloceanToken"] with data.catalog as catalog with input as object.union(base_doks, {"domain": "do.example.com", "disable": ["kubechecks"]})
}

test_agent_requires_principal_and_refs if {
	inp := object.union(base_eks, {"enable": ["argocd-agent"]})
	values.deny["missing required key: argocdAgent"] with data.catalog as agent_catalog with input as inp
	values.deny["missing required key: secretRefs.argocdAgentCert"] with data.catalog as agent_catalog with input as inp
}

test_agent_with_principal_and_refs_passes if {
	inp := object.union(base_eks, {
		"enable": ["argocd-agent"],
		"argocdAgent": {"principalAddress": "agent.hub.example.com", "principalPort": 443},
		"secretRefs": object.union(base_eks.secretRefs, agent_refs),
	})
	count(values.deny) == 0 with data.catalog as agent_catalog with input as inp
}

test_principal_requires_jwt_key if {
	inp := object.union(base_eks, {"enable": ["argocd-agent-principal"], "secretRefs": object.union(base_eks.secretRefs, agent_refs)})
	values.deny["missing required key: secretRefs.argocdAgentJwtKey"] with data.catalog as agent_catalog with input as inp
}

test_agent_settings_without_agent_denied if {
	inp := object.union(base_eks, {"argocdAgent": {"principalAddress": "x", "principalPort": 443}})
	some m in values.deny with data.catalog as agent_catalog with input as inp
	contains(m, "argocdAgent")
}

rook_catalog := array.concat(catalog, [{"name": "rook", "layer": "core", "optIn": true, "providers": ["baremetal"]}])

rook_bm := object.union(base_bm, {"enable": ["rook"], "disable": ["longhorn"]})

test_rook_with_longhorn_disabled_passes if count(values.deny) == 0 with data.catalog as rook_catalog with input as rook_bm

test_rook_requires_longhorn_disabled if {
	some m in values.deny with data.catalog as rook_catalog with input as object.union(base_bm, {"enable": ["rook"]})
	contains(m, "longhorn")
}

test_rook_needs_no_default_sc if {
	count(values.deny) == 0 with data.catalog as rook_catalog with input as object.union(rook_bm, {"disable": ["longhorn", "local-path-provisioner"]})
}

test_default_sc_with_rook_denied if {
	some m in values.deny with data.catalog as rook_catalog with input as object.union(rook_bm, {"disable": ["longhorn", "local-path-provisioner"], "defaultStorageClass": "nfs"})
	contains(m, "defaultStorageClass")
}

test_rook_on_eks_has_no_effect if count(values.deny) == 0 with data.catalog as rook_catalog with input as object.union(base_eks, {"enable": ["rook"]})

id_catalog := array.concat(catalog, [
	{"name": "authentik", "layer": "platform", "optIn": true}, {"name": "keycloak", "layer": "platform", "optIn": true},
	{"name": "oauth2-proxy", "layer": "platform", "optIn": true},
])

id_refs := object.union(base_eks.secretRefs, {
	"authentikSecretKey": "op://v/a/k", "authentikPostgresPassword": "op://v/a/p",
	"keycloakAdminPassword": "op://v/k/a", "keycloakPostgresPassword": "op://v/k/p",
	"oauth2ProxyClientId": "op://v/o/i", "oauth2ProxyClientSecret": "op://v/o/s", "oauth2ProxyCookieSecret": "op://v/o/c",
})

id_eks := object.union(base_eks, {
	"enable": ["authentik", "keycloak", "oauth2-proxy"], "secretRefs": id_refs,
	"authentik": {"postgresHost": "db"}, "keycloak": {"postgresHost": "db", "postgresPort": 25060},
	"oauth2Proxy": {"issuerUrl": "https://auth.example.com/"},
})

test_identity_add_ons_pass if count(values.deny) == 0 with data.catalog as id_catalog with input as id_eks

test_identity_needs_its_settings if {
	d := values.deny with data.catalog as id_catalog with input as object.remove(id_eks, ["authentik", "keycloak", "oauth2Proxy"])
	d["missing required key: authentik"]
	d["missing required key: keycloak"]
	d["missing required key: oauth2Proxy"]
}

test_identity_needs_its_secrets if {
	d := values.deny with data.catalog as id_catalog with input as object.union(object.remove(id_eks, ["secretRefs"]), {"secretRefs": base_eks.secretRefs})
	d["missing required key: secretRefs.authentikPostgresPassword"]
	d["missing required key: secretRefs.keycloakAdminPassword"]
	d["missing required key: secretRefs.oauth2ProxyCookieSecret"]
}

test_identity_settings_without_enable_denied if {
	d := values.deny with data.catalog as id_catalog with input as object.union(id_eks, {"enable": []})
	some m in d
	contains(m, "authentik is only allowed")
}

test_identity_settings_shape_checked if {
	d := values.deny with data.catalog as id_catalog with input as object.union(object.remove(id_eks, ["keycloak", "oauth2Proxy"]), {"keycloak": {"postgresPort": "5432"}, "oauth2Proxy": {}})
	some k in d
	contains(k, "keycloak needs")
	some o in d
	contains(o, "oauth2Proxy needs")
}
