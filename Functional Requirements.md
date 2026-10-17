## Project Identification 

| Item | Information |
|---|---|
| Project title | Volunteer and Community Service Management System|
| Prepared by | Christian Parra, Prabhas Penumatsa|
| Course | CS 437: Database Systems Implementation |
| Version| 1.1 |

## Business Problem and Project Purpose 
Nonprofit organizations need a centralized system for managing their volunteers and community service opportunities. Many organizations rely on tracking volunteers by simple spreadsheet tracking or on paper. Not only does this lead to inaccurate information, but it also makes reporting a volunteer's hours difficult and tedious. 

The purpose of this project is to create a relational database that allows organizations and their staff to maintain accurate volunteer information, sign up volunteers for volunteering shifts, track shift check-in and check-out, and record volunteer hours, look up volunteers by their skills, and produce reports for grant or impact reporting.

| In scope | Out of scope |
|---|---|
| Volunteer contact information | Mobile application development|
| Event and shift information | Outcome tracking |
| Volunteer registration and approval | Public website development |
| Attendance Recording |Online volunteer registration |
| Role-Based Access |Yearly-background checks|
| Audit Logs | Correction of approved hours |
| Operational reports and SQL queries | |

## Stakeholder and user roles   
| Stakeholder | Responsibilities | Database needs |
|---|---|---|
|Manager| Oversees events| Add and update events and staff members, assign Event Coordinators to events, view events, volunteers, and reports, and view the audit log|
|Event Coordinator|Leads events|Add and update volunteer information, add and update shifts, assign volunteers to shifts, record attendance, and approve volunteer hours for their events|
|Staff Members|Works with volunteers|View shift and volunteer information|
|Volunteer| Volunteers at an event| Is represented in the database; does not directly use the database in the project |

## Role permissions
V = view, A = add, U = update, X = execute. No role can delete records.
| Data | Manager | Event Coordinator | Staff Member |
|---|---|---|---|
| StaffMember | V, A, U | none | none |
| Event | V, A, U | V | V |
| Shift | V | V, A, U | V |
| Volunteer, VolunteerSkill, Skill | V | V, A, U | V |
| VolunteerShift | V | V, A, U | V |
| VolunteerHours | V | V (created only by ApproveHours) | none |
| ApproveHours procedure | none | X (own events only) | none |
| AuditLog | V | none | none |


## Functional requirements  
| ID | Functional requirement | Priority | Related data/entities |
|---|---|---|---|
|FR-01|The system shall store one record for each event, its name and the date of the event, and the assigned Event Coordinator |High| Event, StaffMember|
|FR-02|The system shall store one record for each staff member, including name and role.| High |StaffMember|
|FR-03| The system shall store one record for each volunteer, including name, contact information, and whether the volunteer’s background check is verified (yes/no). |High| Volunteer|
|FR-04|The system shall store one record for each shift, including its event, role, capacity, start date/time, and end date/time|High|Event, Shift|
|FR-05|The system shall store one record for one volunteer's assignment to and attendance for one shift, with a status, check-in time, and check-out time (VolunteerShift). |High|Shift, Volunteer, VolunteerShift|
|FR-06|The system shall store one record for the total hours from one approved shift. |High|VolunteerHours, VolunteerShift|
|FR-07|The system shall store a record for each of the volunteer's skills. |Low|Skill, VolunteerSkill|
|FR-08|The system shall prevent a volunteer from being assigned to the same shift more than once.|High| Volunteer, VolunteerShift|
|FR-09|The system shall prevent a volunteer who does not have a verified background check from being assigned a shift. | High |Volunteer, VolunteerShift|
|FR-10|The system shall prevent a volunteer from being assigned to overlapping shifts. | High |Shift, VolunteerShift|
|FR-11|The system shall prevent a volunteer from being assigned to a shift at full capacity. | High |Shift, VolunteerShift|
|FR-12|The system shall allow an Event Coordinator to approve a volunteer’s hours for a completed shift. | High |Event, StaffMember, VolunteerShift|
|FR-13|The system shall add a volunteer’s hours to VolunteerHours when an Event Coordinator approves the hours for a completed shift.| High |VolunteerHours, VolunteerShift|
|FR-14|The system shall only allow the Event Coordinator assigned to an event to approve the hours for that event's completed shift.| High |StaffMember, VolunteerShift|
|FR-15|The system shall limit each staff role to the data and actions permitted for that role.|High|StaffMember|
|FR-16|The system shall record an audit log entry whenever audited data is added or changed, including what changed, who changed it, and when.|High|AuditLog, StaffMember|


