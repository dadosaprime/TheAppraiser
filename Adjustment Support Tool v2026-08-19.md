# ADJUSTMENT SUPPORT TOOL

*Self-contained — nothing outside this file is required. Drop this file and your MLS
CSV exports into Claude (a chat or a Project), paste the command, and it runs: market
conditions analysis, a multi-method adjustment engine, the Adjustment Reconciliation,
five workfile documents, a calculations workbook, and eight market charts — delivered
once, as `Adjustment_Analysis.zip`.*

*This tool produces analysis and workfile support only. Nothing it produces is
written into any report — the appraiser transfers every figure into their forms
software by hand.*

**Versioning.** This file is named `Adjustment Support Tool vYYYY-MM-DD.md`. The date
is the date the file was built. Each revision is saved under a new date and older
dated files are kept — the date in the name is the version history. Always run the
newest date present.

---

# PART ONE — THE COMMAND

Attach your MLS CSV exports. Paste this block and fill the lines.

```
RUN ADJUSTMENT SUPPORT per Adjustment Support Tool (newest dated file)

Address:              [street, city, state, zip]
Effective Date:       [MM/DD/YYYY]
State:                [two-letter state]
MLS Name:             [e.g. StellarMLS, BrightMLS, CRMLS]
Resolution Threshold: [percent per month, or blank for 1.0%]
Notes:                [anything unusual — new construction, water view, product concern]
```

Every input except Address and Effective Date has a default. `Resolution Threshold`
is the appraiser's own professional standard for the smallest market-conditions rate
worth applying; it defaults to 1.0% per month and every gate, band, and sentence in
this run reads it from this one setting. A different appraiser may set it lower or
higher and be right to.

## The run is two messages, not one — and phases do not execute in numeric order

| Message | Run order | Ends with |
|---|---|---|
| **One** | Start Gate → Intake → Data build → Market conditions → Method engine → **ADJUSTMENT RECONCILIATION** | the Reconciliation on screen. Nothing else. |
| **Two** | Research → Charts → Documents → Workbook → **`Adjustment_Analysis.zip`** | the delivered package |

**Get to the Reconciliation as fast as possible.** That is the ordering principle.
If a step does not feed the Reconciliation, it belongs in message two. No web
research, no charts, no documents, and no files of any kind are produced before the
Reconciliation. Message one ends the moment the Reconciliation is displayed — stop
and wait for the appraiser's figures.

## Required inputs — MLS CSV exports

| File | Contents | Required? |
|---|---|---|
| **subject** | one record, the subject property | Recommended. If the subject was never listed, a subject record built from public records using the same column headers works; the run says so in the output. |
| **comps** | the selected comparable sales | Yes |
| **market area 1** | the widest market cut (neighborhood / market area) | Yes |
| **market area 2** | a tighter competing cut | Recommended |

Files may carry Active, Pending and Sold records — the run separates them. Any MLS
works: columns are matched by **concept**, not by exact header (Part Three). If a
required concept cannot be found in any column, the run stops and asks — it never
guesses silently.

**One column, two meanings.** In a sales export the sale-price column is a sale
price. In a rentals export (`Property Type` = Rental / Residential Lease) the same
column is the **monthly rent**. Classify every input file by its property-type
content, never by its filename, and never let lease records enter the sales pools.

---

# PART TWO — STANDING RULES

## Rule 1 — The appraiser selects every adjustment. Always.

**The software produces the range. The appraiser produces the adjustment.**

- The run must stop at the Reconciliation and ask on every grid line, every run,
  every time.
- No automatic, batch, default-to-median, or unattended selection mode exists, by
  any name. A stated time constraint or "just run it" is not permission to select.
- An unanswered Reconciliation is an incomplete run, not a run with default values.
- This tool writes nothing into any report or forms software. The appraiser
  physically types every adjustment into their report. The analysis here is
  workfile support for figures the appraiser develops — the appraiser signs the
  report, so the numbers must be theirs.

## Rule 2 — Unreadable input hard stop

If a file cannot be read — wrong format, empty extraction, garbled content — **stop**,
say which file failed and why in one sentence, and ask for a re-export or pasted text.
Never fabricate, never silently skip a file, never work from a filename.

## Rule 3 — Writing level

