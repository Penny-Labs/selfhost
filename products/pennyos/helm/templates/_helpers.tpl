{{/* Chart/name helpers */}}
{{- define "pennyos.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pennyos.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := include "pennyos.name" . -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Label helpers */}}
{{- define "pennyos.labels" -}}
helm.sh/chart: {{ include "pennyos.chart" . }}
{{ include "pennyos.selectorLabels" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "pennyos.selectorLabels" -}}
app.kubernetes.io/name: {{ include "pennyos.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "pennyos.api.labels" -}}
{{ include "pennyos.labels" . }}
app.kubernetes.io/component: api
{{- end -}}

{{- define "pennyos.web.labels" -}}
{{ include "pennyos.labels" . }}
app.kubernetes.io/component: web
{{- end -}}

{{- define "pennyos.api.selectorLabels" -}}
{{ include "pennyos.selectorLabels" . }}
app.kubernetes.io/component: api
{{- end -}}

{{- define "pennyos.web.selectorLabels" -}}
{{ include "pennyos.selectorLabels" . }}
app.kubernetes.io/component: web
{{- end -}}

{{/* Resource name helpers */}}
{{- define "pennyos.apiServiceName" -}}
{{- printf "%s-api" (include "pennyos.fullname" .) -}}
{{- end -}}

{{- define "pennyos.webServiceName" -}}
{{- printf "%s-web" (include "pennyos.fullname" .) -}}
{{- end -}}

{{- define "pennyos.apiServiceAccountName" -}}
{{- if .Values.api.serviceAccount.create -}}
{{- default (printf "%s-api" (include "pennyos.fullname" .)) .Values.api.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.api.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.webServiceAccountName" -}}
{{- if .Values.web.serviceAccount.create -}}
{{- default (printf "%s-web" (include "pennyos.fullname" .)) .Values.web.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.web.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.migrationsServiceAccountName" -}}
{{- if .Values.migrations.serviceAccount.create -}}
{{- default (printf "%s-migrations" (include "pennyos.fullname" .)) .Values.migrations.serviceAccount.name -}}
{{- else -}}
{{- default "default" .Values.migrations.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.authSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else -}}
{{- printf "%s-auth" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.dbSecretName" -}}
{{- if .Values.database.passwordSecret.name -}}
{{- .Values.database.passwordSecret.name -}}
{{- else if .Values.postgresql.enabled -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- else -}}
{{- printf "%s-external-db" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* Database helpers */}}
{{- define "pennyos.db.host" -}}
{{- if .Values.database.host -}}
{{- .Values.database.host -}}
{{- else if .Values.postgresql.enabled -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- else -}}
{{- required "database.host is required when postgresql.enabled=false" .Values.database.host -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.port" -}}
{{- default 5432 .Values.database.port -}}
{{- end -}}

{{- define "pennyos.db.name" -}}
{{- required "database.name is required" .Values.database.name -}}
{{- end -}}

{{- define "pennyos.db.user" -}}
{{- required "database.user is required" .Values.database.user -}}
{{- end -}}

{{- define "pennyos.db.sslmode" -}}
{{- default "disable" .Values.database.sslmode -}}
{{- end -}}

{{- define "pennyos.db.passwordSecretName" -}}
{{- include "pennyos.dbSecretName" . -}}
{{- end -}}

{{- define "pennyos.db.passwordSecretKey" -}}
{{- default "password" .Values.database.passwordSecret.key -}}
{{- end -}}

{{/* Web API base URL helper */}}
{{- define "pennyos.webApiBaseUrl" -}}
{{- $explicit := trim .Values.web.apiBaseUrl -}}
{{- if $explicit -}}
{{- trimSuffix "/" $explicit -}}
{{- else if .Values.gateway.enabled -}}
  {{- $scheme := default "http" .Values.gateway.publicScheme -}}
  {{- if .Values.gateway.api.separateHost.enabled -}}
    {{- $host := required "gateway.api.separateHost.host is required when separate API host is enabled" .Values.gateway.api.separateHost.host -}}
    {{- printf "%s://%s" $scheme $host -}}
  {{- else -}}
    {{- $host := required "gateway.web.host is required when gateway is enabled" .Values.gateway.web.host -}}
    {{- printf "%s://%s" $scheme $host -}}
  {{- end -}}
{{- else -}}
{{- printf "http://%s:%v" (include "pennyos.apiServiceName" .) .Values.api.service.port -}}
{{- end -}}
{{- end -}}
