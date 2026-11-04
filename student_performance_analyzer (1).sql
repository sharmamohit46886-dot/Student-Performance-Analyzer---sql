-- =====================================================================
-- Student Performance Analyzer Using Oracle SQL and PL/SQL  (BACK END)
-- Includes full CRUD (Create, Read, Update, Delete) - see sections 15 to 19.
-- Run in Oracle Live SQL, SQL Developer or SQL*Plus.
-- The file can be run again: old objects are dropped first.
-- =====================================================================
SET SERVEROUTPUT ON;

-- =========================================
-- 0. CLEAN UP (so the script can be re-run)
-- =========================================
BEGIN EXECUTE IMMEDIATE 'DROP PACKAGE STUDENT_CRUD';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_STUDENT';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_SUBJECT';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP SEQUENCE SEQ_MARK';     EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP VIEW STUDENT_RESULTS';  EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE MARKS';           EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE SUBJECTS';        EXCEPTION WHEN OTHERS THEN NULL; END;
/
BEGIN EXECUTE IMMEDIATE 'DROP TABLE STUDENTS';        EXCEPTION WHEN OTHERS THEN NULL; END;
/

-- =========================================
-- 1. CREATE STUDENTS TABLE
-- =========================================
CREATE TABLE STUDENTS (
    STUDENT_ID NUMBER PRIMARY KEY,
    STUDENT_NAME VARCHAR2(50) NOT NULL,
    COURSE VARCHAR2(30) NOT NULL,
    SEMESTER NUMBER NOT NULL CHECK (SEMESTER BETWEEN 1 AND 12)
);

-- =========================================
-- 2. CREATE SUBJECTS TABLE
-- =========================================
CREATE TABLE SUBJECTS (
    SUBJECT_ID NUMBER PRIMARY KEY,
    SUBJECT_NAME VARCHAR2(50) NOT NULL,
    MAX_MARKS NUMBER NOT NULL CHECK (MAX_MARKS > 0),
    PASS_MARKS NUMBER NOT NULL CHECK (PASS_MARKS >= 0),
    CONSTRAINT CHK_PASS_LE_MAX CHECK (PASS_MARKS <= MAX_MARKS)
);

-- =========================================
-- 3. CREATE MARKS TABLE
-- =========================================
CREATE TABLE MARKS (
    MARK_ID NUMBER PRIMARY KEY,
    STUDENT_ID NUMBER,
    SUBJECT_ID NUMBER,
    OBTAINED_MARKS NUMBER NOT NULL CHECK (OBTAINED_MARKS >= 0),
    CONSTRAINT FK_MARKS_STUDENT FOREIGN KEY (STUDENT_ID)
        REFERENCES STUDENTS(STUDENT_ID) ON DELETE CASCADE,
    CONSTRAINT FK_MARKS_SUBJECT FOREIGN KEY (SUBJECT_ID)
        REFERENCES SUBJECTS(SUBJECT_ID) ON DELETE CASCADE,
    CONSTRAINT UQ_STUDENT_SUBJECT UNIQUE (STUDENT_ID, SUBJECT_ID)
);

-- Marks can never be higher than the subject's maximum marks
CREATE OR REPLACE TRIGGER TRG_CHECK_MARKS
BEFORE INSERT OR UPDATE OF OBTAINED_MARKS ON MARKS
FOR EACH ROW
DECLARE
    V_MAX NUMBER;
BEGIN
    SELECT MAX_MARKS INTO V_MAX
    FROM SUBJECTS
    WHERE SUBJECT_ID = :NEW.SUBJECT_ID;

    IF :NEW.OBTAINED_MARKS < 0 OR :NEW.OBTAINED_MARKS > V_MAX THEN
        RAISE_APPLICATION_ERROR(-20001,
            'Marks must be between 0 and ' || V_MAX);
    END IF;
END;
/