All documents: plain sentences, short paragraphs, active voice, no jargon where a
plain word works. Technical terms of the profession stay. Say "indicated," never
"recommended." Never present a software output as the appraiser's conclusion.

## Rule 4 — Facts get sources

Anything in a document that did not come from the attached CSVs (employers,
hospitals, schools, roads) is stated with its source and flagged for the appraiser to
verify. When web research is unavailable, write the section from the CSV data only
and say what was left for the appraiser.

## Rule 5 — One delivery

Nothing is handed to the appraiser until the end of message two, and then everything
goes at once, in one ZIP, each file exactly once. No previews, no drafts, no
"here's the chart so far."

## Rule 6 — The default support sentence (disclosed here, and in DISCLOSURES)

Some grid lines produce no usable analysis results — either the data cannot support
them (Location, Condition and Quality are appraiser-judgment lines and almost never
measure from MLS columns) or every method was screened out. When the appraiser enters
a figure on such a line, the Adjustment Support Comments **always** use this fixed
sentence:

> Adequate support for this adjustment was provided by Paired Sales, Adjusted Paired
> Sales and/or Online Depreciated Cost analysis.

(or "…for this conclusion…" when the line is not warranted). This is the default for
**every** line with no results — the three judgment lines, a Start-Gate extra that
found no data, any line where all methods were screened. The paragraph reads
identically to the measured lines; nothing in the document marks it as a default.
**The appraiser is responsible for confirming that their workfile actually contains
the support the sentence describes, and for editing or removing the sentence where
it does not.** This obligation is restated in the DISCLOSURES document included in
every ZIP.

The boundary: the switch is **no results**, not out-of-range. If methods returned
figures and the appraiser entered something outside them, the line still lists its
closest methods — only an empty result set triggers the default sentence.

---

# PART THREE — THE DATA MATRIX

**If a `My MLS Profile.md` file is attached (built by the MLS Setup Tool), use it
first:** its column map, date/lot/boolean formats, and status/financing/sale-
condition vocabulary override the generic matching below, its quirks are applied as
parse rules, and its "no data" list is reported as known-absent rather than
searched for. Without a profile, proceed with generic matching.

Columns are matched by concept. For each concept, scan the header row for the first
matching column (case-insensitive, punctuation ignored). The aliases below cover the
major MLS systems; when none match, look for any header containing the key word, and
if still nothing, ask.

| Concept | Common headers |
|---|---|
| Address | Address, Street Address, Full Address |
| City / Zip / County | City; Zip, Postal Code; County |
| Sale price | Close Price, Sold Price, Sale Price, Closed Price |
| Sale date | Close Date, Sold Date, Closing Date |
| Contract date | Contract Date, Pending Date, Under Contract Date |
| List price | List Price, Current List Price / Original List Price |
| Living area | Heated Area, Living Area, GLA, SqFt Heated, Total Living Area |
| Lot size | Lot Size Square Footage, Lot SqFt (or Acres × 43,560) |
| Beds / Baths | Beds, Bedrooms; Full Baths, Half Baths |
| Garage / Carport | Garage Spaces; Carport Spaces |
| Pool | Pool Private Y/N, Private Pool, Pool; Pool Features |
| Waterfront / View | Water Frontage Y/N; Water View Y/N; View; Water Frontage |
| Year built | Year Built, Yr Built |
| Stories | Floors in Unit/Home, Stories, Total # of Floors |
| Fireplace | Fireplace Y/N |
| Concessions | Seller Paid Buyer Costs, Seller Concessions, Concessions |
| Financing | Sold Terms, Financing, Terms of Sale |
| Sale condition | Special Sale Provision(s), Sale Condition |
| Ownership | Ownership (for leasehold screening) |
| Status | Status (Sold / Active / Pending) |
| DOM | ADOM, CDOM, Days on Market |
| MLS number | MLS Number, MLS #, Listing ID |
| Subdivision | Legal Subdivision Name, Subdivision, Subdivision/Condo Name |
| ADU / in-law | In-Law Suite Y/N, In-Law Suite Under Air SQFT, ADU, Accessory Dwelling |
| Builder / model | Builder Name; Builder Model |
| Remarks | Public Remarks, Remarks (used for data audits and narrative, never as a numeric source) |

