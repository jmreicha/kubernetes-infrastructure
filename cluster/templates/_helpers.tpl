{{/* Whether a catalog entry is installed: provider, disable/enable lists (optIn entries need enable), and its `when` template. */}}
{{- define "apps.enabled" -}}
{{- $e := .entry -}}{{- $v := .root.Values -}}
{{- $ok := and (has $v.provider $e.providers) (not (has $e.name ($v.disable | default list))) -}}
{{- if $e.optIn -}}{{- $ok = and $ok (has $e.name ($v.enable | default list)) -}}{{- end -}}
{{- if and $ok $e.when -}}{{- $ok = eq (tpl $e.when .root | trim) "true" -}}{{- end -}}
{{- $ok -}}
{{- end -}}

{{/* Sync options, retry, and finalizer shared by every Application (GitOpsConventions). */}}
{{- define "apps.syncPolicy" -}}
syncPolicy:
  automated:
    prune: true
    selfHeal: true
  retry:
    limit: 5
    refresh: true
    backoff:
      duration: 10s
      factor: 2
      maxDuration: 3m
  syncOptions:
    - CreateNamespace=true
    - ServerSideApply=true
{{- end -}}


{{/* Namespaces each layer deploys into: {layer: [ns]} for enabled entries. */}}
{{- define "apps.namespaces" -}}
{{- $out := dict "bootstrap" (list "argocd") "core" (list) "platform" (list) -}}
{{- range .Values.catalog -}}
{{- if eq (include "apps.enabled" (dict "entry" . "root" $)) "true" -}}
{{- $_ := set $out .layer (append (get $out .layer) .namespace | uniq) -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}

{{/* Repositories each layer sources from: {layer: [repoURL]}, as Argo CD sees them. */}}
{{- define "apps.repos" -}}
{{- $out := dict "bootstrap" (list) "core" (list) "platform" (list) -}}
{{- range .Values.catalog -}}
{{- if eq (include "apps.enabled" (dict "entry" . "root" $)) "true" -}}
{{- $_ := set $out .layer (append (get $out .layer) (.repoURL | trimPrefix "oci://") | uniq) -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}

{{/* Pod Security labels for a namespace (docs/spec/security). */}}
{{- define "apps.psaLabels" -}}
pod-security.kubernetes.io/enforce: {{ ternary "privileged" "baseline" (has .ns .root.Values.privilegedNamespaces) }}
pod-security.kubernetes.io/warn: restricted
pod-security.kubernetes.io/audit: restricted
{{- end -}}

{{/* The enabled metrics stack (ADR 65), or empty; policy keeps it to one. */}}
{{- define "apps.metricsStack" -}}
{{- $enable := .Values.enable | default list -}}
{{- range list "kube-prometheus-stack" "victoria-metrics-k8s-stack" }}{{ if has . $enable }}{{ . }}{{ end }}{{ end -}}
{{- end -}}

{{/* Whether an installed entry renders its monitor (ADR 68): a stack is on, and it is a default or added, and not removed. */}}
{{- define "apps.monitored" -}}
{{- $e := .entry -}}{{- $v := .root.Values -}}
{{- $m := $v.monitor | default dict -}}
{{- $on := or $e.monitorByDefault (has $e.name ($m.add | default list)) -}}
{{- if and $e.monitor (not $v.skipMonitors) (include "apps.metricsStack" .root) $on (not (has $e.name ($m.remove | default list))) -}}
true
{{- else -}}
false
{{- end -}}
{{- end -}}
