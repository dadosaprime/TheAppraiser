# MLS SETUP TOOL

*Run this ONCE to make the Adjustment Support Tool work with YOUR MLS. It reads a sample export from your MLS, checks every
field, tells you what is missing, and builds a small file called **My MLS
Profile** that teaches the tool how to read your system. After this, you
never run it again unless your MLS changes its export.*

*The tool was built and tested on Stellar MLS (Matrix). If you use Stellar, you
do not need this file — the tool already knows your columns. Everyone else: start
here.*

**Versioning.** This file is named `MLS Setup Tool vYYYY-MM-DD.md`. The date is the
build date. Always use the newest date present.

---

# PART ONE — FOR THE APPRAISER (the easy part)

## What you need to grab from your MLS. Two things.

1. **One sales export.** Do a normal market-area search in your MLS — a
   neighborhood you know, last 12 months, **Sold AND Active AND Pending together**.
   Export it as a **CSV** with **every column your MLS will give you**. Do not
   trim columns. Do not open it in Excel and re-save. Fifty or more records is
   ideal.
2. **The name of your MLS** — for example "BrightMLS", "CRMLS", "ARMLS",
   "Canopy", "NTREIS".

If your MLS gives you choices of "export format" or "report type," pick
the one with the MOST columns. More is always better here.

## What you do. Four steps.

1. Start a new chat in Claude. Drag in this file and your sample CSV(s).
2. Paste this and fill in one line:

```
SET UP MY MLS per MLS Setup Tool (newest dated file)

MLS Name: [your MLS name]
```

3. Claude checks everything and shows you a report card: what it found, what is
   missing, and — if something important is missing — exactly which export
   setting or column to turn on in your MLS. If you need to fix your export, fix
   it, drag the new CSV in, and say "check again."
4. When the report card is good, Claude gives you a small file called
   **`My MLS Profile.md`**. **Save it.** From now on, attach it whenever you run
   the Adjustment Support Tool. That's the whole trick — the profile rides
   along with your CSVs, and the tool reads it first.

If you use a Claude **Project**: put `My MLS Profile.md` in the Project knowledge
next to the tool, and you never have to attach it again.

---

# PART TWO — FOR CLAUDE (the run itself)

## Step 1 — Read the sample honestly

Parse the attached CSV(s). Report: how many records, how many columns, how many
Sold / Active / Pending. If a file cannot be parsed, stop and say why in
one sentence — never guess from a filename.

## Step 2 — Map every concept

Work through the full concept list from the MLS Export Field Guide (reproduced
below), matching this MLS's headers case-insensitively, punctuation ignored,
including close variants and containing-matches. For every concept record: the
matched header, or NOT FOUND.

**Concepts to map — required (Tier 1):** address; sale price; sale date; living
area; status.
**Core (Tier 2):** contract date; seller concessions; financing/terms; sale
condition/special provisions; ownership; beds; full baths; half baths; lot size;
year built; list price; original list price; DOM; MLS number; city; zip; county.
**Feature lines (Tier 3):** garage spaces; carport spaces; private pool flag;
pool features; water frontage flag and type; water view flag and type; view;
fireplace; stories; in-law/ADU; builder name; builder model.
**Quality/narrative (Tier 4):** public remarks; subdivision; tax/parcel ID;
property type; property style; HOA fee; condo fee; interior features; exterior
features; flood zone; zoning.

## Step 3 — Learn the quirks (this is why the profile exists)

From the actual data, not the headers, determine and record:

- **Date format** (MM/DD/YYYY, YYYY-MM-DD, DD-MMM-YY…) for each date column.
- **Lot size units** — square feet or acres (check magnitudes; note if a
  conversion × 43,560 is needed, or if both columns exist).
- **Boolean encoding** — True/False, Y/N, Yes/No, X/blank — for pool, waterfront,
  water view, fireplace.
- **Status vocabulary** — this MLS's exact words for closed ("Sold", "Closed",
  "S"), active, and pending/under contract.
- **Bath encoding** — separate full/half columns, one combined "2.1"-style
  column, or total baths only (note the parse rule).
- **Concession format** — dollars, percent, or text; the column's actual contents.
- **Financing vocabulary** — the exact terms used for cash, conventional, FHA,
  VA, owner finance, assumption.
- **Sale-condition vocabulary** — the exact words for REO, short sale, auction,
  estate, relocation, as-is.
- **Property-type vocabulary** — the words for detached, townhouse, condo,
  manufactured.
- **Anything unusual** — combined address fields, duplicated columns, padded
  values, thousands separators, currency symbols.

## Step 4 — The report card

Show a simple table, one row per concept: ✅ found (with the header name),
⚠️ found but odd (with the quirk), ❌ missing. Then, in plain words:

- **Missing Tier 1 or Tier 2 fields:** name each one and say what to do — usually
  "add the [X] column to your export" or "choose the fuller export format." These
  block or weaken the analysis, so fixing the export now is worth it.
- **Missing Tier 3 fields:** name the grid lines that will read "no data."
- **Missing Tier 4 fields:** one line on what gets weaker (audits, narrative,
  paired sales).

Offer to re-check a corrected export. Loop until the appraiser is satisfied.

## Step 5 — Write `My MLS Profile.md`

Produce the profile as a downloadable file, exactly this shape:

```markdown
# MY MLS PROFILE
MLS: [name]    Built: [date]    By: MLS Setup Tool v[date]
Sample: [n] records, [n] columns

## Column map (concept = exact header)
address = [header]
sale_price = [header]
sale_date = [header]
[... every mapped concept, one per line; unmapped concepts listed as
concept = NOT AVAILABLE ...]

## Formats
dates = [format, per column if they differ]
lot_units = [sqft | acres ×43560 | both: header names]
booleans = [encoding]
baths = [separate | combined "N.n" | total only — parse rule]
concessions = [dollars | percent | text — rule]

## Vocabulary
status_sold = [words]      status_active = [words]
status_pending = [words]
financing_noncash = [this MLS's words for owner finance, assumption, ...]
sale_condition_excluded = [this MLS's words for REO, short sale, auction, ...]

## Quirks
- [one line each — anything from Step 3 the tools must know]

## Lines with no data in this MLS
- [grid lines that cannot be supported, so runs report them honestly]
```

Close by telling the appraiser, in two sentences: save this file, attach it (or
add it to the Project) whenever you run the Adjustment Support Tool. Done — setup never runs
again unless the MLS changes its export.

## How the Adjustment Support Tool uses the profile

The Adjustment Support Tool checks for an
attached `My MLS Profile.md` at the start of every run. When present, its column
map, formats, and vocabulary are used **first**, before any generic alias
matching; its quirks are applied as parse rules; its "no data" list is reported
as known-absent rather than searched for. When absent, the tool falls back to
generic concept matching — which works for Stellar and close cousins, and asks
when it cannot find a required concept.

---

# PART THREE — STOPS

Stop for: an unparseable sample; a sample with fewer than 10 sold records (ask
for a bigger search — the quirk detection needs real data); no MLS name given.
Never stop for missing optional fields — that is what the report card is for.

*End of file. Nothing outside this document is required to run it.*
