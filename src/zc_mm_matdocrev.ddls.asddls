@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Reverse Material Document - Projection Root View'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity ZC_MM_MATDOCREV
  provider contract transactional_query
  as projection on ZI_MM_MATDOCREV
{
  key MaterialDocument,
  key MaterialDocumentYear,

      PostingDate,
      DocumentDate,
      MaterialDocumentHeaderText,
      GoodsMovementCode,

      ReverseDocument,
      ReverseDocumentYear,

      CreatedByUser,
      CreationDateTime,

      IsReversed,
      ReversalCriticality,

      _item : redirected to composition child ZC_MM_MATDOCREV_ITEM
}
