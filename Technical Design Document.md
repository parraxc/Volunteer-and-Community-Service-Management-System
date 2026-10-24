# Technical Design Document
## 1. Project Identification

| Item | Information |
|---|---|
| Project title | Volunteer and Community Service Management System |
| Prepared by | Christian Parra, Prabhas Penumatsa |
| Course | CS 437: Database Systems Implementation |
| Date | October 22, 2026 |
| Version | 1.4 |

## 2. Design Overview

The system provides a centralized relational database for a nonprofit organization to manage staff, volunteers, community events, shifts, volunteer skills, attendance, and approved service hours. Staff use individual database accounts. Volunteers are represented as records and do not log in.

The design contains nine related tables. Primary keys, foreign keys, unique constraints, and same-row checks enforce structural integrity. Triggers and controlled stored procedures enforce rules involving other records, maintain an audit trail, and approve hours atomically. Reports support volunteer contact, scheduling, attendance, approved-hours summaries, and management review.

Each event occurs on one calendar date and has one assigned Event Coordinator. A shift belongs to one event. A volunteer can participate in multiple non-overlapping shifts and have multiple skills. Approved hours are created only from a completed assignment by the event's assigned coordinator. Approved attendance cannot subsequently be corrected through this system.

## 3. Technical Environment

| Component | Design selection | Purpose / verification |
|---|---|---|
| DBMS | MySQL Community Server <version from SELECT VERSION()> | CHECK constraints require 8.0.16 or later; record SELECT VERSION() in the test evidence |
| Storage engine | InnoDB for every table | Foreign-key enforcement, transactional changes, and row locking |
| Character set | utf8mb4 | Store names and descriptions without limiting text to ASCII |
| Client | MySQL command-line client and MySQL Workbench | One saved Workbench connection per test account; command line for scripted builds and clean-checkout verification |
| Modeling | Mermaid for embedded relationship documentation; separate Chen diagram for final ER deliverable | Document relationships here and meet the assignment's conceptual ER notation separately |
| Source control | Existing GitHub repository | Version SQL, documents, diagrams, and reproducible build instructions |
| Operating environment | Local installation on macOS | State the real environment; the build scripts are portable to Windows and Linux |
| Operating environment | Local installation on macOS | State the real environment; the build scripts are portable to Windows and Linux |

MySQL is used because the FRD specifies it, and the required integrity, security, and transaction demonstrations can be implemented in the database. A single server is sufficient for the course workload. No ORM, web framework, or application server is required.
MySQL CHECK constraints are used for same-row validation; cross-table rules use procedures and triggers. Technical references are listed at the end of this document.

## 4. Architecture and Scope

### 4.1 System architecture

```mermaid
flowchart LR
    M[Manager SQL client] --> A[Individual MySQL accounts and roles]
    C[Event Coordinator SQL client] --> A
    S[Staff Member SQL client] --> A
    A --> Q[Authorized reads and report queries]
    A --> W[Authorized writes and controlled procedures]
    W --> V[Constraints and validation triggers]
    V --> D[(Nine InnoDB tables)]
    V --> L[Audit triggers]
    L --> AU[(AuditLog)]
    D --> Q
    AU --> MR[Manager audit report]
```

The client is the application integration boundary. A future application can call the same database interfaces using authenticated accounts; building that application is outside scope. Deployment credentials are separate from operational staff accounts.

### 4.2 Information flow

```mermaid
flowchart TD
    MG[Manager] -->|Staff records and event/coordinator setup| P1[Maintain reference data]
    P1 --> D1[(StaffMember and Event)]
    EC[Event Coordinator] -->|Volunteer, skill, and shift details| P2[Maintain scheduling data]
    P2 --> D2[(Volunteer, Skill, VolunteerSkill, Shift)]
    EC -->|Volunteer and shift identifiers| P3[Validate and assign]
    D1 --> P3
    D2 --> P3
    P3 --> D3[(VolunteerShift)]
    EC -->|Actual check-in and check-out| P4[Record attendance]
    P4 --> D3
    EC -->|Approve completed assignment| P5[Authorize and calculate hours]
    D1 --> P5
    D3 --> P5
    P5 -->|Approval metadata| D3
    P5 --> D4[(VolunteerHours)]
    P5 --> D5[(AuditLog)]
    P3 --> D5
    P4 --> D5
    P2 -->|Volunteer changes| D5
    P1 -->|Event changes| D5
    D2 --> R[Authorized reports]
    D3 --> R
    D4 --> R
```

Audit triggers capture each audited insert/update; the flowchart groups those internal operations for readability. Skills and shifts are not audited under BR-29's minimum table list.

### 4.3 Scope and boundaries

Included: staff records and roles, event coordination, shifts, volunteer contact/background-check status, skills, assignments, attendance, approval, audit logging, SQL reports, schema build, and fictional initial data.

Excluded: public registration, mobile/web application development, automatic background-check expiration, multi-day/overnight shifts, correction of approved hours, and long-term community outcomes. Operational roles cannot delete records. Database administration and account provisioning are deployment activities.

## 5. Entity-Relationship Design

### 5.1 Relationships and participation

| Relationship | Cardinality and participation |
|---|---|
| StaffMember coordinates Event | A staff member coordinates 0..N events; each event has exactly 1 coordinator. Event participation is total; staff participation is partial. Assigned staff must have Event Coordinator role. |
| Event contains Shift | An event has 0..N shifts; each shift belongs to exactly 1 event. Shift participation is total. |
| Volunteer has VolunteerShift | A volunteer has 0..N assignments; each assignment has exactly 1 volunteer. Assignment participation is total. |
| Shift has VolunteerShift | A shift has 0..N assignments; each assignment has exactly 1 shift. Assignment participation is total. |
| VolunteerShift produces VolunteerHours | An assignment has 0..1 approved-hours record; each hours record belongs to exactly 1 assignment. Hours participation is total; assignment participation is partial. |
| StaffMember approves VolunteerShift | A staff member approves 0..N assignments; an assignment has 0..1 approver. Approval requires the assigned Event Coordinator. |
| Volunteer has VolunteerSkill | A volunteer has 0..N skill memberships; each membership belongs to exactly 1 volunteer. |
| Skill has VolunteerSkill | A skill has 0..N memberships; each membership references exactly 1 skill. |
| StaffMember is attributed AuditLog | A staff member is associated with 0..N audit entries; an audit entry has 0..1 mapped staff identity plus a required database-actor string. Deployment actors may have no StaffMember row. |

