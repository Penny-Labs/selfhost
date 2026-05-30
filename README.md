# Penny self-hosting

This repository tracks the self-hosted Penny deployment posture for v1.

Penny v1 is local-first: the core finance app must work without the hosted `management-api`, without a license, and without managed Plaid sync. Managed services are optional extensions, not a boot requirement.

## V1 local-only mode

Use local-only mode when you want Penny/PennyOS to run without any hosted PennyLabs services:

```env
MANAGEMENT_MODE=disabled
MANAGEMENT_API_URL=
MANAGEMENT_LICENSE_KEY=
MANAGEMENT_INSTALL_ID=
MANAGEMENT_RUNTIME_WEBSOCKET_URL=
```

Expected behavior:

- local auth and finance pages remain usable,
- no activation starts automatically,
- no lease renewal starts automatically,
- no websocket command transport starts automatically,
- no managed Plaid sync runs automatically,
- PennyOS reads/writes local Penny finance APIs for core app workflows.

## Core v1 app surfaces

The local-first app covers:

- local users/auth,
- accounts and balances,
- transactions and exports,
- categories and tags,
- transaction rules,
- budgets,
- dashboard, insights, forecast, and net-worth views,
- local runtime entitlement/status visibility.

## Optional managed services

Managed services are separate from local-only mode. They require explicit operator configuration and are not enabled by this README alone:

- hosted `management-api`,
- Plaid Link/token exchange,
- managed account/balance/transaction pull,
- runtime activation,
- lease renewal,
- websocket command transport,
- Stripe billing lifecycle.

## Current safety gates

Do not enable or automate these behaviors without an approved credential/token lifecycle design:

- durable install private-key storage,
- durable lease-token storage,
- automatic activation/renewal loops,
- websocket reconnect/command loops.

## Validation references

The canonical v1 validation checklist lives in the Penny repo:

- `penny/hack/docs/local-first-validation.md`
- `penny/hack/docs/v1-implementation-matrix.md`

Useful validation commands:

```bash
# penny
export PATH=/home/openclaw/.openclaw/workspace/.local/bin:$PATH
export HOME=/home/openclaw/.openclaw/workspace
export GOCACHE=/home/openclaw/.openclaw/workspace/.cache/go-build

go test ./...
golangci-lint run ./...
git diff --check

# penny_os
YARN_ENABLE_INLINE_BUILDS=1 yarn build
git diff --check
```

## Status

This repo is documentation-only for the current v1 branch. Deployment manifests or installer automation should be added only after the local-first runtime/configuration contract is stable.
