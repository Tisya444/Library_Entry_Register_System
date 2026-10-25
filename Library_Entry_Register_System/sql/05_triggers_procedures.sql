/* =========================================================
   LIBRARY ENTRY REGISTER SYSTEM
   File 5 of 5 : Functions, Triggers and Stored Procedures
   Run this file AFTER 01_schema.sql and 02_data.sql.
   Fine rule: Rs 10 per day after Due_Date.
   Issue period: 7 days.
   ========================================================= */

USE library_entry_register;

DELIMITER $$


/* =========================================================
   PART A: FUNCTIONS
   ========================================================= */

/* F1. Late fine for a book: Rs 10 per day after due date */

DROP FUNCTION IF EXISTS fn_calculate_fine $$
CREATE FUNCTION fn_calculate_fine(p_due_date DATE, p_return_date DATE)
RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    RETURN GREATEST(DATEDIFF(p_return_date, p_due_date), 0) * 10.00;
END $$


/* F2. Is a book copy available? (1 = yes, 0 = currently issued) */

DROP FUNCTION IF EXISTS fn_is_copy_available $$
CREATE FUNCTION fn_is_copy_available(p_accn_no VARCHAR(30))
RETURNS BOOLEAN
READS SQL DATA
BEGIN
    RETURN NOT EXISTS (
        SELECT 1
        FROM Book_Transaction
        WHERE Accn_No = p_accn_no
          AND Return_Date IS NULL
    );
END $$


/* F3. Total minutes a student has spent in the library */

DROP FUNCTION IF EXISTS fn_total_library_minutes $$
CREATE FUNCTION fn_total_library_minutes(p_student_id INT)
RETURNS INT
READS SQL DATA
BEGIN
    DECLARE v_minutes INT;

    SELECT COALESCE(SUM(TIMESTAMPDIFF(MINUTE, Entry_Time, Exit_Time)), 0)
    INTO v_minutes
    FROM Library_Visit
    WHERE Student_ID = p_student_id
      AND Exit_Time IS NOT NULL;

    RETURN v_minutes;
END $$


/* =========================================================
   PART B: TRIGGERS
   ========================================================= */

/* T1. Before issuing a book:
       - the copy must not already be issued
       - the copy must stay in the same section as before
       - Status is set automatically */

DROP TRIGGER IF EXISTS trg_before_book_issue $$
CREATE TRIGGER trg_before_book_issue
BEFORE INSERT ON Book_Transaction
FOR EACH ROW
BEGIN
    IF NEW.Return_Date IS NULL
       AND NOT fn_is_copy_available(NEW.Accn_No) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This book copy is already issued to another student.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM Book_Transaction
        WHERE Accn_No = NEW.Accn_No
          AND Section_ID <> NEW.Section_ID
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'This Accn_No belongs to a different section.';
    END IF;

    IF NEW.Return_Date IS NOT NULL THEN
        SET NEW.Status = 'Returned';
    ELSEIF NEW.Due_Date < CURDATE() THEN
        SET NEW.Status = 'Overdue';
    ELSE
        SET NEW.Status = 'Issued';
    END IF;
END $$


/* T2. When a return date is filled in, status becomes 'Returned' */

DROP TRIGGER IF EXISTS trg_before_book_return $$
CREATE TRIGGER trg_before_book_return
BEFORE UPDATE ON Book_Transaction
FOR EACH ROW
BEGIN
    IF NEW.Return_Date IS NOT NULL AND OLD.Return_Date IS NULL THEN
        SET NEW.Status = 'Returned';
    END IF;
END $$


/* T3. After a late return, a fine is generated automatically */

DROP TRIGGER IF EXISTS trg_after_book_return $$
CREATE TRIGGER trg_after_book_return
AFTER UPDATE ON Book_Transaction
FOR EACH ROW
BEGIN
    IF NEW.Return_Date IS NOT NULL
       AND OLD.Return_Date IS NULL
       AND NEW.Return_Date > NEW.Due_Date THEN

        INSERT INTO Fine (Transaction_ID, Fine_Amount, Fine_Date, Payment_Status)
        VALUES (NEW.Transaction_ID,
                fn_calculate_fine(NEW.Due_Date, NEW.Return_Date),
                NEW.Return_Date,
                'Unpaid');
    END IF;
END $$


/* T4. A student cannot have two overlapping visits on the same day
       (for example, entering again without exiting) */