Volunteer–Shift and Volunteer–Skill are conceptual M:N relationships resolved through junction tables. Assignment–Hours is a conceptual 1:1 relationship with optional hours on the assignment side.

### 5.2 Relationship sketch

```mermaid
erDiagram
    StaffMember ||--o{ Event : coordinates
    Event ||--o{ Shift : contains
    Volunteer ||--o{ VolunteerShift : receives
    Shift ||--o{ VolunteerShift : includes
    VolunteerShift ||--o| VolunteerHours : produces
    StaffMember o|--o{ VolunteerShift : approves
    Volunteer ||--o{ VolunteerSkill : has
    Skill ||--o{ VolunteerSkill : classifies
    StaffMember o|--o{ AuditLog : attributed_to
```

This relationship sketch supports the TDD. The final ER deliverable must additionally show all attributes, keys, relationship diamonds, total/partial participation, and the assignment's requested attribute-type notation.

### 5.3 Logical attribute diagram

This diagram lists every designed column and its SQL type/key role. Nullability and full constraints are specified in section 7. It is a logical schema diagram; the separate conceptual Chen diagram remains a distinct deliverable.

```mermaid
erDiagram
    StaffMember {
        INT StaffID PK
        VARCHAR_100 StaffName
        VARCHAR_20 StaffRole
        VARCHAR_32 DbUsername UK
    }
    Event {
        INT EventID PK
        VARCHAR_150 EventName
        DATE EventDate
        INT CoordinatorID FK
    }
    Shift {
        INT ShiftID PK
        INT EventID FK
        VARCHAR_100 ShiftRole
        INT Capacity
        DATETIME StartDateTime
        DATETIME EndDateTime
    }
    Volunteer {
        INT VolunteerID PK
        VARCHAR_100 VolunteerName
        VARCHAR_25 VolunteerPhoneNumber
        VARCHAR_100 VolunteerEmail
        BOOLEAN BackgroundCheck
    }
    VolunteerShift {
        INT VolunteerID PK, FK
        INT ShiftID PK, FK
        VARCHAR_40 Status
        DATETIME CheckInTime
        DATETIME CheckOutTime
        INT ApprovedBy FK
        DATETIME_6 ApprovedAt
    }
    VolunteerHours {
        INT VolunteerID PK, FK
        INT ShiftID PK, FK
        DECIMAL_8_2 HoursWorked
    }
    Skill {
        INT SkillCode PK
        VARCHAR_50 SkillName UK
        VARCHAR_100 SkillDescription
    }
    VolunteerSkill {
        INT VolunteerID PK, FK
        INT SkillCode PK, FK
    }
    AuditLog {
        BIGINT_UNSIGNED AuditID PK
        VARCHAR_64 TableName
        ENUM Operation
        VARCHAR_100 RecordId
        VARCHAR_288 ChangedBy
        INT ChangedByStaffID FK
        DATETIME_6 ChangedAt
        JSON OldValues
        JSON NewValues
    }
    StaffMember ||--o{ Event : coordinates
    Event ||--o{ Shift : contains
    Volunteer ||--o{ VolunteerShift : receives
    Shift ||--o{ VolunteerShift : includes
    VolunteerShift ||--o| VolunteerHours : produces
    StaffMember o|--o{ VolunteerShift : approves
    Volunteer ||--o{ VolunteerSkill : has
    Skill ||--o{ VolunteerSkill : classifies
    StaffMember o|--o{ AuditLog : attributed_to
```

### 5.4 Weak entities and attribute types

VolunteerHours is existence- and identification-dependent on VolunteerShift. Its complete primary key is also a foreign key to that assignment. Show it as a weak entity with an identifying relationship in the conceptual diagram. VolunteerShift and VolunteerSkill are associative entities with composite keys.

Identifiers are key attributes. Total approved hours and remaining shift capacity are derived report attributes. HoursWorked is a stored, immutable derived value calculated at approval. A volunteer's collection of skills is a conceptual multivalued attribute represented relationally by VolunteerSkill. Names and phone numbers are treated as atomic text for this application's operations; there is no invented need to split names or store multiple contacts. Composite identifiers are identified explicitly; no composite contact attribute is required by the FDD.

## 6. Relational Schema

PK = primary key; FK = foreign key; UQ = unique key. All foreign keys use RESTRICT behavior for deletion and key updates. No operational role changes identifier values; keys referenced by other tables are protected by RESTRICT.

```text
StaffMember(StaffID PK, StaffName, StaffRole, DbUsername UQ)
Event(EventID PK, EventName, EventDate, CoordinatorID FK -> StaffMember.StaffID)
Shift(ShiftID PK, EventID FK -> Event.EventID, ShiftRole, Capacity,
      StartDateTime, EndDateTime)
Volunteer(VolunteerID PK, VolunteerName, VolunteerPhoneNumber,
          VolunteerEmail, BackgroundCheck)
VolunteerShift(VolunteerID PK/FK -> Volunteer.VolunteerID,
               ShiftID PK/FK -> Shift.ShiftID, Status,
               CheckInTime, CheckOutTime,
               ApprovedBy FK -> StaffMember.StaffID, HoursApproved, ApprovedBy, ApprovedAt)
VolunteerHours(VolunteerID PK, ShiftID PK, HoursWorked,
               FK (VolunteerID, ShiftID)
                   -> VolunteerShift(VolunteerID, ShiftID))
Skill(SkillCode PK, SkillName UQ, SkillDescription)
VolunteerSkill(VolunteerID PK/FK -> Volunteer.VolunteerID,
               SkillCode PK/FK -> Skill.SkillCode)
AuditLog(AuditID PK, TableName, Operation, RecordId,
         ChangedBy, ChangedByStaffID FK -> StaffMember.StaffID,
         ChangedAt, OldValues, NewValues)
```

