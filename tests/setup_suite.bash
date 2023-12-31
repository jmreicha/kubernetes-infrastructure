#!/usr/bin/env bats

# Common setup and configuration for all tests

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
