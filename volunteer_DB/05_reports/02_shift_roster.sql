USE volunteer_db;

-- RQ-02: NULL @report_shift_id / @report_event_id means no filter.
SELECT e.EventID, e.EventName, s.ShiftID, s.ShiftRole,
       v.VolunteerID, v.VolunteerName, vs.Status
FROM Event e
JOIN Shift s ON s.EventID = e.EventID
JOIN VolunteerShift vs ON vs.ShiftID = s.ShiftID
JOIN Volunteer v ON v.VolunteerID = vs.VolunteerID
WHERE vs.Status <> 'Cancelled'
  AND (@report_shift_id IS NULL OR s.ShiftID = @report_shift_id)
  AND (@report_event_id IS NULL OR e.EventID = @report_event_id)
ORDER BY e.EventDate, e.EventID, s.StartDateTime, s.ShiftID, v.VolunteerName, v.VolunteerID;