Report every concept that could not be mapped. Unmapped optional concepts reduce
coverage; unmapped required concepts (price, date, living area, address) stop the run.

## Transactional screens — before any method runs

1. Split closed sales from Active/Pending. Live listings are competing inventory:
   kept, and used for supply and market-conditions indicators — never as sales.
2. Remove: leasehold; REO / short sale / foreclosure / auction / estate / relocation
   sales; non-cash-equivalent financing (seller or owner financing, assumption,
   contract for deed, 1031, lease-option). List every exclusion with its reason.
3. Deduct seller concessions from each sale price → cash-equivalent price.
4. Time-normalize each sale to the effective date at the market-conditions rate
   (Phase A) before any feature method runs.

## Data-quality audits — run on every file, before any method

MLS data is agent-entered and contains errors. Three audits, each producing a flagged
list the appraiser sees in the workbook's Data tab:

1. **Subdivision normalization.** The subdivision field is free text — the same
   subdivision appears under multiple spellings (`CRK`/`CREEK`, `PRCL`/`PCL`/
   `PARCEL`, `PH`/`PHASE`, reordered words). Normalize abbreviations and word order
   **before** any same-subdivision matching (paired sales especially). Exact-string
   matching on this field silently drops qualifying pairs.
2. **Flag-vs-remarks audit.** Boolean amenity fields (private pool, water view,
   waterfront) are frequently miscoded. Cross-check each flag against the remarks
   text and sibling fields: a "private pool = true" record whose remarks mention
   only a community pool, or a "waterfront" record with "water view = false", is
   flagged **unreliable** and excluded from that feature's methods — unreliable
   data is worse than thin data.