-- Sequences give new rows their IDs (they start after the sample data)
CREATE SEQUENCE SEQ_STUDENT START WITH 5   INCREMENT BY 1;
CREATE SEQUENCE SEQ_SUBJECT START WITH 105 INCREMENT BY 1;
CREATE SEQUENCE SEQ_MARK    START WITH 17  INCREMENT BY 1;

-- =========================================
-- 4. INSERT STUDENT RECORDS
-- =========================================
INSERT INTO STUDENTS VALUES (1, 'Mohit', 'MCA', 1);
INSERT INTO STUDENTS VALUES (2, 'Rahul', 'MCA', 1);
INSERT INTO STUDENTS VALUES (3, 'Aman', 'MCA', 1);
INSERT INTO STUDENTS VALUES (4, 'Priya', 'MCA', 1);

-- =========================================
-- 5. INSERT SUBJECT RECORDS
-- =========================================
INSERT INTO SUBJECTS VALUES (101, 'DBMS', 100, 40);
INSERT INTO SUBJECTS VALUES (102, 'Python', 100, 40);
INSERT INTO SUBJECTS VALUES (103, 'Web Programming', 100, 40);
INSERT INTO SUBJECTS VALUES (104, 'Computer Networks', 100, 40);

-- =========================================
-- 6. INSERT MARKS
-- =========================================
INSERT INTO MARKS VALUES (1, 1, 101, 85);
INSERT INTO MARKS VALUES (2, 1, 102, 90);
INSERT INTO MARKS VALUES (3, 1, 103, 78);
INSERT INTO MARKS VALUES (4, 1, 104, 88);
INSERT INTO MARKS VALUES (5, 2, 101, 65);
INSERT INTO MARKS VALUES (6, 2, 102, 70);
INSERT INTO MARKS VALUES (7, 2, 103, 75);
INSERT INTO MARKS VALUES (8, 2, 104, 68);
INSERT INTO MARKS VALUES (9, 3, 101, 35);
INSERT INTO MARKS VALUES (10, 3, 102, 55);
INSERT INTO MARKS VALUES (11, 3, 103, 60);
INSERT INTO MARKS VALUES (12, 3, 104, 45);
INSERT INTO MARKS VALUES (13, 4, 101, 95);
INSERT INTO MARKS VALUES (14, 4, 102, 92);
INSERT INTO MARKS VALUES (15, 4, 103, 89);
INSERT INTO MARKS VALUES (16, 4, 104, 96);

COMMIT;

-- =========================================
-- 7. CREATE GRADE FUNCTION
-- =========================================
CREATE OR REPLACE FUNCTION CALCULATE_GRADE(
    P_PERCENTAGE NUMBER
)
RETURN VARCHAR2
IS
BEGIN
    IF P_PERCENTAGE >= 90 THEN
        RETURN 'A+';
    ELSIF P_PERCENTAGE >= 80 THEN
        RETURN 'A';
    ELSIF P_PERCENTAGE >= 70 THEN
        RETURN 'B';
    ELSIF P_PERCENTAGE >= 60 THEN
        RETURN 'C';
    ELSIF P_PERCENTAGE >= 40 THEN
        RETURN 'D';
    ELSE
        RETURN 'F';
    END IF;
END;
/

-- =========================================
-- 8. CREATE PERFORMANCE ANALYSIS PROCEDURE
-- =========================================
CREATE OR REPLACE PROCEDURE ANALYZE_PERFORMANCE
IS
    CURSOR C_STUDENTS IS
        SELECT STUDENT_ID, STUDENT_NAME
        FROM STUDENTS
        ORDER BY STUDENT_ID;

    V_TOTAL      NUMBER;
    V_MAX        NUMBER;
    V_PERCENTAGE NUMBER;
    V_GRADE      VARCHAR2(10);
    V_STATUS     VARCHAR2(10);
