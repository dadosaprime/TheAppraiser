# TheAppraiser

Open tooling for residential real estate appraisal analysis.

## FullPackageRunner.md

A single self-contained instruction file that takes four MLS CSV exports and produces a complete adjustment support package:

- **Market conditions (time) analysis** — regression across nested market cuts, with a resolution threshold and a sign-stability test
- **Eight market scatter charts** — price, price per square foot, months of supply, days on market, concessions, contribution, absorption, sales count
- **Neighborhood and market analysis** — six-section narrative
- **Adjustment derivation** — twenty-plus methods across two tiers, screened for direction and dispersion
- **Adjustment support commentary** and a **methods workbook** with live Excel formulas

### The design rule that matters most

**The software produces the range. The appraiser produces the adjustment.**

The file computes ranges. It never selects an adjustment. There is no automatic mode, no default-to-median mode, and no fast path — the appraiser is asked on every grid line, on every assignment, every time. The appraiser signs the report, so the appraiser develops the number. Rule 0 exists to keep it that way and to stop anyone from optimizing it away later.

### What it will not do

- Estimate a cost figure without a cost source
- Continue past an unreadable input file
- Apply a market conditions rate that failed its own significance test
- Fabricate a spreadsheet formula check it cannot actually compute
- Carry any figure over from a prior report

### Using it

Drop the file into a Claude project, attach the four exports, and paste the command block at the top of the file.

The MLS column names are from SPARK/StellarMLS. On a different MLS, remap the field table in Phase 1 — the analysis itself does not change.

### Scope

Residential. USPAP-aware. Written for Florida practice but the methodology is not state specific.

It does not write the sales comparison narrative — that needs the completed grid and is a separate step.

### Verification

Every tolerance, formula and format was run end to end on a live assignment before release. The example figures in the traps section come from that run. No property is identified and no client, lender or borrower information appears anywhere in the file.

### License

MIT. Use it, fork it, adapt it to your market.

### A note on the traps section

The known-traps list is the part worth reading even if you never run the file. Each entry is a real failure caught in production, not a hypothetical — a new construction premium hiding inside an age variable, a half bath measuring a floor plan instead of a bathroom, uncontrolled methods inflating correlated features by 8x. Those are the ways an automated adjustment run goes quietly wrong.
