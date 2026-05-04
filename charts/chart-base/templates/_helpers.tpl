{{/*
Nome curto do chart (truncado em 63 chars). Sobrescrito por nameOverride.
*/}}
{{- define "chart-base.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Fullname: usado em metadata.name dos recursos. Se Release.Name já contém o
nome do chart, usa Release.Name puro; senão concatena. Sobrescrito por
fullnameOverride.
*/}}
{{- define "chart-base.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Chart label: nome-versao (sanitizado).
*/}}
{{- define "chart-base.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Selector labels: APENAS name + instance. Estes labels são imutáveis em
Deployment/StatefulSet — qualquer outra coisa aqui causa dor em upgrades.
*/}}
{{- define "chart-base.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chart-base.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{/*
Common labels: selector + metadados informativos.
*/}}
{{- define "chart-base.labels" -}}
helm.sh/chart: {{ include "chart-base.chart" . }}
{{ include "chart-base.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{/*
ServiceAccount em uso. Se serviceAccount.create=true e name vazio, usa fullname.
*/}}
{{- define "chart-base.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "chart-base.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
serviceName referenciado pelo StatefulSet. Default = fullname.
*/}}
{{- define "chart-base.statefulSetServiceName" -}}
{{- default (include "chart-base.fullname" .) .Values.statefulSet.serviceName -}}
{{- end -}}

{{/*
Hosts únicos (FQDN) para Gateway/Certificate (Istio + cert-manager).
Emite YAML list sem newline líder — consumir com `nindent N`.
*/}}
{{- define "chart-base.gateway.uniqueHosts" -}}
{{- $seen := dict -}}
{{- $out := list -}}
{{- range .Values.virtualService.routes -}}
{{- range .hosts -}}
{{- $h := printf "%s.%s" . $.Values.virtualService.domain -}}
{{- if not (hasKey $seen $h) -}}
{{- $_ := set $seen $h true -}}
{{- $out = append $out $h -}}
{{- end -}}
{{- end -}}
{{- end -}}
{{- toYaml $out -}}
{{- end -}}
