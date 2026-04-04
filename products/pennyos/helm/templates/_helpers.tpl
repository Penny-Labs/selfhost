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

{{- define "pennyos.externalDBSecretName" -}}
{{- if .Values.database.external.existingSecret -}}
{{- .Values.database.external.existingSecret -}}
{{- else -}}
{{- printf "%s-external-db" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* Database helpers */}}
{{- define "pennyos.db.host" -}}
{{- if .Values.postgresql.enabled -}}
{{- if .Values.database.internal.host -}}
{{- .Values.database.internal.host -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- else -}}
{{- required "database.external.host is required when postgresql.enabled=false" .Values.database.external.host -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.port" -}}
{{- if .Values.postgresql.enabled -}}
{{- .Values.database.internal.port -}}
{{- else -}}
{{- .Values.database.external.port -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.name" -}}
{{- if .Values.postgresql.enabled -}}
{{- required "postgresql.auth.database is required when postgresql.enabled=true" .Values.postgresql.auth.database -}}
{{- else -}}
{{- required "database.external.name is required when postgresql.enabled=false" .Values.database.external.name -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.user" -}}
{{- if .Values.postgresql.enabled -}}
{{- required "postgresql.auth.username is required when postgresql.enabled=true" .Values.postgresql.auth.username -}}
{{- else -}}
{{- required "database.external.user is required when postgresql.enabled=false" .Values.database.external.user -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.sslmode" -}}
{{- if .Values.postgresql.enabled -}}
{{- default "disable" .Values.database.internal.sslmode -}}
{{- else -}}
{{- default "disable" .Values.database.external.sslmode -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.passwordSecretName" -}}
{{- if .Values.postgresql.enabled -}}
{{- if .Values.database.internal.passwordSecret.name -}}
{{- .Values.database.internal.passwordSecret.name -}}
{{- else -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- end -}}
{{- else -}}
{{- include "pennyos.externalDBSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.db.passwordSecretKey" -}}
{{- if .Values.postgresql.enabled -}}
{{- default "password" .Values.database.internal.passwordSecret.key -}}
{{- else -}}
{{- default "password" .Values.database.external.passwordKey -}}
{{- end -}}
{{- end -}}

{{/* Web API base URL helper */}}
{{- define "pennyos.webApiBaseUrl" -}}
{{- $explicit := trim .Values.web.apiBaseUrl -}}
{{- if $explicit -}}
{{- trimSuffix "/" $explicit -}}
{{- else if .Values.ingress.enabled -}}
  {{- if .Values.ingress.api.separateHost.enabled -}}
    {{- $scheme := ternary "https" "http" .Values.ingress.api.separateHost.tls.enabled -}}
    {{- $host := required "ingress.api.separateHost.host is required when separate API host is enabled" .Values.ingress.api.separateHost.host -}}
    {{- printf "%s://%s" $scheme $host -}}
  {{- else -}}
    {{- $scheme := ternary "https" "http" .Values.ingress.web.tls.enabled -}}
    {{- $host := required "ingress.web.host is required when ingress is enabled" .Values.ingress.web.host -}}
    {{- printf "%s://%s" $scheme $host -}}
  {{- end -}}
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
