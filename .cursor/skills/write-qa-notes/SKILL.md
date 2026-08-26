---
name: write-qa-notes
description: Use this skill when writing or filling in the QA Notes field (customfield_11232) of a Jira ticket — the note manual QA reads to understand a change. Triggers include "write QA notes", "fill in QA notes", "заполни QA Notes", "напиши QA ноутс", preparing a ticket for handoff to QA, or drafting QA Notes before opening a PR. Not for writing unit tests — use the normal test workflows for those.
---

# Write QA Notes

QA Notes tell manual QA, fast: **what changed**, **where to check**, **how to check**, and **what result to expect**. Whatever you produce here — especially an AI draft — is a **draft only**. The developer MUST read it and correct it before handing the ticket to QA.

The field is `customfield_11232` and requires ADF (see AGENTS.md → External Systems → Jira).

Remember what QA actually holds in their hands: this repository ships a library, not an app. QA tests the SDK through the app that embeds it, with real cards. Name the user-visible surface — the screen, the flow, the card operation — not the internal type you edited.

## Language

Write QA Notes in **Russian** — that's the language QA reads. When drafting with AI, ask for Russian output directly: don't write an English draft and translate it, and don't duplicate the same content in both Russian and English.

## When no QA is needed

If the change can't affect the shipped SDK's runtime behaviour — pure docs/comments, dead-code removal, agent configuration, SwiftUI previews (nothing but Xcode ever instantiates them), or CI/build/release tooling that never ships in the binary — the **entire** field is the team's standard one-line shorthand «Задача техническая, тестирование не требуется.» and nothing else. Don't append scenarios after it and don't invent fake ones.

The test is reachability, not whether the code ends up in the binary. Manual QA can only check what a user can reach, so anything they can't reach is noise on their queue.

Everything below applies only to changes that can actually alter how the SDK behaves at runtime.

## Structure

Keep it to about one screen. Use only the sections that carry real information — drop a section rather than pad it. The Russian headings below are the literal headings to paste into the (Russian) QA Notes output.

### 1. Что изменилось и что проверить (required)

- 1–3 sentences describing the change. No abstract phrases like «fixed logic» / «improved behavior».
- Name the affected area — screens, card operations, firmware versions — when it matters.
- Make clear where QA should focus. Never «test everything».
- Call out where reality diverged from the task spec.
- List what else landed in this ticket (parallel work in the same epic, a bug-fix folded in).
- List what was NOT done and moved to another ticket — with a link.
- If the work is split across stories, say explicitly what NOT to test here and where it is tested instead (with a link).
- **Do not write test cases** — QA writes those themselves.

### 2. Как тестировать (only if there are specifics)

- What is needed to reproduce at all: card type, firmware (COS) version, number of cards for backup flows, wallet state.
- Environment specifics, and which app build to take the SDK change in.
- Whether the change is reachable only on some firmware versions — the SDK gates features by `FirmwareVersion`, and QA needs to know which cards can even hit the new path.

### 3. Что НЕ надо тестировать / вне скоупа (only if there are nuances)

- Areas that were NOT touched, so QA doesn't have to guess whether neighbouring flows need checking.

## Quality bar

QA Notes must be: short (ideally ≤ one screen), in Russian, concrete (no filler or generic phrases), verifiable (each point can actually be checked), current (match what was really done), and useful to QA — not a retelling of the PR or ticket.

## Remove before handing to QA

- Repeats.
- Over-long explanations.
- Invented scenarios.
- Wrong screen / command / API names.
- Placeholders like `[insert test data here]`.
- Hedging words: «maybe», «probably», «if needed».
- Extra technical detail that doesn't help testing.

## Developer checklist before handoff

- [ ] QA Notes describe the real change.
- [ ] Notes aren't too long.
- [ ] There are clear steps to check.
- [ ] Expected result is present.
- [ ] Required cards, firmware versions and environment are stated.
- [ ] Regression areas are named, or it says regression isn't expected.
- [ ] AI cruft is removed.
