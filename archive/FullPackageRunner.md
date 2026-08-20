# FULL PACKAGE — Appraisal Analysis Runner

*Version 2.3, 08/04/2026. Self-contained. Runs the market conditions analysis, the SPARK-style market charts, the neighborhood and market analysis, and the full adjustment support tool from one data drop. No other file is required. Every rule, tolerance, formula and format below was verified end to end on a live assignment before this version was written. The example figures come from that run. The property is not identified and no client, lender or borrower information appears anywhere in this file.*

---

# PART ONE — THE COMMAND

Attach the four CSVs. Paste this block and fill the lines.

```
RUN FULL PACKAGE per 260804-FullPackageRunner.md

Address:        [street, city, state, zip]
Effective Date: [MM/DD/YYYY]
Loan Type:      [VA / FHA / Conventional / Other]
Cost Source:    [none / DwellingCost / Marshall & Swift / other]
License Line:   [e.g. CertRes####### Expires MM/DD/YYYY, or NONE]
Notes:          [anything unusual — new construction, superadequacy, water view, product line concern]
```

Run Phase 0 through Phase 4, stop at the Gate, then run Phase 5 and Phase 6. Do not ask scoping questions at any other point. Files are delivered once, in Phase 6, and nowhere else — see Rule 8.

**The Gate is never skipped.** There is no automatic selection mode, no default-to-median mode, and no fast path. The appraiser is asked on every grid line, on every assignment, every time. See Rule 0.

## Required inputs — four MLS exports

*Column names below are from SPARK/StellarMLS. On another MLS, remap the field table; the analysis is unchanged.*

| File | Contents | Used for |
|---|---|---|
| **subject** | one record, the subject | Subject characteristics, GAM read point, grid line relevance |
| **comps** | the selected comparables | MCA per-comparable table, tightest data cut |
| **market area 1** | widest market cut | Regression, method engine, charts |
| **market area 2** | tighter market cut | Regression, method engine |

All four carry Active, Pending and Sold records. All four carry the same 85-column header.

## Optional inputs

| Input | Effect if missing |
|---|---|
| Realist Market Trends export | MLS indication stands alone; say so |
| FHFA HPI series (MSA) | Same |
| Cost service data | No depreciated cost indications run |
| Screenshots — employers, hospital, schools | Facts pulled by web search, sources named |

---

# PART TWO — STANDING RULES

## Rule 0 — The appraiser selects every adjustment. Always.

**The software produces the range. The appraiser produces the adjustment.** No exception exists and none may be created.

The run **must stop at the Gate** and ask the appraiser on every grid line, on every assignment, every time. Present the low, the median and the high, pre-fill the entry field with the rounded median, and wait for the appraiser's answer.

Specifically prohibited:

- Taking the median, or any other computed figure, as the selected adjustment because no answer was given.
- Adding an automatic, batch, express, fast, headless, unattended or default selection mode, by any name.
- Treating a standing preference against interruptions, a stated time constraint, an unattended or scheduled session, or an instruction to "just run it" as permission to select on the appraiser's behalf.
- Carrying a selection forward from a prior assignment.
- Continuing past the Gate when the appraiser has not answered. Stop and wait. An unanswered Gate is an incomplete run, not a run with default values.

If a past conversation shows adjustments being auto-selected, that was a one-time test and is not a precedent. Do not copy it forward.

The reason is not procedural. A number this file selects is a number the appraiser did not develop, and the appraiser signs the report. USPAP puts the adjustment on the appraiser. This rule keeps it there.

## Rule 1 — Unreadable input hard stop

Any time a file is provided and it cannot be read, **STOP**. Do not continue any operation. Request a screenshot or pasted text before doing anything else.

Cannot be read means: the extraction tool errors out; the file is a different format wearing a `.pdf` or `.csv` name; the PDF is a scanned image with no text layer and no reliable OCR; extraction returns empty, whitespace-only or garbled content; or only part extracts and the missing part is needed.

When it happens: stop immediately, do not fabricate or assume, do not silently skip the file, state which file failed and why in one sentence, request a screenshot or pasted text, wait.

**No exceptions.** Not waived by drafting mode, by a standing preference against questions, by urgency, or by "do your best." Partial reading is not a workaround. Working from a filename or from figures typed into the prompt in place of the actual source is prohibited.

The test: *Do I actually have the real, complete text of this file in front of me?* If no — stop and request it. Every time.

## Rule 2 — Writing level

