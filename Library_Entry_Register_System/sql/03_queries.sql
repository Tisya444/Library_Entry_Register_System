/* =========================================================
   LIBRARY ENTRY REGISTER SYSTEM
   File 3 of 5 : Resource Planning & Utilization Queries
   ========================================================= */

USE library_entry_register;


/* =========================================================
   Q1. DUPLICATE / SUSPICIOUS STUDENT IDENTITY RECORDS
   ========================================================= */

/* 1(a) Same full name, department and semester
        registered under different Student_IDs */

SELECT
    First_Name,
    Last_Name,
    Department,
    Semester,
    COUNT(*)                                   AS Number_of_Records,
    GROUP_CONCAT(Student_ID ORDER BY Student_ID) AS Student_IDs
FROM Student
GROUP BY First_Name, Last_Name, Department, Semester
HAVING COUNT(*) > 1;


/* 1(b) Same phone number used by more than one student */

SELECT
    sp.Phone,
    COUNT(*)                                       AS Number_of_Students,
    GROUP_CONCAT(sp.Student_ID ORDER BY sp.Student_ID) AS Student_IDs
FROM Student_Phone sp
GROUP BY sp.Phone
HAVING COUNT(*) > 1;


/* =========================================================
   Q2. PEAK LIBRARY HOURS
   ========================================================= */

/* 2(a) Number of entries in each hour */

SELECT
    HOUR(Entry_Time) AS Library_Hour,
    COUNT(*)         AS Number_of_Entries
FROM Library_Visit
GROUP BY HOUR(Entry_Time)
ORDER BY Number_of_Entries DESC, Library_Hour;


/* 2(b) Number of visits present in the library during each hour
        (a 9:00-14:00 visit is counted in every hour from 9 to 13) */

SELECT
    CONCAT(LPAD(h.Hour_Start, 2, '0'), ':00 - ',
           LPAD(h.Hour_Start + 1, 2, '0'), ':00') AS Time_Slot,
    COUNT(lv.Visit_ID)                            AS Students_Present
FROM (
        SELECT 9 AS Hour_Start UNION ALL SELECT 10 UNION ALL SELECT 11
        UNION ALL SELECT 12 UNION ALL SELECT 13 UNION ALL SELECT 14
        UNION ALL SELECT 15
     ) AS h
LEFT JOIN Library_Visit lv
    ON  lv.Entry_Time < MAKETIME(h.Hour_Start + 1, 0, 0)
    AND COALESCE(lv.Exit_Time, '16:00:00') > MAKETIME(h.Hour_Start, 0, 0)
GROUP BY h.Hour_Start
ORDER BY Students_Present DESC, h.Hour_Start;


/* =========================================================
   Q3. STUDENTS USING LIBRARY DURING FREE PERIODS
   ========================================================= */

/* 3(a) Total number of students */

SELECT
    COUNT(DISTINCT Student_ID) AS Students_Using_Library_During_Free_Period
FROM Library_Visit
WHERE Is_Free_Period = 1;


/* 3(b) Student-wise free-period visits */

SELECT
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
    COUNT(lv.Visit_ID)                     AS Free_Period_Visits
FROM Student s
JOIN Library_Visit lv
    ON s.Student_ID = lv.Student_ID
WHERE lv.Is_Free_Period = 1
GROUP BY s.Student_ID, s.First_Name, s.Last_Name
ORDER BY Free_Period_Visits DESC;


/* =========================================================
   Q4. MOST FREQUENT LIBRARY VISITORS
   ========================================================= */

SELECT
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
    s.Department,
    COUNT(lv.Visit_ID)                     AS Number_of_Visits
FROM Student s
JOIN Library_Visit lv
    ON s.Student_ID = lv.Student_ID
GROUP BY s.Student_ID, s.First_Name, s.Last_Name, s.Department
ORDER BY Number_of_Visits DESC;


/* =========================================================
   Q5. PURPOSE OF LIBRARY VISITS
   ========================================================= */

SELECT
    Visit_Purpose,
    COUNT(*)                                            AS Number_of_Visits,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM Library_Visit), 2)
                                                        AS Percentage
