
SET SERVEROUTPUT ON;

-- =========================================
-- 1. CREATE STUDENTS TABLE
-- =========================================

CREATE TABLE STUDENTS (
    STUDENT_ID NUMBER PRIMARY KEY,
    STUDENT_NAME VARCHAR2(50),
    COURSE VARCHAR2(30),
    SEMESTER NUMBER
);

-- =========================================
-- 2. CREATE SUBJECTS TABLE
-- =========================================

CREATE TABLE SUBJECTS (
    SUBJECT_ID NUMBER PRIMARY KEY,
    SUBJECT_NAME VARCHAR2(50),
    MAX_MARKS NUMBER,
    PASS_MARKS NUMBER
);

-- =========================================
-- 3. CREATE MARKS TABLE
-- =========================================

CREATE TABLE MARKS (
    MARK_ID NUMBER PRIMARY KEY,
    STUDENT_ID NUMBER,
    SUBJECT_ID NUMBER,
    OBTAINED_MARKS NUMBER,
    FOREIGN KEY (STUDENT_ID)
        REFERENCES STUDENTS(STUDENT_ID),
    FOREIGN KEY (SUBJECT_ID)
        REFERENCES SUBJECTS(SUBJECT_ID)
);

-- =========================================
-- 4. INSERT STUDENT RECORDS
-- =========================================

INSERT INTO STUDENTS VALUES
(1, 'Mohit', 'MCA', 1);

INSERT INTO STUDENTS VALUES
(2, 'Rahul', 'MCA', 1);

INSERT INTO STUDENTS VALUES
(3, 'Aman', 'MCA', 1);

INSERT INTO STUDENTS VALUES
(4, 'Priya', 'MCA', 1);

-- =========================================
-- 5. INSERT SUBJECT RECORDS
-- =========================================

INSERT INTO SUBJECTS VALUES
(101, 'DBMS', 100, 40);

INSERT INTO SUBJECTS VALUES
(102, 'Python', 100, 40);

INSERT INTO SUBJECTS VALUES
(103, 'Web Programming', 100, 40);

INSERT INTO SUBJECTS VALUES
(104, 'Computer Networks', 100, 40);

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
        FROM STUDENTS;

    V_TOTAL NUMBER;
    V_MAX NUMBER;
    V_PERCENTAGE NUMBER;
    V_GRADE VARCHAR2(10);
    V_STATUS VARCHAR2(10);

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

            V_PERCENTAGE :=
                (V_TOTAL / V_MAX) * 100;

            V_GRADE :=
                CALCULATE_GRADE(V_PERCENTAGE);

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

            DBMS_OUTPUT.PUT_LINE(
                '-----------------------------'
            );

            DBMS_OUTPUT.PUT_LINE(
                'Student Name: ' || S.STUDENT_NAME
            );

            DBMS_OUTPUT.PUT_LINE(
                'Total Marks: ' || V_TOTAL || '/' || V_MAX
            );

            DBMS_OUTPUT.PUT_LINE(
                'Percentage: ' ||
                ROUND(V_PERCENTAGE, 2) || '%'
            );

            DBMS_OUTPUT.PUT_LINE(
                'Grade: ' || V_GRADE
            );

            DBMS_OUTPUT.PUT_LINE(
                'Result: ' || V_STATUS
            );

        END IF;

    END LOOP;

EXCEPTION
    WHEN ZERO_DIVIDE THEN
        DBMS_OUTPUT.PUT_LINE('Division by zero error');

    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'Error: ' || SQLERRM
        );

END;
/

-- =========================================
-- 9. EXECUTE PERFORMANCE ANALYZER
-- =========================================

BEGIN
    ANALYZE_PERFORMANCE;
END;
/

-- =========================================
-- 10. DISPLAY ALL STUDENT RECORDS
-- =========================================

SELECT * FROM STUDENTS;

-- =========================================
-- 11. DISPLAY ALL SUBJECTS
-- =========================================

SELECT * FROM SUBJECTS;

-- =========================================
-- 12. DISPLAY ALL MARKS
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
