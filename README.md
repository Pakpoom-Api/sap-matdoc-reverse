# SAP Fiori — Reverse Material Document
### Enterprise RAP + OData V4 | ZMM_MATDOCREV_V1 | MBST/MIGO Cancel Equivalent

---

## Overview

Fiori Elements **List Report + Object Page** application for reversing (cancelling) SAP Material Documents. Replaces transaction **MBST** and **MIGO cancellation** with a modern Fiori UI built on the RESTful ABAP Programming Model (RAP).

| Property | Value |
|---|---|
| **Package** | `ZMM_MATDOCREV_V1` |
| **Module** | MM — Materials Management |
| **App ID** | `ZMMF001` |
| **RAP Type** | Unmanaged · Action-Only · No custom persistent table |
| **OData** | V4 only |
| **BDEF Mode** | `strict ( 2 )` |
| **Source BO** | `I_MaterialDocumentTP` (SAP Standard Released) |

---

## Architecture

```
Fiori UI (OData V4)
    │
    ▼
ZSB_MM_MATDOCREV_UI  (Service Binding — OData V4 UI)
ZSD_MM_MATDOCREV_SRV (Service Definition)
    │
    ▼
ZC_MM_MATDOCREV       (Projection Root — transactional_query)
ZC_MM_MATDOCREV_ITEM  (Projection Item)
Metadata Extensions   (@UI annotations)
    │
    ▼
ZI_MM_MATDOCREV       (Interface Root — selects I_MaterialDocumentTP)
ZI_MM_MATDOCREV_ITEM  (Interface Item — selects I_MaterialDocumentItem_2)
    │
    ▼
I_MaterialDocumentTP  (SAP Standard Released BO — source of truth)
I_MaterialDocumentItem_2
    │
    ▼  EML action
MODIFY ENTITIES OF i_materialdocumenttp EXECUTE Cancel
```

---

## Artifacts (13 files — activate in order)

| # | File | SAP Object | Type |
|---|---|---|---|
| 01 | `01_ZI_MM_MATDOCREV.ddls` | `ZI_MM_MATDOCREV` | Interface Root CDS View |
| 02 | `02_ZI_MM_MATDOCREV_ITEM.ddls` | `ZI_MM_MATDOCREV_ITEM` | Interface Item CDS View |
| 03 | `03_ZC_MM_MATDOCREV.ddls` | `ZC_MM_MATDOCREV` | Projection Root CDS View |
| 04 | `04_ZC_MM_MATDOCREV_ITEM.ddls` | `ZC_MM_MATDOCREV_ITEM` | Projection Item CDS View |
| 05 | `05_ZC_MM_MATDOCREV_MDE.ddlx` | `ZC_MM_MATDOCREV` | Metadata Extension (Root) |
| 06 | `06_ZC_MM_MATDOCREV_ITEM_MDE.ddlx` | `ZC_MM_MATDOCREV_ITEM` | Metadata Extension (Item) |
| 07 | `07_ZI_MM_MATDOCREV_BDEF.bdef` | `ZI_MM_MATDOCREV` | Behavior Definition (Interface) |
| 08 | `08_ZC_MM_MATDOCREV_BDEF.bdef` | `ZC_MM_MATDOCREV` | Behavior Definition (Projection) |
| 09 | `09_ZBP_I_MM_MATDOCREV_CLAS.abap` | `ZBP_I_MM_MATDOCREV` | Behavior Pool Class |
| 10 | `10_ZCL_MM_MATDOCREV_ACTION_CLAS.abap` | `ZCL_MM_MATDOCREV_ACTION` | Business Logic Class |
| 11 | `11_ZSD_MM_MATDOCREV_SRV.srvd` | `ZSD_MM_MATDOCREV_SRV` | Service Definition |
| 12 | `12_ZSB_MM_MATDOCREV_UI.md` | `ZSB_MM_MATDOCREV_UI` | Service Binding (manual steps) |
| 13 | `13_ZMMF001_MANIFEST.json` | `ZMMF001` | Fiori App Manifest |

