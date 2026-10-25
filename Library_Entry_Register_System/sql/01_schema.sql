/* =========================================================
   LIBRARY ENTRY REGISTER SYSTEM
  
  ========================================================= */

DROP DATABASE IF EXISTS library_entry_register;
CREATE DATABASE library_entry_register;
USE library_entry_register;


/* ---------- 1. STUDENT ---------- */

CREATE TABLE Student (
    Student_ID        INT PRIMARY KEY,
    First_Name        VARCHAR(50)  NOT NULL,
    Middle_Name       VARCHAR(50),
    Last_Name         VARCHAR(50)  NOT NULL,
    Email             VARCHAR(100) NOT NULL UNIQUE,
    Department        VARCHAR(100) NOT NULL,
    Semester          INT          NOT NULL,
    Registration_Date DATE         NOT NULL,

    CHECK (Semester BETWEEN 1 AND 8)
);


/* ---------- 2. STUDENT PHONE ----------
   Phone is a multivalued attribute (double oval in ER diagram),
   so it is stored in a separate table.
*/

CREATE TABLE Student_Phone (
    Student_ID INT         NOT NULL,
    Phone      VARCHAR(15) NOT NULL,

    PRIMARY KEY (Student_ID, Phone),

    FOREIGN KEY (Student_ID)
        REFERENCES Student(Student_ID)
        ON DELETE CASCADE
);


/* ---------- 3. SECTION ---------- */

CREATE TABLE Section (
    Section_ID   INT PRIMARY KEY,
    Section_Name VARCHAR(100) NOT NULL UNIQUE,
    Location     VARCHAR(100)
);


/* ---------- 4. LIBRARY VISIT ----------
   Relationship: Student (1) --Makes-- (N) Library_Visit
   Exit_Time is NULL while the student is still inside the library.
*/

CREATE TABLE Library_Visit (
    Visit_ID       INT AUTO_INCREMENT PRIMARY KEY,
    Student_ID     INT          NOT NULL,
    Visit_Date     DATE         NOT NULL,
    Entry_Time     TIME         NOT NULL,
    Exit_Time      TIME,
    Visit_Purpose  VARCHAR(20)  NOT NULL,
    Is_Free_Period BOOLEAN      NOT NULL,

    FOREIGN KEY (Student_ID)
        REFERENCES Student(Student_ID),

    /* Library timing: 9 AM to 4 PM */
    CHECK (Entry_Time BETWEEN '09:00:00' AND '16:00:00'),

    CHECK (Exit_Time IS NULL
           OR Exit_Time BETWEEN '09:00:00' AND '16:00:00'),

    /* Exit cannot be before or equal to entry */
    CHECK (Exit_Time IS NULL OR Exit_Time > Entry_Time),

    CHECK (Visit_Purpose IN
           ('Borrowing', 'Returning', 'Reading', 'Studying', 'Other'))
);


/* ---------- 5. BOOK TRANSACTION ----------
   Relationships:
   Student (1) --Performs--   (N) Book_Transaction
   Section (1) --Belongs_To-- (N) Book_Transaction
*/

CREATE TABLE Book_Transaction (
    Transaction_ID   INT AUTO_INCREMENT PRIMARY KEY,
    Student_ID       INT         NOT NULL,
    Accn_No          VARCHAR(30) NOT NULL,
    Section_ID       INT         NOT NULL,
    Transaction_Type VARCHAR(20) NOT NULL,
    Issue_Date       DATE        NOT NULL,
    Due_Date         DATE        NOT NULL,
    Return_Date      DATE,
    Status           VARCHAR(20) NOT NULL,

    FOREIGN KEY (Student_ID)
        REFERENCES Student(Student_ID),

    FOREIGN KEY (Section_ID)
        REFERENCES Section(Section_ID),

    CHECK (Transaction_Type IN ('Issue', 'Return')),

    CHECK (Status IN ('Issued', 'Returned', 'Overdue')),

    CHECK (Due_Date >= Issue_Date),

    CHECK (Return_Date IS NULL OR Return_Date >= Issue_Date),

    /* Status must match Return_Date */
    CHECK (
        (Status = 'Returned' AND Return_Date IS NOT NULL)
        OR (Status IN ('Issued', 'Overdue') AND Return_Date IS NULL)
    )
);


/* ---------- 6. FINE ----------
   Relationship: Book_Transaction (1) --Generates-- (N) Fine
   One transaction can have more than one fine
   (for example, late return + damage).
*/

CREATE TABLE Fine (
    Fine_ID        INT AUTO_INCREMENT PRIMARY KEY,
    Transaction_ID INT           NOT NULL,
    Fine_Amount    DECIMAL(10,2) NOT NULL,
    Fine_Date      DATE          NOT NULL,
    Payment_Status VARCHAR(20)   NOT NULL DEFAULT 'Unpaid',
    Payment_Date   DATE,

    FOREIGN KEY (Transaction_ID)
        REFERENCES Book_Transaction(Transaction_ID),

    CHECK (Fine_Amount >= 0),

    CHECK (Payment_Status IN ('Paid', 'Unpaid')),

    /* Paid fine must have a payment date, unpaid fine must not */
    CHECK (
        (Payment_Status = 'Paid'   AND Payment_Date IS NOT NULL)
        OR (Payment_Status = 'Unpaid' AND Payment_Date IS NULL)
    )
);
