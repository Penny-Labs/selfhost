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

Authentication signing key must be provided either by:
- `auth.existingSecret` + `auth.sessionSigningKeyKey`, or
- `auth.sessionSigningKey` (chart-managed secret)

## Install Example (Bundled Postgres)

```bash
helm dependency update selfhost/products/pennyos/helm

helm upgrade --install pennyos selfhost/products/pennyos/helm \
  --set api.image.repository=ghcr.io/your-org/penny \
  --set api.image.tag=v1.2.3 \
  --set web.image.repository=ghcr.io/your-org/penny-os \
  --set web.image.tag=v1.2.3 \
  --set auth.sessionSigningKey='replace-with-strong-secret'
```

## Install Example (External Postgres)

```bash
helm upgrade --install pennyos selfhost/products/pennyos/helm \
  --set api.image.repository=ghcr.io/your-org/penny \
  --set api.image.tag=v1.2.3 \
  --set web.image.repository=ghcr.io/your-org/penny-os \
  --set web.image.tag=v1.2.3 \
  --set auth.sessionSigningKey='replace-with-strong-secret' \
  --set postgresql.enabled=false \
  --set database.external.host=postgres.example.internal \
  --set database.external.port=5432 \
  --set database.external.name=penny \
  --set database.external.user=penny \
  --set database.external.password='replace-db-password'
```

## Ingress Modes

Default mode (`ingress.enabled=true`, `ingress.api.separateHost.enabled=false`):
- `ingress.web.host` serves web at `/`
- same host routes `/v1` to API

Separate API host mode:

```yaml
ingress:
  api:
    separateHost:
      enabled: true
      host: api.example.com
```

## Gateway API HTTPRoute

Enable Gateway API routing with:

```yaml
gateway:
  enabled: true
  parentRefs:
    - name: public-gateway
```

Default behavior mirrors Ingress:
- single host routes `/v1` to API and `/` to web
- optional separate API host via `gateway.api.separateHost.enabled=true`

## Web API Base URL

- `web.apiBaseUrl`: optional explicit override
- If unset and ingress is enabled, the chart derives it from ingress host/tls settings.
- If ingress is disabled and gateway is enabled, it derives from gateway host settings.
- If unset and ingress is disabled, it defaults to the in-cluster API service URL.

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
- `web.serviceAccount.*`
- `web.image.*`
- `web.apiBaseUrl`
- `ingress.enabled`
- `ingress.className`
- `ingress.annotations`
- `ingress.web.host`
- `ingress.web.tls.*`
- `ingress.api.separateHost.enabled`
- `ingress.api.separateHost.host`
- `ingress.api.separateHost.tls.*`
- `gateway.enabled`
- `gateway.parentRefs`
- `gateway.annotations`
- `gateway.labels`
- `gateway.web.host`
- `gateway.web.pathPrefix`
- `gateway.api.pathPrefix`
- `gateway.api.separateHost.enabled`
- `gateway.api.separateHost.host`
- `gateway.publicScheme`
- `postgresql.enabled`
- `database.external.*`
- `auth.existingSecret`
- `auth.sessionSigningKey`
- `migrations.serviceAccount.*`
- `migrations.enabled`
- `migrations.backoffLimit`
- `migrations.activeDeadlineSeconds`
