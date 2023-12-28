#!/usr/bin/env bats

setup() {
    TEST_PREFIX="/usr/lib"
    load "${TEST_PREFIX}/bats-support/load.bash"
    load "${TEST_PREFIX}/bats-assert/load.bash"
    load "${TEST_PREFIX}/bats-file/load.bash"
    load "${TEST_PREFIX}/bats-detik/detik.bash"
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAME="kubectl"
}

@test "verify install dry run works" {
    run kubectl apply -f infrastructure --dry-run=server
    [ "$status" -eq 0 ]
}
