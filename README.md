# Kubernetes Infrastructure

Declarative infrastructure for Kubernetes. These configs should be deployed as
part of every cluster deployment. The configs are split into different parts:

- bootstrap: bootstrap the required ArgoCD configs.
- infrastructure: core infrastructure pieces that should be deployed into every cluster.
- monitoring: monitoring configuration for the cluster.
- network: network configuration for the cluster.
- security: security configuration for the cluster.

> [!NOTE]
> These configs assume deployment with ArgoCD.

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
```

Deploy the rest of the infrastructure pieces.

```bash
kubectl apply -f infrastructure
kubectl apply -f monitoring
kubectl apply -f network
kubectl apply -f security
```

## TODO

- [ ] Add labels for the resource type.
- [ ] Update project names.
- [ ] Tests for renovate version update automerges. Run a k3s cluster and make sure all the manifests deploy correctly?
- [ ] Pull Request previews. Create and comment a diff on a PR with the changes.
- [ ] Pull Request test. Figure out what tests to run for changes.
