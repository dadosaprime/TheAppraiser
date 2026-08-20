# INSTRUCTIONS — Adjustment Support Tool

Written for an appraiser who has never used Claude. No coding, no installs.

## What this tool does

You give it your MLS CSV exports. It runs the market conditions analysis and a
multi-method adjustment analysis, shows you the supported range for every grid
line, and asks you to enter your adjustment on each line (the Adjustment
Reconciliation). Then it delivers one download, `Adjustment_Analysis.zip`:
five Word documents, a calculations workbook, and eight market charts — workfile
support for the adjustments **you** develop and sign for.

The tool never writes anything into your report or forms software. You type every
adjustment yourself.

## One-time setup

1. Go to **claude.ai** and sign in (create a free account if you don't have one).
   Paid plans handle the file sizes better.
2. Recommended: create a **Project** and upload the tool file
   (`Adjustment Support Tool v[date].md`) to the Project's knowledge. Then every
   new chat in that Project already knows the tool. (Alternative: just drag the
   `.md` file into any new chat.)
3. **Not on Stellar MLS?** Run the **MLS Setup Tool** once first. You give it one
   sample export from your MLS, it checks every field, tells you what to fix in
   your export settings, and hands you a small `My MLS Profile.md` file. Put that
   file in your Project (or attach it with your CSVs every run) and the tool will
   read your MLS correctly from then on. Stellar/Matrix users skip this — the
   tool already knows those columns.
4. **Speed tip:** if your Claude has an "extended thinking" toggle, turn it
   **off** for these runs. The tool does the heavy math procedurally; extended
   thinking just makes you wait.

## Step 1 — Export your CSVs from your MLS

See the **MLS Export Field Guide** for exactly which fields to include and the
five export habits that keep runs clean. The short version: use your MLS's full
residential export with all columns, all statuses, 12–24 months.

Four exports (any MLS works — columns are matched by meaning, not by name):

| File | What it is |
|---|---|
| subject | one record — your subject (skip if never listed; say so in Notes) |
| comps | your selected comparable sales |
| market area 1 | your widest market-area search |
| market area 2 | a tighter competing search |

## Step 2 — Run it

1. Start a chat. Attach your CSVs (drag them in).
2. Paste the command block from Part One of the tool file and fill in the address
   and effective date.
3. **First question on screen:** whether you want adjustments for any
   non-standard MLS fields (barns, storage, etc.). Click **No** to continue, or
   type the fields in — extras take longer, because the tool has to search for
   and analyze them.
4. The analysis runs and the **Adjustment Reconciliation** appears: every grid
   line's Analysis Result Range with Low / Median / High buttons and an
   **Appraiser's Adjustment** box. Enter your figure on each line — clicking
   Low/Median/High fills the box, typing your own number overrides it. The Site
   line shows both $/sf and $/acre — pick the unit that fits your subject.
5. Send your figures. The tool builds everything and delivers
   **`Adjustment_Analysis.zip`** — one download, containing:
   - Neighborhood and Market Analysis (Word)
   - Market Conditions (Word)
   - Adjustment_Support_Comments (Word)
   - Adjustment_Method_Definitions (Word)
   - DISCLOSURES (Word)
   - Adjustment Methods Workbook (Excel — every calculation, traceable)
   - Eight market charts (images, named for what they show)

Copy what you need into your report, keep the rest in your workfile, and type
your adjustments into your forms software by hand.

## You must know this — default comment language

**The Adjustment Support Comments document contains default language.** On any
grid line where the analysis produced no results (Location, Condition, and
Quality almost always; occasionally others) and you entered an adjustment, the
document states by default that support was provided by **Paired Sales, Adjusted
Paired Sales and/or Online Depreciated Cost analysis.** That sentence describes
support you are expected to have in your own workfile. It reads exactly like
every other comment — nothing marks it as a default.

**It is your responsibility to review every comment and to modify or remove any
that do not reflect your actual workfile before using the document.** The
DISCLOSURES file in every ZIP restates this and the other terms of use — read it
once, and keep it with your workfile.

## Troubleshooting

| Symptom | Fix |
|---|---|
| "Cannot read file" | Re-export from your MLS as CSV (not PDF/XLSX), or paste the text into the chat. |
| A grid line shows "No analysis results" | Not an error — your data has no variation on that feature. Enter your figure; the default comment rule above applies. |
| A range looks wrong | Open the workbook tab for that line — every number traces to a data row. Screened-out results are shown with reasons. |
| The run is slow before the Reconciliation | Make sure extended thinking is off, and answer the first question (the extra-fields gate) promptly — the run waits for it. |
| New chat doesn't know your data | That's expected — attach your CSVs again. |

## Rules the tool will not break

- It stops and asks you on every grid line — there is no auto-select mode.
- It writes nothing into your report or forms software.
- Unreadable data stops the run — it is never guessed at.
