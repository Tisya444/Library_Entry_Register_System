/* =========================================================
   LIBRARY ENTRY REGISTER SYSTEM
   File 2 of 5 : Sample Data
   ========================================================= */

USE library_entry_register;


/* ---------- STUDENT DATA ----------
   Student 109 is a deliberately suspicious record:
   same name, department and semester as student 101,
   different email, and shares 101's phone number.
   Query Q1 should catch it.
*/

INSERT INTO Student
    (Student_ID, First_Name, Middle_Name, Last_Name,
     Email, Department, Semester, Registration_Date)
VALUES
    (101, 'Aarav',  NULL, 'Sharma',   'aarav@gmail.com',        'CSE', 3, '2026-08-20'),
    (102, 'Priya',  NULL, 'Singh',    'priya@gmail.com',        'CSE', 3, '2026-08-20'),
    (103, 'Rahul',  NULL, 'Verma',    'rahul@gmail.com',        'IT',  5, '2026-08-21'),
    (104, 'Ananya', NULL, 'Gupta',    'ananya@gmail.com',       'ECE', 3, '2026-08-21'),
    (105, 'Rohan',  NULL, 'Mehta',    'rohan@gmail.com',        'CSE', 5, '2026-08-22'),
    (106, 'Sneha',  NULL, 'Kapoor',   'sneha@gmail.com',        'IT',  3, '2026-08-22'),
    (107, 'Karan',  NULL, 'Malhotra', 'karan@gmail.com',        'ECE', 5, '2026-08-23'),
    (108, 'Neha',   NULL, 'Jain',     'neha@gmail.com',         'CSE', 3, '2026-08-23'),
    (109, 'Aarav',  NULL, 'Sharma',   'aarav.sharma@gmail.com', 'CSE', 3, '2026-09-05');


/* ---------- STUDENT PHONE DATA ---------- */

INSERT INTO Student_Phone (Student_ID, Phone)
VALUES
    (101, '9876543210'),
    (101, '9123456789'),
    (102, '9876543211'),
    (103, '9876543212'),
    (104, '9876543213'),
    (105, '9876543214'),
    (106, '9876543215'),
    (107, '9876543216'),
    (108, '9876543217'),
    (109, '9876543210');   -- same phone as student 101


/* ---------- SECTION DATA ---------- */

INSERT INTO Section (Section_ID, Section_Name, Location)
VALUES
    (1, 'Computer Science', 'Ground Floor'),
    (2, 'Mathematics',      'First Floor'),
    (3, 'Literature',       'First Floor'),
    (4, 'Reference',        'Second Floor');


/* ---------- LIBRARY VISIT DATA ---------- */

INSERT INTO Library_Visit
    (Visit_ID, Student_ID, Visit_Date, Entry_Time, Exit_Time,
     Visit_Purpose, Is_Free_Period)
VALUES
    (1,  101, '2026-09-01', '09:10:00', '10:30:00', 'Reading',   1),
    (2,  102, '2026-09-01', '10:00:00', '12:00:00', 'Studying',  1),
    (3,  103, '2026-09-01', '11:00:00', '13:00:00', 'Borrowing', 0),
    (4,  104, '2026-09-02', '09:30:00', '11:30:00', 'Reading',   1),
    (5,  105, '2026-09-02', '12:00:00', '15:30:00', 'Studying',  0),
    (6,  101, '2026-09-03', '10:00:00', '13:00:00', 'Studying',  1),
    (7,  106, '2026-09-03', '09:15:00', '10:15:00', 'Returning', 1),
    (8,  107, '2026-09-04', '11:00:00', '14:30:00', 'Reading',   0),
    (9,  108, '2026-09-04', '13:00:00', '15:00:00', 'Borrowing', 1),
    (10, 101, '2026-09-04', '09:00:00', '14:00:00', 'Studying',  0);


/* ---------- BOOK TRANSACTION DATA ----------
   Note: Transaction 1004 now starts on 2026-08-28.
   Earlier it started on 2026-08-23, when copy ACC001 was
   still issued to student 101 (returned on 2026-08-27).
*/

INSERT INTO Book_Transaction
    (Transaction_ID, Student_ID, Accn_No, Section_ID, Transaction_Type,
     Issue_Date, Due_Date, Return_Date, Status)
VALUES
    (1001, 101, 'ACC001', 1, 'Issue', '2026-08-20', '2026-08-27', '2026-08-27', 'Returned'),
    (1002, 102, 'ACC002', 1, 'Issue', '2026-08-21', '2026-08-28', '2026-08-30', 'Returned'),
    (1003, 103, 'ACC003', 2, 'Issue', '2026-08-22', '2026-08-29', '2026-09-02', 'Returned'),
    (1004, 104, 'ACC001', 1, 'Issue', '2026-08-28', '2026-09-04', '2026-09-04', 'Returned'),
    (1005, 105, 'ACC004', 3, 'Issue', '2026-08-24', '2026-08-31', NULL,         'Overdue'),
    (1006, 106, 'ACC005', 2, 'Issue', '2026-08-25', '2026-09-01', '2026-09-04', 'Returned'),
    (1007, 101, 'ACC002', 1, 'Issue', '2026-09-01', '2026-09-08', '2026-09-10', 'Returned'),
    (1008, 103, 'ACC003', 2, 'Issue', '2026-09-02', '2026-09-09', '2026-09-12', 'Returned');


/* ---------- FINE DATA ----------
   Late fine = Rs 10 per day after Due_Date.
   Transaction 1002 has two fines: Rs 20 late fine + Rs 10 damage fine.
*/

INSERT INTO Fine
    (Fine_ID, Transaction_ID, Fine_Amount, Fine_Date, Payment_Status, Payment_Date)
VALUES
    (1, 1002, 20.00, '2026-08-30', 'Paid',   '2026-08-30'),
    (2, 1002, 10.00, '2026-08-30', 'Paid',   '2026-08-30'),
    (3, 1003, 40.00, '2026-09-02', 'Paid',   '2026-09-03'),
    (4, 1006, 30.00, '2026-09-04', 'Paid',   '2026-09-04'),
    (5, 1007, 20.00, '2026-09-10', 'Paid',   '2026-09-10'),
    (6, 1008, 30.00, '2026-09-12', 'Unpaid', NULL);