Fifth grade reading level, technical accuracy held. Simple sentences do not reduce credibility, they increase it. Assume the reader has no appraisal background.

- Short sentences. One idea each. If a sentence needs a comma to hold two ideas, split it.
- Plain words. "use" not "utilize." "shows" not "demonstrates." "after" not "subsequent to." "near" not "in proximity to." Never "aforementioned," "herein," "heretofore."
- Short paragraphs, three to five sentences.
- Active voice. Lead with the conclusion, support it second.

UAD ratings, methodology, and reconciliation language stay technically accurate. Standard terms stay. Plain language is not casual language.

The test: could a motivated 10-year-old read this and get the main point?

## Rule 3 — Prohibited and required wording

- The word **"average" is prohibited** in commentary.
- **"indicated," never "recommended."**
- **"resolution threshold," never "noise floor."**
- **"three months," never "90 days,"** in report narrative prose. The MCA document is the exception — it uses "90 days" in both the intro paragraph and the table reason text, because that is the established exhibit wording.
- No subjective descriptors.

## Rule 4 — Formatting

- **Arial 10 pt throughout, including the chart PNGs.** Where Arial is unavailable to a rendering engine, use Liberation Sans — it is metrically identical.
- 0.5 inch (720 DXA) margins, US Letter.
- Justified body text. Bold blue (`1F4E79`) section headings.
- Prose paragraphs, never bullets, unless bullets are requested.
- Table data may drop to 9 pt, reason rows to 9 pt italic, for fit.
- Header shading `F2F2F2`, thin top borders `BFBFBF`. `ShadingType.CLEAR`, never `SOLID`.
- Render every Word document to PDF and look at it before presenting.

## Rule 5 — Identity

**No appraiser name anywhere in a work file document.** Where a license number is required, use only the License Line from the command block. If it says NONE, omit it.

## Rule 6 — File naming

`YYMMDD-[Address][Description].ext` — two-digit year, zero-padded month and day, hyphen, PascalCase description, no spaces. Save to `/mnt/user-data/outputs/`. Every Word document intended for TOTAL paste-in ships with a plain text twin.

## Rule 7 — Nothing carries over

No trendline value, rate, adjustment or method result carries from a prior report. Every figure is read from this assignment's source.

## Rule 8 — One delivery, at the end, each file exactly once

**Nothing is delivered to the appraiser until Phase 6.** Every phase writes its output to `/mnt/user-data/outputs/` and says nothing more about it. No file card, no attachment, no zip, no "here's the chart so far" — at any point before Phase 6.

Specifically prohibited:

- Delivering a file in the phase that built it. Building and delivering are separate steps that happen at separate times.
- Zipping the charts anywhere except Phase 6. The zip is created once, from the finished PNG folder, at delivery.
- Re-delivering a file that was already delivered. If a file was corrected, deliver the corrected version once and say it replaces the earlier one — do not send both.
- Delivering anything at the Gate. The Gate is a question, not a handoff.
- Delivering a preview, draft or intermediate copy "so the appraiser can look while it runs."

Phase 6 is the only place a file leaves the workspace. Count the deliverables before sending: five entries, one send. If a file appears twice in that list, the run has a bug — fix the run, do not send the duplicate.

**Where files go.** If a folder on the appraiser's machine is connected, write there directly and skip file cards entirely. Otherwise send the set once, together, in a single Phase 6 message.

---

# PART THREE — THE RUN

## PHASE 0 — Intake and validation

1. List every attached file and state what each is being read as.
2. Apply Rule 1. Any unreadable file stops the run.
3. Confirm the effective date. Without it the 90-day rule and the trendline value cannot be computed. Stop and ask.
4. Install and confirm:

```bash
pip install pygam statsmodels --break-system-packages
```

`numpy`, `pandas`, `scipy`, `scikit-learn`, `matplotlib`, `openpyxl` are present. `pygam` and `statsmodels` are not and must be installed each session. Confirm both import before running anything.

5. Report intake in one short block: file count, record count and status mix per file, date range of closed sales, any file that failed.

---

## PHASE 1 — Shared data build

Runs **once**. Feeds every later phase. Do not rebuild the frame.

### Field mapping