3. **GLA cross-check.** Where the remarks state a square footage ("1,787 square
   feet"), compare it to the living-area column. A material mismatch (> ~25 sf) is
   flagged; if the record would be influential in a size method, prefer the more
   conservative figure and note the flag.

---

# PART FOUR — MESSAGE ONE

## Phase 0 — THE START GATE (before anything else runs)

The very first thing on screen, before any file is parsed:

> **Other than the standard grid line adjustments, are there any other MLS fields
> you would like adjustments for, such as barns, storage, etc.? Select No to
> continue, or enter other MLS field data in the boxes.**
> *Note: this will cause a delay as I search for and run analysis on them.*
>
> `[ No ]`  `[________]`  `[________]`  `[________]`

- **No** → the run proceeds with the standard grid lines.
- Entered fields → each is added to the analysis as its own grid line. The engine
  searches the CSV columns (and remarks where the concept is text-only) for usable
  data on each. Up to three extras — that matches the three "Other" rows available
  on the form grid.
- An extra field that yields no usable data still appears in the Reconciliation
  (marked "no data — appraiser entry") and, if the appraiser enters a figure, takes
  the Rule 6 default sentence in the comments.

## Phase A — Market conditions (run once, used everywhere)

Measure the monthly rate several independent ways on the cash-equivalent sales:
ordinary least squares, Theil-Sen, and least absolute deviation on ln(price/sf);
ordinary least squares on ln(price); and a monthly-median $/sf series. Report each
rate, the range, the median, n, and the R² of the primary fit. **The rate may be
positive or negative.** Also test whether the sign is stable across the data cuts —
a rate that reverses direction between cuts is an absent trend, not a weak one.

**The rate gate** (this run's internal normalization only — nothing here is ever
written into a form):

```
trend_supported = abs(rate) >= resolution_threshold AND sign stable across cuts
rate_applied    = median rate if trend_supported else 0.0
```

The R² is reported to be weighed, never to gate. The threshold is the appraiser's
setting from the command block.

## Phase B — The method engine

Run every applicable method on every data cut, on cash-equivalent, time-normalized
prices, for every grid line the data can support:

- True paired sales (average and median) — matching tolerances: living area and lot
  within 5%; bed/bath/garage/carport/pool/waterfront/view/stories/fireplace exact
  (beds: equal, or both above 3); same normalized subdivision where the pool allows;
  IQR filter on pair results; minimum 3 pairs.
- Adjusted paired sales (average and median) — normalize the other differing
  features first with preliminary slopes.
- Grouped data analysis (average and median) — split around the feature median.
- Sensitivity analysis — the adjustment that minimizes the spread of prices
  normalized to the subject's feature level.
- Regression family — multivariate ordinary least squares, robust (Huber),
  Theil-Sen, least absolute deviation, least median of squares, modified quantile
  (nine quantiles, best pseudo-R² kept), and the simple-regression set.
- Generalized additive modeling at two smoothing levels, where the data volume
  supports it.

**Site is measured once, expressed twice.** All site methods run on square feet.
Every site result is then reported in **both units** — per square foot, and per
acre (per-acre = per-sf × 43,560) — the same analysis in two denominations, never
two separate analyses that could disagree. Both expressions appear everywhere the
site line appears: the Reconciliation, the comments, and the workbook.

**Hard separation rules — these are not style preferences:**

- **View types are never pooled.** Water view, woods/conservation, golf, park, city —
  each is its own grid line with its own methods, its own range, its own
  Reconciliation row. A single blended "view adjustment" is never produced. (The
  form grid has one View cell; the appraiser reconciles the separate lines to the
  figure they enter there — the analysis never does the blending for them.)
- **Pool types are never pooled.** Private in-ground, above-ground, screen
  enclosure, spa, and community pool access are distinct lines. A record whose pool
  flag failed the flag-vs-remarks audit joins none of them.

**Screens, in order — and every screened result is kept visible with its reason:**
1. Wrong sign (a feature that cannot subtract value may not return negative; age may
   not return newer-is-cheaper).
2. Plausibility ceiling from this market's own numbers: marginal $/sf may not exceed
   the gross median $/sf; lot capped at half of it; per-unit features capped at a
   sensible fraction of the median sale price.
3. Robust statistical outliers (median ± 3 MAD with a floor of 50% of the median, so
   one tight method family cannot collapse the range).

**Supported range = the span of the survivors.** A line with fewer than 3 surviving
method types is flagged as thin support. A line with no survivors is reported as
"no adjustment developed" — that is information, not a failure, and it routes the
line to the Rule 6 default in the comments if the appraiser enters a figure.

## Phase C — THE ADJUSTMENT RECONCILIATION (message one ends here)

One row per grid line, in grid order — market conditions first (in %/month), then
the standard lines, view lines separated, pool lines separated, any Start-Gate
extras, and after Builder/Model:

- **ADU (accessory dwelling unit)** — shown with this disclaimer on the row:
  *"ADU data depends on how agents entered it in MLS and may be less reliable than
  other fields."*

Every row shows, in this order:

1. **Analysis Result Range** — in text: "Analysis Result Range $X to $Y · median $Z
   · [n] methods". A judgment or no-data line shows "No analysis results —
   appraiser entry."
2. **Three boxes: Low, Median, High.** Clicking one writes that number into the
   entry field. It does not advance and it does not lock.
3. **Appraiser's Adjustment** — the entry field for the appraiser's own figure, the
   primary path, not the fallback. `type="text"` with `inputmode="decimal"` (never
   `type="number"`). Pre-fill with the rounded median where one exists, select-all
   on focus, accept `$`, commas, and a leading minus. Validate on Enter or Next
   only — never per keystroke.

**The advance rule:** the Reconciliation moves to the next line on exactly two
events — the Next button, or Enter inside the entry field. Nothing else advances it.

**The bubbling rule:** never nest the entry field inside a clickable card. Keep the
Low/Median/High boxes and the entry field as siblings so a click in the field cannot
select-and-skip the line. Before showing the Reconciliation, confirm: typing a
four-digit number into the first line's field shows the characters and does not
change the line.

**The Site row shows both units.** Its Analysis Result Range reads in both
denominations — "Analysis Result Range $2.10 to $4.75 /sf ($91,476 to $206,910
/acre) · median $3.00/sf ($130,680/acre) · [n] methods" — with a **SF / Acre unit
selector** on the row. The selector controls which unit the Low/Median/High boxes
write and which unit the entered figure is recorded in; switching it converts a
figure already in the box. Default to SF when the subject's lot is under one acre,
Acre at one acre or more. The recorded selection carries its unit with it — the
comments and workbook state the figure in the selected unit with the other unit in
parentheses.

A figure outside a supported range is allowed and flagged, never blocked. Confidence
flags (thin support, unreliable data) appear here and in the workbook — never in the
Adjustment Support Comments.