BEGIN
    FOR S IN C_STUDENTS LOOP

        SELECT SUM(M.OBTAINED_MARKS),
               SUM(SU.MAX_MARKS)
        INTO V_TOTAL, V_MAX
        FROM MARKS M
        JOIN SUBJECTS SU
            ON M.SUBJECT_ID = SU.SUBJECT_ID
        WHERE M.STUDENT_ID = S.STUDENT_ID;

        IF V_MAX IS NULL OR V_MAX = 0 THEN
            DBMS_OUTPUT.PUT_LINE(
                'No marks found for ' || S.STUDENT_NAME
            );
        ELSE
            V_PERCENTAGE := (V_TOTAL / V_MAX) * 100;
            V_GRADE := CALCULATE_GRADE(V_PERCENTAGE);

            SELECT CASE
                       WHEN COUNT(*) = SUM(
                           CASE
                               WHEN M.OBTAINED_MARKS >= SU.PASS_MARKS
                               THEN 1
                               ELSE 0
                           END
                       )
                       THEN 'PASS'
                       ELSE 'FAIL'
                   END
            INTO V_STATUS
            FROM MARKS M
            JOIN SUBJECTS SU
                ON M.SUBJECT_ID = SU.SUBJECT_ID
            WHERE M.STUDENT_ID = S.STUDENT_ID;

            DBMS_OUTPUT.PUT_LINE('-----------------------------');
            DBMS_OUTPUT.PUT_LINE('Student Name: ' || S.STUDENT_NAME);
            DBMS_OUTPUT.PUT_LINE('Total Marks: ' || V_TOTAL || '/' || V_MAX);
            DBMS_OUTPUT.PUT_LINE('Percentage: ' || ROUND(V_PERCENTAGE, 2) || '%');
            DBMS_OUTPUT.PUT_LINE('Grade: ' || V_GRADE);
            DBMS_OUTPUT.PUT_LINE('Result: ' || V_STATUS);
        END IF;

    END LOOP;

EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Division by zero error');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;
/

-- =========================================
-- 9. VIEW FOR THE FRONT END (one row per student)
-- =========================================
CREATE OR REPLACE VIEW STUDENT_RESULTS AS
SELECT S.STUDENT_ID,
       S.STUDENT_NAME,
       SUM(M.OBTAINED_MARKS) AS TOTAL_MARKS,
       SUM(SU.MAX_MARKS)     AS MAX_TOTAL,
       ROUND(SUM(M.OBTAINED_MARKS) / SUM(SU.MAX_MARKS) * 100, 2) AS PERCENTAGE,
       CALCULATE_GRADE(SUM(M.OBTAINED_MARKS) / SUM(SU.MAX_MARKS) * 100) AS GRADE,
       CASE
           WHEN COUNT(*) = SUM(CASE WHEN M.OBTAINED_MARKS >= SU.PASS_MARKS THEN 1 ELSE 0 END)
           THEN 'PASS'
           ELSE 'FAIL'
       END AS RESULT
FROM STUDENTS S
JOIN MARKS M     ON S.STUDENT_ID = M.STUDENT_ID
JOIN SUBJECTS SU ON M.SUBJECT_ID = SU.SUBJECT_ID
GROUP BY S.STUDENT_ID, S.STUDENT_NAME;

-- =========================================
-- 10. EXECUTE PERFORMANCE ANALYZER
-- =========================================
BEGIN
    ANALYZE_PERFORMANCE;
END;
/

-- =========================================
-- 11. DISPLAY ALL STUDENT RECORDS
-- =========================================
SELECT * FROM STUDENTS;

-- =========================================
-- 12. DISPLAY ALL SUBJECTS
-- =========================================
SELECT * FROM SUBJECTS;

-- =========================================
-- 13. DISPLAY ALL MARKS
-- =========================================
SELECT
    S.STUDENT_NAME,
    SU.SUBJECT_NAME,
    M.OBTAINED_MARKS,
    SU.MAX_MARKS
FROM STUDENTS S
JOIN MARKS M
    ON S.STUDENT_ID = M.STUDENT_ID
JOIN SUBJECTS SU
    ON M.SUBJECT_ID = SU.SUBJECT_ID