| Field | MLS column | | Field | MLS column |
|---|---|---|---|---|
| price | Close Price | | conc | Seller Paid Buyer Costs |
| list_price | List Price | | terms | Sold Terms |
| close | Close Date | | special | Special Sale Provision(s) |
| contract | Contract Date | | status | Status |
| onmkt | On Market Date | | waterview | Water View Y/N |
| statchg | Status Change Timestamp | | waterfront | Water Frontage Y/N |
| gla | Heated Area | | subdiv | Legal Subdivision Name |
| lot | Lot Size Square Footage | | builder | Builder Name |
| yb | Year Built | | ownership | Ownership |
| gar / carport | Garage Spaces / Carport Spaces | | cdom / adom | CDOM / ADOM |
| beds / fb / hb | Beds / Full Baths / Half Baths | | zip / city | Zip / City |
| pool | Pool Private Y/N | | | |

### Date parsing — per column, not per file

**SPARK mixes date formats inside a single file.** Verified: `Close Date` and `Contract Date` come as `2026-07-30`; `On Market Date` comes as `06/09/2026`; `Status Change Timestamp` comes as `2026-07-30 14:18:31`. Strip any trailing time, then try `%Y-%m-%d` and fall back to `%m/%d/%Y`, **column by column**. A single format assumption silently drops half the dates to null.

### The two-frame rule

The same CSVs serve two different purposes with two different filters. Build both frames and keep them separate.

| Frame | Filter | Used by |
|---|---|---|
| **All-status** | Sold + Active + Pending | Charts, inventory, absorption, supply, market analysis |
| **Closed-only** | Sold only | Every regression, every paired sale, every adjustment |

"Closed sales only" is a **derivation** rule, not a description of the export. The actives and pendings are in the file and they are needed. Do not read the derivation rule as permission to discard them at intake.

### Nesting

The cuts are **nested, not disjoint**. Verify by MLS number, every run, printing the result: comps inside market area 2 inside market area 1. Deduplicate on MLS keeping the innermost cut label. Sort so nested membership is contiguous — comps first, then each wider cut's additions. Every dataset must be a contiguous row range; the live Excel formulas in Phase 5C depend on it.

### Transactional screens, in order

1. **Property rights.** Confirm fee simple. Remove leasehold.
2. **Financing.** Confirm cash equivalent terms. Conventional, FHA, VA and cash all qualify.
3. **Conditions of sale.** Remove short sales and REO before any calculation.
4. **Seller concessions.** Deduct each reported concession from its own sale price to give `net`. **Comparables only.** Never carry a concession deduction into the subject value conclusion — that is double counting.
5. **Market conditions.** Phase 2.

Records with a reported lot size of zero are excluded from analyses using site area only, not from the frame. State the count.

### Derived fields

`net = price − conc` · `psf = net / gla` · `age = effective year − year built` · `days = contract date − earliest contract date` · `baths = fb + 0.5 × hb` · `lot_ok = lot > 0` · `newconst = age ≤ 1`

### Subject record

Read the subject CSV into a separate dictionary: address, GLA, lot, year built, age, beds, full baths, half baths, garage, carport, pool, water view, subdivision, builder, model, list price, status. **The subject is the read point for every GAM marginal rate and the basis for the grid line relevance check.** Print it.

Output: two frames, the row range of each cut, a stated exclusion count. Three sentences, not a table dump.

---

## PHASE 2 — Market conditions (run once, used twice)

The regression runs one time. Its result populates the MCA document and picker line 1. They can never disagree because they are the same number.

### The regressions

Regress price per square foot on contract date, and net price on contract date, **within each cut and pooled**. Report monthly rate, base, R-squared and t statistic for each. With three cuts that is 8 runs.

### The threshold

**Resolution threshold: one percent per month.** A rate below it is not a trend. Also test whether the sign is stable across cuts. A rate that reverses direction between cuts is an absent trend, not a weak one.

Do not write "no rate was statistically significant" unless every test was checked and every one failed. A pooled regression can clear a bar the individual cuts do not.

Standard no-adjustment wording:

> The indicated rates all fell below one percent per month, which is the resolution threshold applied in this analysis. Below that threshold a measured change cannot be separated from ordinary variation between sales. The rates also reversed direction between data sets.

### Reconciliation

Price per square foot is the primary indication — it controls for home size, and raw price in a builder market measures product mix, not appreciation. MLS carries the most weight, then Realist Market Trends, then FHFA HPI. If only MLS is provided, say so and let it stand alone.

### THE RATE GATE — do not skip this

```
trend_supported = abs(rate) >= 1.0% per month AND sign is stable across cuts
rate_applied    = rate if trend_supported else 0.0
```

**Every per-comparable calculation uses `rate_applied`, never `rate`.**

