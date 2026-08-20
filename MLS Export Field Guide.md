# MLS EXPORT FIELD GUIDE

Companion to the **Adjustment Support Tool**.
This is the checklist for building your MLS CSV export so the tools have what they
need. Columns are matched by **meaning**, not by exact name — the "Common names"
column shows typical headers from major MLS systems, and close variants work.

The safest export is your MLS's full residential export with **all columns
included**. Extra columns are ignored and cost nothing. Missing columns cost
analysis. Only trim the export if your MLS forces you to.

---

## Tier 1 — Required. The run stops without these.

| Field | Common names | Why it is required |
|---|---|---|
| Address | Address, Street Address, Full Address | Identifies every record in the analysis and documents |
| Sale price | Close Price, Sold Price, Sale Price | The dependent variable in every method |
| Sale date | Close Date, Sold Date, Closing Date | Time adjustment and market conditions |
| Living area | Heated Area, Living Area, GLA, SqFt Heated | The primary size variable |
| Status | Status (Sold / Active / Pending / Leased) | Separates sales from competing inventory |

## Tier 2 — Core analysis. Missing these weakens every result.

| Field | Common names | What it feeds |
|---|---|---|
| Contract date | Contract Date, Pending Date, Under Contract Date | The market conditions per-comparable table (contract date, not close date, is when price was struck) |
| Seller concessions | Seller Paid Buyer Costs, Seller Concessions, Concessions | Cash-equivalent prices — every method runs on these |
| Financing | Sold Terms, Financing, Terms of Sale | Screens non-cash-equivalent sales (owner financing, assumption, etc.) |
| Sale condition | Special Sale Provision(s), Sale Condition | Screens REO, short sales, auction, estate, relocation |
| Ownership | Ownership | Screens leasehold |
| Beds | Beds, Bedrooms | Bedroom line + paired-sales matching |
| Full / half baths | Full Baths; Half Baths | Bath lines + matching |
| Lot size | Lot Size Square Footage, Lot SqFt, Acres | Site line |
| Year built | Year Built, Yr Built | Age line |
| List price + original list price | List Price; Original List Price | Market conditions, list-to-sale behavior |
| DOM | ADOM, CDOM, Days on Market | Marketing time indicators |
| MLS number | MLS Number, MLS #, Listing ID | Data source citations in the documents |
| City / Zip / County | City; Zip, Postal Code; County | Market segmentation |

## Tier 3 — Feature lines. Each enables one grid line; missing = that line reads "no data."

| Field | Common names | Grid line |
|---|---|---|
| Garage spaces | Garage Spaces | Garage |
| Carport spaces | Carport Spaces | Carport |
| Private pool flag | Pool Private Y/N, Private Pool | Pool (private) |
| Pool features | Pool Features | Pool type separation (in-ground / above-ground / screen enclosure / spa) |
| Water frontage | Water Frontage Y/N; Water Frontage (type) | Waterfront line |
| Water view | Water View Y/N; Water View (type) | Water view line (separate from waterfront) |
| View | View | Non-water view lines (woods, golf, park — each separated) |
| Fireplace | Fireplace Y/N | Fireplace |
| Stories | Floors in Unit/Home, Stories, Total # of Floors | Design/story matching |
| In-law / ADU | In-Law Suite Y/N, In-Law Suite Under Air SQFT, Accessory Dwelling | ADU line (flagged less reliable — agent entry varies) |
| Builder / model | Builder Name; Builder Model | Model matching, new-construction context |

## Tier 4 — Data quality and narrative. Strongly recommended.

| Field | Common names | Why it matters |
|---|---|---|
| Public remarks | Public Remarks, Remarks | The audit layer: pool/view flags are cross-checked against remarks; GLA is cross-checked against stated square footage; concession and condition detail feeds the narrative. Never used as a numeric source. |
| Subdivision | Legal Subdivision Name, Subdivision, Subdivision/Condo Name | Paired-sales matching (names are normalized — CRK/CREEK, PRCL/PARCEL, reordered words) |
| Tax ID / parcel | Tax ID, Parcel Number, APN | Record identification |
| Property type / style | Property Type; Property Style, Property Description | Product screening (detached / townhouse / condo / manufactured) |
| HOA / condo fees | HOA Fee; Condo Fee + schedules | Product context, fee-inclusive pricing |
| Interior / exterior features | Interior Features; Exterior Features | Feature audits and narrative |
| Flood zone | Flood Zone Code | Subject context |
| Zoning | Zoning | Subject and site context |

---


## Export practice — the five habits that make runs clean

1. **All statuses, one file per search.** Include Sold, Active, and Pending — the
   tools separate them and use live listings for supply and marketing-time
   indicators. Do not pre-filter to Sold only.
2. **12 months minimum, 24 preferred** for the market-area searches — the time
   adjustment needs a series, not a snapshot.
3. **CSV format only.** Not PDF, not XLSX, not a print view. One header row, one
   record per row.
4. **Don't hand-edit the export.** Deleting columns, renaming headers, or sorting
   in Excel and re-saving can corrupt dates and drop leading zeros. Export, save,
   attach.
5. **Subject not in MLS?** Build a one-row CSV for the subject from public records
   using the same column headers as your comps file, and say so in the command's
   Notes line — the run will state the source in the output.

## What happens when a field is missing

The tools never guess. A missing Tier 1 field stops the run with a one-sentence
explanation. A missing Tier 2 field is reported and the affected screens or
indicators are skipped by name. A missing Tier 3 field means that grid line reports
"no data" — and if you enter an adjustment on it anyway, the default support
comment applies (see DISCLOSURES). Every unmapped column and every skipped concept
is listed in the run's output, so you always know what the analysis did and did not
see.
