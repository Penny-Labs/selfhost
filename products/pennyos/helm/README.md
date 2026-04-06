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
  --set database.host=postgres.example.internal \
  --set database.port=5432 \
  --set database.name=penny \
  --set database.user=penny \
  --set database.password='replace-db-password'
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
- optional web HTTPS redirect filter via:
  - `gateway.web.httpsRedirect.enabled=true`
  - `gateway.web.httpsRedirect.statusCode` (default `301`)

## Web API Base URL

- `web.apiBaseUrl`: optional explicit override
- If unset and gateway is enabled, it derives from gateway host settings.
- If unset and gateway is disabled, it defaults to the in-cluster API service URL.

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
- `gateway.enabled`
- `gateway.parentRefs`
- `gateway.annotations`
- `gateway.labels`
- `gateway.web.host`
- `gateway.web.pathPrefix`
- `gateway.web.httpsRedirect.enabled`
- `gateway.web.httpsRedirect.statusCode`
- `gateway.api.pathPrefix`
- `gateway.api.separateHost.enabled`
- `gateway.api.separateHost.host`
- `gateway.publicScheme`
- `postgresql.enabled`
- `database.*`
- `auth.existingSecret`
- `auth.sessionSigningKey`
- `migrations.serviceAccount.*`
- `migrations.enabled`
- `migrations.backoffLimit`
- `migrations.activeDeadlineSeconds`