Without this gate the cumulative math manufactures adjustments from a rate the analysis has already rejected. In the verification run a −0.478%/month rate — failed at the threshold, sign-reversed between cuts — still produced −$6,000 to −$7,000 adjustments on three comparables, because 3.4 months of a sub-threshold rate crosses the 1% band. Report the reconciled rate for the record; apply the gated rate to the comps.

### Per comparable

- Months between contract date and effective date.
- Trendline value on contract date = (trendline value at effective date) ÷ (1 + rate_applied × months).
- Percent = (effective-date value − contract-date value) ÷ contract-date value.
- Adjustment = percent × sale price, rounded to nearest $500.
- $0 where the 90-day rule or the ±1% stable band applies.

Trendline value at the effective date = the pooled price-per-square-foot fit evaluated at the effective date, multiplied by the market median GLA.

**Do not build the MCA document yet.** Hold the table. The decision is Gate item 1.

Carry `days` as a control variable inside every multivariate model in Phase 4 regardless of the outcome here.

---

## PHASE 3 — Market charts and neighborhood analysis

### 3A — The eight SPARK-style charts

Built from the **all-status** frame. Arial 10 pt. One PNG each, 11.0 × 5.4 inches at 200 dpi.

**Write the eight PNGs to a `charts/` folder in the workspace and stop there.** Do not zip them here. Do not deliver them here. Do not show them in chat. Per Rule 8 they leave in Phase 6, zipped once, and nowhere else. Report only a one-line count when the eight are written.

| # | Chart | Source | Regression line? |
|---|---|---|---|
| 1 | Competing Med Sale $ | closed price by close date | yes |
| 2 | Competing Med Sale $/SqFt | price ÷ GLA | yes |
| 3 | Competing Housing Supply (Months of) | daily inventory ÷ absorption | yes |
| 4 | Competing Med DOM (Sales) | CDOM, falling back to ADOM | yes |
| 5 | Competing Concession % | share of sales carrying a concession | yes |
| 6 | Competing Med Contribution % | concession ÷ price | no |
| 7 | Competing Absorption (Sales/Month) | trailing sales rate | no |
| 8 | Competing # Sales | count by day | no |

**Layout, matching SPARK:** blue filled dot then the bold series label; `Total: X` line; `y = mx + b` line; `Simple Regression Per Month: +X%` with the value in green for positive and red for negative; centered bold `Date Range: M/D/YYYY - M/D/YYYY` title; 45° rotated monthly date ticks; no gridlines; left and bottom spines only; markers `#5B9BD5` at ~52 pt, alpha 0.92, no edge; a gray striped data panel on the right carrying the monthly values. Y-axis formatted per metric — dollars, dollars with cents, percent, or count.

Measure the label text width with the renderer before placing the colored percent value. A fixed offset collides at some label lengths.

Plot **one dot per sale per day**, including the days that read zero. That is what makes them look like SPARK charts.

**Inventory reconstruction.** A listing is active on day D when `On Market Date <= D` and it had not gone under contract or closed by D. **Absorption uses a trailing 90-day window, not trailing 12 months**, and the series starts 90 days after the first close date. The export carries only about 12 months of closed sales, so a 12-month lookback has no history at the left edge — in the verification run it produced a false 108-month supply spike that flattened the entire chart. A 90-day window fills in three months and reads clean.

**State the basis.** A SPARK snapshot export carries Active, Pending and Sold only. Listings that expired, withdrew or cancelled are absent, so reconstructed inventory on the earliest months runs below SPARK's own figure. Note it rather than implying an exact match.

### 3B — Neighborhood and market analysis

Independent of the adjustment work, so it is built here rather than in Phase 5. Built, not delivered — it waits for Phase 6 with everything else.

**Scope rule.** No sales comparison content. No comparable selection, no adjustments, no grid discussion.

**Six sections, in order:**

**1. Neighborhood Description.** The subject's own community only. **No boundaries** — they are on page 1 of the report. No competing neighborhoods here.

**2. Market Description.** The market area the neighborhood sits in, including similar competing communities within reasonable proximity. This is the only section where other neighborhoods appear. Reasonable means what a typical buyer would cross-shop.

**3. Employment.** Employment centers and major employers with distances.

**4. Support Services.** Name the nearest hospital and give the distance. Schools, fire and police need general proximity only.

**5. Shopping, Dining, Entertainment.** General.

