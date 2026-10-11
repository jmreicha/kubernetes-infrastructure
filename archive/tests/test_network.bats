load common.bats

setup() {
    load 'common.bats'
    _config
}

@test "verify 'network' install dry-run works" {
    run kubectl apply -f network --dry-run=server
    assert_success
}
