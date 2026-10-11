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