Do not duplicate volunteer, event, or shift descriptive data in assignment or hours records. Joins retrieve those attributes. Audit snapshots intentionally preserve historical old/new values and are not the authoritative current records.

## 7. Table and Attribute Specifications

Unless marked nullable, columns are NOT NULL. Integer surrogate primary keys use AUTO_INCREMENT. Composite primary keys have no generated component. Text length limits are initial design choices to verify against sample data.

### 7.1 StaffMember

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| StaffID | INT | Required; generated | PK |
| StaffName | VARCHAR(100) | Required | Staff display name |
| StaffRole | VARCHAR(20) | Required | CHECK: Manager, Event Coordinator, or Staff Member |
| DbUsername | VARCHAR(32) | Required | UQ; individual database username |

Operational usernames are unique across allowed account hosts; anonymous accounts and shared staff accounts are excluded. Use a case-sensitive comparison for identity mapping, matching the account provisioning convention. MySQL roles and StaffRole must agree; provisioning and role changes update both under administrator control. DbUsername uses the utf8mb4_bin collation so identity matching is case-sensitive.

### 7.2 Event

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| EventID | INT | Required; generated | PK |
| EventName | VARCHAR(150) | Required | Event title |
| EventDate | DATE | Required | Single calendar date |
| CoordinatorID | INT | Required | FK to StaffMember; role validated |

### 7.3 Shift

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| ShiftID | INT | Required; generated | PK |
| EventID | INT | Required | FK to Event |
| ShiftRole | VARCHAR(100) | Required | Work performed |
| Capacity | INT | Required | CHECK > 0 |
| StartDateTime | DATETIME | Required | Event-local start |
| EndDateTime | DATETIME | Required | CHECK > StartDateTime |

Both timestamp dates must equal EventDate. Overnight shifts are rejected.

### 7.4 Volunteer

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| VolunteerID | INT | Required; generated | PK |
| VolunteerName | VARCHAR(100) | Required | Display/contact name |
| VolunteerPhoneNumber | VARCHAR(20) | Required | Text preserves leading zeros, plus signs, and formatting |
| VolunteerEmail | VARCHAR(100) | Required | Contact email; uniqueness is not required by the FDD |
| BackgroundCheck | BOOLEAN | Required; FALSE | CHECK IN (0,1); current verified flag |

No background-check documents, expiration dates, or sensitive background-check details are stored.

### 7.5 VolunteerShift

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| VolunteerID | INT | Required | Composite PK; FK to Volunteer |
| ShiftID | INT | Required | Composite PK; FK to Shift |
| Status | VARCHAR(40) | Required; Scheduled | Allowed values below |
| CheckInTime | DATETIME | Nullable; NULL | Actual attendance start |
| CheckOutTime | DATETIME | Nullable; NULL | Actual attendance end |
| ApprovedBy | INT | Nullable; NULL | FK to StaffMember; procedure-managed |
| ApprovedAt | DATETIME(6) | Nullable; NULL | UTC approval time; procedure-managed |

There is no separately stored HoursApproved flag: approval is derived from ApprovedAt IS NOT NULL. ApprovedBy and ApprovedAt must both be NULL or both non-NULL; non-NULL approval requires Completed status.

| Status | CheckInTime | CheckOutTime |
|---|---|---|
| Scheduled | NULL | NULL |
| In-Progress | Required | NULL |
| Completed | Required | Required, later than check-in |
| No-Show | NULL | NULL |
| Cancelled | NULL | NULL |

A same-row CHECK enforces this matrix. A new assignment must be Scheduled with no times (BR-34). Check-in must fall within the shift (not earlier than its start and before its end), and check-out must fall on the event's date (BR-17).

A BEFORE UPDATE trigger derives the status from newly recorded times (BR-35): the first check-in sets In-Progress, and a check-out sets Completed, including when both times are recorded together on a Scheduled assignment. A requested status that contradicts the times is rejected. Other status changes follow this table (BR-20):

| From | Allowed to |
|---|---|
| Scheduled | In-Progress, Completed (both times recorded together), No-Show, Cancelled |
| In-Progress | Completed |
| Completed | none (final) |
| No-Show | none (final) |
| Cancelled | Scheduled (re-runs the background-check, capacity, and overlap checks) |

After approval, no column of the assignment can change (BR-24). Test T09 verifies that the status set by the trigger is the value the CHECK constraint evaluates.

### 7.6 VolunteerHours

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| VolunteerID | INT | Required | Composite PK; component of assignment FK |
| ShiftID | INT | Required | Composite PK; component of assignment FK |
| HoursWorked | DECIMAL(8,2) | Required | CHECK > 0; approval-time calculated hours |

Hours are calculated at approval as ROUND(TIMESTAMPDIFF(SECOND, CheckInTime, CheckOutTime) / 3600.0, 2). ApproveHours rejects a rounded result of zero or less. No manual edits or duplicate approval records are permitted (FRD BR-22, BR-36)

### 7.7 Skill

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| SkillCode | INT | Required; generated | PK |
| SkillName | VARCHAR(50) | Required | UQ |
| SkillDescription | VARCHAR(100) | Required | Explanation of skill |

### 7.8 VolunteerSkill

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| VolunteerID | INT | Required | Composite PK; FK to Volunteer |
| SkillCode | INT | Required | Composite PK; FK to Skill |

The pair is unique. Neither a volunteer nor a skill is required to have a membership. Deletes remain disallowed under the FDD; skill removal/deactivation is outside the current specification.

### 7.9 AuditLog

| Column | Type | Null/default | Key / meaning |
|---|---|---|---|
| AuditID | BIGINT UNSIGNED | Required; generated | PK; standardized from starter column Id |
| TableName | VARCHAR(64) | Required | Audited source table |
| Operation | ENUM('INSERT','UPDATE') | Required | DML operation |
| RecordId | VARCHAR(100) | Required | Source key; composite key serialized consistently |
| ChangedBy | VARCHAR(288) | Required | Full connected database actor string |
| ChangedByStaffID | INT | Nullable; NULL | FK to mapped StaffMember; NULL for deployment actor |
| ChangedAt | DATETIME(6) | Required; UTC assigned by trigger | Change timestamp |
| OldValues | JSON | Nullable | NULL for insert; before-image for update |
| NewValues | JSON | Required | After-image |

