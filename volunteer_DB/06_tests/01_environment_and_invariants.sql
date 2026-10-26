-- Read-only checks; run as deployment/admin or Manager (not Staff/Coordinator).
USE volunteer_db;
SELECT VERSION() AS ServerVersion, @@version_comment AS Distribution,
       @@session.sql_mode AS SqlMode, @@session.transaction_isolation AS IsolationLevel,
       @@session.time_zone AS SessionTimeZone, USER() AS ConnectedActor;
SHOW GRANTS;

-- Every Violations count below should be zero. Nonzero means FAIL, not an expected error.
SELECT 'capacity exceeded' AS Invariant, COUNT(*) AS Violations
FROM (SELECT s.ShiftID FROM Shift s JOIN VolunteerShift vs ON vs.ShiftID=s.ShiftID
      WHERE vs.Status <> 'Cancelled' GROUP BY s.ShiftID,s.Capacity
      HAVING COUNT(*) > s.Capacity) invalid;
SELECT 'overlapping assignments' AS Invariant, COUNT(*) AS Violations
FROM VolunteerShift a JOIN VolunteerShift b
  ON a.VolunteerID=b.VolunteerID AND a.ShiftID < b.ShiftID
JOIN Shift sa ON sa.ShiftID=a.ShiftID JOIN Shift sb ON sb.ShiftID=b.ShiftID
WHERE a.Status<>'Cancelled' AND b.Status<>'Cancelled'
  AND sa.StartDateTime < sb.EndDateTime AND sa.EndDateTime > sb.StartDateTime;
SELECT 'approved assignment without hours' AS Invariant, COUNT(*) AS Violations
FROM VolunteerShift vs LEFT JOIN VolunteerHours vh
 ON vh.VolunteerID=vs.VolunteerID AND vh.ShiftID=vs.ShiftID
WHERE vs.ApprovedAt IS NOT NULL AND vh.VolunteerID IS NULL;
SELECT 'hours without completed approved assignment' AS Invariant, COUNT(*) AS Violations
FROM VolunteerHours vh LEFT JOIN VolunteerShift vs
 ON vh.VolunteerID=vs.VolunteerID AND vh.ShiftID=vs.ShiftID
WHERE vs.VolunteerID IS NULL OR vs.Status <> 'Completed' OR vs.ApprovedAt IS NULL;
SELECT 'hours do not match attendance' AS Invariant, COUNT(*) AS Violations
FROM VolunteerHours vh JOIN VolunteerShift vs
 ON vh.VolunteerID=vs.VolunteerID AND vh.ShiftID=vs.ShiftID
WHERE vh.HoursWorked <> ROUND(TIMESTAMPDIFF(SECOND,vs.CheckInTime,vs.CheckOutTime)/3600.0,2);
SELECT 'approval flag inconsistent' AS Invariant, COUNT(*) AS Violations
FROM VolunteerShift WHERE NOT (HoursApproved <=> (ApprovedAt IS NOT NULL));
SELECT 'event coordinator has wrong role' AS Invariant, COUNT(*) AS Violations
FROM Event e JOIN StaffMember st ON st.StaffID=e.CoordinatorID
WHERE st.StaffRole <> 'Event Coordinator';
SELECT 'shift outside event date' AS Invariant, COUNT(*) AS Violations
FROM Shift s JOIN Event e ON e.EventID=s.EventID
WHERE DATE(s.StartDateTime)<>e.EventDate OR DATE(s.EndDateTime)<>e.EventDate;
