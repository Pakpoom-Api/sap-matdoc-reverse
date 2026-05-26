@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Reverse Material Document - Interface Item View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
    serviceQuality: #X,
    sizeCategory:   #M,
    dataClass:      #TRANSACTIONAL
}
define view entity ZI_MM_MATDOCREV_ITEM
  as select from I_MaterialDocumentItem_2
  association to parent ZI_MM_MATDOCREV as _MatDocRev
    on  $projection.MaterialDocument     = _MatDocRev.MaterialDocument
    and $projection.MaterialDocumentYear = _MatDocRev.MaterialDocumentYear
{
  key MaterialDocument,
  key MaterialDocumentYear,
  key MaterialDocumentItem,

      Material,
      Plant,
      StorageLocation,
      Batch,
      GoodsMovementType,

      @Semantics.quantity.unitOfMeasure: 'QuantityUnit'
      Quantity,
      QuantityUnit,

      @Semantics.quantity.unitOfMeasure: 'EntryUnit'
      EntryQuantity,
      EntryUnit,

      GoodsMovementRefDocType,
      InventorySpecialStockType,
      GoodsRecipientName,
      UnloadingPointName,

      _MatDocRev
}
