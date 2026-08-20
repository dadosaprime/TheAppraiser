# Adjustment Support Tool

Free, open-source adjustment support for residential appraisers — runs entirely
inside [Claude](https://claude.ai). No installs, no subscriptions, no data leaves
your chat.

Drop the tool file and your MLS CSV exports into a Claude chat, paste one
command, and it:

1. Measures market conditions several independent ways (the rate can be positive
   or negative — the tool reports facts, not verdicts)
2. Runs a multi-method adjustment engine — regression family, GAM, paired sales,
   grouped data, sensitivity — on every grid line the data supports, on every
   data cut, with visible screens and reasons
3. Shows the **Adjustment Reconciliation**: the Analysis Result Range for each
   line (Low / Median / High) with an **Appraiser's Adjustment** box — you enter
   every figure yourself; there is no auto-select
4. Delivers one ZIP: Neighborhood & Market Analysis, Market Conditions,
   Adjustment Support Comments, Method Definitions, DISCLOSURES, a fully
   traceable calculations workbook, and eight market charts

**The tool determines nothing.** It reports the range indicated by the market
under the methods utilized. Every adjustment is selected by the appraiser, typed
into the report by the appraiser, and supported in the appraiser's workfile.
Read `DISCLOSURES` in every output ZIP.

## Files

| File | What it is |
|---|---|
| `Adjustment Support Tool v[date].md` | The tool. Use the newest date. |
| `INSTRUCTIONS.md` | Start here — written for first-time Claude users |
| `MLS Export Field Guide.md` | Which MLS fields to include in your export, and why |
| `MLS Setup Tool v[date].md` | Run once if you're not on Stellar MLS — builds a profile so the tool reads your MLS |

## Quick start

1. Read `INSTRUCTIONS.md` (five minutes).
2. Export your CSVs per the `MLS Export Field Guide`.
3. Drag the tool file + your CSVs into a Claude chat, paste the command from
   Part One of the tool, fill in the address and effective date.
4. Answer the Reconciliation. Download the ZIP.

Built and tested on Stellar MLS (Matrix). Other MLS systems: run the
`MLS Setup Tool` once first.

## Versioning

Tool files are dated (`v2026-08-19`). The date is the build date and the version
history — newer date supersedes older. Nothing else to track.