On completion, send the figures back and **stop. Message one is over.**

---

# PART FIVE — MESSAGE TWO (starts when the figures arrive)

No new analysis. No re-derivation. No further questions.

## Phase D — Research and charts

- Neighborhood facts (competing areas, employers, hospital, schools, roads) by web
  search where available, every fact sourced per Rule 4.
- Eight market charts from the all-status data, one image each, consistent style,
  **each file named for what it shows** (e.g. `Chart - Median Sale Price.png`):
  median sale price; median $/sf; months of supply; median DOM; % of sales with
  concessions; concession contribution %; absorption (sales/month); sales count —
  monthly series over the study period.

## Phase E — The documents (five .docx — no .txt twins)

### 1. Neighborhood and Market Analysis

Neighborhood description with the price band and product description from the data;
market description naming the competing areas the comps actually came from;
employment; support services; shopping and recreation; market trends closing section
with the measured rates, DOM, supply, and concession pattern.

### 2. Market Conditions

The rate measured every way (table), the range and median, R² reported to be
weighed, the threshold sentence rendering the appraiser's configured threshold in
words, the appraiser's selected rate, and a per-comparable table: contract date,
months to effective, indicated adjustment at the selected rate, $0 inside the 90-day
window — labeled as workfile support that the appraiser transfers by hand.

### 3. Adjustment_Support_Comments

**Opening paragraph — always first, exactly this content:**

> The appraiser's analysis to arrive at the following adjustments included
> generalized additive modeling at two smoothing levels, multivariate ordinary least
> squares, robust least squares using the Huber M-estimator, least absolute
> deviation, modified quantile regression, Theil-Sen regression, least median of
> squares, grouped data analysis, sensitivity analysis, six different types of
> simple regression, True Paired Sales, and Adjusted Paired Sales. This report's
> current work file and prior work files were also considered. This data was all
> extracted from the local MLS sold listings data contained within the appraiser's
> work file.

**Then one short paragraph per grid line, in grid order.** Three shapes, all
parallel:

*A line with an adjustment, methods measured:*

> **Site**
> The Site adjustment was developed at $3.00 per square foot of site area
> ($130,680 per acre). Adequate support for this adjustment was provided by
> Theil-Sen regression, grouped data analysis, and multivariate ordinary least
> squares.

