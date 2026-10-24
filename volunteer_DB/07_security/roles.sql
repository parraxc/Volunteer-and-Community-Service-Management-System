GRANT SELECT                 ON volunteer_db.StaffMember    TO 'volunteer_proc'@'localhost';
GRANT SELECT, UPDATE         ON volunteer_db.Volunteer      TO 'volunteer_proc'@'localhost';
GRANT SELECT, UPDATE         ON volunteer_db.Shift          TO 'volunteer_proc'@'localhost';
GRANT SELECT, UPDATE         ON volunteer_db.Event          TO 'volunteer_proc'@'localhost';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.VolunteerShift TO 'volunteer_proc'@'localhost';
GRANT SELECT, INSERT         ON volunteer_db.VolunteerHours TO 'volunteer_proc'@'localhost';

CREATE ROLE IF NOT EXISTS 'manager_role', 'coordinator_role', 'staff_role';

GRANT SELECT, INSERT, UPDATE ON volunteer_db.StaffMember    TO 'manager_role';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.Event          TO 'manager_role';
GRANT SELECT ON volunteer_db.Shift          TO 'manager_role';
GRANT SELECT ON volunteer_db.Volunteer      TO 'manager_role';
GRANT SELECT ON volunteer_db.Skill          TO 'manager_role';
GRANT SELECT ON volunteer_db.VolunteerSkill TO 'manager_role';
GRANT SELECT ON volunteer_db.VolunteerShift TO 'manager_role';
GRANT SELECT ON volunteer_db.VolunteerHours TO 'manager_role';
GRANT SELECT ON volunteer_db.AuditLog       TO 'manager_role';

GRANT SELECT ON volunteer_db.Event          TO 'coordinator_role';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.Shift          TO 'coordinator_role';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.Volunteer      TO 'coordinator_role';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.Skill          TO 'coordinator_role';
GRANT SELECT, INSERT, UPDATE ON volunteer_db.VolunteerSkill TO 'coordinator_role';
GRANT SELECT ON volunteer_db.VolunteerShift TO 'coordinator_role';
GRANT SELECT ON volunteer_db.VolunteerHours TO 'coordinator_role';
GRANT EXECUTE ON PROCEDURE volunteer_db.SaveAssignment TO 'coordinator_role';
GRANT EXECUTE ON PROCEDURE volunteer_db.ApproveHours   TO 'coordinator_role';

GRANT SELECT ON volunteer_db.Event          TO 'staff_role';
GRANT SELECT ON volunteer_db.Shift          TO 'staff_role';
GRANT SELECT ON volunteer_db.Volunteer      TO 'staff_role';
GRANT SELECT ON volunteer_db.Skill          TO 'staff_role';
GRANT SELECT ON volunteer_db.VolunteerSkill TO 'staff_role';
GRANT SELECT ON volunteer_db.VolunteerShift TO 'staff_role';