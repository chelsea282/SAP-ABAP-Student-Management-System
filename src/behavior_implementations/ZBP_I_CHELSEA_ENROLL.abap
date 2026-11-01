
CLASS lhc_ZI_CHELSEA_ENROLL DEFINITION
  INHERITING FROM cl_abap_behavior_handler.

  PRIVATE SECTION.

    METHODS get_instance_authorizations
      FOR INSTANCE AUTHORIZATION
      keys REQUEST requested_authorizations
      FOR zi_chelsea_enroll RESULT result.

    METHODS get_global_authorizations
      FOR GLOBAL AUTHORIZATION
      REQUEST requested_authorizations
      FOR zi_chelsea_enroll RESULT result.

    METHODS precheck_delete
      FOR PRECHECK
      IMPORTING keys FOR DELETE zi_chelsea_enroll.

    METHODS validateStudentCourse
      FOR VALIDATE ON SAVE
      IMPORTING keys FOR
        zi_chelsea_enroll~validateStudentCourse.

ENDCLASS.


CLASS lhc_ZI_CHELSEA_ENROLL IMPLEMENTATION.

  METHOD get_instance_authorizations.

    result = VALUE #(
      FOR key IN keys
      (
        %tky = key-%tky

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

    READ ENTITIES OF zi_chelsea_enroll IN LOCAL MODE
      ENTITY zi_chelsea_enroll
      FIELDS ( enrollment_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_enrollments).

    LOOP AT lt_enrollments INTO DATA(ls_enrollment).

      SELECT SINGLE marks_id
        FROM zchelsea_marks
        WHERE enrollment_id = @ls_enrollment-enrollment_id
        INTO @DATA(lv_marks_id).

      IF sy-subrc = 0.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky
        ) TO failed-zi_chelsea_enroll.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Cannot delete enrollment with marks'
          )
        ) TO reported-zi_chelsea_enroll.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.


  METHOD validateStudentCourse.

    READ ENTITIES OF zi_chelsea_enroll IN LOCAL MODE
      ENTITY zi_chelsea_enroll
      FIELDS ( student_id course_id )
      WITH CORRESPONDING #( keys )
      RESULT DATA(lt_enrollments).

    LOOP AT lt_enrollments INTO DATA(ls_enrollment).

      SELECT SINGLE student_id
        FROM zchelsea_stu
        WHERE student_id = @ls_enrollment-student_id
        INTO @DATA(lv_student_id).

      IF sy-subrc <> 0.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky
        ) TO failed-zi_chelsea_enroll.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Student ID does not exist'
          )

          %element-student_id = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_enroll.

      ENDIF.


      SELECT SINGLE course_id
        FROM zchelsea_course
        WHERE course_id = @ls_enrollment-course_id
        INTO @DATA(lv_course_id).

      IF sy-subrc <> 0.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky
        ) TO failed-zi_chelsea_enroll.

        APPEND VALUE #(
          %tky = ls_enrollment-%tky

          %msg = new_message(
            id       = '00'
            number   = '001'
            severity = if_abap_behv_message=>severity-error
            v1       = 'Course ID does not exist'
          )

          %element-course_id = if_abap_behv=>mk-on
        ) TO reported-zi_chelsea_enroll.

      ENDIF.

    ENDLOOP.

  ENDMETHOD.

ENDCLASS.
