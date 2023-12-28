#!/usr/bin/env bats

setup() {
    if [[ $CI == true ]]; then
        TEST_PREFIX="/usr/lib"
    else
        TEST_PREFIX="$(brew --prefix)/lib"
    fi

    load "${TEST_PREFIX}/bats-assert/load.bash"
    load "${TEST_PREFIX}/bats-detik/detik.bash"
    load "${TEST_PREFIX}/bats-file/load.bash"
    load "${TEST_PREFIX}/bats-support/load.bash"
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAME="kubectl"
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAMESPACE="argocd"
}

@test "verify bats works" {
    run true
    [ "$status" -eq 0 ]
}

@test "verify cluster connectivity works" {
    run kubectl get pods -A
    [ "$status" -eq 0 ]
}

@test "verify argocd-application-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-application-controller' and verify that 'status' is 'running'"
	[ "$status" -eq 0 ]
}

@test "verify argocd-applicationset-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-applicationset-controller' and verify that 'status' is 'running'"
	[ "$status" -eq 0 ]
}

@test "verify argocd-dex-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-dex-server' and verify that 'status' is 'running'"
    [ "$status" -eq 0 ]
}

@test "verify argocd-notifications-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-notifications-controller' and verify that 'status' is 'running'"
    [ "$status" -eq 0 ]
}

@test "verify argocd-redis is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-redis' and verify that 'status' is 'running'"
    [ "$status" -eq 0 ]
}

@test "verify argocd-repo-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-repo-server' and verify that 'status' is 'running'"
    [ "$status" -eq 0 ]
}

@test "verify argocd-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-server' and verify that 'status' is 'running'"
    [ "$status" -eq 0 ]
}

@test "verify 'monitoring' install dry-run works" {
    run kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}

@test "verify 'network' install dry-run works" {
    run kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}

@test "verify 'security' install dry-run works" {
    run kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}