## Data Requirements
| Data Subject | Information to Store | Example Identifies |
|---|---|---|
|Event|Event name, event date, event coordinator|EventID|
|Shift|Date/time,, role of the shift, shift capacity | ShiftID |
|Volunteer| Volunteer name, phone number, email, background-check verified (yes/no)| VolunteerID|
|StaffMember| Staff member name and role of the staff member, database login name| StaffID |
|VolunteerShift|Volunteer, shift, check-in and check-out time, status of shift(Scheduled, In-Progress, Completed, No-Show), approved by event coordinator|Composite VolunteerID/ShiftID|
|VolunteerHours | Volunteer, shift, hours worked per shift|Composite VolunteerID/ShiftID|
|Skill|Skill, description of skill|SkillCode|
|VolunteerSkill|Volunteer, skill|Composite VolunteerID/SkillCode|
|AuditLog| Table changed, record identifier, action (Insert or Update), old values, new values, staff member who made the change, date/time of the change | AuditID |

## Business rules and Validation rules
| ID | Business Rule | Possible database enforcement |
|---|---|---|
|BR-01| Every event must have a unique Event ID. | Primary key on Event |
|BR-02| Each volunteer must have a unique Volunteer ID | Primary key on Volunteer |
|BR-03| Each shift must belong to exactly one event. | NOT NULL foreign key from Shift(EventID) to Event(EventID) |
|BR-04| Each event must have one assigned Event Coordinator. | NOT NULL foreign key from Event to StaffMember |
|BR-05| An event's assigned coordinator must be a staff member whose role is Event Coordinator. | BEFORE INSERT/UPDATE trigger on Event |
|BR-06| A staff member's role must be Manager, Event Coordinator, or Staff Member. | CHECK constraint on StaffMember |
|BR-07| A shift's capacity must be greater than zero, and its end must be later than its start. | Same-row CHECK constraints on Shift |
|BR-08| A shift must start and end on its event's date. | BEFORE INSERT/UPDATE trigger on Shift |
|BR-09| A volunteer can be assigned to many shifts, and a shift can have many volunteers. | VolunteerShift junction table with foreign keys to Volunteer and Shift |
|BR-10| A volunteer may be assigned to the same shift no more than once. | Composite primary key on VolunteerShift (VolunteerID, ShiftID) |
|BR-11| A volunteer may be assigned to a shift only if the volunteer's background check is verified. | BEFORE INSERT/UPDATE trigger on VolunteerShift |
|BR-12| The number of non-cancelled assignments for a shift must not exceed that shift's capacity. | BEFORE INSERT/UPDATE trigger that locks the Shift row (SELECT ... FOR UPDATE) before counting |
|BR-13| A volunteer may not have two non-cancelled assignments that overlap in time; back-to-back shifts are allowed. | BEFORE INSERT/UPDATE trigger: reject if new start < existing end AND new end > existing start |
|BR-14| Check-in and check-out times are recorded only for an existing assignment. | Columns of VolunteerShift (composite primary key and foreign keys); no separate attendance table |
|BR-15| An assignment's status must be Scheduled, In-Progress, Completed, No-Show, or Cancelled. | CHECK constraint on VolunteerShift |
|BR-16| An assignment's status must agree with its recorded times: Scheduled, No-Show, and Cancelled have none; In-Progress has check-in only; Completed has both. | Same-row CHECK constraint on VolunteerShift |
|BR-17| A check-in time must not be earlier than the shift's start time. | BEFORE INSERT/UPDATE trigger on VolunteerShift |
|BR-18| A check-out time must be later than the check-in time. | Same-row CHECK: CheckOutTime IS NULL OR CheckInTime IS NULL OR CheckOutTime > CheckInTime |
|BR-19| An assignment cannot be deleted; a withdrawing volunteer is marked Cancelled. | BEFORE DELETE trigger on VolunteerShift that rejects all deletes |
|BR-20| Only a Scheduled assignment may be changed to Cancelled, and a Cancelled assignment may return only to Scheduled. | BEFORE UPDATE trigger on VolunteerShift (returning to Scheduled re-runs BR-10, BR-11, and BR-12) |
|BR-21| Hours may be approved only for a Completed assignment, and only by the Event Coordinator assigned to that shift's event. | Stored procedure ApproveHours that validates both conditions, then records approved-by and approved-at |
|BR-22| When hours are approved, one VolunteerHours record is created for that assignment, with hours worked equal to check-out minus check-in. | Same stored procedure, in a single transaction with the approval; VolunteerHours is written no other way |
|BR-23| Hours worked in a VolunteerHours record must be greater than zero. | Same-row CHECK (HoursWorked > 0) on VolunteerHours |
|BR-24| Once an assignment's hours are approved, its status and check-in/check-out times cannot be changed. | BEFORE UPDATE trigger on VolunteerShift, rejects changes when approved-at is set |
|BR-25| A volunteer may have more than one skill, and a skill may belong to multiple volunteers. | VolunteerSkill junction table with composite primary key (VolunteerID, SkillCode) and foreign keys |
|BR-26| Each staff member must have a unique database login name. | UNIQUE NOT NULL column on StaffMember |
|BR-27| Each role may perform only the actions shown in the role permissions table. | MySQL roles with GRANT statements; EXECUTE on ApproveHours granted only to the Event Coordinator role |
|BR-28| The staff member who approves hours is identified by the logged-in database user, not by a value the caller supplies. | ApproveHours takes no staff parameter; it matches USER() to StaffMember |
|BR-29| Every insert or update to an audited table must create an audit log entry. | AFTER INSERT and AFTER UPDATE triggers on Volunteer, VolunteerShift, VolunteerHours, and Event |
|BR-30| Audit log entries cannot be changed or deleted. | No UPDATE or DELETE privilege for any role, plus BEFORE UPDATE and BEFORE DELETE triggers that reject changes |