**6. Market Trends.** The neighborhood compared to the subject market and the regional market. **Use the Phase 2 rate.** Do not compute a second one. Include days on market, months of supply and its direction, absorption, active and pending counts, and the concession share. Where builders are paying concessions instead of cutting price, say so — it is why a price trend reads flat while supply climbs.

Facts not in the CSVs come from web search or appraiser screenshots. Name the source of any figure not from the MLS data.

**Output.** Write the .docx plus a .txt twin to the outputs folder. Arial 10–12 pt. Fit one page if reasonable, two maximum, floor 10 pt. Tighten paragraph spacing before dropping font size. Do not paste the text into chat and do not deliver the file — per Rule 8 it goes out in Phase 6.

---

## PHASE 4 — The method engine

Every method runs against every cut. Record feature, method, tier, dataset, data points and result for every run including failures. That record is the work file. Expect roughly 400 analyses on a normal assignment.

### Tier A — controlled. Sets the acceptance window.

- Generalized additive model, `lam` 0.6 and 8.0
- Multivariate ordinary least squares
- Robust least squares, Huber M-estimator
- Least absolute deviation (median quantile regression)
- Modified quantile regression — nine quantiles 0.1 to 0.9, best pseudo R-squared reported
- Theil-Sen regression, multivariate
- Least median of squares, random elemental subsets
- True paired sales, average and median
- Adjusted paired sales, average and median

Run each cut twice: once on the `lot_ok` subset with site area included, once on the full cut with site area dropped. Label the second `(no site)`.

### Tier B — uncontrolled. Reported, never sets the window.

Six single-variable regressions, grouped data average and median under two group definitions, sensitivity analysis.

### GAM configuration

Constrain living area and site size monotonic increasing, age monotonic decreasing. **Read the marginal rate at the subject's own characteristics**, not the market median — set every predictor to the subject's value, clamped to observed support, then take the central difference on the feature being measured. Skip below 25 observations.

### Paired sales tolerances

Living area and site size within 5%. Full bath, half bath, garage, carport, pool, view and water exact. Bedrooms identical or both above three. Age within 2 years. The measured feature must NOT match. Remove outlying pairs by the interquartile rule before taking the average and median.

### Depreciated cost

Not run without a cost source. No cost figure is estimated or reconstructed from memory. When used, produce a separate source document naming the service, edition, quality and condition conversion, and unit costs.

### Screen 1 — direction

Living area, site size, garage, pool, bedroom and bath cannot carry negative contributory value. Age cannot carry positive value. A result pointing the wrong way is a method artifact. Remove it.

### Screen 2 — the window

Median of the surviving **Tier A** results ± two robust deviations, computed from the median absolute deviation scaled by 1.4826. Iterate up to four passes, never below three retained. Fall back to standard deviation only when MAD is zero.

Test every result, both tiers, against that window. Retained results stay; excluded results stay listed by name with the reason. If fewer than two method types survive, widen to the full Tier A range.

### Reliability rating

High: 6+ method types and 25+ sales carrying the feature. Moderate: 4+ types and 15+. Low: 2+ types, or fewer than 10 sales carry the feature regardless of type count. Not supported: fewer than 2 types.

### Grid line relevance — run this before writing anything

For each feature, count how many comparables differ from the subject. **A feature matched across the entire comp set needs no adjustment and is removed from the assignment.** In the verification run this removed full baths, half baths, garage and pool — four of the ten lines, and the four thinnest. Report each removed line and why.

### Known traps — check every one

**New construction riding on the age variable.** A single linear age term blends a one-time new-construction step into a per-year rate and amortizes it across the whole age range. Test four ways: all sales with one age term; all sales plus a new-construction flag; resale only at age 2+; resale only at age 4+. In the verification run, 34% new construction, the rate ran $6,483/yr blended, split to a **$33,355 one-time step plus $4,226/yr**, and collapsed to $1,987/yr on age 4+ resales — a 69% drop. Measure and report the step separately. When the subject is new construction and comps are not, this line moves the value.

**A variable standing in for a product line.** A feature concentrated in one subdivision or floor plan measures the product line. In the verification run half baths appeared in 11 of 64 sales across 3 subdivisions and every single method returned negative. Screen 1 killed the line, correctly. When a result is directionally impossible and every method agrees, look at where the feature lives before assuming the methods are wrong.

**Uncontrolled methods inflating correlated features.** Bedroom, bath and living area move together. Verified: single-variable bedroom returned $41,782 against a controlled $5,300. This is why Tier B never sets the window.

