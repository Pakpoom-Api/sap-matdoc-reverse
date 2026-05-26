/*
  Service Binding: ZSB_MM_MATDOCREV_UI
  Type           : OData V4 - UI
  Service Def    : ZSD_MM_MATDOCREV_SRV
  Package        : ZMM_MATDOCREV_V1

  ── MANUAL SETUP STEPS IN SAP ADT ────────────────────────────────

  1. Right-click Package ZMM_MATDOCREV_V1
     → New → Other ABAP Repository Object
     → Business Services → Service Binding
     → Finish

  2. Fill fields:
     Name         :  ZSB_MM_MATDOCREV_UI
     Description  :  Reverse Material Document - OData V4 UI Binding
     Binding Type :  OData V4 - UI
     Service Def  :  ZSD_MM_MATDOCREV_SRV

  3. Save and Activate

  4. Click [ Publish ] in the Service Binding editor

  5. Click [ Service URL ] or [ Preview ] to open the Fiori Elements preview
     → Select entity: MatDoc
     → Verify:
         ✓ Filter bar shows: MaterialDocument, Year, PostingDate, GoodsMovementCode
         ✓ List table shows all columns including IsReversed with icon
         ✓ Toolbar button "Reverse Material Document" visible
         ✓ Button disabled (grey) on already-reversed rows (IsReversed = 'X')
         ✓ Clicking a row navigates to Object Page
         ✓ Object Page shows Header section + Items table

  ── RUNTIME SERVICE URL (after Publish) ──────────────────────────

  /sap/opu/odata4/sap/zsd_mm_matdocrev_srv/srvd/sap/zsd_mm_matdocrev_srv/0001/

  ── OData V4 TEST REQUESTS ───────────────────────────────────────

  GET List:
    .../MatDoc

  GET Single Document:
    .../MatDoc(MaterialDocument='4900000001',MaterialDocumentYear='2024')

  GET Items:
    .../MatDoc(MaterialDocument='4900000001',MaterialDocumentYear='2024')/_item

  POST Cancel Action (single):
    POST .../MatDoc(MaterialDocument='4900000001',MaterialDocumentYear='2024')/Cancel
    Body: {}
    Content-Type: application/json

  ── IAM SETUP CHAIN ──────────────────────────────────────────────

  Step 1 — IAM Application
    Name    : ZMMF001
    Type    : UI5 Application
    Assign  : Service Binding ZSB_MM_MATDOCREV_UI

  Step 2 — Business Catalog
    Name    : ZBC_MM_MATDOCREV
    Label   : Reverse Material Document
    Tab Apps → Add ZMMF001

  Step 3 — Business Role Template
    Name    : ZBR_MM_MATDOCREV
    Label   : Reverse Material Document Role
    Add Business Catalog: ZBC_MM_MATDOCREV

  Step 4 — Launchpad Tile
    Semantic Object : MM_MatDocRev
    Action          : manage
    Title           : Reverse Material Document
    Subtitle        : Cancel Material Documents
    Icon            : sap-icon://decline
*/
