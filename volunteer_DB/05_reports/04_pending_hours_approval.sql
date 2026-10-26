USE volunteer_db;

-- RQ-04: Manager/coordinator. Set @report_coordinator_id to a StaffID.
-- This report filter does not authorize ApproveHours; that procedure checks USER().
SELECT e.EventID, e.EventName, e.CoordinatorID, s.ShiftID, s.ShiftRole,
       v.VolunteerID, v.VolunteerName, vs.CheckInTime, vs.CheckOutTime,
       ROUND(TIMESTAMPDIFF(SECOND, vs.CheckInTime, vs.CheckOutTime) / 3600.0, 2) AS CalculatedHours
FROM Event e
JOIN Shift s ON s.EventID = e.EventID
JOIN VolunteerShift vs ON vs.ShiftID = s.ShiftID
JOIN Volunteer v ON v.VolunteerID = vs.VolunteerID
WHERE e.CoordinatorID = @report_coordinator_id
  AND vs.Status = 'Completed' AND vs.ApprovedAt IS NULL
  AND NOT EXISTS (
      SELECT 1 FROM VolunteerHours vh
      WHERE vh.VolunteerID = vs.VolunteerID AND vh.ShiftID = vs.ShiftID
  )
ORDER BY e.EventDate, e.EventID, s.ShiftID, v.VolunteerID;
