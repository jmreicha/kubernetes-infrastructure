# Kubernetes Infrastructure

Declarative (and slightly opinionated) infrastructure for Kubernetes. This set
of resources intends to provide a batteries-included set of self-updating
infrastructure that can be used for configuring and securing Kubernetes clusters
according to best practices.

The configs are split into different parts, which can be deployed separately:

- bootstrap: required ArgoCD configs for configuration.
- system: core system infrastructure to be deployed into every cluster.
- monitoring: monitoring configuration for the cluster.
- network: network configuration for the cluster.
- security: security configuration for the cluster.

> [!NOTE]
> These configs all assume deployment with ArgoCD.

## Bootstrap configs with ArgoCD

To bootstrap and deploy the configurations, we first need to install ArgoCD. You
can do this with a local Kubernetes cluster to test.

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Grab the admin password and log in.

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
kubectl port-forward svc/argocd-server -n argocd 8080:443
argocd login localhost:8080
```

Bootstrap the ArgoCD infrastructure project. This needs to exist first for
the infra charts to be deployed.

```bash
kubectl apply -f bootstrap/project.yaml
kubectl get appprojects -A
```

Deploy the rest of the infrastructure pieces.

```bash
kubectl apply -f system
kubectl apply -f monitoring
kubectl apply -f network
kubectl apply -f security
```

You can run `bats tests` from the root of the repo to run all tests.

## TODO

- [ ] More tests for PRs.
- [ ] Look into how hard it would be to automate/template out new applications.
- [ ] Bootstrap Argo to be managed with Argo.