FROM Library_Visit
GROUP BY Visit_Purpose
ORDER BY Number_of_Visits DESC;


/* =========================================================
   Q6. MOST DEMANDED BOOK IN EACH SECTION
   ========================================================= */

/* 6(a) Demand count of every book, section-wise */

SELECT
    sec.Section_Name,
    bt.Accn_No,
    COUNT(*) AS Demand_Count
FROM Book_Transaction bt
JOIN Section sec
    ON bt.Section_ID = sec.Section_ID
GROUP BY sec.Section_ID, sec.Section_Name, bt.Accn_No
ORDER BY sec.Section_ID, Demand_Count DESC;


/* 6(b) Only the top book of each section (ties are shown together) */

SELECT
    Section_Name,
    Accn_No,
    Demand_Count
FROM (
        SELECT
            sec.Section_Name,
            bt.Accn_No,
            COUNT(*) AS Demand_Count,
            RANK() OVER (
                PARTITION BY bt.Section_ID
                ORDER BY COUNT(*) DESC
            ) AS Ranking
        FROM Book_Transaction bt
        JOIN Section sec
            ON bt.Section_ID = sec.Section_ID
        GROUP BY bt.Section_ID, sec.Section_Name, bt.Accn_No
     ) AS Ranked_Books
WHERE Ranking = 1;


/* =========================================================
   Q7. STUDENTS WHO SPEND MAXIMUM TIME IN LIBRARY
   ========================================================= */

/* 7(a) Total time of every student (only completed visits) */

SELECT
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name)                       AS Student_Name,
    SUM(TIMESTAMPDIFF(MINUTE, lv.Entry_Time, lv.Exit_Time))      AS Total_Time_Spent_Minutes,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, lv.Entry_Time, lv.Exit_Time)), 0)
                                                                 AS Avg_Minutes_Per_Visit
FROM Student s
JOIN Library_Visit lv
    ON s.Student_ID = lv.Student_ID
WHERE lv.Exit_Time IS NOT NULL
GROUP BY s.Student_ID, s.First_Name, s.Last_Name
ORDER BY Total_Time_Spent_Minutes DESC;


/* 7(b) Student(s) with the maximum total time (ties included) */

SELECT
    Student_ID,
    Student_Name,
    Total_Time_Spent_Minutes
FROM (
        SELECT
            s.Student_ID,
            CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
            SUM(TIMESTAMPDIFF(MINUTE, lv.Entry_Time, lv.Exit_Time))
                                                   AS Total_Time_Spent_Minutes,
            RANK() OVER (
                ORDER BY SUM(TIMESTAMPDIFF(MINUTE, lv.Entry_Time, lv.Exit_Time)) DESC
            ) AS Ranking
        FROM Student s
        JOIN Library_Visit lv
            ON s.Student_ID = lv.Student_ID
        WHERE lv.Exit_Time IS NOT NULL
        GROUP BY s.Student_ID, s.First_Name, s.Last_Name
     ) AS Ranked_Students
WHERE Ranking = 1;


/* =========================================================
   Q8. FREQUENT DEFAULTERS ON BOOK RETURN (2 or more late returns)
   ========================================================= */

SELECT
    s.Student_ID,
    CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
    COUNT(*)                               AS Late_Returns
FROM Student s
JOIN Book_Transaction bt
    ON s.Student_ID = bt.Student_ID
WHERE bt.Return_Date > bt.Due_Date
GROUP BY s.Student_ID, s.First_Name, s.Last_Name
HAVING COUNT(*) >= 2
ORDER BY Late_Returns DESC;


/* =========================================================
   Q9. TOTAL FINE COLLECTED PER MONTH
   ========================================================= */

SELECT
    YEAR(Payment_Date)      AS Payment_Year,
    MONTHNAME(Payment_Date) AS Payment_Month,
    SUM(Fine_Amount)        AS Total_Fine_Collected
FROM Fine
WHERE Payment_Status = 'Paid'
GROUP BY YEAR(Payment_Date), MONTH(Payment_Date), MONTHNAME(Payment_Date)
ORDER BY Payment_Year, MONTH(Payment_Date);
