CLASS ZBP_I_MM_MATDOCREV DEFINITION PUBLIC ABSTRACT FINAL
  FOR BEHAVIOR OF ZI_MM_MATDOCREV.
ENDCLASS.
CLASS ZBP_I_MM_MATDOCREV IMPLEMENTATION.
ENDCLASS.

"══════════════════════════════════════════════════════════════
" Handler class for ZI_MM_MATDOCREV
"══════════════════════════════════════════════════════════════

CLASS lhc_ZI_MM_MATDOCREV DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS:

      get_instance_features FOR INSTANCE FEATURES
        IMPORTING keys             REQUEST requested_features
                  FOR MatDocRev   RESULT  result,

      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING REQUEST requested_authorizations FOR MatDocRev
        RESULT result,

      Cancel FOR MODIFY
        IMPORTING keys FOR ACTION MatDocRev~Cancel
        RESULT result.

ENDCLASS.

CLASS lhc_ZI_MM_MATDOCREV IMPLEMENTATION.

  METHOD get_instance_features.
    READ ENTITIES OF ZI_MM_MATDOCREV IN LOCAL MODE
      ENTITY MatDocRev
      FIELDS ( ReverseDocument IsReversed )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_data).

    result = VALUE #( FOR ls IN lt_data (
      %tky = ls-%tky
      %features-%action-Cancel =
        COND #( WHEN ls-IsReversed = 'X'
                THEN if_abap_behv=>fc-o-disabled
                ELSE if_abap_behv=>fc-o-enabled )
    ) ).
  ENDMETHOD.

  METHOD get_global_authorizations.
    result-%action-Cancel = if_abap_behv=>auth-allowed.
  ENDMETHOD.

  METHOD Cancel.
    READ ENTITIES OF ZI_MM_MATDOCREV IN LOCAL MODE
      ENTITY MatDocRev
      ALL FIELDS
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_matdocs).

    LOOP AT lt_matdocs INTO DATA(ls_doc).

      DATA(lo_action) = NEW ZCL_MM_MATDOCREV_ACTION(
        iv_material_document      = ls_doc-MaterialDocument
        iv_material_document_year = ls_doc-MaterialDocumentYear
        iv_reverse_document       = ls_doc-ReverseDocument
      ).

      IF lo_action->execute( ) = abap_true.
        result = VALUE #( BASE result (
          %tky   = ls_doc-%tky
          %param = ls_doc
        ) ).
      ELSE.
        LOOP AT lo_action->get_messages( ) INTO DATA(ls_msg).
          APPEND VALUE #(
            %tky = ls_doc-%tky
            %msg = new_message(
              id       = ls_msg-id
              number   = ls_msg-number
              severity = if_abap_behv_message=>severity-error
              v1       = ls_msg-v1
              v2       = ls_msg-v2
              v3       = ls_msg-v3
              v4       = ls_msg-v4
            )
          ) TO reported-matdocrev.

          APPEND VALUE #( %tky = ls_doc-%tky )
            TO failed-matdocrev.
        ENDLOOP.
      ENDIF.

    ENDLOOP.
  ENDMETHOD.

ENDCLASS.
