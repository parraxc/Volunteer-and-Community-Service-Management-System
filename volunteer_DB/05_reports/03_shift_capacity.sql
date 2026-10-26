USE volunteer_db;

-- RQ-03: Include empty shifts; cancelled assignments consume no capacity.
SELECT s.ShiftID, e.EventID, e.EventName, s.ShiftRole, s.Capacity,
       COUNT(vs.VolunteerID) AS AssignedVolunteers,
       s.Capacity - COUNT(vs.VolunteerID) AS RemainingSpots
FROM Shift s
JOIN Event e ON e.EventID = s.EventID
LEFT JOIN VolunteerShift vs ON vs.ShiftID = s.ShiftID AND vs.Status <> 'Cancelled'
WHERE (@report_event_id IS NULL OR e.EventID = @report_event_id)
GROUP BY s.ShiftID, e.EventID, e.EventName, s.ShiftRole, s.Capacity
ORDER BY e.EventID, s.ShiftID;
