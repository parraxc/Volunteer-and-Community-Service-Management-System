USE volunteer_db;

-- RQ-05: Manager/coordinator only. Inclusive EventDate bounds; NULL = unbounded.
-- Filter INSIDE the aggregate to retain volunteers with zero hours in the range.
SELECT v.VolunteerID, v.VolunteerName,
       COALESCE(h.TotalApprovedHours, 0.00) AS TotalApprovedHours
FROM Volunteer v
LEFT JOIN (
    SELECT vh.VolunteerID, SUM(vh.HoursWorked) AS TotalApprovedHours
    FROM VolunteerHours vh
    JOIN Shift s ON s.ShiftID = vh.ShiftID
    JOIN Event e ON e.EventID = s.EventID
    WHERE (@report_start_date IS NULL OR e.EventDate >= @report_start_date)
      AND (@report_end_date IS NULL OR e.EventDate <= @report_end_date)
    GROUP BY vh.VolunteerID
) h ON h.VolunteerID = v.VolunteerID
ORDER BY v.VolunteerName, v.VolunteerID;