Composite RecordId values use stable field names, for example `VolunteerID=12;ShiftID=7`. TableName and RecordId identify different source tables and therefore do not form a single foreign key. Actor strings are retained even when no operational staff identity exists. Audit snapshots contain only the relevant table's fields; no account passwords or connection secrets are included.

## 8. Normalization Analysis

The operational relations satisfy 3NF under the following stated dependencies. Reports compute totals rather than storing running aggregates.

| Relation | Functional dependencies and normalization reasoning |
|---|---|
| StaffMember | StaffID → StaffName, StaffRole, DbUsername; DbUsername is another candidate key. No role description or repeated event list is stored. |
| Event | EventID → EventName, EventDate, CoordinatorID. Staff name/login remain in StaffMember, removing transitive staff details. |
| Shift | ShiftID → EventID, ShiftRole, Capacity, StartDateTime, EndDateTime. Event name/date are not copied into Shift. |
| Volunteer | VolunteerID → VolunteerName, VolunteerPhoneNumber, VolunteerEmail, BackgroundCheck. Skills are separate rows, not repeating columns. |
| VolunteerShift | (VolunteerID, ShiftID) → Status, CheckInTime, CheckOutTime, ApprovedBy, ApprovedAt. All non-key attributes describe the complete assignment, not either key component independently. Approver name is not duplicated. |
| VolunteerHours | (VolunteerID, ShiftID) → HoursWorked. There are no non-key determinants within this relation. This is an approval snapshot; cross-table consistency with attendance is maintained by atomic approval and immutability. |
| Skill | SkillCode → SkillName, SkillDescription; SkillName is an alternate candidate key. Description is not repeated in membership rows. |
| VolunteerSkill | Only the complete composite key is stored; no non-key attribute can introduce partial/transitive dependency. |
| AuditLog | AuditID → remaining columns. Actor and JSON snapshots are deliberate historical records; staff names are not maintained here as current staff master data. |

1NF: each operational column stores one value and memberships use separate rows. Audit JSON is an intentional history payload, not a substitute for normalized operational entities. 2NF: assignment-related facts depend on the entire composite key; single-key tables have no partial-key dependency. 3NF: descriptive staff, event, volunteer, and skill facts are stored in their own relations and accessed by keys.

Stored HoursWorked is deliberate derivation, not a claim that derivation alone violates 3NF. Its redundancy across tables requires the approval controls described below.

## 9. Integrity, Validation, and Business-Rule Enforcement

### 9.1 Enforcement matrix

Object names below describe the implemented objects; trigger names follow the pattern Table_timing_event.

| FDD rule | Design enforcement |
|---|---|
| BR-01, BR-02 | Event and Volunteer primary keys |
| BR-03 | Shift.EventID NOT NULL FK |
| BR-04 | Event.CoordinatorID NOT NULL FK |
| BR-05 | Event BEFORE INSERT/UPDATE trigger checks coordinator role; controlled staff-role maintenance prevents invalidating existing assignments |
| BR-06 | StaffRole CHECK |
| BR-07 | Capacity and timestamp CHECK constraints |
| BR-08 | Shift BEFORE INSERT/UPDATE trigger checks EventDate; event-date edits restricted as below |
| BR-09, BR-10 | VolunteerShift composite PK and FKs |
| BR-11 | BEFORE INSERT trigger on VolunteerShift; BEFORE UPDATE trigger when a Cancelled assignment returns to Scheduled |
| BR-12 | BEFORE INSERT/UPDATE trigger locks the Shift row (SELECT ... FOR UPDATE), then counts non-Cancelled assignments with a plain read; SaveAssignment holds the Volunteer and Shift locks under READ COMMITTED (section 9.2) |
| BR-13 | BEFORE INSERT/UPDATE trigger checks overlapping non-Cancelled assignments; SaveAssignment locks the Volunteer row so one person's requests are serialized |
| BR-14 | Attendance fields exist only on VolunteerShift |
| BR-15, BR-16 | Status domain and status/time CHECK constraints |
| BR-17 | BEFORE UPDATE trigger compares attendance times with the shift window and event date |
| BR-18 | CHECK: CheckOutTime IS NULL OR CheckInTime IS NULL OR CheckOutTime > CheckInTime; status matrix independently rejects incomplete Completed rows |
| BR-19 | No operational DELETE grants; BEFORE DELETE trigger rejects assignment deletion |
| BR-20 | BEFORE UPDATE trigger checks cancellation transitions; reactivation runs full eligibility/capacity/overlap validation |
| BR-21| ApproveHours validates identity, ownership, and completion; updates approval and inserts hours in one transaction |
| BR-22 | ApproveHours calculates hours, rounds to two decimals, and rejects a rounded result of zero or less |
| BR-23 | HoursWorked CHECK > 0 and procedure rounding validation |
| BR-24 | BEFORE UPDATE trigger rejects any change to an approved assignment |
| BR-25 | VolunteerSkill composite PK and FKs |
| BR-26 | StaffMember.DbUsername UNIQUE NOT NULL |
| BR-27 | MySQL roles; EXECUTE on SaveAssignment and ApproveHours granted only to the Event Coordinator role; no INSERT/UPDATE/DELETE grants on VolunteerShift or VolunteerHours for operational roles; account/StaffRole alignment |
| BR-28 | ApproveHours derives actor from connected user; no staff-ID argument |
| BR-29 | AFTER INSERT/UPDATE triggers on Volunteer, VolunteerShift, VolunteerHours, and Event insert AuditLog records |
| BR-30 | No operational AuditLog DML grants; BEFORE UPDATE/DELETE triggers reject mutation |
| BR-31 | Event BEFORE UPDATE trigger rejects EventDate changes once the event has shifts |
| BR-32 | Shift BEFORE UPDATE trigger rejects changes to event, start, end, and capacity once any assignment exists |
| BR-33 | StaffMember BEFORE UPDATE trigger rejects a role change away from Event Coordinator while the person coordinates an event |
| BR-34 | VolunteerShift BEFORE INSERT trigger requires status Scheduled and no times |
| BR-35 | VolunteerShift BEFORE UPDATE trigger sets NEW. Status from newly recorded times and rejects a contradictory requested status |
| BR-36 | BEFORE UPDATE and BEFORE DELETE triggers on VolunteerHours; no UPDATE or DELETE grants |
| BR-37 | SaveAssignment: locks Volunteer, then Shift, then the assignment, under READ COMMITTED; no direct INSERT or UPDATE grants on VolunteerShift |

