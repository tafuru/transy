<!-- GSD Configuration — managed by get-shit-done installer -->
# Instructions for GSD

- Use the get-shit-done skill when the user asks for GSD or uses a `gsd-*` command.
- Treat `/gsd-...` or `gsd-...` as command invocations and load the matching file from `.github/skills/gsd-*`.
- When a command says to spawn a subagent, prefer a matching custom agent from `.github/agents`.
- Do not apply GSD workflows unless the user explicitly asks for them.
- After completing any `gsd-*` command (or any deliverable it triggers: feature, bug fix, tests, docs, etc.), ALWAYS: (1) offer the user the next step by prompting via `ask_user`; repeat this feedback loop until the user explicitly indicates they are done.
<!-- /GSD Configuration -->

# Development Rules

**IMPORTANT:** Read and follow `.github/DEVELOPMENT.md` for all development workflow rules. Key rules:

- **Never push directly to `main`** — all changes must go through a Pull Request.
- **Create GitHub Issues** for milestones and phases when using GSD workflows.
- **Squash merge PRs** and sync local main with `git reset --hard origin/main`.
- **Language**: Japanese for chat, English for code/commits/PRs/Issues.
