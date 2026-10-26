# Reports (FRD v1.5)

These are read-only SQL queries, not definer views/routines. Existing table grants enforce access. Run each in a MySQL connection logged in as the intended role. They are deliberately excluded from the schema build. Unset MySQL user variables are NULL; initialize filters explicitly in reused connections.

```sql
USE volunteer_db;
SET @report_event_id = 1, @report_shift_id = NULL;
SOURCE volunteer_DB/05_reports/02_shift_roster.sql;
SET @report_event_id = NULL;
SOURCE volunteer_DB/05_reports/03_shift_capacity.sql;
SET @report_coordinator_id = 2;
SOURCE volunteer_DB/05_reports/04_pending_hours_approval.sql;
SET @report_start_date = '2026-10-01', @report_end_date = '2026-10-31';
SOURCE volunteer_DB/05_reports/05_volunteer_hours_summary.sql;
SET @report_skill_code = 3;
SOURCE volunteer_DB/05_reports/07_volunteer_skills_search.sql;
-- In a Manager connection only:
SET @report_table = 'Volunteer', @report_record_id = 'VolunteerID=6',
    @report_staff_id = NULL, @report_audit_start = NULL, @report_audit_end = NULL;
SOURCE volunteer_DB/05_reports/10_audit_log.sql;
```

Run SOURCE from the repository root. Report filenames match RQ-01 through RQ-10. NULL event/shift/date/audit filters mean all; coordinator and skill filters require an explicit ID. Empty or reversed date ranges return zero totals rather than hiding volunteers. Coordinator filtering is not a security boundary for approval.

| Report | Allowed operational roles | Expected on a fresh seed |
|---|---|---|
| 01 Directory | Manager, Coordinator, Staff | 10 volunteers, alphabetically |
| 02 Roster | Manager, Coordinator, Staff | Shift 2 has 3 rows; cancelled volunteer 8 excluded |
| 03 Capacity | Manager, Coordinator, Staff | Shift 10: 2 assigned, 0 left; shift 7: 0 assigned, 3 left |
| 04 Pending approval | Manager, Coordinator | Coordinator 2: 12 completed, unapproved assignments |
| 05 Volunteer totals | Manager, Coordinator | All 10 volunteers have 0 approved hours before approval calls |
| 06 Event totals | Manager, Coordinator | All events have 0 approved volunteers/hours before approval calls |
| 07 Skills | Manager, Coordinator, Staff | Skill 3: volunteers 2, 4, 10 |
| 08 Background | Manager, Coordinator, Staff | Volunteer 6 only |
| 09 Attendance | Manager, Coordinator, Staff | Shift 1 includes No-Show volunteer 3; shift 2 includes Cancelled volunteer 8 |
| 10 Audit | Manager only | Seed inserts/updates present; old values NULL on INSERT; newest first |

The automated suite checks the actual report files on isolated fixtures, including positive approved totals, date-range boundaries, zero-hour volunteers, empty shifts, and DISTINCT event counts. RQ-04 uses NOT EXISTS to demonstrate a subquery; approved timestamps and hours rows must remain consistent.