### 9.2 Concurrent scheduling

A count followed by an insert without serialization is insufficient. Assignment writes go through the SaveAssignment procedure, which owns the transaction. Staff roles receive EXECUTE for permitted assignment actions instead of INSERT/UPDATE on VolunteerShift. This implements the FRD's add/update entitlement through a controlled interface; it changes the physical enforcement, not the business permission.

SaveAssignment sets READ COMMITTED, then locks the Volunteer row, the Shift row, and the assignment row in that order using SELECT ... FOR UPDATE, then writes. The VolunteerShift triggers perform the eligibility, capacity, overlap, transition, and attendance validation. MySQL does not allow a trigger to take a locking read on the table that fired it (error 1442), so the trigger locks the Shift row, which is a different table, and counts assignments with a plain read. Under READ COMMITTED that read sees rows committed by a competing request that held the lock first.

The Volunteer lock serializes competing schedules for the same person. The Shift lock serializes competing requests for the same capacity. The overlap predicate is new.StartDateTime < existing.EndDateTime AND new.EndDateTime > existing.StartDateTime. Cancelled rows are excluded, which also excludes the row being reactivated, since it is Cancelled until the update completes. Back-to-back shifts are allowed.

Transactions are short. Deadlock and lock-timeout errors roll back and return a retryable error; clients retry the whole operation. The procedures assume no transaction is already open (START TRANSACTION would commit it). Two-session tests (T17, T18) are required before describing the concurrency protection as verified.

### 9.3 Parent edits and historical consistency

Parent edits are restricted by triggers (BR-31 to BR-33). Once an event has shifts, EventDate cannot change. Once a shift has any assignment, including a Cancelled one, its event, start, end, and capacity cannot change; a shift with no assignments can still be edited, subject to the event-date rule. A staff member cannot leave the Event Coordinator role while coordinating an event.

An UPDATE takes an exclusive lock on the row it changes, so these edits serialize with SaveAssignment and ApproveHours, which lock the Shift and Event rows. Reassigning an event's coordinator is a Manager action; because ApproveHours locks the Event row, an approval and a reassignment cannot interleave, and past approvals are not rewritten. A background-check revocation blocks new or reactivated assignments; it does not remove historical attendance or approved hours.

## 10. Database Objects and SQL Design

### 10.1 Stored procedures
| Object | Responsibility |
|---|---|
| SaveAssignment | Parameters: VolunteerID, ShiftID, status, check-in time, check-out time (NULL leaves a value unchanged). Identifies an Event Coordinator from USER(); owns the transaction; locks Volunteer, Shift, then the assignment; inserts or updates. The VolunteerShift triggers validate. Does not accept approval metadata. Runs as the restricted definer volunteer_proc. |
| ApproveHours | Parameters: VolunteerID, ShiftID only. Identifies the assigned Event Coordinator from USER(); owns the transaction; approves and creates the hours record atomically. Runs as volunteer_proc. |

Parent edits (shift, event, staff role) use ordinary UPDATE statements protected by the triggers in section 9.3, and no separate maintenance routines exist. Reports are plain SELECT queries in reports.sql; access is controlled by grants.

### 10.2 ApproveHours algorithm

1. Resolve the connected username from USER() to exactly one StaffMember and require StaffRole = Event Coordinator. Preserve the full connection actor for audit. Do not substitute CURRENT_USER() inside a definer routine for the caller identity.
2. Begin a transaction; lock the Volunteer and Shift rows in the scheduling lock order, then lock the Event and VolunteerShift records needed for authorization and approval. Maintenance routines must use compatible ordering; test conflicting event/shift operations for deadlocks.
3. Require Event.CoordinatorID to equal the caller's StaffID, assignment Status = Completed, valid check-in/out, and NULL approval fields. Reject a missing assignment or an existing VolunteerHours row.
4. Calculate rounded hours using section 7.6. Reject an unrepresentable/nonpositive result.
5. Set ApprovedBy and ApprovedAt on VolunteerShift and insert the single VolunteerHours row. The auditing triggers write entries for both changes.
6. Commit only if all changes succeed. An EXIT handler for SQLEXCEPTION performs ROLLBACK and RESIGNAL. A duplicate/concurrent approval must result in one successful record and one rejection, never duplicate hours.

Approval fields are not writable by coordinator grants or SaveAssignment. A narrowly privileged SQL SECURITY DEFINER routine performs those writes. Do not use a caller-set session variable as an authorization bypass. Triggers enforce immutability after approval; routine privileges enforce who can set initial approval.

### 10.3 Trigger responsibilities

Validation triggers enforce coordinator role, shift date, attendance and time rules, status transitions, approved-record immutability, delete protection, and parent-edit restrictions. Eligibility, capacity, and overlap are checked in VolunteerShift triggers so that no write path can bypass them; SaveAssignment adds serialization (section 9.2).

AFTER INSERT and AFTER UPDATE audit triggers cover Event, Volunteer, and VolunteerShift, and an AFTER INSERT trigger covers VolunteerHours, whose updates and deletes are always rejected. That makes seven audit triggers. Each inserts an AuditLog row with the connected actor, the mapped staff ID (NULL for a deployment account), source key, operation, UTC timestamp, and old/new JSON images. AuditLog has no audit trigger of its own. Rejected or rolled-back writes leave no audit entry. Failed login and permission attempts would need server security logging and are out of scope.

