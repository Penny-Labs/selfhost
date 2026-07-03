# PennyOS Combined Helm Chart

This chart deploys:
- `penny` API
- `penny_os` web
- optional Bitnami PostgreSQL (`postgresql.enabled=true`)

## Required Values

You must provide both image references:

```yaml
api:
  image:
    repository: ghcr.io/your-org/penny
    tag: "v1.2.3"

web:
  image:
    repository: ghcr.io/your-org/penny-os
    tag: "v1.2.3"
```

By default, the chart runs a bootstrap hook job that generates install-local
secret material and preserves existing keys across upgrades:
- `IAM_SESSION_SIGNING_KEY`
- `PENNY_RUNTIME_LEASE_ENC_KEY`
- bundled PostgreSQL admin/user passwords when `postgresql.enabled=true`

PennyOS defaults to managed runtime mode. You must also provide:
- `management.apiUrl`
- `management.runtimeAutoActivate.licenseKey`, `management.runtimeAutoActivate.licenseKeySecret`, or an `api.extraEnv` entry matching `management.runtimeAutoActivate.licenseKeyEnv`

If `generatedSecrets.enabled=false`, you must provide the auth signing key and
runtime lease encryption key with direct values or existing Secret refs.

## Install Example (Bundled Postgres)

```bash
helm dependency update selfhost/products/pennyos/helm

helm upgrade --install pennyos selfhost/products/pennyos/helm \
  --set api.image.repository=ghcr.io/your-org/penny \
  --set api.image.tag=v1.2.3 \
  --set web.image.repository=ghcr.io/your-org/penny-os \
  --set web.image.tag=v1.2.3 \
  --set postgresql.enabled=true \
  --set management.apiUrl=https://management.example.com \
  --set management.apiTokenSecret.name=pennyos-management \
  --set management.runtimeAutoActivate.licenseKeySecret.name=pennyos-management
```

## Install Example (External Postgres)

```bash
helm upgrade --install pennyos selfhost/products/pennyos/helm \
  --set api.image.repository=ghcr.io/your-org/penny \
  --set api.image.tag=v1.2.3 \
  --set web.image.repository=ghcr.io/your-org/penny-os \
  --set web.image.tag=v1.2.3 \
  --set postgresql.enabled=false \
  --set database.host=postgres.example.internal \
  --set database.port=5432 \
  --set database.name=penny \
  --set database.user=penny \
  --set database.password='replace-db-password' \
  --set management.apiUrl=https://management.example.com \
  --set management.apiTokenSecret.name=pennyos-management \
  --set management.runtimeAutoActivate.licenseKeySecret.name=pennyos-management
```

You can also configure the database with a full DSN. When `database.url` or
`database.urlSecret.name` is set, the chart renders `DB_URL` and does not render
the split `DB_HOSTNAME`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`, and
`DB_SSLMODE` variables.

```yaml
database:
  urlSecret:
    name: pennyos-db-url
    key: DB_URL
```

## Penny API Runtime Configuration

The chart exposes the Penny API environment variables from `penny/internal/app/config.go`.
It points PennyOS at an already deployed `management-api`; this chart does not deploy `management-api`.

Non-secret API runtime values are rendered into a chart-managed ConfigMap and
loaded into the Penny API Deployment with `envFrom`. The pod template includes a
checksum annotation for that ConfigMap, so changing ConfigMap-backed values
rolls the API Deployment automatically. Secret values stay as `secretKeyRef`
entries and are not copied into the ConfigMap.

Default managed runtime behavior:

```yaml
generatedSecrets:
  enabled: true

management:
  mode: required
  apiUrl: https://management.example.com
  runtimeSecretDir: /var/lib/penny/runtime
  runtimeLeaseCache: encrypted_file
  runtimeLeaseCachePath: /var/lib/penny/runtime/runtime_lease.enc.json
  runtimeAutoActivate:
    enabled: true
    licenseKeySecret:
      name: pennyos-management
      key: MANAGEMENT_RUNTIME_AUTO_ACTIVATE_LICENSE_KEY
    licenseKeyEnv: MANAGEMENT_LICENSE_KEY
    productId: pennyos
    confirmTransfer: false
    renewBefore: 5m
  runtimeWebsocket:
    enabled: true
  runtimeStorage:
    enabled: true
    mountPath: /var/lib/penny
    size: 1Gi

sync:
  provider: managed
```

Use an existing claim for runtime install keys and encrypted lease cache:

```yaml
management:
  runtimeStorage:
    enabled: true
    existingClaim: pennyos-runtime