(The Site paragraph always states both units — the appraiser's selected unit
first, the equivalent in parentheses. An acre-selected figure reads "…at $130,000
per acre ($2.98 per square foot).")

*A line not warranted, methods measured:*

> **Actual Age**
> Actual Age adjustments were not warranted. Adequate support for this conclusion
> was provided by least absolute deviation, sensitivity analysis, and grouped data
> analysis.

*Any line with no analysis results where the appraiser entered a figure (Rule 6 —
Location, Condition, Quality, and any other empty-result line):*

> **Location**
> The Location adjustment was developed at $5,000. Adequate support for this
> adjustment was provided by Paired Sales, Adjusted Paired Sales and/or Online
> Depreciated Cost analysis.

**A worked stretch of the document — this is the complete pattern, including how
consecutive lines read. Note every paragraph ends after its method list:**

> **Garage**
> The Garage adjustment was developed at $10,000 per space. Adequate support for
> this adjustment was provided by modified quantile regression, least absolute
> deviation, multivariate ordinary least squares, and robust least squares using
> the Huber M-estimator.
>
> **Carport**
> The Carport adjustment was developed at $5,000 per space. Adequate support for
> this adjustment was provided by grouped data analysis, multivariate ordinary
> least squares, Adjusted Paired Sales, and simple regression.
>
> **Fireplace**
> Fireplace adjustments were not warranted. Adequate support for this conclusion
> was provided by grouped data analysis, robust least squares using the Huber
> M-estimator, and multivariate ordinary least squares.
>
> **Private Pool**
> The Private Pool adjustment was developed at $30,000. Adequate support for this
> adjustment was provided by sensitivity analysis, modified quantile regression,
> robust least squares using the Huber M-estimator, and least absolute deviation.
>
> **Stories**
> Stories adjustments were not warranted. Adequate support for this conclusion
> was provided by Paired Sales, Adjusted Paired Sales and/or Online Depreciated
> Cost analysis.

**Selecting the listed methods:** for measured lines, list the **1 to 4 methods
whose results were closest to the appraiser's figure**, by absolute distance —
methods only, no commentary on closeness, no note on whether they sit above or
below the figure. For a $0 / not-warranted line, distance is measured from zero.
Ranges are never printed in this document. Confidence never appears in this
document. Every line gets support language — no line is ever blank.

**Each paragraph is exactly two sentences and ends after the method list. Nothing
is ever appended.** No closing sentence, no boilerplate, no per-line mention of
workfiles or past adjustments — specifically, never the sentence "In addition to
the methods described the appraiser also considers past adjustments from their
workfiles and paired sales," or any variant of it. Workfile consideration is
stated once, in the opening paragraph, and never repeated on a line. A run that
adds a third sentence to any line is producing the wrong document.

### 4. Adjustment_Method_Definitions

One entry per method considered, whether or not it produced results on this run:
generalized additive modeling (two smoothing levels), multivariate ordinary least
squares, robust least squares (Huber M-estimator), least absolute deviation,
modified quantile regression, Theil-Sen regression, least median of squares, grouped
data analysis, sensitivity analysis, the six simple-regression forms, True Paired
Sales, Adjusted Paired Sales, and Online Depreciated Cost analysis.

Each entry: the method's name, a brief plain-language description of what it does,
and **one sentence on its strength as a tool.** Descriptions state what each method
contributes — this document exists to support the analysis.

### 5. DISCLOSURES

Included in **every** ZIP, on every run, unconditionally. Content in Part Seven.

## Phase F — The calculations workbook (.xlsx)

- **Summary tab** — one row per grid line: Analysis Result Range, median, method
  count, status, and a highlighted **Appraiser's Adjustment** column holding the
  Reconciliation figures.
- **Data tab** — the screened sales, every column the methods used, plus the
  data-quality flags (subdivision normalization map, flag-vs-remarks hits, GLA
  mismatches), so every number and every exclusion traces to a visible row.
- **Time tab** — every sale's date, price, concession, cash-equivalent, $/sf; the
  rate by each method; a date-vs-$/sf scatter chart with the trend.
- **One tab per adjusted grid line** — the method × dataset matrix heat-mapped by
  distance from the median (agreement reads as a color band, outliers glow at the
  edges), screened results flagged with reasons, the surviving range, and a native
  Excel scatter of price vs. the feature. Native Excel charts and conditional
  formatting only — no pasted images, so it opens correctly everywhere. The
  **Site tab** carries paired per-sf and per-acre columns for every method result
  (per-acre by formula, `=sf_cell*43560`, so the two can never disagree), and the
  Summary tab's Site row shows the range and the Appraiser's Adjustment in both
  units.

## Phase G — Delivery. The only one.

**One ZIP named `Adjustment_Analysis.zip`**, containing, at the top level (no nested
zips, no subfolders):

1. `Neighborhood and Market Analysis.docx`
2. `Market Conditions.docx`
3. `Adjustment_Support_Comments.docx`
4. `Adjustment_Method_Definitions.docx`
5. `DISCLOSURES.docx`
6. `Adjustment Methods Workbook.xlsx`
7. The eight chart images, each named for its content

Verify each file exists and appears exactly once. Close with one short block: what
was delivered, the market-conditions finding, the appraiser's figures, any line that
took the Rule 6 default, and the reminder that every adjustment must be typed into
the report by hand.

---

# PART SIX — STOPS

The run stops for: an unreadable file (Rule 2); a required concept that cannot be
mapped; an unanswered Start Gate; an unanswered Reconciliation. It does not stop
for: thin data (report it), an empty grid line (report it), missing optional inputs
(say what was skipped), or chart trouble (deliver without the failed chart and say
so in one line).

---

# PART SEVEN — THE DISCLOSURES DOCUMENT

Generated verbatim into every `Adjustment_Analysis.zip` as `DISCLOSURES.docx`. The
first section is rendered entirely in bold.

---

**DEFAULT LANGUAGE IS INSERTED INTO THESE DOCUMENTS. IT IS THE APPRAISER'S
RESPONSIBILITY TO REVIEW, MODIFY, OR REMOVE EVERY COMMENT BEFORE ANY PART OF THIS
PACKAGE IS USED IN A REPORT OR WORKFILE. IN PARTICULAR: WHERE A GRID LINE PRODUCED
NO ANALYSIS RESULTS AND THE APPRAISER ENTERED AN ADJUSTMENT, THE ADJUSTMENT SUPPORT
COMMENTS STATE BY DEFAULT THAT SUPPORT WAS PROVIDED BY PAIRED SALES, ADJUSTED PAIRED
SALES AND/OR ONLINE DEPRECIATED COST ANALYSIS. THAT SENTENCE DESCRIBES SUPPORT THE
APPRAISER IS EXPECTED TO HOLD IN THEIR OWN WORKFILE. IF THE APPRAISER'S WORKFILE
DOES NOT CONTAIN SUCH SUPPORT, THE APPRAISER MUST EDIT OR REMOVE THAT COMMENT.
NOTHING IN THE DOCUMENTS DISTINGUISHES DEFAULT LANGUAGE FROM MEASURED LANGUAGE —
REVIEWING IT IS THE APPRAISER'S OBLIGATION, NOT AN OPTION.**

**1. Analytical support tools only.** These tools do not determine adjustments. They
report the range indicated by the market data under the methods utilized. Selection
of every adjustment, every rate, and every conclusion is solely the appraiser's.
The tools have no opinion of value and produce none.

**2. Verification is the appraiser's responsibility — entirely.** It is 100% the
appraiser's responsibility to verify the results using the included methods
workbook, in which every figure traces to a visible data row. Use of any figure
without verification is at the appraiser's own risk.

**3. Data limitations.** All results derive from MLS data supplied by the appraiser.
MLS data is entered by real estate agents, is not independently verified, and is
known to contain errors, omissions, and miscoded fields — including, without
limitation, incorrect living area, misreported amenities such as pools and views,
and inconsistent subdivision naming. The tools apply automated screens for certain
error patterns; those screens are not exhaustive and do not relieve the appraiser
of the duty to verify.

**4. Artificial intelligence disclosure.** This package was generated with the
assistance of artificial intelligence. AI-generated output may contain errors,
including plausible-sounding statements that are wrong. Narrative text is
machine-drafted and becomes the appraiser's work only upon the appraiser's review,
modification, and adoption. The appraiser is responsible for reviewing the terms of
the AI platform used, including its handling of any data submitted to it.

**5. Professional responsibility.** The appraiser remains solely responsible for
compliance with USPAP and all applicable law and regulation, for the credibility of
assignment results, for workfile sufficiency, and for all certifications signed.
Use of these tools does not create an appraisal, an appraisal review, or an
appraisal practice service by the tool's author, and creates no obligation of the
author to any party.

**6. No warranty.** These tools and their output are provided "as is" and "as
available," without warranty of any kind, express or implied, including without
limitation warranties of merchantability, fitness for a particular purpose,
accuracy, completeness, or non-infringement. No oral or written information obtained
through the tools creates any warranty.

**7. Limitation of liability.** To the maximum extent permitted by law, the author
of these tools shall not be liable for any direct, indirect, incidental, special,
consequential, or exemplary damages — including without limitation lost profits,
lost fees, professional discipline, license actions, repurchase demands, or claims
by lenders, borrowers, or other third parties — arising from or related to the use
of, or inability to use, these tools or their output, even if advised of the
possibility of such damages. The appraiser's sole and exclusive remedy is to
discontinue use.

**8. Errors and omissions.** The author is not responsible for errors, omissions,
or inaccuracies in the tools or their output, however caused.

**9. Indemnification.** By using these tools, the appraiser agrees to indemnify and
hold harmless the author from any claim, demand, or damage, including reasonable
attorneys' fees, arising out of the appraiser's use of the tools or their output in
any appraisal, report, or professional engagement.

**10. Not professional advice.** Nothing produced by these tools constitutes
appraisal, legal, tax, accounting, or investment advice. No party other than the
appraiser using the tools may rely on any output, and no such reliance is intended
or authorized.

**11. Open-source software.** These tools are distributed free of charge. They may
be modified by anyone after distribution; the author is responsible for no version
of these tools other than as originally published, and for no output of any
modified version.

---

*End of file. Nothing outside this document is required to run it.*