The required “trigger making an update” demonstration is satisfied by a proposed BEFORE UPDATE attendance trigger that sets NEW.Status to In-Progress when check-in is first recorded and to Completed when checkout is recorded on an unapproved assignment. It must reject an explicitly contradictory requested status, then apply status/time checks. This mutates the incoming row using SET NEW.Status, rather than issuing a second UPDATE against the triggering table. The concrete implementation and instructor interpretation of this demonstration must be verified; audit-trigger INSERTs alone are not presented as an UPDATE demonstration.

### 10.4 Build and initial-data process

The final repository must provide an entry script and documented commands that obtain the repository and build a fresh schema with fictional initial data. Build order: setup (restricted definer account), tables, routines, triggers, roles and grants, seed data, account provisioning, then the approval seed scripts run as the coordinator accounts.” Replace “Internal seed routines may be executed by the deployment account” (in 10.5) with “Seed approvals are run by the coordinator test accounts, since ApproveHours accepts only a connected Event Coordinator.

Privileged account provisioning is a separate, documented deployment step and uses local secrets. No password is committed. The build must stop on SQL errors; do not conceal errors with force/continue options. Document required working directory and paths. Keep reset/drop behavior explicit and limited to the project's test database. A fresh build is verified from a clean checkout, rather than assuming the existing developer database proves reproducibility.

### 10.5 Concrete deployment and build contract

he reference database is volunteer_db. Use InnoDB and utf8mb4 with strict SQL mode. SaveAssignment sets READ COMMITTED for its own transaction, so no connection-level setting is required. Shift and attendance times are event-local values supplied explicitly; approval and audit times use UTC_TIMESTAMP(6)

Recommended repository layout:

```text
build.sql
volunteer_DB/
  00_setup/accounts.sql
  01_tables/tables.sql
  02_routines/routines.sql
  03_triggers/triggers.sql
  04_seed/sample_data.sql
  05_reports/reports.sql
  06_tests/acceptance.sql
  07_security/roles.sql
scripts/
  provision_accounts.sql.example
  seed_approvals_coord1.sql
  seed_approvals_coord2.sql
```

build.sql drops and recreates volunteer_db and is intended for the project’s test database only; it must not be pointed at any other database. It must be run from the repository root.

Reference fresh-checkout invocation (requires the completed build files and configured MySQL login path):

```sh
git clone https://github.com/parraxc/Volunteer-and-Community-Service-Management-System.git
cd Volunteer-and-Community-Service-Management-System
mysql --login-path=volunteer-build --show-warnings < build.sql
```

The build account is an administrative deployment identity, not a Manager account. Credential setup uses a local login configuration or secret store, never a plaintext repository file. Operational accounts and the restricted routine definer are provisioned by deployment SQL after their required objects exist. Internal seed routines may be executed by the deployment account, but operational accounts must already have valid StaffMember mappings before their writes are tested.

Environment evidence query, run in each demonstration connection:

```sql
SELECT VERSION() AS ServerVersion,
       @@version_comment AS Distribution,
       @@session.sql_mode AS SqlMode,
       @@session.transaction_isolation AS IsolationLevel,
       @@session.time_zone AS SessionTimeZone,
       USER() AS ConnectedActor,
       CURRENT_USER() AS AuthenticatedAccount;
SHOW SESSION STATUS LIKE 'Ssl_cipher';
SHOW GRANTS;
```

A blank TLS cipher may be expected for a local Unix socket; it does not prove remote encryption. Record the connection method alongside the output. Maintain a versioned fixture timezone setting independent of the machine timezone. Actual outputs belong in test evidence, not fabricated into this document.

### 10.6 Indexing, performance, and growth

| Proposed index / existing key | Purpose |
|---|---|
| StaffMember(DbUsername) UNIQUE | Login mapping |
| Event(CoordinatorID, EventDate) | Coordinator/event filtering |
| Shift(EventID, StartDateTime) | Event shift lookups |
| VolunteerShift PK(VolunteerID, ShiftID) | Uniqueness and volunteer assignment lookup |
| VolunteerShift(ShiftID, Status, VolunteerID) | Capacity counting and rosters |
| VolunteerShift(Status, ApprovedAt, ShiftID) | Candidate index for pending approval; measure selectivity before keeping |
| VolunteerHours PK(VolunteerID, ShiftID), plus ShiftID index where needed | Volunteer totals and event joins |
| VolunteerSkill PK(VolunteerID, SkillCode), plus (SkillCode, VolunteerID) | Skill search in either direction |
| Volunteer(VolunteerName) | Directory sorting/search where optimizer benefits |
| AuditLog(TableName, RecordId, ChangedAt) | Record history |
| AuditLog(ChangedByStaffID, ChangedAt) | Staff audit review |

Review automatically created foreign-key indexes before adding redundant indexes. Use EXPLAIN and measured execution times for capacity, hours summary, skill search, and audit history queries. Indexes increase write/audit storage cost and are retained based on observed benefit.

| Workload | Design approach |
|---|---|
| Large batch writes | Bounded transactions through supported interfaces, parent-before-child loading, no constraint bypass; measure lock duration |
| Reads | Indexed joins, selective date/event filters, preaggregate hours before joining other one-to-many data |
| Updates | Lookup by indexed keys; hold locks only for validation/write; retain audit records |
| Deletes | Demonstrate operational denial; any future retention purge needs a separate design |
| High transaction volume | Test simultaneous signups and approvals, deadlock handling, and audit write overhead |
| Large extracts | Stream filtered results or use stable keyset pages; export an immutable dataset/snapshot when consistency is required |
| Growth | Monitor rows, query latency, database/audit size, and index usage; increase resources and tune queries before considering replication/partitioning |

Suggested nonbinding test scales are hundreds of fictional volunteers for correctness and larger generated datasets for query-plan comparison. No response-time or scalability result is claimed without measurements.

## 11. Query and Report Design

Report IDs follow the FRD’s Reports and Queries table.

