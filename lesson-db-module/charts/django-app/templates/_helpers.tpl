{{/* Визначає ім'я чарту */}}
{{- define "django-app.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Визначає повне ім'я застосунку */}}
{{- define "django-app.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Стандартні лейбли */}}
{{- define "django-app.labels" -}}
helm.sh/chart: {{ include "django-app.name" . }}
{{ include "django-app.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{/* Селектор лейбли */}}
{{- define "django-app.selectorLabels" -}}
app.kubernetes.io/name: {{ include "django-app.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}