**Assuming the cuts are disjoint.** They are nested. Verify by MLS number.

**Marginal versus gross rate.** The living area adjustment sits well below the market's median price per square foot — verified at $89.13 marginal against $190.49 gross, 47%. This is correct: the gross rate carries land, site improvements and the fixed cost of the house. State the relationship before a reviewer asks.

**Thin features.** Under about ten sales carrying the feature, report the range, rate it Low, and say a second source is needed. Do not narrow a range the data cannot narrow.

Report per feature: full range, narrowed range, most probable value, retained count, method type count, reliability, and whether the grid line is relevant.

---

## THE GATE — one stop, all decisions

**Gate item 1 — market conditions.** Present the Phase 2 finding, the reconciled rate, whether the gate passed, and the per-comparable table. The appraiser confirms adjust or no adjustment. Drives the MCA document and picker line 1.

**Gate items 2 through 21 — the picker.** Interactive selector, one grid line at a time, in this order:

market conditions, location, site, view, design, quality, actual age, condition, bedroom, bathroom, gross living area, basement gross living area, rooms below grade, heating and cooling, energy efficient items, garage spaces, carport spaces, porches patios and decks, pool spa and other, subdivision, builder.

Every line appears whether or not the data supported it. Four choices per line — low, median, high, appraiser entry — with the entry field pre-filled to the rounded median. Running list, Back, No adjustment, Start over. Status badge per line: Supported, Low reliability, Not supported, Not relevant (subject and all comps match), or No data.

**The software produces the range. The appraiser produces the adjustment.** Per Rule 0, this stop is mandatory and cannot be skipped, defaulted or automated. Every line waits for an answer. A line the appraiser has not answered is not finished, and Phase 5 does not begin until all of them are.

### Picker UI — required behavior

The appraiser's own figure is the primary path, not the fallback. Build the entry field so it behaves like a field.

**The advance rule.** The picker advances to the next grid line on exactly two events: a click on the explicit **Next** button, or **Enter** pressed inside the entry field. Nothing else advances it. Not a click on a card, not focus, not blur, not a value change, not an arrow key, not a click anywhere in the entry option.

**The bubbling rule.** If the entry field sits inside a clickable card, a click on the field bubbles to the card, the card's handler fires, and the line is selected and skipped before a single character can be typed. This is the failure to design against.

Fix it in both directions, not one:

```js
// 1. the input swallows its own events
['click','mousedown','pointerdown','touchstart','keydown'].forEach(evt =>
  input.addEventListener(evt, e => e.stopPropagation()));

// 2. the parent refuses events that originated in a field, even if one slips through
card.addEventListener('click', e => {
  if (e.target.closest('input, textarea, select, button, label')) return;
  selectOption(card);              // does NOT advance - see the advance rule
});
```

Better still, **do not nest the input inside the clickable card at all.** Put the low, median and high choices in one row and the entry field in its own container, siblings rather than parent and child. Bubbling cannot cause a bug that has no path to travel.

**Field behavior.** `type="text"` with `inputmode="decimal"`, not `type="number"` — number spinners hijack arrow keys and scroll, and drop leading zeros and partial entries mid-typing. Pre-fill with the rounded median. Select the whole value on focus so typing replaces it. Accept `$`, commas, decimals and a leading minus, and strip them on read. Never re-format or re-validate on every keystroke; validate on Enter or on Next.

**Selecting low, median or high writes that number into the entry field.** It does not advance and it does not lock. The appraiser can click median and then edit it to a round number — that is the intended workflow, and it is the reason the field exists.

**Test before shipping the picker.** Click into the entry field on the first grid line, type a four digit number, and confirm two things: the characters appear, and the line does not change. If either fails the picker is broken. A picker that will not accept a typed number violates Rule 0 in practice regardless of what the code intends, because the appraiser cannot enter a figure the software did not produce.

On completion send the selections back through `sendPrompt` and continue to Phase 5 without further questions.

---

## PHASE 5 — Build the documents

No new analysis. No new questions.

### 5A — Market conditions (time) adjustment document — ONE PAGE

The assembled TOTAL/Synapse exhibit holds an intro, a chart, a table, a NOTE and a source line. **This build produces everything except the chart.** TOTAL places the chart.

**Hold it to one page.** Four intro paragraphs, heading, trendline line, table, NOTE, source line. Nothing else. Do not add data commentary, method lists, regression statistics, cut descriptions or reliability notes — that material belongs in the workbook and the adjustment comments, not here. If it runs to two pages, cut prose, not table rows.

