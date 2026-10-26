USE volunteer_db;

-- RQ-08: All three roles. Only currently unverified volunteers.
SELECT VolunteerID, VolunteerName, 'No' AS BackgroundCheckVerified
FROM Volunteer
WHERE BackgroundCheck = 0
ORDER BY VolunteerName, VolunteerID;
