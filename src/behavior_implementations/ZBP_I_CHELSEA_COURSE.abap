
CLASS lhc_ZI_CHELSEA_COURSE DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations
      FOR zi_chelsea_course RESULT result.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations
      FOR zi_chelsea_course RESULT result.

    METHODS precheck_delete
      FOR PRECHECK
      IMPORTING keys FOR DELETE zi_chelsea_course.

ENDCLASS.


CLASS lhc_ZI_CHELSEA_COURSE IMPLEMENTATION.

  METHOD get_instance_authorizations.

    READ ENTITIES OF zi_chelsea_course IN LOCAL MODE
      ENTITY zi_chelsea_course
      FIELDS ( course_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_courses).

    result = VALUE #(
      FOR ls_course IN lt_courses
      (
        %tky = ls_course-%tky
        %update = if_abap_behv=>auth-allowed
        %delete = if_abap_behv=>auth-allowed
      )
    ).

  ENDMETHOD.


  METHOD get_global_authorizations.

    result = VALUE #(
      %create = if_abap_behv=>auth-allowed
    ).

  ENDMETHOD.


  METHOD precheck_delete.

    READ ENTITIES OF zi_chelsea_course IN LOCAL MODE
      ENTITY zi_chelsea_course
      FIELDS ( course_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_courses).

    LOOP AT lt_courses INTO DATA(ls_course).

      SELECT SINGLE enrollment_id
        FROM zchelsea_enroll
        WHERE course_id = @ls_course-course_id
        INTO @DATA(lv_enrollment_id).

      IF sy-subrc = 0.

        APPEND VALUE #(
          %tky = ls_course-%tky
        ) TO failed-zi_chelsea_course.

        APPEND VALUE #(
          %tky = ls_course-%tky
          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Cannot delete course with enrollments'
          )
        ) TO reported-zi_chelsea_course.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
