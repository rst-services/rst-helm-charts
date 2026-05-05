{{- define "zabbix-proxy.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
StatefulSet/Service/Pod nome = release name diretamente (em vez do padrão
Bitnami `<release>-<chart>`). Isso resulta em pods curtos: <release>-0, -1, ...
ZBX_HOSTNAME via fieldRef.metadata.name herda esse nome curto.
*/}}
{{- define "zabbix-proxy.fullname" -}}
{{- default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
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