## Reports and Queries

| ID | Report/query name | Purpose | Required result |
|---|---|---|---|
| RQ-01 | Volunteer Directory | Give staff an easy way to view and contact volunteers | Volunteer ID, name, phone number, email, and background check verified (yes/no); sorted by volunteer name |
| RQ-02 | Shift Roster | Show which volunteers are assigned to a particular shift | Filtered by Shift ID or Event ID. Event name, Shift ID, shift role, Volunteer ID, volunteer name, and assignment status. Includes all assignments except Cancelled |
| RQ-03 | Shift Capacity Report | Show which shifts have space and which are full | Shift ID, event name, role, capacity, number of assigned volunteers (all assignments except Cancelled), and remaining spots; includes shifts with no volunteers |
| RQ-04 | Pending Hours Approval Report | Show an Event Coordinator which completed shifts still need hours approved | Filtered by coordinator. Event name, shift role, Volunteer ID, volunteer name, check-in time, check-out time, and calculated hours, for Completed assignments with no approval |
| RQ-05 | Volunteer Hours Summary | Show the total approved hours worked by each individual volunteer | Volunteer ID, volunteer name, and total approved hours (sum of VolunteerHours); can be filtered by a date range on the event date; volunteers with no approved hours show 0 |
| RQ-06 | Event Volunteer Hours Report | Help the staff summarize volunteer participation for a particular event | Event ID, event name, number of volunteers with approved hours (COUNT DISTINCT VolunteerID), and total approved volunteer hours |
| RQ-07 | Volunteer Skills Search | Help the staff find volunteers who have a skill that they may need | Filtered by skill. Volunteer ID, volunteer name, SkillCode, and skill description |
| RQ-08 | Background Check Report | Show the volunteers who are not currently cleared to work a shift | Volunteer ID, volunteer name, and background check verified (volunteers where the value is No) |
| RQ-09 | Attendance Report | Show attendance information for a selected event and/or shift | Filtered by Event ID and/or Shift ID. Volunteer name, event name, shift role, check-in time, check-out time, and status (all statuses included) |
| RQ-10 | Audit Log Report | Let a Manager review who changed what | Filtered by table, record, staff member, and/or date range. Date/time, staff member, table, record identifier, action, old values, and new values; sorted newest first |

