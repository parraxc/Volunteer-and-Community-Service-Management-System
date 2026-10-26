USE volunteer_db;

-- RQ-01: Volunteer Directory. All three operational roles.
SELECT VolunteerID, VolunteerName, VolunteerPhoneNumber, VolunteerEmail,
       CASE WHEN BackgroundCheck = 1 THEN 'Yes' ELSE 'No' END AS BackgroundCheckVerified
FROM Volunteer
ORDER BY VolunteerName, VolunteerID;
