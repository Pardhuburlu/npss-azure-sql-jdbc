# NPSS (National Park Service System) — Azure SQL + T-SQL + Java (JDBC)

This project is a database-backed system for a National Park Service–style application.  
I designed the ER model, converted it into a relational schema in **Azure SQL Database**, wrote **T-SQL stored procedures** for core operations/queries, and built a **Java (JDBC) menu-driven program** to run everything end-to-end. I also included **CSV import/export** for selected workflows.

---

## What this project includes
- **ER model → relational database design** (tables + relationships + constraints)
- **Azure SQL implementation** (PK/FK constraints, data integrity rules)
- **Stored procedures (T-SQL)** to execute required queries and operations
- **Java JDBC console app** with a simple menu interface to run procedures
- **CSV import/export** to move data in/out of the database (where applicable)

---

## Data model (high level)
The ER model covers key NPSS components such as:
- **People** (base entity) with specialized roles (e.g., **Visitor, Ranger, Researcher, Donor**)
- **National Parks**, including programs offered and conservation projects hosted
- **Ranger teams** and team structure
- **Donations** and payment details
- **Park passes** owned by visitors
- Supporting details like **emergency contact**, enrollments, reporting/oversight links, etc.


## Tech stack
- **Azure SQL Database**
- **T-SQL** (stored procedures, queries)
- **Java + JDBC**
- CSV import/export utilities (as needed)

