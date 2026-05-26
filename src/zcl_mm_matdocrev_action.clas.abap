CLASS ZCL_MM_MATDOCREV_ACTION DEFINITION
  PUBLIC
  FINAL
  CREATE PUBLIC.

  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_message,
        id     TYPE symsgid,
        number TYPE symsgno,
        type   TYPE symsgty,
        v1     TYPE symsgv,
        v2     TYPE symsgv,
        v3     TYPE symsgv,
        v4     TYPE symsgv,
      END OF ty_message,
      tt_messages TYPE STANDARD TABLE OF ty_message WITH EMPTY KEY.

    METHODS:

      constructor
        IMPORTING
          iv_material_document      TYPE mblnr
          iv_material_document_year TYPE mjahr
          iv_reverse_document       TYPE mblnr,

      execute
        RETURNING VALUE(rv_success) TYPE abap_bool,

      get_messages
        RETURNING VALUE(rt_messages) TYPE tt_messages.

  PRIVATE SECTION.

    DATA:
      mv_material_document      TYPE mblnr,
      mv_material_document_year TYPE mjahr,
      mv_reverse_document       TYPE mblnr,
      mt_messages               TYPE tt_messages.

    METHODS:
      validate_can_reverse
        RETURNING VALUE(rv_ok) TYPE abap_bool,

      call_eml_cancel,

      append_error
        IMPORTING
          iv_id     TYPE symsgid
          iv_number TYPE symsgno
          iv_v1     TYPE symsgv OPTIONAL
          iv_v2     TYPE symsgv OPTIONAL
          iv_v3     TYPE symsgv OPTIONAL
          iv_v4     TYPE symsgv OPTIONAL.

ENDCLASS.

CLASS ZCL_MM_MATDOCREV_ACTION IMPLEMENTATION.

  METHOD constructor.
    mv_material_document      = iv_material_document.
    mv_material_document_year = iv_material_document_year.
    mv_reverse_document       = iv_reverse_document.
  ENDMETHOD.

  METHOD execute.
    IF validate_can_reverse( ) = abap_false.
      rv_success = abap_false.
      RETURN.
    ENDIF.

    call_eml_cancel( ).

    rv_success = COND #(
      WHEN mt_messages IS INITIAL                      THEN abap_true
      WHEN line_exists( mt_messages[ type = 'E' ] )    THEN abap_false
      WHEN line_exists( mt_messages[ type = 'A' ] )    THEN abap_false
      ELSE abap_true
    ).
  ENDMETHOD.

  METHOD validate_can_reverse.
    IF mv_reverse_document IS NOT INITIAL.
      append_error(
        iv_id     = 'ZMM_01'
        iv_number = '002'
        iv_v1     = mv_material_document
        iv_v2     = mv_material_document_year
        iv_v3     = mv_reverse_document
      ).
      rv_ok = abap_false.
      RETURN.
    ENDIF.

    rv_ok = abap_true.
  ENDMETHOD.

  METHOD call_eml_cancel.
    DATA lt_keys TYPE TABLE FOR ACTION IMPORT i_materialdocumenttp~Cancel
                 WITH EMPTY KEY.

    APPEND VALUE #(
      %key-MaterialDocument     = mv_material_document
      %key-MaterialDocumentYear = mv_material_document_year
    ) TO lt_keys.

    MODIFY ENTITIES OF i_materialdocumenttp
      ENTITY MaterialDocument
      EXECUTE Cancel FROM lt_keys
      MAPPED   DATA(lt_mapped)
      FAILED   DATA(lt_failed)
      REPORTED DATA(lt_reported).

    IF lt_failed-materialdocument IS NOT INITIAL.
      append_error(
        iv_id     = 'ZMM_01'
        iv_number = '003'
        iv_v1     = mv_material_document
        iv_v2     = mv_material_document_year
      ).
    ENDIF.

    LOOP AT lt_reported-materialdocument INTO DATA(ls_rep)
      WHERE %msg IS NOT INITIAL.

      APPEND VALUE #(
        id     = ls_rep-%msg->if_t100_message~msgid
        number = ls_rep-%msg->if_t100_message~msgno
        type   = ls_rep-%msg->if_t100_message~msgty
        v1     = ls_rep-%msg->if_t100_message~attr1
        v2     = ls_rep-%msg->if_t100_message~attr2
        v3     = ls_rep-%msg->if_t100_message~attr3
        v4     = ls_rep-%msg->if_t100_message~attr4
      ) TO mt_messages.
    ENDLOOP.
  ENDMETHOD.

  METHOD append_error.
    APPEND VALUE #(
      id     = iv_id
      number = iv_number
      type   = 'E'
      v1     = iv_v1
      v2     = iv_v2
      v3     = iv_v3
      v4     = iv_v4
    ) TO mt_messages.
  ENDMETHOD.

  METHOD get_messages.
    rt_messages = mt_messages.
  ENDMETHOD.

ENDCLASS.
