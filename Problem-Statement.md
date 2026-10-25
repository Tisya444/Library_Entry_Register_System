# Library Entry Register System

## 1. Resource Planning & Utilization Queries

- Identify duplicate or suspicious student identity records to help detect unauthorized use of identities.
- Identify peak library hours.
- Determine how many students use the library during their free periods.
- Identify the most frequent library visitors.
- Analyze the purpose of library visits, such as borrowing books, returning books, reading/studying, or other activities.
- Identify the most demanded book in each library section.
- Identify the students who spend the maximum amount of time in the library.

## 2. Database Design

Based on the identified requirements and queries, a relational database needs to be designed to store and manage information about students, books, sections, library visits, book transactions, accession records, and other relevant entities.

### Requirements and Corresponding Tables

| Requirement | Required Table(s) |
|---|---|
| Fake/duplicate identity | Student |
| Peak library hours | Library_Visit |
| Free-period usage | Library_Visit, Student |
| Frequent visitors | Library_Visit, Student |
| Visit purpose | Library_Visit |
| Most demanded books in each section | Book_Transaction, Accession_Register, Section |
| Students who spend maximum time in the library | Student, Library_Visit |
| Book and accession records | Accession_Register, Book |
| Fine management | Fine, Book_Transaction, Student |

The database should define appropriate tables, attributes, primary keys, foreign keys, relationships, and constraints.

### Main Tables

The main tables proposed for the system are:

- Student
- Library_Visit
- Book
- Book_Transaction
- Accession_Register
- Section
- Fine

## 3. User-specific Views

The system should provide appropriate database views for different types of users, such as students, librarians, and administrators. Each user should be able to access information relevant to their role while maintaining appropriate data visibility.

## 4. Triggers, Procedures and Functions

The system should use triggers, stored procedures, and functions to handle important database operations and automatic updates. These may include updating book availability after issue or return, calculating fines, maintaining visit records, tracking library usage, and ensuring data consistency during updates.

## Overall Objective

The overall objective is to develop a Library Management System that can efficiently manage library data, support resource planning and utilization, provide role-specific information, and automate important database operations.
