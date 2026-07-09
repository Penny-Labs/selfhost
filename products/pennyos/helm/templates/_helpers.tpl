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

{{- define "pennyos.generatedSecretsServiceAccountName" -}}
{{- if .Values.generatedSecrets.serviceAccount.create -}}
{{- default (printf "%s-bootstrap" (include "pennyos.fullname" .)) .Values.generatedSecrets.serviceAccount.name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default "default" .Values.generatedSecrets.serviceAccount.name -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.authSecretName" -}}
{{- if .Values.auth.existingSecret -}}
{{- .Values.auth.existingSecret -}}
{{- else if and (not .Values.auth.sessionSigningKey) (include "pennyos.generatedSecrets.sessionSigningKeyEnabled" .) -}}
{{- include "pennyos.generatedSecretsName" . -}}
{{- else -}}
{{- printf "%s-auth" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.dbSecretName" -}}
{{- if .Values.database.passwordSecret.name -}}
{{- .Values.database.passwordSecret.name -}}
{{- else if and .Values.postgresql.enabled .Values.postgresql.auth.existingSecret -}}
{{- tpl .Values.postgresql.auth.existingSecret . -}}
{{- else if .Values.postgresql.enabled -}}
{{- printf "%s-postgresql" .Release.Name -}}
{{- else -}}
{{- printf "%s-external-db" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.dbUrlSecretName" -}}
{{- if .Values.database.urlSecret.name -}}
{{- .Values.database.urlSecret.name -}}
{{- else -}}
{{- printf "%s-db-url" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.managementSecretName" -}}
{{- printf "%s-management" (include "pennyos.fullname" .) -}}
{{- end -}}

{{- define "pennyos.apiConfigMapName" -}}
{{- printf "%s-api-env" (include "pennyos.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pennyos.generatedSecretsName" -}}
{{- tpl (required "generatedSecrets.name is required when generatedSecrets.enabled=true" .Values.generatedSecrets.name) . | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pennyos.generatedSecretsJobName" -}}
{{- printf "%s-bootstrap-secrets" (include "pennyos.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pennyos.generatedSecretsRoleName" -}}
{{- printf "%s-bootstrap-secrets" (include "pennyos.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "pennyos.runtimeStorageClaimName" -}}
{{- if .Values.management.runtimeStorage.existingClaim -}}
{{- .Values.management.runtimeStorage.existingClaim -}}
{{- else -}}
{{- printf "%s-runtime" (include "pennyos.fullname" .) -}}
{{- end -}}
{{- end -}}

{{/* Database helpers */}}
{{- define "pennyos.db.urlConfigured" -}}
{{- if or .Values.database.url .Values.database.urlSecret.name -}}true{{- end -}}
{{- end -}}

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
{{- if .Values.database.passwordSecret.name -}}
{{- default "password" .Values.database.passwordSecret.key -}}
{{- else if .Values.postgresql.enabled -}}
{{- default "password" .Values.postgresql.auth.secretKeys.userPasswordKey -}}
{{- else -}}
{{- default "password" .Values.database.passwordSecret.key -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.postgresql.adminPasswordSecretKey" -}}
{{- default "postgres-password" .Values.postgresql.auth.secretKeys.adminPasswordKey -}}
{{- end -}}

{{- define "pennyos.db.urlSecretKey" -}}
{{- default "DB_URL" .Values.database.urlSecret.key -}}
{{- end -}}

{{/* Generated Secret helpers */}}
{{- define "pennyos.generatedSecrets.sessionSigningKeyEnabled" -}}
{{- if and .Values.generatedSecrets.enabled .Values.generatedSecrets.keys.sessionSigningKey (not .Values.auth.existingSecret) (not .Values.auth.sessionSigningKey) -}}true{{- end -}}
{{- end -}}

{{- define "pennyos.generatedSecrets.runtimeLeaseEncryptionKeyEnabled" -}}
{{- if and .Values.generatedSecrets.enabled .Values.generatedSecrets.keys.runtimeLeaseEncryptionKey (eq (lower (toString .Values.management.runtimeLeaseCache)) "encrypted_file") (not .Values.management.runtimeLeaseEncryptionKeySecret.name) (not .Values.management.runtimeLeaseEncryptionKey) -}}true{{- end -}}
{{- end -}}

{{- define "pennyos.generatedSecrets.postgresqlPasswordEnabled" -}}
{{- if and .Values.generatedSecrets.enabled .Values.generatedSecrets.keys.postgresqlPassword .Values.postgresql.enabled (not .Values.postgresql.auth.password) .Values.postgresql.auth.existingSecret -}}
{{- if eq (tpl .Values.postgresql.auth.existingSecret .) (include "pennyos.generatedSecretsName" .) -}}true{{- end -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.generatedSecrets.needsJob" -}}
{{- if or (include "pennyos.generatedSecrets.sessionSigningKeyEnabled" .) (include "pennyos.generatedSecrets.runtimeLeaseEncryptionKeyEnabled" .) (include "pennyos.generatedSecrets.postgresqlPasswordEnabled" .) -}}true{{- end -}}
{{- end -}}

{{- define "pennyos.auth.validate" -}}
{{- if not (or .Values.auth.existingSecret .Values.auth.sessionSigningKey (include "pennyos.generatedSecrets.sessionSigningKeyEnabled" .)) -}}
{{- fail "auth.sessionSigningKey, auth.existingSecret, or generatedSecrets.keys.sessionSigningKey=true is required for IAM_SESSION_SIGNING_KEY" -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.generatedSecrets.validate" -}}
{{- if and .Values.postgresql.enabled (eq (tpl .Values.postgresql.auth.existingSecret .) (include "pennyos.generatedSecretsName" .)) (not .Values.generatedSecrets.enabled) -}}
{{- fail "generatedSecrets.enabled must be true when postgresql.auth.existingSecret points at the generated Secret" -}}
{{- end -}}
{{- end -}}

{{/* Management secret helpers */}}
{{- define "pennyos.management.apiTokenSecretName" -}}
{{- if .Values.management.apiTokenSecret.name -}}
{{- .Values.management.apiTokenSecret.name -}}
{{- else -}}
{{- include "pennyos.managementSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.management.apiTokenSecretKey" -}}
{{- default "MANAGEMENT_API_TOKEN" .Values.management.apiTokenSecret.key -}}
{{- end -}}

{{- define "pennyos.management.runtimeLeaseEncryptionKeySecretName" -}}
{{- if .Values.management.runtimeLeaseEncryptionKeySecret.name -}}
{{- .Values.management.runtimeLeaseEncryptionKeySecret.name -}}
{{- else if and (not .Values.management.runtimeLeaseEncryptionKey) (include "pennyos.generatedSecrets.runtimeLeaseEncryptionKeyEnabled" .) -}}
{{- include "pennyos.generatedSecretsName" . -}}
{{- else -}}
{{- include "pennyos.managementSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.management.runtimeLeaseEncryptionKeySecretKey" -}}
{{- default "PENNY_RUNTIME_LEASE_ENC_KEY" .Values.management.runtimeLeaseEncryptionKeySecret.key -}}
{{- end -}}

{{- define "pennyos.management.runtimeAutoActivateLicenseKeySecretName" -}}
{{- if .Values.management.runtimeAutoActivate.licenseKeySecret.name -}}
{{- .Values.management.runtimeAutoActivate.licenseKeySecret.name -}}
{{- else -}}
{{- include "pennyos.managementSecretName" . -}}
{{- end -}}
{{- end -}}

{{- define "pennyos.management.runtimeAutoActivateLicenseKeySecretKey" -}}
{{- default "MANAGEMENT_RUNTIME_AUTO_ACTIVATE_LICENSE_KEY" .Values.management.runtimeAutoActivate.licenseKeySecret.key -}}
{{- end -}}

{{- define "pennyos.api.extraEnv.hasName" -}}
{{- $root := .root -}}
{{- $name := toString .name -}}
{{- $found := false -}}
{{- range $root.Values.api.extraEnv }}
{{- if eq (toString .name) $name -}}
{{- $found = true -}}
{{- end -}}
{{- end -}}
{{- if $found -}}true{{- end -}}
{{- end -}}

{{- define "pennyos.management.enabled" -}}
{{- $mode := lower (toString .Values.management.mode) -}}
{{- $leaseCache := lower (toString .Values.management.runtimeLeaseCache) -}}
{{- $syncProvider := lower (toString .Values.sync.provider) -}}
{{- if or (eq $mode "required") .Values.management.runtimeAutoActivate.enabled .Values.management.runtimeWebsocket.enabled (eq $leaseCache "encrypted_file") (eq $syncProvider "managed") -}}true{{- end -}}
{{- end -}}

{{- define "pennyos.management.validate" -}}
{{- include "pennyos.generatedSecrets.validate" . -}}
{{- $managementEnabled := include "pennyos.management.enabled" . -}}
{{- if and $managementEnabled (not .Values.management.apiUrl) -}}
{{- fail "management.apiUrl is required when management runtime integration is enabled" -}}
{{- end -}}
{{- if eq (lower (toString .Values.management.runtimeLeaseCache)) "encrypted_file" -}}
{{- if not (or .Values.management.runtimeLeaseEncryptionKey .Values.management.runtimeLeaseEncryptionKeySecret.name (include "pennyos.generatedSecrets.runtimeLeaseEncryptionKeyEnabled" .)) -}}
{{- fail "management.runtimeLeaseEncryptionKey, management.runtimeLeaseEncryptionKeySecret.name, or generatedSecrets.keys.runtimeLeaseEncryptionKey=true is required when management.runtimeLeaseCache=encrypted_file" -}}
{{- end -}}
{{- end -}}
{{- if .Values.management.runtimeAutoActivate.enabled -}}
{{- $licenseKeyEnv := toString .Values.management.runtimeAutoActivate.licenseKeyEnv -}}
{{- $licenseKeyEnvConfigured := include "pennyos.api.extraEnv.hasName" (dict "root" . "name" $licenseKeyEnv) -}}
{{- if not (or .Values.management.runtimeAutoActivate.licenseKey .Values.management.runtimeAutoActivate.licenseKeySecret.name $licenseKeyEnvConfigured) -}}
{{- fail "management.runtimeAutoActivate.licenseKey, management.runtimeAutoActivate.licenseKeySecret.name, or matching api.extraEnv entry for management.runtimeAutoActivate.licenseKeyEnv is required when runtime auto activation is enabled" -}}
{{- end -}}
{{- end -}}
{{- if and (or .Values.management.runtimeAutoActivate.enabled .Values.management.runtimeWebsocket.enabled (eq (lower (toString .Values.management.runtimeLeaseCache)) "encrypted_file")) (not .Values.management.runtimeStorage.enabled) -}}
{{- fail "management.runtimeStorage.enabled must be true when runtime auto activation, runtime websocket, or encrypted lease cache is enabled" -}}
{{- end -}}
{{- if and .Values.management.runtimeStorage.enabled (not .Values.management.runtimeStorage.mountPath) -}}
{{- fail "management.runtimeStorage.mountPath is required when management.runtimeStorage.enabled=true" -}}
{{- end -}}
{{- end -}}

{{/* API environment helpers */}}
{{- define "pennyos.db.env" -}}
{{- if include "pennyos.db.urlConfigured" . }}
- name: DB_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.dbUrlSecretName" . | quote }}
      key: {{ include "pennyos.db.urlSecretKey" . | quote }}
{{- else }}
- name: DB_HOSTNAME
  value: {{ include "pennyos.db.host" . | quote }}
- name: DB_PORT
  value: {{ include "pennyos.db.port" . | quote }}
- name: DB_NAME
  value: {{ include "pennyos.db.name" . | quote }}
- name: DB_USER
  value: {{ include "pennyos.db.user" . | quote }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.db.passwordSecretName" . | quote }}
      key: {{ include "pennyos.db.passwordSecretKey" . | quote }}
- name: DB_SSLMODE
  value: {{ include "pennyos.db.sslmode" . | quote }}
{{- end }}
{{- end -}}

{{- define "pennyos.api.configData" -}}
{{- include "pennyos.management.validate" . -}}
{{- if not (include "pennyos.db.urlConfigured" .) }}
DB_HOSTNAME: {{ include "pennyos.db.host" . | quote }}
DB_PORT: {{ include "pennyos.db.port" . | quote }}
DB_NAME: {{ include "pennyos.db.name" . | quote }}
DB_USER: {{ include "pennyos.db.user" . | quote }}
DB_SSLMODE: {{ include "pennyos.db.sslmode" . | quote }}
{{- end }}
IAM_TENANT: {{ .Values.auth.tenant | quote }}
IAM_SESSION_SIGNING_KEY_ID: {{ .Values.auth.sessionSigningKeyId | quote }}
IAM_SESSION_ISSUER: {{ .Values.auth.sessionIssuer | quote }}
IAM_SESSION_AUDIENCE: {{ .Values.auth.sessionAudience | quote }}
IAM_SESSION_TTL: {{ .Values.auth.sessionTTL | quote }}
IAM_SESSION_COOKIE_NAME: {{ .Values.auth.sessionCookieName | quote }}
IAM_SESSION_COOKIE_PATH: {{ .Values.auth.sessionCookiePath | quote }}
IAM_SESSION_COOKIE_DOMAIN: {{ .Values.auth.sessionCookieDomain | quote }}
IAM_COOKIE_SECURE: {{ ternary "true" "false" .Values.auth.cookieSecure | quote }}
HTTP_TRUSTED_PROXY_CIDRS: {{ join "," .Values.api.trustedProxyCIDRs | quote }}
MANAGEMENT_MODE: {{ .Values.management.mode | quote }}
MANAGEMENT_API_URL: {{ .Values.management.apiUrl | quote }}
PENNY_RUNTIME_SECRET_DIR: {{ .Values.management.runtimeSecretDir | quote }}
PENNY_RUNTIME_LEASE_CACHE: {{ .Values.management.runtimeLeaseCache | quote }}
PENNY_RUNTIME_LEASE_CACHE_PATH: {{ .Values.management.runtimeLeaseCachePath | quote }}
MANAGEMENT_RUNTIME_AUTO_ACTIVATE_ENABLED: {{ ternary "true" "false" .Values.management.runtimeAutoActivate.enabled | quote }}
MANAGEMENT_RUNTIME_AUTO_ACTIVATE_LICENSE_KEY_ENV: {{ .Values.management.runtimeAutoActivate.licenseKeyEnv | quote }}
MANAGEMENT_RUNTIME_AUTO_ACTIVATE_PRODUCT_ID: {{ .Values.management.runtimeAutoActivate.productId | quote }}
MANAGEMENT_RUNTIME_AUTO_ACTIVATE_CONFIRM_TRANSFER: {{ ternary "true" "false" .Values.management.runtimeAutoActivate.confirmTransfer | quote }}
MANAGEMENT_RUNTIME_AUTO_ACTIVATE_RENEW_BEFORE: {{ .Values.management.runtimeAutoActivate.renewBefore | quote }}
MANAGEMENT_RUNTIME_WEBSOCKET_ENABLED: {{ ternary "true" "false" .Values.management.runtimeWebsocket.enabled | quote }}
MANAGEMENT_RUNTIME_WEBSOCKET_URL: {{ .Values.management.runtimeWebsocket.url | quote }}
SYNC_PROVIDER: {{ .Values.sync.provider | quote }}
{{- end -}}

{{- define "pennyos.management.secretEnv" -}}
{{- if or .Values.management.apiToken .Values.management.apiTokenSecret.name }}
- name: MANAGEMENT_API_TOKEN
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.management.apiTokenSecretName" . | quote }}
      key: {{ include "pennyos.management.apiTokenSecretKey" . | quote }}
{{- end }}
{{- if or .Values.management.runtimeLeaseEncryptionKey .Values.management.runtimeLeaseEncryptionKeySecret.name (include "pennyos.generatedSecrets.runtimeLeaseEncryptionKeyEnabled" .) }}
- name: PENNY_RUNTIME_LEASE_ENC_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.management.runtimeLeaseEncryptionKeySecretName" . | quote }}
      key: {{ include "pennyos.management.runtimeLeaseEncryptionKeySecretKey" . | quote }}
{{- end }}
{{- if or .Values.management.runtimeAutoActivate.licenseKey .Values.management.runtimeAutoActivate.licenseKeySecret.name }}
- name: MANAGEMENT_RUNTIME_AUTO_ACTIVATE_LICENSE_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.management.runtimeAutoActivateLicenseKeySecretName" . | quote }}
      key: {{ include "pennyos.management.runtimeAutoActivateLicenseKeySecretKey" . | quote }}
{{- end }}
{{- end -}}

{{- define "pennyos.api.secretEnv" -}}
{{- include "pennyos.auth.validate" . -}}
{{- include "pennyos.management.validate" . -}}
{{- if include "pennyos.db.urlConfigured" . }}
- name: DB_URL
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.dbUrlSecretName" . | quote }}
      key: {{ include "pennyos.db.urlSecretKey" . | quote }}
{{- else }}
- name: DB_PASSWORD
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.db.passwordSecretName" . | quote }}
      key: {{ include "pennyos.db.passwordSecretKey" . | quote }}
{{- end }}
- name: IAM_SESSION_SIGNING_KEY
  valueFrom:
    secretKeyRef:
      name: {{ include "pennyos.authSecretName" . | quote }}
      key: {{ .Values.auth.sessionSigningKeyKey | quote }}
{{- $managementSecretEnv := include "pennyos.management.secretEnv" . | trim }}
{{- if $managementSecretEnv }}
{{ $managementSecretEnv }}
{{- end }}
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
