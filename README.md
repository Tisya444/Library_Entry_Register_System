# Library Entry Register System

A MySQL database for recording library entries, book issues and returns, and fines, with queries that support resource planning and utilization.

See the full [Problem Statement](Problem-Statement.md).

## ER Diagram

![ER Diagram](Library_Entry_Register_System/er-diagram.png)

### Relationships

| Relationship | Entities | Cardinality |
|---|---|---|
| Makes | Student – Library_Visit | 1 : N |
| Performs | Student – Book_Transaction | 1 : N |
| Belongs_To | Book_Transaction – Section | N : 1 |
| Generates | Book_Transaction – Fine | 1 : N |

`Phone` is a multivalued attribute of Student, so it is stored in a separate `Student_Phone` table.

## Project Files

| File | Contents |
|---|---|
| [01_schema.sql](Library_Entry_Register_System/sql/01_schema.sql) | Database and 6 tables with primary keys, foreign keys and CHECK constraints |
| [02_data.sql](Library_Entry_Register_System/sql/02_data.sql) | Sample data (includes one suspicious duplicate student for testing) |
| [03_queries.sql](Library_Entry_Register_System/sql/03_queries.sql) | 9 resource planning and utilization queries |
| [04_views.sql](Library_Entry_Register_System/sql/04_views.sql) | Views for students, librarians and administrators |
| [05_triggers_procedures.sql](Library_Entry_Register_System/sql/05_triggers_procedures.sql) | 3 functions, 5 triggers, 7 stored procedures |

## Queries

| No. | Query | Tables Used |
|---|---|---|
| Q1 | Duplicate / suspicious student identities | Student, Student_Phone |
| Q2 | Peak library hours | Library_Visit |
| Q3 | Students using the library in free periods | Library_Visit, Student |
| Q4 | Most frequent visitors | Library_Visit, Student |
| Q5 | Purpose of visits | Library_Visit |
| Q6 | Most demanded book in each section | Book_Transaction, Section |
| Q7 | Students who spend maximum time in the library | Library_Visit, Student |
| Q8 | Frequent defaulters on book return | Book_Transaction, Student |
| Q9 | Total fine collected per month | Fine |

## How to Run

Requires MySQL 8.0.16 or later. Run the files in this order in MySQL Workbench:

1. `01_schema.sql`
2. `02_data.sql`
3. `03_queries.sql`
4. `04_views.sql`
5. `05_triggers_procedures.sql`