```

Sensitive fields support direct values for local/dev installs and Secret refs for
production-style installs. Secret refs win when both are set. Direct values
without Secret refs create chart-managed Secrets:

- `auth.sessionSigningKey` / `auth.existingSecret` -> `IAM_SESSION_SIGNING_KEY`
- `database.url` / `database.urlSecret` -> `DB_URL`
- `management.apiToken` / `management.apiTokenSecret` -> `MANAGEMENT_API_TOKEN`
- `management.runtimeLeaseEncryptionKey` / `management.runtimeLeaseEncryptionKeySecret` -> `PENNY_RUNTIME_LEASE_ENC_KEY`
- `management.runtimeAutoActivate.licenseKey` / `management.runtimeAutoActivate.licenseKeySecret` -> `MANAGEMENT_RUNTIME_AUTO_ACTIVATE_LICENSE_KEY`

When `generatedSecrets.enabled=true`, the chart-generated Secret is used as a
fallback for `IAM_SESSION_SIGNING_KEY` and `PENNY_RUNTIME_LEASE_ENC_KEY` if no
direct value or existing Secret ref is set. Bundled PostgreSQL also uses the
generated Secret by default. To supply the bundled PostgreSQL password yourself,
set `postgresql.auth.existingSecret=""` and `postgresql.auth.password`, or point
`postgresql.auth.existingSecret` at your own Secret with keys `postgres-password`
and `password`.

For local-only installs, explicitly opt out:

```yaml
management:
  mode: disabled
  runtimeLeaseCache: memory
  runtimeAutoActivate:
    enabled: false
  runtimeWebsocket:
    enabled: false
  runtimeStorage:
    enabled: false

sync:
  provider: local
```

## Gateway API HTTPRoute

Enable Gateway API routing with:

```yaml
gateway:
  enabled: true
  parentRefs:
    - name: public-gateway
```

Default gateway behavior:
- always generates 2 HTTPRoutes on `gateway.web.host`:
  - web route (`gateway.web.pathPrefix`) to web service
  - api route (`gateway.api.pathPrefix`) to api service
- when `gateway.api.separateHost.enabled=true`, generates a 3rd HTTPRoute for API on `gateway.api.separateHost.host`
- optional separate web HTTP redirect route via:
  - `gateway.web.httpsRedirect.enabled=true`
  - `gateway.web.httpsRedirect.statusCode` (default `301`)
  - `gateway.web.httpsRedirect.parentRefs` (required when enabled; typically points to your HTTP listener)

Example HTTPS backend route + HTTP redirect route:

```yaml
gateway:
  enabled: true
  parentRefs:
    - group: gateway.networking.k8s.io
      kind: Gateway
      name: shared
      namespace: httpgateway
      sectionName: marone-us-wild-https
  web:
    host: plex.marone.us
    httpsRedirect:
      enabled: true
      statusCode: 302
      parentRefs:
        - group: gateway.networking.k8s.io
          kind: Gateway
          name: shared
          namespace: httpgateway
          sectionName: http
```

## Web API Base URL

- `web.apiBaseUrl`: optional explicit override
- If unset and gateway is enabled, it derives from gateway host settings.
- If unset and gateway is disabled, it defaults to the in-cluster API service URL.
- `PENNY_OS_BUILD_PROFILE` is build-time only in the web image and is not a runtime chart value.

## Migration Hook Job

When `migrations.enabled=true`, a migration job runs using the API image and the bundled migration paths:
- `/migrations/penny`
- `/migrations/openauth`

Hook behavior:
- external DB mode: `pre-install,pre-upgrade`
- bundled Postgres mode: `post-install,pre-upgrade` (ensures DB exists before first migration run)

## Main Values

- `api.serviceAccount.*`
- `api.image.*`
- `generatedSecrets.*`
- `web.serviceAccount.*`
- `web.image.*`
- `web.apiBaseUrl`
- `gateway.enabled`
- `gateway.parentRefs`
- `gateway.annotations`
- `gateway.labels`
- `gateway.web.host`
- `gateway.web.pathPrefix`
- `gateway.web.httpsRedirect.enabled`
- `gateway.web.httpsRedirect.statusCode`
- `gateway.web.httpsRedirect.parentRefs`
- `gateway.api.pathPrefix`
- `gateway.api.separateHost.enabled`
- `gateway.api.separateHost.host`
- `gateway.publicScheme`
- `postgresql.enabled`
- `database.*`
- `management.*`
- `management.runtimeStorage.*`
- `sync.provider`
- `auth.existingSecret`
- `auth.sessionSigningKey`
- `migrations.serviceAccount.*`
- `migrations.enabled`
- `migrations.backoffLimit`
- `migrations.activeDeadlineSeconds`
