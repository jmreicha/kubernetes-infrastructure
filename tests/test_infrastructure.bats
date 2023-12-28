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

@test "verify 'infrastructure' install dry-run works" {
    run kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}

@test "verify the argo custom resources were deployed" {
    skip
    kubectl get applications.argoproj.io k8up -n argocd -o jsonpath='{.status.health.status}'
}
