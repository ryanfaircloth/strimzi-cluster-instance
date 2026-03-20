{{/*
Expand the name of the chart.
*/}}
{{- define "strimzi-kafka-users.name" -}}
{{- default "sku" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "strimzi-kafka-users.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "sku" .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "strimzi-kafka-users.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "strimzi-kafka-users.labels" -}}
helm.sh/chart: {{ include "strimzi-kafka-users.chart" . }}
{{ include "strimzi-kafka-users.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "strimzi-kafka-users.selectorLabels" -}}
app.kubernetes.io/name: {{ include "strimzi-kafka-users.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