ORDER BY S.STUDENT_ID, SU.SUBJECT_ID;

-- =========================================
-- 14. RESULT SUMMARY (the data the front end shows)
-- =========================================
SELECT * FROM STUDENT_RESULTS ORDER BY STUDENT_ID;

-- =====================================================================
-- CRUD OPERATIONS
-- =====================================================================

-- =========================================
-- 15. CRUD PACKAGE (reusable procedures)
-- =========================================
CREATE OR REPLACE PACKAGE STUDENT_CRUD IS
    -- STUDENTS
    PROCEDURE ADD_STUDENT   (P_NAME VARCHAR2, P_COURSE VARCHAR2, P_SEM NUMBER, P_ID OUT NUMBER);
    PROCEDURE UPDATE_STUDENT(P_ID NUMBER, P_NAME VARCHAR2, P_COURSE VARCHAR2, P_SEM NUMBER);
    PROCEDURE DELETE_STUDENT(P_ID NUMBER);
    -- SUBJECTS
    PROCEDURE ADD_SUBJECT   (P_NAME VARCHAR2, P_MAX NUMBER, P_PASS NUMBER, P_ID OUT NUMBER);
    PROCEDURE UPDATE_SUBJECT(P_ID NUMBER, P_NAME VARCHAR2, P_MAX NUMBER, P_PASS NUMBER);
    PROCEDURE DELETE_SUBJECT(P_ID NUMBER);
    -- MARKS (SAVE_MARKS inserts a new row, or updates it if it already exists)
    PROCEDURE SAVE_MARKS    (P_STUDENT_ID NUMBER, P_SUBJECT_ID NUMBER, P_MARKS NUMBER);
    PROCEDURE DELETE_MARKS  (P_MARK_ID NUMBER);
END STUDENT_CRUD;
/

