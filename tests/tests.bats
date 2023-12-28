#!/usr/bin/env bats

setup() {
	cd tests || true
    TEST_BREW_PREFIX="$(brew --prefix)"
    load "${TEST_BREW_PREFIX}/lib/bats-support/load.bash"
    load "${TEST_BREW_PREFIX}/lib/bats-assert/load.bash"
    load "${TEST_BREW_PREFIX}/lib/bats-file/load.bash"
    load "${TEST_BREW_PREFIX}/lib/bats-detik/detik.bash"
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAME="kubectl"
}

@test "verify install dry run works" {
    kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}

@test "verify the argocd resources were deployed" {
    skip
}

@test "verify argcocd components are working" {
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAMESPACE="argocd"

	run verify "there is 1 pod named 'argocd-application-controller'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-applicationset-controller'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-dex-server'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-notifications-controller'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-redis'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-repo-server'"
	[ "$status" -eq 0 ]

	run verify "there is 1 pod named 'argocd-server'"
	[ "$status" -eq 0 ]
}

@test "verify infrastructure resources" {
	# PODs
	run verify "there is 1 pod named 'my-test-drupal'"
	[ "$status" -eq 0 ]

	run verify "'.subsets[*].ports[*].port' is '44320' for endpoints named 'my-test-postgres'"
	[ "$status" -eq 0 ]

	# Services
	run verify "there is 1 service named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	run verify "'port' is '80' for services named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	# Deployments
	run verify "there is 1 deployment named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	# Ingress
	run verify "there is 1 ingress named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	run verify "'.spec.rules[*].host' is 'varnish.test.local' for ingress named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	run verify "'.spec.rules[*].http.paths[*].backend.serviceName' is 'my-test-varnish' for ingress named 'my-test-varnish'"
	[ "$status" -eq 0 ]

	# PODs should be running
	run try "at most 5 times every 30s to get pods named 'my-test-varnish' and verify that 'status' is 'running'"
	[ "$status" -eq 0 ]
}


@test "verify monitoring resources" {
    skip
}

@test "verify network resources" {
    skip
}
@test "verify security resources" {
    skip
}

@test "verify resources properly labeled" {
    skip
}

@test "verify resources get properly removed" {
    skip
}
