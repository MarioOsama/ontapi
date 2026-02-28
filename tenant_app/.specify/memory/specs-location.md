# Specs Folder & Monorepo Structure

**Decided**: 2026-02-27

## Repository Structure

The project uses a **monorepo** at `d:\flutter_projects\pager\ontapi\` with a single `.git` at the root.

```
ontapi/                    ← git root (.git)
├── tenant_app/
│   ├── .specify/          ← tenant_app's spec-kit (independent)
│   └── specs/             ← tenant_app's feature specs
├── client_app/
│   ├── .specify/          ← (future) client_app's spec-kit
│   └── specs/             ← (future) client_app's feature specs
└── backend/
    ├── .specify/          ← (future) backend's spec-kit
    └── specs/             ← (future) backend's feature specs
```

## Key Rules

1. **Each project owns its own `.specify/` and `specs/`** — they are NOT shared across the monorepo.
2. **`.git` stays at `ontapi/`** — the monorepo root. Do NOT move it.
3. **Always run `.specify` scripts from the project directory** (e.g., `cd tenant_app` then run scripts).
4. **`common.ps1` `Get-RepoRoot`** resolves via `.specify` marker (not git root), so each project's scripts automatically scope to the correct root.
