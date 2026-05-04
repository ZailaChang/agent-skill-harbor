# Change Impact Matrix

Use this table whenever you are unsure which files a change should be synced to.

## Code-Layer Changes → Doc-Layer Changes

| What happened in this session | Files to update (by audience) |
|---|---|
| New API / route | Project-root markdown route index · `docs/integration-guide.md` API reference table · `docs/architecture.md` Routes section |
| New / renamed env var | Project-root markdown env var table · `docs/operator-runbook.md` env var section · `docs/integration-guide.md` (if downstream needs to configure it) |
| New database table / column | Project-root markdown database table · `docs/architecture.md` Data Model |
| New / changed user flow | Project-root markdown user flow · README CLI examples · `docs/handoff.md` What Exists Today |
| Large new feature (spans multiple files) | All of the above + new `docs/architecture.md` section + `docs/handoff.md` completed list |
| New term / rename | `docs/integration-guide.md` glossary (if present) + global search-and-replace of old term |
| Deployment params / infra change | `docs/operator-runbook.md` · project-root markdown deployment section |
| Downstream integration method changed | Downstream project's `docs/<integration>.md` · upstream project's `integration-guide.md` |

## Memory-Layer Changes

| Situation | Action |
|---|---|
| Stale fact | Edit the memory file and update the index (e.g. MEMORY.md) `description` |
| Relative timestamp ("today", "recently") | Convert to absolute date (`2026-04-29`, never "today") |
| Duplicate entries (multiple entries saying the same thing) | Merge into one entry, update the index |
| Completed TODO | Delete — the knowledge base is not a history archive |
| Overturned decision | Delete old entry, keep new decision |
| Temporary context only used once across sessions | Delete |

## Cross-Project Impact Check

Most commonly missed scenarios:

- **Upstream API changed → downstream SDK docs**: protocol changes must be aligned on both sides
- **Shared subdomain / route / env var changed → setup docs in all consumer projects**
- **Auth platform changed → integration guide in every connected application**
- **Shared component / infra upgraded → version references in each project's operator-runbook**

How to check: does the thing you changed have an SDK, subdomain, shared config, or cross-process protocol? If yes, search every dependent project's docs for any mention of it.

## Standard Doc Structure Convention

Adding a capability (API, flow, feature) means updating **four places**:

1. **integration-guide / external-perspective doc**: how to use it (curl / SDK examples / error codes)
2. **architecture**: how it works (data flow, state machine, design trade-offs)
3. **runbook**: how to operate it (smoke commands, troubleshooting, env vars)
4. **handoff / CHANGELOG**: marked as completed

API reference tables, env var tables, and glossaries are high-frequency structured lookups — **they must always reflect the current state**.