## Assumptions and Constraints
Assumptions:
- **Assumption:** Each shift belongs to one event.
- **Assumption:** An event can have multiple shifts.
- **Assumption:** An event occurs on a single calendar date. Multi-day activities are entered as separate events.
- **Assumption:** Each event has one assigned Event Coordinator.
- **Assumption:** Event Coordinators are responsible for entering check-in and check-out times.
- **Assumption:** A shift starts and ends on its event's date. Overnight shifts are not supported.
- **Assumption:** A volunteer can participate in multiple different shifts as long as the shifts do not overlap in time.
- **Assumption:** Each volunteer has one current background check status recorded as verified or not verified. Background checks do not expire in this system, and staff update the value manually.
- **Assumption:** A volunteer who withdraws from a shift before it starts is marked Cancelled by staff. A Cancelled assignment does not count toward shift capacity or overlap checks, and it can be reactivated.
- **Assumption:** Volunteer hours are recorded in VolunteerHours only after the assignment is Completed and the Event Coordinator assigned to the event has approved the hours. VolunteerHours is the record of approved hours, created from the attendance record by a stored procedure. The check-in and check-out times on VolunteerShift remain the source of the calculation.
- **Assumption:** A volunteer may leave before a shift ends. Hours worked are calculated from the actual check-in and check-out times.
- **Assumption:** Once hours are approved, the assignment's status and times cannot be changed. Correcting approved hours is outside the scope of this project.
- **Assumption:** A volunteer can have multiple skills, and the same skill can belong to multiple volunteers.
Constraints:
- **Constraint:** The project will use a relational database.
- **Constraint:** Rules that compare data across tables are enforced with triggers and stored procedures, because MySQL CHECK constraints cannot reference other tables.
- **Constraint:** Volunteers will not directly access the database.
- **Constraint:** The project will use fictional or sample volunteer data for testing.
- **Constraint:** The system is not made to track the long-term results or impact of community service events.

## Acceptance Criteria

## Acceptance Criteria

