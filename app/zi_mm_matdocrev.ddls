@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Reverse Material Document - Interface Root View'
@Metadata.ignorePropagatedAnnotations: true
@ObjectModel.usageType: {
    serviceQuality: #X,
    sizeCategory:   #M,
    dataClass:      #TRANSACTIONAL
}
define root view entity ZI_MM_MATDOCREV
  as select from I_MaterialDocumentTP
  composition [0..*] of ZI_MM_MATDOCREV_ITEM as _item
{
  key MaterialDocument,
  key MaterialDocumentYear,

      PostingDate,
      DocumentDate,
      MaterialDocumentHeaderText,
      GoodsMovementCode,

      ReverseDocument,
      ReverseDocumentYear,

      @Semantics.user.createdBy: true
      CreatedByUser,

      @Semantics.systemDateTime.createdAt: true
      CreationDateTime,

      case when ReverseDocument is not initial
           then cast( 'X' as abap.char(1) )
           else cast( ' ' as abap.char(1) )
      end as IsReversed,

      case when ReverseDocument is not initial
           then cast( 3 as abap.int1 )
           else cast( 0 as abap.int1 )
      end as ReversalCriticality,

      _item
}
