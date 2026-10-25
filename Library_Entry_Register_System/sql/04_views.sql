/* =========================================================
   LIBRARY ENTRY REGISTER SYSTEM
   File 4 of 5 : User-specific Views
   Student   -> own borrowing, fines and visits (no other student's
                email/phone is exposed)
   Librarian -> day-to-day issue, overdue and visit information
   Admin     -> summary reports for planning
   ========================================================= */

USE library_entry_register;


/* =========================================================
   STUDENT VIEWS
   Application filters by the logged-in student:
   SELECT * FROM vw_student_books WHERE Student_ID = 101;
   ========================================================= */

/* My borrowed books */

CREATE OR REPLACE VIEW vw_student_books AS
SELECT
    bt.Student_ID,
    bt.Transaction_ID,
    bt.Accn_No,
    sec.Section_Name,
    bt.Issue_Date,
    bt.Due_Date,
    bt.Return_Date,
    bt.Status
FROM Book_Transaction bt
JOIN Section sec
    ON bt.Section_ID = sec.Section_ID;


/* My fines */

CREATE OR REPLACE VIEW vw_student_fines AS
SELECT
    bt.Student_ID,
    f.Fine_ID,
    bt.Accn_No,
    f.Fine_Amount,
    f.Fine_Date,
    f.Payment_Status,
    f.Payment_Date
FROM Fine f
JOIN Book_Transaction bt
    ON f.Transaction_ID = bt.Transaction_ID;


/* My library visits */

CREATE OR REPLACE VIEW vw_student_visits AS
SELECT
    Student_ID,
    Visit_Date,
    Entry_Time,
    Exit_Time,
    TIMESTAMPDIFF(MINUTE, Entry_Time, Exit_Time) AS Minutes_Spent,
    Visit_Purpose
FROM Library_Visit;


/* =========================================================
   LIBRARIAN VIEWS
   ========================================================= */

/* Books currently out of the library, with days overdue */

CREATE OR REPLACE VIEW vw_librarian_books_out AS
SELECT
    bt.Transaction_ID,
    bt.Accn_No,
    sec.Section_Name,
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name)          AS Student_Name,
    bt.Issue_Date,
    bt.Due_Date,
    GREATEST(DATEDIFF(CURDATE(), bt.Due_Date), 0)   AS Days_Overdue,
    bt.Status
FROM Book_Transaction bt
JOIN Student s
    ON bt.Student_ID = s.Student_ID
JOIN Section sec
    ON bt.Section_ID = sec.Section_ID
WHERE bt.Return_Date IS NULL;


/* Unpaid fines with student contact (email) */

CREATE OR REPLACE VIEW vw_librarian_unpaid_fines AS
SELECT
    f.Fine_ID,
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
    s.Email,
    bt.Accn_No,
    f.Fine_Amount,
    f.Fine_Date
FROM Fine f
JOIN Book_Transaction bt
    ON f.Transaction_ID = bt.Transaction_ID
JOIN Student s
    ON bt.Student_ID = s.Student_ID
WHERE f.Payment_Status = 'Unpaid';


/* Visit register (entry book of the library) */

CREATE OR REPLACE VIEW vw_librarian_visit_register AS
SELECT
    lv.Visit_ID,
    lv.Visit_Date,
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
    s.Department,
    lv.Entry_Time,
    lv.Exit_Time,
    lv.Visit_Purpose,
    CASE WHEN lv.Is_Free_Period = 1 THEN 'Yes' ELSE 'No' END AS Free_Period
FROM Library_Visit lv
JOIN Student s
    ON lv.Student_ID = s.Student_ID;


/* =========================================================
   ADMINISTRATOR VIEWS
   ========================================================= */

/* Department-wise library usage */

CREATE OR REPLACE VIEW vw_admin_department_usage AS
SELECT
    s.Department,
    COUNT(DISTINCT lv.Student_ID)                           AS Students_Visited,
    COUNT(lv.Visit_ID)                                      AS Total_Visits,
    SUM(TIMESTAMPDIFF(MINUTE, lv.Entry_Time, lv.Exit_Time)) AS Total_Minutes
FROM Student s
JOIN Library_Visit lv
    ON s.Student_ID = lv.Student_ID
GROUP BY s.Department;


/* Section-wise book circulation */

CREATE OR REPLACE VIEW vw_admin_section_circulation AS
SELECT
    sec.Section_ID,
    sec.Section_Name,
    sec.Location,
    COUNT(bt.Transaction_ID)                                      AS Total_Issues,
    SUM(CASE WHEN bt.Return_Date IS NULL
                  AND bt.Transaction_ID IS NOT NULL THEN 1 ELSE 0 END) AS Currently_Out
FROM Section sec
LEFT JOIN Book_Transaction bt
    ON sec.Section_ID = bt.Section_ID
GROUP BY sec.Section_ID, sec.Section_Name, sec.Location;


/* Fine summary */

CREATE OR REPLACE VIEW vw_admin_fine_summary AS
SELECT
    Payment_Status,
    COUNT(*)         AS Number_of_Fines,
    SUM(Fine_Amount) AS Total_Amount
FROM Fine
GROUP BY Payment_Status;


/* =========================================================
   OPTIONAL: Access control with roles (MySQL 8+ / MariaDB)
   Remove the comment marks to run. Needs admin privileges.
   =========================================================

CREATE ROLE IF NOT EXISTS student_role, librarian_role, admin_role;

GRANT SELECT ON library_entry_register.vw_student_books  TO student_role;
GRANT SELECT ON library_entry_register.vw_student_fines  TO student_role;
GRANT SELECT ON library_entry_register.vw_student_visits TO student_role;

GRANT SELECT ON library_entry_register.vw_librarian_books_out      TO librarian_role;
GRANT SELECT ON library_entry_register.vw_librarian_unpaid_fines   TO librarian_role;
GRANT SELECT ON library_entry_register.vw_librarian_visit_register TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library_entry_register.Book_Transaction TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library_entry_register.Library_Visit    TO librarian_role;
GRANT SELECT, INSERT, UPDATE ON library_entry_register.Fine             TO librarian_role;

GRANT ALL PRIVILEGES ON library_entry_register.* TO admin_role;

*/
