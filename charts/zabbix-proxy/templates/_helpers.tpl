{{- define "zabbix-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "zabbix-proxy.fullname" -}}
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

{{- define "zabbix-proxy.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "zabbix-proxy.selectorLabels" -}}
app.kubernetes.io/name: {{ include "zabbix-proxy.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "zabbix-proxy.labels" -}}
helm.sh/chart: {{ include "zabbix-proxy.chart" . }}
{{ include "zabbix-proxy.selectorLabels" . }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: proxy
app.kubernetes.io/part-of: zabbix
{{- end -}}

{{- define "zabbix-proxy.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- default (include "zabbix-proxy.fullname" .) .Values.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{/*
Nome do Secret que contém o PSK. Pode ser referência externa (existingSecret)
ou criado pelo chart.
*/}}
{{- define "zabbix-proxy.pskSecretName" -}}
{{- if .Values.psk.existingSecret -}}
{{- .Values.psk.existingSecret -}}
{{- else -}}
{{- printf "%s-psk" (include "zabbix-proxy.fullname" .) -}}
{{- end -}}
{{- end -}}
