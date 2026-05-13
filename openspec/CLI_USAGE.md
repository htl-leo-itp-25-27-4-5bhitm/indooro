# OpenSpec CLI Usage for Indooro

Indooro uses OpenSpec with the `spec-driven` schema and the experimental OPSX workflow.
The durable project truth lives in `openspec/specs/`; proposed changes live in
`openspec/changes/<change-name>/` until they are verified and archived.

## Standard Commands

Use the pinned OpenSpec CLI version documented in `openspec/config.yaml`:

```bash
npx -y @fission-ai/openspec@1.3.1 validate --all --strict
```

This is the recommended standard validation command before considering OpenSpec
work done.

List active changes:

```bash
npx -y @fission-ai/openspec@1.3.1 list --json
```

If this returns `{"changes":[]}`, there are no active OpenSpec changes.

List existing specs:

```bash
npx -y @fission-ai/openspec@1.3.1 list --specs
```

Check artifact status for an active change:

```bash
npx -y @fission-ai/openspec@1.3.1 status --change <change-name>
```

Archive a completed change:

```bash
npx -y @fission-ai/openspec@1.3.1 archive <change-name>
```

Avoid `--no-validate` unless there is a deliberate, documented reason.

## Do Not Re-run Init Blindly

Do not run `openspec init` again when `openspec/`, `openspec/config.yaml`, and
`openspec/specs/` already exist.

`init` is for initializing OpenSpec in a project. Re-running it may alter
existing instructions, tool configuration, or generated structure. In Indooro,
use `init --help` for inspection only unless the team intentionally decides to
reinitialize or update OpenSpec setup files.

## Verification Practice

OpenSpec CLI version `1.3.1` does not expose a top-level `verify` command.

For Indooro, use:

- Current spec health: `npx -y @fission-ai/openspec@1.3.1 validate --all --strict`
- Active change verification: the OPSX `/opsx:verify` phase or an agentic/manual
  verification pass against proposal, delta specs, design, tasks, code, and tests
- Change progress: `npx -y @fission-ai/openspec@1.3.1 status --change <change-name>`

Verification means checking that the implementation satisfies the relevant
requirements and scenarios, that tasks are complete, that tests or manual checks
cover the change, and that validation still passes.

## Future Feature Workflow

For changes to durable product behavior, architecture, security, deployment, or
public API contracts:

1. Create a change under `openspec/changes/<change-name>/`.
2. Write `proposal.md` explaining why the change exists and what it affects.
3. Write delta specs under `openspec/changes/<change-name>/specs/...`.
4. Write `design.md` for technical decisions, tradeoffs, and integration points.
5. Write `tasks.md` with explicit, reviewable implementation and verification tasks.
6. Implement the change.
7. Verify the implementation against requirements, scenarios, tasks, code, and tests.
8. Run `npx -y @fission-ai/openspec@1.3.1 validate --all --strict`.
9. Archive the completed change so permanent behavior lands in `openspec/specs/`.