---

## Features

- **List Report** with filter bar: Material Document, Year, Posting Date, Movement Code
- **Multi-select** reversal: select multiple documents → click action button → all reversed
- **Smart button state**: action button auto-disabled (greyed) for already-reversed documents
- **Object Page**: header facets + document items table
- **Criticality coloring**: reversed documents shown with red icon in list
- **Full message handling**: success toast / error toast from EML `reported` / `failed`
- **No draft**: single-step action, no edit workflow required

---

## Action: Cancel (→ "Reverse Material Document" label on UI)

```
User selects document(s) → clicks "Reverse Material Document" button
    ↓
get_instance_features: verify IsReversed ≠ 'X'  (button disabled if already reversed)
    ↓
lhc_ZI_MM_MATDOCREV::Cancel  (MatDocRev~Cancel)
    ↓
ZCL_MM_MATDOCREV_ACTION::validate_can_reverse()   (uses ReverseDocument from READ ENTITIES)
    ↓
ZCL_MM_MATDOCREV_ACTION::call_eml_cancel()
    DATA lt_keys TYPE TABLE FOR ACTION IMPORT i_materialdocumenttp~Cancel
    MODIFY ENTITIES OF i_materialdocumenttp
      ENTITY MaterialDocument
      EXECUTE Cancel FROM lt_keys
      %key-MaterialDocument / %key-MaterialDocumentYear
    ↓
Propagate reported / failed → Fiori UI toast message
```

---

## SAP Activation Order

> **Rule: always activate Root before Child. Never activate Child before Root.**

```
1.  ZI_MM_MATDOCREV        (Interface Root CDS)
2.  ZI_MM_MATDOCREV_ITEM   (Interface Item CDS)
3.  ZC_MM_MATDOCREV        (Projection Root CDS)
4.  ZC_MM_MATDOCREV_ITEM   (Projection Item CDS)
5.  ZC_MM_MATDOCREV        (Metadata Extension)
6.  ZC_MM_MATDOCREV_ITEM   (Metadata Extension)
7.  ZI_MM_MATDOCREV        (Behavior Definition)
8.  ZC_MM_MATDOCREV        (Behavior Definition)
9.  ZBP_I_MM_MATDOCREV     (Behavior Pool Class)
10. ZCL_MM_MATDOCREV_ACTION (Business Logic Class)
11. ZSD_MM_MATDOCREV_SRV   (Service Definition)
12. ZSB_MM_MATDOCREV_UI    (Service Binding — then Publish)
13. ZMMF001                 (Fiori App via Fiori Generator)
```

---

## IAM Setup

```
IAM App:          ZMMF001
Business Catalog: ZBC_MM_MATDOCREV
Role Template:    ZBR_MM_MATDOCREV
```

Assign `ZBR_MM_MATDOCREV` → create Business Role → assign to users.

---

## Technical Notes

- **No custom database table**: data sourced entirely from `I_MaterialDocumentTP`
- **EML action name**: `Cancel` (PascalCase — matches SAP released API)
- **Key structure**: `%key-MaterialDocument` + `%key-MaterialDocumentYear`
- **Validation**: pre-checked in `ZCL_MM_MATDOCREV_ACTION` using data passed from `READ ENTITIES` (no redundant SELECT)
- **Lock**: `lock master unmanaged` — custom BO defers to standard SAP BO locking

---

## Coding Standards

- ABAP Cloud compliant
- `strict ( 2 )` everywhere
- EML only inside behavior handler (`READ ENTITIES` / `MODIFY ENTITIES`)
- `VALUE #( )` and `CORRESPONDING #( )` patterns
- No obsolete ABAP syntax
- No SELECT inside behavior handler methods
- No hardcoded values — constants used for status fields

---

## Author

- **Developer**: Ta (naypac00@gmail.com)
- **Package**: `ZMM_MATDOCREV_V1`
- **Generated**: 2026-05-22
- **Reference**: SAP RAP Fiori Skill — Enterprise Standard
