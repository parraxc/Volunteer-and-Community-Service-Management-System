USE volunteer_db;

-- RQ-07: Set @report_skill_code. All three roles.
SELECT v.VolunteerID, v.VolunteerName, sk.SkillCode, sk.SkillName, sk.SkillDescription
FROM Skill sk
JOIN VolunteerSkill vk ON vk.SkillCode = sk.SkillCode
JOIN Volunteer v ON v.VolunteerID = vk.VolunteerID
WHERE sk.SkillCode = @report_skill_code
ORDER BY v.VolunteerName, v.VolunteerID;
