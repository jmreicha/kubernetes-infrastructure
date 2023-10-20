# Kubernetes Infrastructure

Declarative infrastructure for Kubernetes. These configs should be deployed as
part of every cluster deployment. This set of configs assumes deployment to AWS.

Generic infrastructure included:

- [x] Argo events
- [x] Argo image updater
- [x] Argo rollouts
- [x] Argo workflows
- [x] Cert manager
- [x] External secrets
- [x] Gatekeeper
- [x] Kube Prometheus
- [x] Nginx Ingress
- [x] Reloader
- [x] Velero

## Getting started

To bootstrap the configurations, we first need to install ArgoCD. You can do
this with a local Kubernetes cluster to test.

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

Bootstrap the ArgoCD infrastructure project. This is needs to exist first for
the infra charts to be deployed into.

```bash
kubectl apply -f bootstrap/project.yaml
```

Deploy the rest of the infrastructure pieces.

```bash
kubectl apply -f infrastructure
```

TODO: Alternatively, deploy everything with `argocd`.

TODO: Tests for renovate version update automerges. Run a k3s cluster and make sure all the manifests deploy correctly?