**1. Four intro paragraphs, justified.**

- *Paragraph 1* — what was tested and where. The community, the market type, that all relevant closed sales over the past 12 months were studied, that sale price and price per square foot were both reviewed, that a simple linear regression trendline was run.
- *Paragraph 2* — why raw sale price is unreliable here. Quote the actual monthly median swing and name the cause: different product types and phases releasing at different times. "The price slope is measuring what sold, not appreciation."
- *Paragraph 3* — why price per square foot is the better measure, the actual range it held, and the finding. "The trendline rate falls within normal data noise." Add the sign reversal if there was one.
- *Paragraph 4* — the conclusion and the two rules. Rounding to the nearest $500, the 90-day rule, the ±1% stable band, that every comparable met one of the two conditions, and "The below chart and data (based on the effective date of MM/DD/YYYY) show the market trend and adjustment details."

Match the reasoning to the conclusion. **Do NOT insert a chart, a chart image, or a placeholder of any kind.** No gap, no bracketed note, nothing.

**2. Heading and trendline line.**

- Bold blue heading: `Comparable Market Conditions (Time) Adjustments`
- Bold line: `Trendline Value as of the Effective Date: $XXX,XXX`
- When no trend is supported the line reads exactly: `Trendline Value as of the Effective Date: Flat — No Time Trend Supported`

**3. The table — two variants, chosen by the finding.**

*No trend supported — five columns:* Comparable, Contract Date, Sale Date, Sale Price, Adjustment. Trendline Value and Percent are **dropped**, because a flat market has no per-comparable trendline value to show and every percent is zero. Printing zero columns invites a question that has no useful answer.

*Trend supported — seven columns:* Comparable, Contract Date, Sale Date, Sale Price, Trendline Value, Adjustment, Percent.

Either way: header row shaded `F2F2F2` with a thin bottom border, one data row per comparable with a thin top border, and directly below it an indented italic reason row spanning the full width.

Reason text, exactly:
- `No Adjustment - Contracted Within 90 Days of the Effective Date`
- `No Adjustment - Change Within Stable Band (<1%), No Time Adjustment Warranted`
- Adjusted comps show the figure in the data row; no reason row needed.

**4. NOTE.** The Trendline Value for each comparable is the trendline value on that comparable's contract date; the percent is the change from there to the effective date. When the conclusion is no adjustment, state that the change fell within the stable band for every comparable so each adjustment is $0.

**5. Source line**, exactly: `* May include properties that were considered but not utilized in the sales grid.`

The per-comparable figures here are exhibit data and are expected to be specific and to match the grid. The report narrative references this document and does not restate the figures.

### 5B — Sales comparison adjustment comments

Word plus a plain text twin. One section per line that had analyses run. **Final figure only. No ranges.**

> The [Feature] adjustment was developed at $[figure]. To arrive at this adjustment, [N] different adjustment methods were utilized and most of those were calculated on three sets of data. That resulted in a total of [M] different analyses being performed. Of those analyses, a total of [K] were given weight and consideration. [method list] were the adjustment methods used to develop this adjustment.

Lines carrying no adjustment open with "[Feature] adjustments were not warranted. To arrive at this conclusion, ..." and follow the same shape.

**Method list rules.** Every list includes **Paired Sales (Median and Average)** and ends with **Appraiser's files**, in that order, on every line without exception. Group the single-variable regressions as "N different types of simple regression." Name the controlled methods individually.

**Standing intro sentence:**

> Where the appraiser selected a figure outside the range produced by the data, paired sales from the subject's market and the appraiser's files were relied on to support the figure applied.

**Sign convention.** All figures positive. Direction is handled in the grid. Age reads "$X per year of age."

**Tail sentences** — one line only, where a real finding belongs on the record. Add them for: the marginal-versus-gross living area relationship, the new construction step, a product line contaminating a variable, and any thin feature. Nothing else.

**Closing section** naming every line where no adjustment was developed and why, including the lines removed by the relevance check with the wording "the subject and every comparable match on this line, so no adjustment is required."

### 5C — Methods workbook

**Summary tab.** One row per adjustment: label, unit, **grid line relevant?**, picker low, median, high, **SELECTED BY APPRAISER** (bold, shaded `FFF2CC`), analyses run, given weight, method types, reliability, tab name.

**Data tab.** Every sale, every variable, sorted so nested membership is contiguous. Footer stating each cut's worksheet row range, the net price definition, the exclusion count, and the LINEST note.