| Requirement | Acceptance criterion |
|---|---|
| FR-01 | Show that event records can be added, viewed, and updated with a unique EventID, event name, event date, and assigned Event Coordinator. |
| FR-02 | Show that staff member records can be added and viewed with a name and a role. |
| FR-03 | Show that volunteer records can be added and viewed with name, contact information, and background check verified (yes/no). |
| FR-04 | Show that shifts can be added and linked to a valid event with a role, capacity, start date/time, and end date/time. |
| FR-05 | Show that a volunteer can be assigned to a shift with the status Scheduled, and that check-in time, check-out time, and the status Completed can then be recorded for that assignment. |
| FR-06 | Show that approved hours for a shift can be stored in VolunteerHours and retrieved for a volunteer. |
| FR-07 | Show that multiple skills can be assigned to a volunteer and that volunteers can be searched by skill. |
| FR-08 | Try to assign the same volunteer to the same shift twice and show that the second assignment is rejected. |
| FR-09 | Try to assign a volunteer whose background check is not verified to a shift and show that the assignment is rejected. Then verify the volunteer and show that the assignment succeeds. |
| FR-10 | Assign a volunteer to a 12:00 to 15:00 shift, then try to assign the same volunteer to a 14:00 to 17:00 shift and show that it is rejected. Then assign the volunteer to a 15:00 to 17:00 shift and show that the back-to-back assignment is accepted. |
| FR-11 | Try to assign a volunteer to a shift that is already at capacity and show that the assignment is rejected. Cancel one assignment on that shift and show that a new volunteer can now be assigned. |
| FR-12 | Show that the assigned Event Coordinator can approve hours for a Completed assignment. Try to approve hours for an assignment that is not Completed and show that it is rejected. |
| FR-13 | Approve hours for an assignment with check-in at 12:00 and check-out at 15:00 and show that a VolunteerHours record with 3.00 hours is created. Show that no VolunteerHours record exists for an assignment that has not been approved. |
| FR-14 | Try to approve hours as an Event Coordinator who is not assigned to the event and show that the approval is rejected. |
| FR-15 | Log in as a Staff Member and show that data can be viewed but an insert or update is rejected. Log in as an Event Coordinator and show that an event cannot be edited. Log in as a Manager and show that hours cannot be approved.|
| FR-16 | Change a volunteer's background check from No to Yes and show an audit entry with the old and new values, the staff member, and the time. Approve hours and show entries for the VolunteerShift update and the new VolunteerHours record.|
| BR-05 | Try to assign a staff member whose role is not Event Coordinator as an event's coordinator and show that it is rejected. |
| BR-08 | Try to add a shift whose start or end falls outside its event's date and show that it is rejected. |
| BR-13| Show that a volunteer can be assigned to two non-overlapping shifts at the same event. |
| BR-16 | Try to mark an assignment Completed without a check-out time and show that it is rejected. |
| BR-17 | Try to record a check-in at 11:55 for a shift that starts at 12:00 and show that it is rejected. |
| BR-18 | Try to record a check-out earlier than the check-in time and show that it is rejected. |
| BR-19 | Try to delete an assignment and show that the delete is rejected. |
| BR-20 | Show that a Scheduled assignment can be changed to Cancelled, and that a Completed assignment cannot. Try to reactivate a Cancelled assignment on a shift that has since become full and show that it is rejected. |
| BR-24 | Try to change the check-out time or status of an assignment whose hours have been approved and show that the change is rejected. |
| BR-28 | Show that ApproveHours cannot be called on behalf of another coordinator, because it takes no staff parameter and uses the logged-in user. |
| BR-30 | Try to update and to delete an audit log entry and show that both are rejected. |
| RQ-01 | Run the volunteer directory and show each volunteer's ID, name, phone number, email, and background check status, sorted by name. |
| RQ-02 | Run the shift roster for a selected shift and show its assigned volunteers and their statuses, with Cancelled assignments excluded. |
| RQ-03 | Run the shift capacity report and show the capacity, number of assigned volunteers (excluding Cancelled), and remaining spots for each shift, including a shift with no volunteers. |
| RQ-04 | Run the volunteer hours summary and show the total approved hours for each volunteer, including a volunteer with 0 hours. Filter by an event date range and show that only hours from events in that range are totaled. |
| RQ-05 | Run the event hours report for an event where one volunteer worked two shifts and show that the volunteer is counted once and the hours from both shifts are summed. |
| RQ-06 | Run the volunteer skills search and show only volunteers who have the selected skill. |
| RQ-07 | Run the background check report and show only volunteers whose background check is not verified. |
| RQ-08 | Run the attendance report for an event and for a single shift and show check-in time, check-out time, and status, including a No-Show and a Cancelled assignment. |
| RQ-09 | Run the pending hours approval report for an Event Coordinator and show Completed assignments awaiting approval. Approve one and show that it no longer appears. |
| RQ-10 | Log in as a Manager, run the audit log report for one volunteer, and show the entries. Log in as an Event Coordinator and show that the report is not accessible. |
