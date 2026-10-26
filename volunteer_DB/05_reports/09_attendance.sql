USE volunteer_db;

-- RQ-09: NULL filters = all events/shifts. Include EVERY assignment status.
SELECT e.EventID, e.EventName, s.ShiftID, s.ShiftRole,
       v.VolunteerID, v.VolunteerName, vs.CheckInTime, vs.CheckOutTime, vs.Status
FROM Event e
JOIN Shift s ON s.EventID = e.EventID
JOIN VolunteerShift vs ON vs.ShiftID = s.ShiftID
JOIN Volunteer v ON v.VolunteerID = vs.VolunteerID
WHERE (@report_event_id IS NULL OR e.EventID = @report_event_id)
  AND (@report_shift_id IS NULL OR s.ShiftID = @report_shift_id)
ORDER BY e.EventDate, e.EventID, s.ShiftID, v.VolunteerName, v.VolunteerID;