CREATE OR REPLACE PACKAGE BODY STUDENT_CRUD IS

    -- ---------- STUDENTS ----------
    PROCEDURE ADD_STUDENT(P_NAME VARCHAR2, P_COURSE VARCHAR2, P_SEM NUMBER, P_ID OUT NUMBER) IS
    BEGIN
        P_ID := SEQ_STUDENT.NEXTVAL;
        INSERT INTO STUDENTS (STUDENT_ID, STUDENT_NAME, COURSE, SEMESTER)
        VALUES (P_ID, P_NAME, P_COURSE, P_SEM);
        DBMS_OUTPUT.PUT_LINE('Student added with ID ' || P_ID);
    END ADD_STUDENT;

    PROCEDURE UPDATE_STUDENT(P_ID NUMBER, P_NAME VARCHAR2, P_COURSE VARCHAR2, P_SEM NUMBER) IS
    BEGIN
        UPDATE STUDENTS
        SET STUDENT_NAME = P_NAME, COURSE = P_COURSE, SEMESTER = P_SEM
        WHERE STUDENT_ID = P_ID;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Student ' || P_ID || ' not found');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Student ' || P_ID || ' updated');
    END UPDATE_STUDENT;

    PROCEDURE DELETE_STUDENT(P_ID NUMBER) IS
    BEGIN
        -- the student's MARKS rows are removed too (ON DELETE CASCADE)
        DELETE FROM STUDENTS WHERE STUDENT_ID = P_ID;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Student ' || P_ID || ' not found');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Student ' || P_ID || ' deleted');
    END DELETE_STUDENT;

    -- ---------- SUBJECTS ----------
    PROCEDURE ADD_SUBJECT(P_NAME VARCHAR2, P_MAX NUMBER, P_PASS NUMBER, P_ID OUT NUMBER) IS
    BEGIN
        P_ID := SEQ_SUBJECT.NEXTVAL;
        INSERT INTO SUBJECTS (SUBJECT_ID, SUBJECT_NAME, MAX_MARKS, PASS_MARKS)
        VALUES (P_ID, P_NAME, P_MAX, P_PASS);
        DBMS_OUTPUT.PUT_LINE('Subject added with ID ' || P_ID);
    END ADD_SUBJECT;

    PROCEDURE UPDATE_SUBJECT(P_ID NUMBER, P_NAME VARCHAR2, P_MAX NUMBER, P_PASS NUMBER) IS
        V_TOO_HIGH NUMBER;
    BEGIN
        -- do not let MAX_MARKS drop below marks that are already saved
        SELECT COUNT(*) INTO V_TOO_HIGH
        FROM MARKS
        WHERE SUBJECT_ID = P_ID AND OBTAINED_MARKS > P_MAX;
        IF V_TOO_HIGH > 0 THEN
            RAISE_APPLICATION_ERROR(-20003,
                'Some saved marks are higher than the new maximum of ' || P_MAX);
        END IF;

        UPDATE SUBJECTS
        SET SUBJECT_NAME = P_NAME, MAX_MARKS = P_MAX, PASS_MARKS = P_PASS
        WHERE SUBJECT_ID = P_ID;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Subject ' || P_ID || ' not found');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Subject ' || P_ID || ' updated');
    END UPDATE_SUBJECT;

    PROCEDURE DELETE_SUBJECT(P_ID NUMBER) IS
    BEGIN
        DELETE FROM SUBJECTS WHERE SUBJECT_ID = P_ID;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Subject ' || P_ID || ' not found');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Subject ' || P_ID || ' deleted');
    END DELETE_SUBJECT;

    -- ---------- MARKS ----------
    PROCEDURE SAVE_MARKS(P_STUDENT_ID NUMBER, P_SUBJECT_ID NUMBER, P_MARKS NUMBER) IS
    BEGIN
        UPDATE MARKS
        SET OBTAINED_MARKS = P_MARKS
        WHERE STUDENT_ID = P_STUDENT_ID AND SUBJECT_ID = P_SUBJECT_ID;

        IF SQL%ROWCOUNT = 0 THEN
            INSERT INTO MARKS (MARK_ID, STUDENT_ID, SUBJECT_ID, OBTAINED_MARKS)
            VALUES (SEQ_MARK.NEXTVAL, P_STUDENT_ID, P_SUBJECT_ID, P_MARKS);
            DBMS_OUTPUT.PUT_LINE('Marks added');
        ELSE
            DBMS_OUTPUT.PUT_LINE('Marks updated');
        END IF;
    END SAVE_MARKS;

    PROCEDURE DELETE_MARKS(P_MARK_ID NUMBER) IS
    BEGIN
        DELETE FROM MARKS WHERE MARK_ID = P_MARK_ID;
        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Mark entry ' || P_MARK_ID || ' not found');
        END IF;
        DBMS_OUTPUT.PUT_LINE('Marks entry ' || P_MARK_ID || ' deleted');
    END DELETE_MARKS;

END STUDENT_CRUD;
/

-- =========================================
-- 16. CRUD WITH PLAIN SQL (one test student: Neha)
-- =========================================

-- ---- CREATE ----
INSERT INTO STUDENTS VALUES (SEQ_STUDENT.NEXTVAL, 'Neha', 'MCA', 1);

INSERT INTO MARKS VALUES (SEQ_MARK.NEXTVAL,
    (SELECT STUDENT_ID FROM STUDENTS WHERE STUDENT_NAME = 'Neha'), 101, 72);
INSERT INTO MARKS VALUES (SEQ_MARK.NEXTVAL,
    (SELECT STUDENT_ID FROM STUDENTS WHERE STUDENT_NAME = 'Neha'), 102, 38);
COMMIT;

-- ---- READ ----
-- all students
SELECT * FROM STUDENTS ORDER BY STUDENT_ID;

-- one student's marks, subject by subject
SELECT S.STUDENT_NAME, SU.SUBJECT_NAME, M.OBTAINED_MARKS, SU.MAX_MARKS,
       CASE WHEN M.OBTAINED_MARKS >= SU.PASS_MARKS THEN 'PASS' ELSE 'FAIL' END AS SUBJECT_RESULT
