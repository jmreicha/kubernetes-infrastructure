load common.bats

setup() {
    load 'common.bats'
    _config
}
@test "verify 'monitoring' install dry-run works" {
    skip
    run kubectl apply -f monitoring --dry-run=server
    [ "$status" -eq 0 ]
}
