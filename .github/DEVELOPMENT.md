# Development Rules

This file defines the development workflow rules that all contributors (human and AI) must follow.
It is referenced from `copilot-instructions.md` and persists across GSD updates.

## Git Workflow

### Branch Strategy

- **Never push directly to `main`**. All changes must go through a Pull Request.
- Use feature branches with the naming pattern: `phase/{phase}-{slug}` (e.g., `phase/03-feature-name`, where `{phase}` is zero-padded).
- PRs should be **squash-merged** to keep the main branch history clean.
- After squash merge, sync local main with `git reset --hard origin/main` (not rebase).

### Commit Conventions

- Use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `refactor:`, `docs:`, `chore:`, etc.
- Include the `Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>` trailer on AI-generated commits.
- Use `git -c commit.gpgsign=false commit` when automated GPG signing is unavailable.

## Issue Management

### Milestone Issues

When a new GSD milestone is created (`/gsd-new-milestone`):

1. **Create a GitHub Milestone** via `gh api` with the version and name (e.g., `v0.4.0 — Feature Name`).
2. **Create a tracking Issue** for the milestone with:
   - Title: `v0.4.0: Milestone Name`
   - Body: Milestone goal, list of phases as task checkboxes
   - Labels: `milestone`
   - Assigned to the GitHub Milestone created above
3. Update the milestone Issue as phases are completed (check off tasks).

### Phase Issues (Sub-Issues)

When phases are defined in the roadmap:

1. **Create an Issue for each phase** with:
   - Title: `Phase N: Phase Name`
   - Body: Phase goal, requirements (REQ-IDs), success criteria
   - Labels: `phase`
   - Assigned to the parent milestone's GitHub Milestone
   - Reference the milestone tracking Issue (e.g., "Part of #XX")
2. When a phase PR is merged, **close the phase Issue** (use `Closes #N` in the PR body).
3. If requirements change (e.g., scope deferred), **update the affected Issues** to reflect the change.

### Labels

Ensure these labels exist in the repository:

| Label | Description | Color |
|-------|-------------|-------|
| `milestone` | Milestone tracking issue | `#0E8A16` |
| `phase` | Phase implementation issue | `#1D76DB` |

## PR Workflow

### Creating PRs

- Always include in PR body:
  - Summary of changes
  - Requirement IDs addressed (e.g., `SET-03`)
  - `Closes #N` for the related phase Issue
- Request Copilot code review automatically.

### Addressing Reviews

- Fix all review comments before merging.
- Push fixes as additional commits (they'll be squashed on merge).

### Merging

- Use **squash merge** (via `gh pr merge --squash --delete-branch`).
- After merge, sync local: `git checkout main && git reset --hard origin/main`.

## Language

- **Chat/conversation**: Japanese
- **Code, commits, PRs, Issues**: English
