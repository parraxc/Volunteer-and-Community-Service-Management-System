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
| Volunteer contact information | Moblie application development|
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

## Assumptions and Constraints

## Acceptance Criteria









