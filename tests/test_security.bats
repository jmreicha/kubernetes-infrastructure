load common.bats

setup() {
    load 'common.bats'
    _config
}

@test "verify 'security' install dry-run works" {
    run kubectl apply -f security --dry-run=server
    [ "$status" -eq 0 ]
}
