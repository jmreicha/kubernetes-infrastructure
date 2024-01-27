load common.bats

setup() {
    load 'common.bats'
    _config
}

teardown_file() {
    kubectl delete -f bootstrap
}

@test "verify bats works" {
    run false
    assert_success
}

@test "verify cluster connectivity works" {
    run kubectl get pods -A
    assert_success
}

@test "verify argocd app projects are created" {
    run kubectl apply -f bootstrap
    assert_success

    run kubectl get appprojects -A
    assert_success
}

@test "verify system appproject is created" {
    run kubectl get appprojects system -n argocd
    assert_success
}

@test "verify monitoring appproject is created" {
    run kubectl get appprojects system -n argocd
    assert_success
}

@test "verify network appproject is created" {
    run kubectl get appprojects system -n argocd
    assert_success
}

@test "verify security appproject is created" {
    run kubectl get appprojects system -n argocd
    assert_success
}

@test "verify argocd-application-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-application-controller' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-applicationset-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-applicationset-controller' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-dex-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-dex-server' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-notifications-controller is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-notifications-controller' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-redis is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-redis' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-repo-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-repo-server' and verify that 'status' is 'running'"
    assert_success
}

@test "verify argocd-server is running" {
    run try "at most 3 times every 10s to get pods named 'argocd-server' and verify that 'status' is 'running'"
    assert_success
}
