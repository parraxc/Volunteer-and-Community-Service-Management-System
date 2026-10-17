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
| Role-Based Access | |
| Audit Logs |  |
| Operational reports and SQL queries | |

## Stakeholder and user roles   
| Stakeholder | Responsibilities | Database needs |
|---|---|---|
|Manager| Oversees events| View events, volunteers, and reports |
|Event Coordinator|Leads events|Add and update volunteer information, add and update shifts, record attendance, and approve volunteer hours|
|Staff Members|Works with volunteers|View shift and volunteer information|
|Volunteer| Volunteers at an event| Is represented in the database; does not directly use the database in the project |

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


## Data Requirements
| Data Subject | Information to Store | Example Identifies |
|---|---|---|
|Event|Event name, event date, event coordinator|EventID|
|Shift|Date/time,, role of the shift, shift capacity | ShiftID |
|Volunteer| Volunteer name, phone number, email, background-check verified (yes/no)| VolunteerID|
|StaffMember| Staff member name and role of the staff member | StaffID |
|VolunteerShift|Volunteer, shift, check-in and check-out time, status of shift(Scheduled, In-Progress, Completed, No-Show), approved by event coordinator|Composite VolunteerID/ShiftID|
|VolunteerHours | Volunteer, shift, hours worked per shift|Composite VolunteerID/ShiftID|
|Skill|Skill, description of skill|SkillCode|
|VolunteerSkill|Volunteer, skill|Composite VolunteerID/SkillCode|

## Business rules and Validation rules
| ID | Business Rule | Possible database enforcement |
|---|---|---|
|BR-01| Every event must have a unique Event ID. | Primary key on Event |
|BR-02| Each volunteer must have a unique Volunteer ID | Primary key on Volunteer  |
|BR-03| Each shift must be assigned to one event | NOT NULL foreign key from Shift to Event |
|BR-04| A volunteer can sign up for many shifts and a shift may have many volunteers | VolunteerShift junction table with foreign keys to Volunteer and Shift|
|BR-05| A volunteer cannot be assigned to the same shift more than once.| Composite primary key on VolunteerShift|
|BR-06| Only volunteers with a verified background check can work a shift | BEFORE INSERT trigger |
|BR-07| The number of volunteer assignments for a shift must not exceed that shift’s capacity|Transactional stored procedure|
|BR-08| Check-in and check-out time is only recorded for a volunteer who is signed for that shift |Composite primary key with foreign key |
|BR-09| A check-in time must occur after or on the shift's start time | Trigger procedure |
|BR-10| A VolunteerShift's status must be one of No-Show, Scheduled, or Completed | CHECK constraint |
|BR-11| VolunteerHours record is created only when the assignment is Completed and has been approved|A stored procedure that records the approval and inserts the hours in one transaction |
|BR-12| A volunteer's completed hours must be greater than zero | CHECK (HoursWorked > 0) |
|BR-13| A volunteer may have more than one skill, and a skill may have multiple volunteers | VolunteerSkills junction table|
|BR-14| A volunteer can’t be assigned to two overlapping shifts (back-to-back shifts are allowed)| BEFORE INSERT trigger on VolunteerShift|
|BR-15| An assignment’s status must agree with its recorded times: Scheduled and No-Show have none, In-Progress has check-in only, Completed has both.| Same-row CHECK on VolunteerShift |
|BR-16| Status must match the recorded times (Completed needs both times; In-Progress needs a check-in and no check-out)|Same-row CHECK constraint on VolunteerShift |
|BR-17| A check-out time must be later than the check-in time.| Same-row CHECK on VolunteerShift |
|BR-18| Only an assignment with status Scheduled may be deleted.| Only an assignment with status Scheduled may be deleted. |
|BR-19| Hours may be approved only for a Completed shift, and only by the Event Coordinator assigned to that shift’s event.| Stored procedure ApproveHours that validates both conditions, then records approved-by and approved-at|
|BR-20| When hours are approved, one VolunteerHours record is created for that assignment, with hours worked equal to check-out minus check-in.| Same stored procedure, in a single transaction with the approval|

## Reports and Queries

| ID | Report/query name | Purpose | Required result |
|---|---|---|---|
| RQ-01 | Volunteer Directory | Give staff an easy way to view and contact volunteers | Volunteer ID, name, phone number, email, and background-check status; sorted by volunteer name |
| RQ-02 | Shift Roster | Show which volunteers are signed up for a particular shift | Event name, Shift ID, shift role, Volunteer ID, volunteer name, and shift status |
| RQ-03 | Shift Capacity Report | Show which shifts have space and which are full | Shift ID, event name, role, capacity, number of volunteers signed up, and remaining spots |
| RQ-04 | Volunteer Hours Summary | Show the total number of hours completed by each individual volunteer | Volunteer ID, volunteer name, and total completed hours; can be filtered by date range |
| RQ-05 | Event Volunteer Hours Report | Help the staff summarize volunteer participation for a particular event | Event ID, event name, number of volunteers, and total volunteer hours |
| RQ-06 | Volunteer Skills Search | Help the staff find volunteers who have a skill that they may need | Volunteer ID, volunteer name, SkillCode, and skill description; filtered by skill |
| RQ-07 | Background Check Report | Show the volunteers who are not currently cleared to work a shift | Volunteer ID, volunteer name, and background-check status |
| RQ-08 | Attendance Report | Show attendance information for a selected event and/or shift | Volunteer name, event name, shift role, check-in time, check-out time, and status |

## Assumptions and Constraints
Assumptions:
- **Assumption:** Each shift belongs to one event.
- **Assumption:** An event can have multiple shifts.
- **Assumption:** A volunteer can participate in multiple different shifts.
- **Assumption:** Each volunteer has one current background check status.
- **Assumption:** Volunteer hours are only recorded after a shift is marked as Completed.
- **Assumption:** A volunteer can have multiple skills, and the same skill can belong to multiple volunteers.
- **Assumption:** Staff members are responsible for entering check-in and check-out times.
Constraints:
- **Constraint:** The project will use a relational database.
- **Constraint:** Volunteers will not directly access the database.
- **Constraint:** The project will use fictional or sample volunteer data for testing.
- **Constraint:** The system is not made to track the long-term results or impact of community service events.

## Acceptance Criteria

| Requirement | Acceptance criterion |
|---|---|
| FR-01 | Show that event records can be added, viewed, and updated with a unique EventID, event name, and event date. |
| FR-02 | Show that volunteer records can be added and viewed with name, contact information, and background-check status. |
| FR-03 | Show that shifts can be added and linked to a valid event with a role, capacity, start time, and end time. |
| FR-04 | Show that the total hours worked by a volunteer at an event can be stored and retrieved. |
| FR-05 | Show that multiple skills can be assigned to a volunteer and that volunteers can be searched by skill. |
| FR-06 | Try to sign up the same volunteer for the same shift twice and show that the second signup is rejected. |
| FR-07 | Try to sign up a volunteer without a completed background check and show that the signup is rejected. |
| RQ-03 | Run the shift capacity report and show the capacity, number of volunteers signed up, and remaining spots for each shift. |
| RQ-04 | Run the volunteer hours report and show the total completed hours for each volunteer. |
| RQ-05 | Run the event hours report and show the number of volunteers and total volunteer hours for a selected event. |
| RQ-06 | Run the volunteer skills search and show only volunteers who have the selected skill. |

