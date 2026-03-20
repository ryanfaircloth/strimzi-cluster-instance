{{/*
Expand the name of the chart.
*/}}
{{- define "strimzi-mirrormaker2-instance.name" -}}
{{- default "smm2i" .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "strimzi-mirrormaker2-instance.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "smm2i" .Values.nameOverride }}
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
{{- define "strimzi-mirrormaker2-instance.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "strimzi-mirrormaker2-instance.labels" -}}
helm.sh/chart: {{ include "strimzi-mirrormaker2-instance.chart" . }}
{{ include "strimzi-mirrormaker2-instance.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "strimzi-mirrormaker2-instance.selectorLabels" -}}
app.kubernetes.io/name: {{ include "strimzi-mirrormaker2-instance.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
