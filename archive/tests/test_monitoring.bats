load common.bats

setup() {
    load 'common.bats'
    _config
}

@test "verify 'monitoring' install dry-run works" {
    run kubectl apply -f monitoring --dry-run=server
    assert_success
}
