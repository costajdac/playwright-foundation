# {{PLAN_TITLE}}

{{#IF_DIFF_MODE}}
**Branch:** {{BRANCH_NAME}}
**Compared against:** {{BASE_BRANCH}}
{{/IF_DIFF_MODE}}
{{#IF_BASELINE_MODE}}
**Type:** Baseline (no diff — covers current app functionality)
{{/IF_BASELINE_MODE}}
**Generated:** {{DATE}}
**Test cases:** {{INCLUDED_COUNT}} of {{TOTAL_CANDIDATE_COUNT}} found (limit: {{MAX_CASES}})

Short summary of what changed and the overall testing focus for this branch
(2-3 sentences, plain language — not a restated diff). For baseline mode,
summarize what area of the app this plan covers instead.

---

## P0 — Critical

### [P0] {{Test case title}}

**Description:** {{One to two sentences — what this tests and why it matters.}}

**Steps to Reproduce:**
1. {{Step}}
2. {{Step}}
3. {{Step}}

**Expected Result:** {{What should happen if this works correctly.}}

---

## P1 — High

### [P1] {{Test case title}}

**Description:** {{One to two sentences.}}

**Steps to Reproduce:**
1. {{Step}}
2. {{Step}}

**Expected Result:** {{Expected outcome.}}

---

## P2 — Medium/Low

### [P2] {{Test case title}}

**Description:** {{One to two sentences.}}

**Steps to Reproduce:**
1. {{Step}}
2. {{Step}}

**Expected Result:** {{Expected outcome.}}

---

## Already covered (not retested here)

- {{Existing automated test or prior test-plan entry that already covers a
  related change — briefly note why no new case was needed.}}

## Not included this round

Cases identified but left out due to the {{MAX_CASES}}-case limit, listed by
title only, lowest priority first:

- [{{Priority}}] {{Title}}
- [{{Priority}}] {{Title}}

{{IF_NONE_OMITTED: "None — every identified case fit within the limit."}}

## Notes / unclear impact

- {{Anything where business/user impact couldn't be confidently determined
  from the code alone — flagged rather than guessed at.}}