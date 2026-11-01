
CLASS lhc_ZI_CHELSEA_STUDENT DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations
      FOR zi_chelsea_student RESULT result.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations
      FOR zi_chelsea_student RESULT result.

    METHODS precheck_delete
      FOR PRECHECK
      IMPORTING keys FOR DELETE zi_chelsea_student.

ENDCLASS.


CLASS lhc_ZI_CHELSEA_STUDENT IMPLEMENTATION.

  METHOD get_instance_authorizations.

    READ ENTITIES OF zi_chelsea_student IN LOCAL MODE
      ENTITY zi_chelsea_student
      ALL FIELDS WITH CORRESPONDING #( keys )
      RESULT DATA(lt_students).

    result = VALUE #(
      FOR ls_student IN lt_students
      (
        %tky = ls_student-%tky

        %update = COND #(
          WHEN requested_authorizations-%update
            = if_abap_behv=>mk-on
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized
        )

        %delete = COND #(
          WHEN requested_authorizations-%delete
            = if_abap_behv=>mk-on
          THEN if_abap_behv=>auth-allowed
          ELSE if_abap_behv=>auth-unauthorized
        )
      )
    ).

  ENDMETHOD.


  METHOD get_global_authorizations.

    IF requested_authorizations-%create
       = if_abap_behv=>mk-on.

      result-%create = if_abap_behv=>auth-allowed.

    ENDIF.

  ENDMETHOD.


  METHOD precheck_delete.

    READ ENTITIES OF zi_chelsea_student IN LOCAL MODE
      ENTITY zi_chelsea_student
      FIELDS ( student_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_students).

    LOOP AT lt_students INTO DATA(ls_student).

      SELECT SINGLE enrollment_id
        FROM zchelsea_enroll
        WHERE student_id = @ls_student-student_id
        INTO @DATA(lv_enrollment_id).

      IF sy-subrc = 0.

        APPEND VALUE #(
          %tky = ls_student-%tky
        ) TO failed-zi_chelsea_student.

        APPEND VALUE #(
          %tky = ls_student-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Cannot delete student with enrollments'
          )
        ) TO reported-zi_chelsea_student.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
