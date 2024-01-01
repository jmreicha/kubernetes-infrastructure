load common.bats

setup() {
    load 'common.bats'
    _config
}

# TODO: Fix this test
@test "verify 'monitoring' install dry-run works" {
    skip
    run kubectl apply -f monitoring --dry-run=server
    assert_success
}
