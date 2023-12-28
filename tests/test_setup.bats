#!/usr/bin/env bats

setup() {
    TEST_PREFIX="/usr/lib"
    load "${TEST_PREFIX}/bats-assert/load.bash"
    load "${TEST_PREFIX}/bats-detik/detik.bash"
    load "${TEST_PREFIX}/bats-file/load.bash"
    load "${TEST_PREFIX}/bats-support/load.bash"
    # shellcheck disable=SC2034
    DETIK_CLIENT_NAME="kubectl"
}

@test "verify bats works" {
    run true
    [ "$status" -eq 0 ]
}

@test "verify cluster connectivity works" {
    run kubectl get pods -A
    [ "$status" -eq 0 ]
}

# @test "verify install dry run works" {
#     run kubectl apply -f infrastructure --dry-run=server
#     [ "$status" -eq 0 ]
# }