| ID / report | Inputs and SQL design | Result / edge case |
|---|---|---|
| RQ-01 Volunteer Directory | SELECT Volunteer; ORDER BY VolunteerName, VolunteerID | ID, name, phone, email, background status |
| RQ-02 Shift Roster | Optional ShiftID/EventID; join Event → Shift → VolunteerShift → Volunteer; Status <> Cancelled | Event/shift/role, volunteer, status; cancelled rows excluded |
| RQ-03 Shift Capacity | Event → Shift LEFT JOIN non-Cancelled assignments; GROUP BY shift attributes | Capacity, COUNT of matching assignment key, capacity minus count; empty shifts remain |
| RQ-04 Pending Hours Approval | Join Event, Shift, VolunteerShift, Volunteer; Completed and ApprovedAt IS NULL; filter coordinator | Attendance and calculated hours; approved assignment disappears after success |
| RQ-05 Volunteer Hours Summary | Aggregate VolunteerHours joined through Shift/Event with date filter inside aggregate; LEFT JOIN aggregate to Volunteer; COALESCE(total,0) | Every volunteer, including zero hours in selected range |
| RQ-06 Event Volunteer Hours | Event/Shift joined to approved hours; COUNT(DISTINCT VolunteerID), SUM(HoursWorked) | Volunteer counted once across multiple event shifts; hours from every approved shift included |
| RQ-07 Volunteer Skills Search | SkillCode filter; join Skill → VolunteerSkill → Volunteer | Matching volunteer, skill code, description |
| RQ-08 Background Check | Volunteer WHERE BackgroundCheck = FALSE | Only uncleared volunteers |
| RQ-09 Attendance | EventID/ShiftID filters; join Event, Shift, VolunteerShift, Volunteer; no status exclusion | Check-in/out and every status, including No-Show and Cancelled |
| RQ-10 Audit Log | Optional table/key/staff/date range; manager-only SELECT or report routine; ORDER BY ChangedAt DESC, AuditID DESC | Actor, timestamp, table/key, operation, old/new values |

Pending-hours coordinator filtering is a query parameter for discovery; ApproveHours always derives authorization independently. Global SELECT visibility for coordinators otherwise follows the FDD. Do not imply that report filters provide row-level access control.

Date ranges are inclusive for EventDate. Timestamp reports use a documented half-open interval [start, end) to avoid losing fractional seconds. All user-supplied values are bound parameters in future application integration; SQL demonstrations use clearly defined parameters.

Required SQL demonstrations include joins in the roster, UPDATE through attendance maintenance, aggregates in hours reports, a NOT EXISTS subquery identifying completed assignments with no VolunteerHours row, and procedure exception handling. The subquery report must agree with ApprovedAt-based pending results; a mismatch indicates an integrity defect.

## 12. Security, Privacy, and Backup Assumptions

### 12.1 Entitlements

V = view; A/U = authorized add/update, which may be exposed through controlled procedures; X = execute. No operational role receives DELETE, DDL, GRANT OPTION, or broad administrator privileges.

| Resource | Manager | Event Coordinator | Staff Member |
|---|---|---|---|
| StaffMember | V, A, U via controlled role maintenance where needed | None | None |
| Event | V, A, U | V | V |
| Shift | V | V, A, U | V |
| Volunteer, Skill, VolunteerSkill | V | V, A, U | V |
| VolunteerShift | V | V; changes only through SaveAssignment | V |
| SaveAssignment | None | X | None |
| VolunteerHours | V | V; no direct writes | None |
| ApproveHours | None | X, own events only | None |
| AuditLog | V | None | None |

Approval metadata is excluded from user-writable columns. Event Coordinators have no INSERT or UPDATE grant on VolunteerShift or VolunteerHours; assignment changes go through EXECUTE on SaveAssignment and approval through EXECUTE on ApproveHours. Both run as the restricted definer volunteer_proc, which holds only the privileges those routines need. Report queries must not expose a source table forbidden by this matrix

The database schema owner remains technically capable of altering controls; audit immutability is an operational-role guarantee, not protection against a malicious database administrator.

### 12.2 Identity, encryption, and privacy

Provision one database login per staff member and map it to DbUsername. Restrict account host patterns and disallow username reuse across hosts for different people. USER() identifies the connected actor; record the full value in AuditLog and compare the username component case-sensitively to the provisioned staff mapping. Database role grants and stored StaffRole are separate controls and must be kept consistent.

Use only fictional volunteer/contact data for the course. Restrict database and backup files to authorized users. Require TLS with certificate verification for remote connections; record whether the class demonstration uses a local socket or verified TLS. At-rest protection relies initially on host/disk and backup encryption; native MySQL tablespace encryption is not asserted as configured. MySQL manages account authentication; application tables never store passwords.

### 12.3 Backup and recovery

Source control preserves schema and seed scripts, not live database state. Before major changes or submission, make a consistent logical backup of InnoDB data using an appropriate mysqldump invocation, including routines and triggers. Record the backup time, server version, and repository commit. Do not store credentials or contact-data backups in a public repository.

Restore to a separate empty test database, then verify row counts, procedure/trigger presence, role setup, and a sample hours report. MySQL user accounts/role grants require their own provisioning process and are not assumed to be included in an application schema dump. For the course, recovery means restoring a verified backup or rebuilding fictional initial data; production recovery objectives are outside scope.

## 13. Test Plan and Acceptance Criteria

### 13.1 Test data and execution

Use a Manager, two Event Coordinators, and a Staff Member with separate logins. Include verified/unverified volunteers; two events assigned to different coordinators; empty, full, overlapping, and back-to-back shifts; multiple skills; all five assignment statuses; completed but unapproved assignments; approved hours; and a volunteer with no hours. Use a reproducible fictional seed dataset and record each test's actual output, account, server version, and source commit.

The following are planned tests. No pass status is implied. Each test must leave known state or rebuild its fixture before rerunning.

