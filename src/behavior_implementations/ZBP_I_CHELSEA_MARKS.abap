
CLASS lhc_ZI_CHELSEA_MARKS DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations
      FOR zi_chelsea_marks RESULT result.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations
      FOR zi_chelsea_marks RESULT result.

    METHODS validateEnrollment
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_CHELSEA_MARKS~validateEnrollment.

    METHODS validateMarksRange
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_CHELSEA_MARKS~validateMarksRange.

    METHODS validateDuplicateSubject
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR ZI_CHELSEA_MARKS~validateDuplicateSubject.

ENDCLASS.


CLASS lhc_ZI_CHELSEA_MARKS IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = VALUE #(
      FOR key IN keys
      (
        %tky = key-%tky

        %update = COND #(
          WHEN requested_authorizations-%update = if_abap_behv=>mk-on
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized
        )

        %delete = COND #(
          WHEN requested_authorizations-%delete = if_abap_behv=>mk-on
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized
        )
      )
    ).

  ENDMETHOD.


  METHOD get_global_authorizations.

    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.

  ENDMETHOD.


  METHOD validateEnrollment.

    READ ENTITIES OF ZI_CHELSEA_MARKS IN LOCAL MODE
      ENTITY ZI_CHELSEA_MARKS
      FIELDS ( enrollment_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_marks).

    LOOP AT lt_marks INTO DATA(ls_marks).

      SELECT SINGLE enrollment_id
        FROM zchelsea_enroll
        WHERE enrollment_id = @ls_marks-enrollment_id
        INTO @DATA(lv_enrollment_id).

      IF sy-subrc <> 0.

        APPEND VALUE #(
          %tky = ls_marks-%tky
        ) TO failed-zi_chelsea_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Enrollment ID does not exist'
          )

          %element-enrollment_id = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_marks.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD validateMarksRange.

    READ ENTITIES OF ZI_CHELSEA_MARKS IN LOCAL MODE
      ENTITY ZI_CHELSEA_MARKS
      FIELDS ( max_marks marks_obtained )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_marks).

    LOOP AT lt_marks INTO DATA(ls_marks).

      IF ls_marks-max_marks <= 0.

        APPEND VALUE #(
          %tky = ls_marks-%tky
        ) TO failed-zi_chelsea_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Maximum marks must be greater than zero'
          )

          %element-max_marks = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_marks.

      ENDIF.


      IF ls_marks-marks_obtained < 0.

        APPEND VALUE #(
          %tky = ls_marks-%tky
        ) TO failed-zi_chelsea_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Marks obtained cannot be negative'
          )

          %element-marks_obtained = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_marks.

      ENDIF.


      IF ls_marks-marks_obtained > ls_marks-max_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky
        ) TO failed-zi_chelsea_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Marks obtained cannot exceed maximum marks'
          )

          %element-marks_obtained = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_marks.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD validateDuplicateSubject.

    READ ENTITIES OF ZI_CHELSEA_MARKS IN LOCAL MODE
      ENTITY ZI_CHELSEA_MARKS
      FIELDS ( marks_id enrollment_id subject_name )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_marks).

    LOOP AT lt_marks INTO DATA(ls_marks).

      " Check records already saved in the database
      SELECT SINGLE marks_id
        FROM zchelsea_marks
        WHERE enrollment_id = @ls_marks-enrollment_id
          AND subject_name = @ls_marks-subject_name
          AND marks_id <> @ls_marks-marks_id
        INTO @DATA(lv_existing_marks_id).

      DATA(lv_duplicate) = xsdbool( sy-subrc = 0 ).

      " Check other records in the current validation batch
      LOOP AT lt_marks INTO DATA(ls_other).

        IF ls_other-marks_id <> ls_marks-marks_id
           AND ls_other-enrollment_id = ls_marks-enrollment_id
           AND ls_other-subject_name = ls_marks-subject_name.

          lv_duplicate = abap_true.
          EXIT.

        ENDIF.

      ENDLOOP.

      IF lv_duplicate = abap_true.

        APPEND VALUE #(
          %tky = ls_marks-%tky
        ) TO failed-zi_chelsea_marks.

        APPEND VALUE #(
          %tky = ls_marks-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Marks already exist for this subject and enrollment'
          )

          %element-subject_name = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_marks.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
