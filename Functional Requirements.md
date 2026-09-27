## Project Identification 

| Item | Information |
|---|---|
| Project title | Volunteer and Community Service Management System|
| Prepared by | Christian Parra, Prabhas Penumatsa|
| Course | CS 437: Database Systems Implementation |
| Verison| 1.0 |

## Business Problem and Project Purpose 
Nonprofit organizations need a centralized system for managing their volunteers and community service opportunities. 

The purpose of this project is to create a service where organizations can post their available volunteering shifts. It also manages volunteer registration and approval, and maintains volunteers' information and hours completed by tracking volunteers' attendance. Organizations will be able to maintain text communication between volunteers. As well, organizations will be able to generate a report of their events for grants or impact reporting. 

| In scope | Out of scope |
|---|---|
| Volunteer contact information | Moblie application development|
| Organizer information and event information | Outcome tracking |
| User registration and approval |  |
| Attendance Recording | |
| Role-Based Access | |
| Audit Logs |  |
| Operational reports and SQL queries | |

## Stakeholder and user roles   
| Stakeholder | Responsibilities | Database needs |
|---|---|---|
|Organization Manager| Oversees events and event organizers | View and create  events, add event organizers, and view event organizer information |
|Event Organizer|Leads an assigned event|Add volunteers and view volunteer information, record attendance, and view attendance information |
|Organization Staff|Leads an assigned event|Add volunteers and view volunteer information, record attendance, and view attendance information |
|Volunteer| Volunteers at an event| Is represented in the database; does not directly use the database in the project |

## Functional requirements  
| ID | Functional requirement | Priority | Related data/entites |
|---|---|---|---|
|FR-01|The system shall store one record for each event, its name and the date of the event |High| Event|
| FR-02 | The system shall store one record for each volunteer, including name and contact information, background-check status |High| Volunteer|
|FR-03|The system shall store one record for attendance; this includes the event date, the volunteer's ID, and the check-in and check-out times.|High|Event, Volunteer|
|FR-04|The system shall store a record for the volunteer's skills. |Low| Volunteer, Skills|
|FR-05|The system shall prevent the same volunteer from volunteering at the same event more than once|High| Attendance|
|FR-06|The system shall prevent a volunteer who does not have a verified background check from volunteering | High |Volunteer, Attendance|


## Data requirements
| Data Subject | Information to Store | Example Identifies |
|---|---|---|
|Event|Event name, Event Date|EventID|
|Event Shift|Start and end time of shift, role of the shift, shift capacity | ShiftID |
|Volunteer Shift|Volunteer, shift, check-in and check-out time, status of shift|Composite VolunteerID/ShiftID|
| Volunteer | Volunteer name, phone number, email, background-checkstatus | VolunteerID|
|Volunteer Hours | Volunteer, event, Hours worked from event|Composite VolunteerID/EventID|
|VolunteerSkills|Volunteer, Skills|Composite VolunteerID/SkillID|
|Skills|Skill, description of skill|SkillID|

## Business rules and validation rules

## Reports and Queries

## Assumptions and Constraints

## Acceptance Criteria









