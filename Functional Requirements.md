## Project Identification 

| Item | Information |
|---|---|
| Project title | Volunteer and Community Service Management System|
| Prepared by | Christian Parra, Prabhas Penumatsa|
| Course | CS 437: Database Systems Implementation |
| Verison| 1.0 |

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
|Event Organizer|Leads events|Add and update volunteer information, record attendance, add and update shifts|
|Staff Members|Works with volunteers|View shift and volunteer information|
|Volunteer| Volunteers at an event| Is represented in the database; does not directly use the database in the project |

## Functional requirements  
| ID | Functional requirement | Priority | Related data/entites |
|---|---|---|---|
|FR-01|The system shall store one record for each event, its name and the date of the event |High| Event|
| FR-02 | The system shall store one record for each volunteer, including name and contact information, background-check status |High| Volunteer|
|FR-03|The system shall store one record for each shift, including its event, the shift's role, and capacity, its start time and end time.|High|Event, Volunteer|
|FR-04|The system shall store one record for the total hours worked at an event by a volunteer. |High|Event, Volunteer|
|FR-04|The system shall store a record for each skill of a volunteer. |Low| Volunteer, Skills|
|FR-05|The system shall prevent the same volunteer from volunteering at the same event more than once|High| Attendance|
|FR-06|The system shall prevent a volunteer who does not have a verified background check from volunteering | High |Volunteer, Attendance|


## Data Requirements
| Data Subject | Information to Store | Example Identifies |
|---|---|---|
|Event|Event name, Event Date|EventID|
|Shifts|Start and end time of shift, role of the shift, shift capacity | ShiftID |
|Volunteer Shift|Volunteer, shift, check-in and check-out time, status of shift|Composite VolunteerID/ShiftID|
|Volunteer | Volunteer name, phone number, email, background-checkstatus | VolunteerID|
|Volunteer Hours | Volunteer, event, Hours worked from event|Composite VolunteerID/EventID|
|VolunteerSkills|Volunteer, Skills|Composite VolunteerID/SkillCode|
|Skills|Skill, description of skill|SkillCode|

## Business rules and Validation rules
| ID | Business Rule | Possible database enforcement |
|---|---|---|
|BR-01| Every event must have a unique Event ID. | Primary key on Event |
|BR-02| Each volunteer must have a unique Volunteer ID | Primary key on Volunteer  |
|BR-03| Each shift must be assigned to one event | Foreign key from Shift to Event |
|BR-04| A volunteer can sign up for many shifts and a shift may have many volunteers | VolunteerShift junction table |
|BR-05| A volunteer may work in a specific shift no more than once| UNIQUE constraint on VolunteerShift (VolunteerID/ShiftID) |
|BR-06| Only volunteers with a completed background check can work in a shift | Controlled VolunteerShift procedure |
|BR-07| A VolunteerShift count for a shift may not exceed the shift capacity  |Query/procedure/trigger logic before logic |
|BR-08| Check-in and check-out time is only recorded for a volunteer who is signed for that shift | Foreign key to VolunteerShift|
|BR-09| A check-in time must occur after or on the shift's start time | CHECK constraint |
|BR-10| A VolunteerShift's status must be one of No-Show, In-Progress, or Completed | CHECK constraint |
|BR-11| A volunteer's completed hours are added to VolunteerHours only after the status is Completed |Controlled insert logic|
|BR-12| A volunteer's completed hours must be greater than zero | CHECK constraint |
|BR-13| A volunteer may have more than one skill, and a skill may have multiple volunteers | VolunteerSkills junction table|

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