DROP TRIGGER IF EXISTS trg_before_visit_insert $$
CREATE TRIGGER trg_before_visit_insert
BEFORE INSERT ON Library_Visit
FOR EACH ROW
BEGIN
    IF EXISTS (
        SELECT 1
        FROM Library_Visit
        WHERE Student_ID = NEW.Student_ID
          AND Visit_Date = NEW.Visit_Date
          AND NEW.Entry_Time < COALESCE(Exit_Time, '16:00:00')
          AND COALESCE(NEW.Exit_Time, '16:00:00') > Entry_Time
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Student already has a visit at this time.';
    END IF;
END $$


/* T5. When a fine is marked 'Paid' without a date, today's date is used */

DROP TRIGGER IF EXISTS trg_before_fine_payment $$
CREATE TRIGGER trg_before_fine_payment
BEFORE UPDATE ON Fine
FOR EACH ROW
BEGIN
    IF NEW.Payment_Status = 'Paid' AND NEW.Payment_Date IS NULL THEN
        SET NEW.Payment_Date = CURDATE();
    END IF;
END $$


/* =========================================================
   PART C: STORED PROCEDURES
   ========================================================= */

/* P1. Issue a book (due date = issue date + 7 days) */

DROP PROCEDURE IF EXISTS sp_issue_book $$
CREATE PROCEDURE sp_issue_book(
    IN p_student_id INT,
    IN p_accn_no    VARCHAR(30),
    IN p_section_id INT,
    IN p_issue_date DATE
)
BEGIN
    INSERT INTO Book_Transaction
        (Student_ID, Accn_No, Section_ID, Transaction_Type,
         Issue_Date, Due_Date, Return_Date, Status)
    VALUES
        (p_student_id, p_accn_no, p_section_id, 'Issue',
         p_issue_date, DATE_ADD(p_issue_date, INTERVAL 7 DAY), NULL, 'Issued');

    SELECT LAST_INSERT_ID() AS New_Transaction_ID;
END $$


/* P2. Return a book (fine is created by trigger T3 if late) */

DROP PROCEDURE IF EXISTS sp_return_book $$
CREATE PROCEDURE sp_return_book(
    IN p_transaction_id INT,
    IN p_return_date    DATE
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Book_Transaction
        WHERE Transaction_ID = p_transaction_id
          AND Return_Date IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'No open issue found for this transaction.';
    END IF;

    UPDATE Book_Transaction
    SET Return_Date      = p_return_date,
        Transaction_Type = 'Return'
    WHERE Transaction_ID = p_transaction_id;
END $$


/* P3. Record a student's entry into the library */

DROP PROCEDURE IF EXISTS sp_record_entry $$
CREATE PROCEDURE sp_record_entry(
    IN p_student_id INT,
    IN p_visit_date DATE,
    IN p_entry_time TIME,
    IN p_purpose    VARCHAR(20),
    IN p_free       BOOLEAN
)
BEGIN
    INSERT INTO Library_Visit
        (Student_ID, Visit_Date, Entry_Time, Exit_Time, Visit_Purpose, Is_Free_Period)
    VALUES
        (p_student_id, p_visit_date, p_entry_time, NULL, p_purpose, p_free);

    SELECT LAST_INSERT_ID() AS New_Visit_ID;
END $$


/* P4. Record a student's exit from the library */

DROP PROCEDURE IF EXISTS sp_record_exit $$
CREATE PROCEDURE sp_record_exit(
    IN p_visit_id  INT,
    IN p_exit_time TIME
)
BEGIN
    IF NOT EXISTS (
        SELECT 1
        FROM Library_Visit
        WHERE Visit_ID = p_visit_id
          AND Exit_Time IS NULL
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Visit not found or exit already recorded.';
    END IF;

    UPDATE Library_Visit
    SET Exit_Time = p_exit_time
    WHERE Visit_ID = p_visit_id;
END $$


/* P5. Mark all unreturned books past their due date as 'Overdue' */

DROP PROCEDURE IF EXISTS sp_mark_overdue $$
CREATE PROCEDURE sp_mark_overdue()
BEGIN
    UPDATE Book_Transaction
    SET Status = 'Overdue'
    WHERE Return_Date IS NULL
      AND Due_Date < CURDATE()
      AND Status = 'Issued';

    SELECT ROW_COUNT() AS Books_Marked_Overdue;
END $$


/* P6. Pay a fine */

DROP PROCEDURE IF EXISTS sp_pay_fine $$
CREATE PROCEDURE sp_pay_fine(IN p_fine_id INT)
BEGIN
    UPDATE Fine
    SET Payment_Status = 'Paid'
    WHERE Fine_ID = p_fine_id
      AND Payment_Status = 'Unpaid';
END $$


/* P7. Full report of one student */

DROP PROCEDURE IF EXISTS sp_student_report $$
CREATE PROCEDURE sp_student_report(IN p_student_id INT)
BEGIN
    SELECT
        s.Student_ID,
        CONCAT(s.First_Name, ' ', s.Last_Name)            AS Student_Name,
        s.Department,
        s.Semester,
        (SELECT COUNT(*) FROM Library_Visit lv
          WHERE lv.Student_ID = s.Student_ID)             AS Total_Visits,
        fn_total_library_minutes(s.Student_ID)            AS Total_Minutes,
        (SELECT COUNT(*) FROM Book_Transaction bt
          WHERE bt.Student_ID = s.Student_ID)             AS Books_Issued,
        (SELECT COALESCE(SUM(f.Fine_Amount), 0)
           FROM Fine f
           JOIN Book_Transaction bt ON f.Transaction_ID = bt.Transaction_ID
          WHERE bt.Student_ID = s.Student_ID
            AND f.Payment_Status = 'Unpaid')              AS Unpaid_Fine
    FROM Student s
    WHERE s.Student_ID = p_student_id;
END $$


DELIMITER ;


/* =========================================================
   PART D: HOW TO TEST (run these one by one)
   =========================================================

-- Issue ACC003 to student 104 on 2026-09-15 (due 2026-09-22)
CALL sp_issue_book(104, 'ACC003', 2, '2026-09-15');

-- Try to issue the same copy again -> error from trigger T1
CALL sp_issue_book(105, 'ACC003', 2, '2026-09-16');

-- Return it 3 days late -> trigger T3 creates a Rs 30 fine
CALL sp_return_book(1009, '2026-09-25');
SELECT * FROM Fine WHERE Transaction_ID = 1009;

-- Pay that fine -> trigger T5 fills today's date
CALL sp_pay_fine(7);

-- Entry and exit of a student
CALL sp_record_entry(102, '2026-09-15', '10:00:00', 'Reading', 1);
CALL sp_record_exit(11, '11:30:00');

-- Mark overdue books and see one student's report
CALL sp_mark_overdue();
CALL sp_student_report(101);

-- Functions
SELECT fn_calculate_fine('2026-09-01', '2026-09-05');   -- 40.00
SELECT fn_is_copy_available('ACC004');                  -- 0 (not returned)

*/
