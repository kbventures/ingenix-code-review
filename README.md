# Code Review Kit for Claude Code

AI writes code fast. The mistakes pile up quietly. This kit is the review system we run on client apps at [Ingenix Online](https://ingenix.online), free to use.

It does three jobs:

1. **Checks every change before it ships.** It finds bugs and checks the change against 13 architecture rules.
2. **Checks the whole app once a week.** It reads every file, double-checks each problem so you don't chase false alarms, and tracks what got fixed since last week.
3. **Tells you how your app should be structured.** It names the structure you have, flags "god files" (one file doing far too much), and recommends a simple structure for each part of your app.

Full write-up: [How We Review AI-Written Code](https://ingenix.online/blog/how-we-review-ai-written-code).

## Install

In Claude Code, run:

```
/plugin marketplace add kbventures/ingenix-code-review
/plugin install code-review-kit@ingenix
```

## Use

| When | Run |
|---|---|
| You finished a feature or fix | `/code-review-kit:pr-review` |
| Weekly health check of the whole app | `/code-review-kit:full-review-weekly` |
| "Where should this new code go?" | `/code-review-kit:modular-monolith-arch` |
| One big file needs splitting | `/code-review-kit:refactor-slicer` |

Reports are saved under `code-review/` in your project.

## The 13 rules

The reviews check code against 13 architecture rules — see [`skills/architecture-rules/SKILL.md`](skills/architecture-rules/SKILL.md). Why each rule exists: [How to Stop AI from Vibe-Coding Your Next.js App into a Mess](https://ingenix.online/blog/stop-ai-vibe-coding-nextjs-architecture).

If your project's `CLAUDE.md` has its own "Architecture Rules" section, the reviews use yours instead. To adopt ours, copy the list into your `CLAUDE.md`.

## What's inside

**Main reviews**
- `pr-review` — every change: bug pass, architecture pass, specialist passes, one report, writes missing tests
- `full-review-weekly` — whole app: tool checks, every file, verify pass, specialists, follow-up, pattern tally, architecture fit

**Passes they call**
- `bug-review` — bugs, regressions, test gaps
- `arch-review` — the 13 rules
- `architecture-rules` — the rule list
- `test-fix` — writes missing tests, fixes broken ones
- `security-checklist` — secrets, input validation, auth, XSS, CSRF, rate limits
- `error-contract-auditor`, `test-gap-auditor`, `typescript-auditor`
- `api-contract-auditor`, `json-boundary-auditor`, `nullability-auditor`, `db-mapper-auditor`
- `db-schema-auditor`, `ddd-auditor`, `dead-code-and-drift-auditor`
- `modular-monolith-arch`, `refactor-slicer`

Built for TypeScript / Next.js apps with a SQL database. Most checks work on any JavaScript or TypeScript web app.

## Want it run on your app?

We run the full review on client apps and walk you through the report: what's broken, what's risky, and the first three fixes that matter. [Book a free discovery call](https://ingenixonline.zohobookings.com/#/4769814000000061008).

## License

MIT — see [LICENSE](LICENSE). Two skills are adapted from other MIT projects — see [NOTICE.md](NOTICE.md).