FROM STUDENTS S
JOIN MARKS M     ON S.STUDENT_ID = M.STUDENT_ID
JOIN SUBJECTS SU ON M.SUBJECT_ID = SU.SUBJECT_ID
WHERE S.STUDENT_NAME = 'Neha'
ORDER BY SU.SUBJECT_ID;

-- search by part of a name
SELECT * FROM STUDENTS WHERE UPPER(STUDENT_NAME) LIKE UPPER('%an%');

-- students who failed
SELECT * FROM STUDENT_RESULTS WHERE RESULT = 'FAIL';

-- topper
SELECT * FROM STUDENT_RESULTS
ORDER BY PERCENTAGE DESC
FETCH FIRST 1 ROW ONLY;

-- average marks per subject
SELECT SU.SUBJECT_NAME, ROUND(AVG(M.OBTAINED_MARKS), 2) AS AVG_MARKS
FROM SUBJECTS SU
JOIN MARKS M ON SU.SUBJECT_ID = M.SUBJECT_ID
GROUP BY SU.SUBJECT_NAME
ORDER BY SU.SUBJECT_NAME;

-- ---- UPDATE ----
UPDATE STUDENTS SET SEMESTER = 2 WHERE STUDENT_NAME = 'Neha';

UPDATE MARKS
SET OBTAINED_MARKS = 80
WHERE STUDENT_ID = (SELECT STUDENT_ID FROM STUDENTS WHERE STUDENT_NAME = 'Neha')
  AND SUBJECT_ID = 102;

UPDATE SUBJECTS SET PASS_MARKS = 40 WHERE SUBJECT_NAME = 'Python';
COMMIT;

SELECT * FROM STUDENT_RESULTS WHERE STUDENT_NAME = 'Neha';

-- ---- DELETE ----
-- one marks entry
DELETE FROM MARKS
WHERE STUDENT_ID = (SELECT STUDENT_ID FROM STUDENTS WHERE STUDENT_NAME = 'Neha')
  AND SUBJECT_ID = 101;

-- the student (her remaining marks go with her: ON DELETE CASCADE)
DELETE FROM STUDENTS WHERE STUDENT_NAME = 'Neha';
COMMIT;

-- =========================================
-- 17. CRUD WITH THE PACKAGE (one test student: Karan)
-- =========================================
DECLARE
    V_ID NUMBER;
BEGIN
    STUDENT_CRUD.ADD_STUDENT('Karan', 'MCA', 1, V_ID);          -- Create
    STUDENT_CRUD.SAVE_MARKS(V_ID, 101, 66);                      -- Create marks
    STUDENT_CRUD.SAVE_MARKS(V_ID, 101, 70);                      -- Update marks
    STUDENT_CRUD.UPDATE_STUDENT(V_ID, 'Karan Singh', 'MCA', 2);  -- Update student

    FOR R IN (SELECT STUDENT_NAME, TOTAL_MARKS, MAX_TOTAL, GRADE, RESULT   -- Read
              FROM STUDENT_RESULTS WHERE STUDENT_ID = V_ID) LOOP
        DBMS_OUTPUT.PUT_LINE(R.STUDENT_NAME || ': ' || R.TOTAL_MARKS || '/' || R.MAX_TOTAL
                             || ', grade ' || R.GRADE || ', ' || R.RESULT);
    END LOOP;

    STUDENT_CRUD.DELETE_STUDENT(V_ID);                           -- Delete
    COMMIT;
END;
/

-- =========================================
-- 18. ERROR HANDLING CHECK (this must be rejected)
-- =========================================
BEGIN
    STUDENT_CRUD.SAVE_MARKS(1, 101, 150);   -- more than MAX_MARKS
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Rejected as expected: ' || SQLERRM);
        ROLLBACK;
END;
/

-- =========================================
-- 19. FINAL CHECK - data is back to the 4 sample students
-- =========================================
SELECT * FROM STUDENT_RESULTS ORDER BY STUDENT_ID;