**Column order matters.** Put the no-site predictor block — GLA, age, garage, full baths, half baths, beds, pool, view, days — **contiguous**, and put **site area after it**, outside the block. LINEST needs a contiguous range for its known_x's, and the site models drop the zero-lot sales, which are not contiguous rows. This ordering is what lets the multivariate check work at all.

**One tab per adjustment.** Header block with picker low, median, high, **SELECTED BY APPRAISER** highlighted, reliability, and grid line relevance. Then every method run for that line, retained first, excluded in red. Columns: Method, Tier, Data set, Data points, Result, Given weight, How it was calculated, Live Excel check. Footer rows computing low, median and high of the retained results with real `MIN`, `MEDIAN`, `MAX` formulas.

**Live Excel checks — attach each to the row whose model it actually reproduces.**

| Check | Attach to | Formula |
|---|---|---|
| Simple regression | Simple OLS on the largest cut | `=SLOPE(Data!$G$2:$G$65,Data!$H$2:$H$65)` |
| Multivariate | Multivariate OLS on the largest cut, **(no site) variant** | `=INDEX(LINEST(Data!$G$2:$G$65,Data!$H$2:$P$65),1,k)` |

`k = (number of predictors + 1) − column position in the block`. Wrap age in `ABS()` on **both** formulas to match the positive display convention — the SLOPE check needs it too, not just LINEST.

Site area gets **no** worksheet check on either formula. Its models exclude the zero-lot sales, those rows are not contiguous, and no worksheet formula can reproduce that. Write the reason in the cell.

Rank-based, spline and matched-pair methods cannot be expressed as worksheet formulas. Say so in the cell. **Never fake a check.**

**Verify before delivering.** Convert the workbook through LibreOffice, reload with `data_only=True`, and confirm two things: zero cells beginning with `#`, and every computed check matching its Python value within 2%. A mismatch means the formula and the model are looking at different rows — find it and fix it, do not ship it. Watch for text cells that start with `=`; Excel parses them as formulas and they surface as `#VALUE!`.

**Trap checks tab.** The four age-model variants with the new construction step, the product-line finding, each thin feature with its count, the marginal-versus-gross comparison, the nesting verification, and the grid lines removed by the relevance check.

---

## PHASE 6 — Delivery. The only one.

Nothing has been handed over before this point. Everything goes now, together, once.

1. **Confirm the workspace holds exactly these files**, and no duplicates or older versions:

| # | File | Built in |
|---|---|---|
| 1 | `YYMMDD-[Address]MarketCharts.zip` (8 PNGs) | zipped here, from 3A's folder |
| 2 | `YYMMDD-[Address]NeighborhoodMarketAnalysis.docx` + `.txt` | 3B |
| 3 | `YYMMDD-[Address]MarketConditionsTimeAdjustments.docx` | 5A |
| 4 | `YYMMDD-[Address]SalesComparisonAdjustmentComments.docx` + `.txt` | 5B |
| 5 | `YYMMDD-[Address]AdjustmentMethodsWorkbook.xlsx` | 5C |

2. **Zip the charts now.** One zip, built here, from the eight PNGs written in 3A. This is the only place the zip is created.

3. **Delete any stale copy** of a file that was rebuilt during the run, so nothing ships twice under two names.

4. **Send once.** If a folder on the appraiser's machine is connected, write all seven items straight into it and name the folder in the reply — no file cards at all. If not, send the whole set in one message.

5. **Report in one short block:** what was delivered, the market conditions finding, the adjustments the appraiser selected, and any line where no adjustment was developed. No re-explaining of documents the appraiser can open.

If a file needs correcting after Phase 6, send the corrected version once and say it replaces the earlier one. Never send both.

# PART FOUR — STOPS

## What stops the run

1. A file that will not parse or render.
2. A missing effective date.
3. Zero closed sales after the transactional screens.
4. A cost approach figure requested with no cost source provided.
5. The appraiser's stated position conflicting with the data — surface the tension, ask which position to build, do not silently substitute.
6. An unanswered Gate. Per Rule 0 the run waits. It does not select on the appraiser's behalf and it does not proceed to Phase 5.

## Out of scope

The four-paragraph sales comparison narrative. It needs the completed grid — adjusted prices, net and gross percentages, weighting sheet labels, deviation figures. Export the MISMO XML from TOTAL and write it as a separate command after the grid is built.

*End of file. Nothing outside this document is required to run it.*