| Test | Scenario | Expected result |
|---|---|---|
| T01 | Insert/view/update staff, events, volunteers, and shifts using entitled roles | Valid records persist; identifiers and references are correct |
| T02 | Duplicate PK/login/skill or nonexistent FK; invalid role/capacity/time/date/coordinator | Statement rejected; no invalid record committed |
| T03 | Duplicate volunteer/shift assignment | Second assignment rejected |
| T04 | Assign unverified volunteer, then verify and retry | First rejected; second accepted |
| T05 | Assign 12:00–15:00 then 14:00–17:00; retry with 15:00–17:00 | Overlap rejected; back-to-back accepted |
| T06 | Fill shift, attempt another assignment, cancel one, retry | Full shift rejected; cancellation releases capacity |
| T07 | Inconsistent status/times, check-in before shift start or after shift end, check-out on another day, reversed checkout | Invalid attendance rejected; valid sequence accepted |
| T08 | Scheduled → Cancelled → Scheduled; Completed → Cancelled; reactivate on full/overlapping shift | Valid transitions succeed; invalid transitions/reactivation rejected |
| T09 | Record only a check-in; then only a check-out; record both on a Scheduled row; request a contradictory status | Status becomes In-Progress, then Completed; both-at-once gives Completed; contradiction rejected; audit entries committed |
| T10 | Assigned coordinator approves completed 12:00–15:00 assignment | One 3.00-hour row and matching approver/timestamp; both audit changes captured |
| T11 | Wrong coordinator, incomplete assignment, duplicate approval, or very short rounded-zero duration | Clear exception; no partial approval or hours row |
| T12 | Attempt direct approval-field writes, direct VolunteerHours insert/update, and postapproval attendance edits | Operational accounts denied or validation rejects; original approval unchanged |
| T13 | Staff Member reads then attempts write; coordinator edits Event; Manager calls ApproveHours | Reads permitted only as matrix allows; forbidden actions rejected |
| T14 | Change background status and approve hours; inspect audit; try audit UPDATE/DELETE | Correct old/new actor/time values; mutation rejected; only Manager can view |
| T15 | Begin transaction, change volunteer, inspect inside session, then ROLLBACK | Data and same-transaction audit inserts absent after rollback |
| T16 | Session A changes a record inside uncommitted transaction; deployment operator uses KILL CONNECTION from session B; reconnect | InnoDB rolls back uncommitted data and audit changes; unrelated committed data remains |
| T17 | Two sessions contend for last capacity slot, then for same volunteer's overlapping shifts | At most one conflicting operation commits; no capacity/overlap violation |
| T18 | Two sessions approve same assignment; race assignment against capacity edit and approval against coordinator reassignment | One approval only; final state satisfies serialized rules; no partial state |
| T19 | Execute RQ-01–RQ-10 under permitted accounts | Results match section 11, including empty shifts, zero-hour volunteers, distinct event counts, and every attendance status |
| T20 | Clean checkout/build, then backup/restore into separate test database | Schema/data/routines/triggers restored; deployment roles provisioned; smoke tests pass |
| T21 | Reject assignment DELETE; reject invalid parent edits and coordinator-role change | Records and dependencies remain valid |
| T22 | Measure representative queries with EXPLAIN and larger fictional data | Record plans and elapsed times; justify indexes from evidence |
| T23 | Volunteer with multiple skills and volunteer with two approved shifts at same event | Skill search accurate; event counts person once and sums both shifts |
| T24 | Create an assignment with a status other than Scheduled, or with attendance times | Rejected (BR-34) |

For T16, issue KILL CONNECTION against the exact test session ID using a deployment account with appropriate authority. Do not use KILL QUERY alone as proof that the whole transaction was rolled back. Verification waits for rollback to finish. The operational roles do not receive session-management privileges.

### 13.2 Required demonstration coverage

| Assignment requirement | Evidence to capture |
|---|---|
| Transaction killed and rolled back | T16 before/after queries and test connection ID |
| Audit captures changes | T14 audit JSON and actor/time |
| Trigger makes an update | T09 incoming attendance row's status changed by trigger; confirm accepted interpretation |
| Constraint enforcement | T02, T03, T07 error and unchanged state |
| Joins, updates, subqueries, aggregates, exception handling | Roster join; attendance update; pending NOT EXISTS; hours aggregates; T11 procedure error |
| 3NF | Section 8 dependencies and schema comparison |
| Entitlements | T13 real-account permission attempts, including protected report sources |
| Performance | T17 contention results and T22 query plans/timings |

## 14. Requirement Traceability

### 14.1 Functional requirements

| Requirement | Design objects / sections | Tests |
|---|---|---|
| FR-01 | Event, coordinator validation; §§5–9 | T01, T02 |
| FR-02 | StaffMember and role maintenance; §§7,12 | T01, T02, T21 |
| FR-03 | Volunteer and audit; §§7,10 | T01, T04, T14 |
| FR-04 | Shift, Event FK, date/capacity/time validation | T01, T02, T21 |
| FR-05 | VolunteerShift, SaveAssignment, attendance trigger | T07–T09 |
| FR-06 | VolunteerHours assignment FK and reports | T10, T19 |
| FR-07 | Skill, VolunteerSkill, RQ-07 | T23 |
| FR-08 | VolunteerShift composite PK | T03 |
| FR-09 | Background activation check | T04 |
| FR-10 | Overlap triggers plus SaveAssignment serialization. | T05, T08, T17 |
| FR-11 | Capacity triggers plus SaveAssignment serialization. | T06, T08, T17 |
| FR-12 | ApproveHours completion validation | T10, T11 |
| FR-13 | Atomic hours insert and approval | T10, T11, T18 |
| FR-14 | Connected coordinator and Event ownership | T11, T18 |
| FR-15 | Role grants and controlled interfaces | T12, T13 |
| FR-16 | Four-table audit triggers and protected AuditLog | T14–T16 |
| FR-17 | VolunteerShift BEFORE UPDATE trigger sets status from times | T09 |
| FR-18 | SaveAssignment locks; Shift lock in triggers; READ COMMITTED | T17, T18 |
| FR-19 | Event, Shift, and StaffMember BEFORE UPDATE triggers | T21 |

All BR-01–BR-37 are mapped in section 9.1. Every RQ-01–RQ-10 is specified in section 11 and verified under T19 with additional RQ-07/RQ-06 fixtures in T23. Performance, architecture, and security requirements are addressed in sections 4, 10.6, and 12.
