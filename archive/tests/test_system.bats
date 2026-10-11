load common.bats

setup() {
    load 'common.bats'
    _config
}

@test "verify 'system' install dry-run works" {
    run kubectl apply -f system --dry-run=server
    assert_success
}

@test "verify the argo custom resources were deployed" {
    skip
    kubectl get applications.argoproj.io k8up -n argocd -o jsonpath='{.status.health.status}'
}
