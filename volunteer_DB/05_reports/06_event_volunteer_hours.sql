USE volunteer_db;

-- RQ-06: Manager/coordinator only. NULL @report_event_id = all events.
-- Hours have one row per assignment: COUNT DISTINCT counts a person only once.
SELECT e.EventID, e.EventName,
       COUNT(DISTINCT vh.VolunteerID) AS VolunteersWithApprovedHours,
       COALESCE(SUM(vh.HoursWorked), 0.00) AS TotalApprovedHours
FROM Event e
LEFT JOIN Shift s ON s.EventID = e.EventID
LEFT JOIN VolunteerHours vh ON vh.ShiftID = s.ShiftID
WHERE (@report_event_id IS NULL OR e.EventID = @report_event_id)
GROUP BY e.EventID, e.EventName
ORDER BY e.EventID;
