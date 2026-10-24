
INSERT INTO StaffMember (StaffID, StaffName, StaffRole, DbUsername) VALUES
    (1,'Smith Pill', 'Manager', 'mgr_test'),
    (2,'Wanda Maximoff', 'Event Coordinator', 'coord_test1'),
    (3,'Maria Zardoya', 'Event Coordinator', 'coord_test2'),
    (4,'Josh Conway', 'Staff Member', 'staff_test');

INSERT INTO Event (EventID, EventName, EventDate, CoordinatorID) VALUES
    (1,'Food Pantry Restock', '2026-10-03', '2'),
    (2,'Soup Kitchen Work', '2026-10-4', '2'),
    (3,'Halloween at Recitation Center', '2026-10-31', '3'),
    (4,'Christimas Giveaway', '2026-12-25', '3');


INSERT INTO Shift (ShiftID, EventID, ShiftRole, Capacity, StartDateTime, EndDateTime) VALUES
    (1, 1, 'Delivery Driver', 3, '2026-10-03 08:00:00', '2026-10-03 11:00:00'),
    (2, 1, 'Food Sorting',    4, '2026-10-03 11:00:00', '2026-10-03 14:00:00'),
    (3, 1, 'Clean-Up',        3, '2026-10-03 13:00:00', '2026-10-03 16:00:00'),

    (4, 2, 'Cooking',  3, '2026-10-04 08:00:00', '2026-10-04 11:00:00'),
    (5, 2, 'Cooking',  4, '2026-10-04 11:00:00', '2026-10-04 14:00:00'),
    (6, 2, 'Clean-Up', 3, '2026-10-04 13:00:00', '2026-10-04 16:00:00'),

     (7, 3, 'Greeter',         3, '2026-10-31 12:00:00', '2026-10-31 15:00:00'),
     (8, 3, 'Coustme Characters',          3, '2026-10-31 14:00:00', '2026-10-31 17:00:00'),
     (9, 3, 'Giveaways',         3, '2026-10-31 15:00:00', '2026-10-31 17:00:00'),
     (10, 3, 'Floaters',   2, '2026-10-31 09:00:00', '2026-10-31 12:00:00'),
     (11, 3, 'Parking Helper', 4, '2026-10-31 08:00:00', '2026-10-31 10:00:00');


INSERT INTO Volunteer (VolunteerID, VolunteerName, VolunteerPhoneNumber, VolunteerEmail, BackgroundCheck) VALUES
    (1,  'Jean Day',   '555-0101',  'jean.day@example.org',  TRUE),
    (2,  'Jillian Smith',     '555-0102',  'jillian.smith@example.org',    TRUE),
    (3,  'Alberto Sosa',   '555-0103',  'alberto.sosa@example.org',  TRUE),
    (4,  'Allison Mendoza',      '555-0104',  'allison.mendoza@example.org',     TRUE),
    (5,  'Frank Damico',    '555-0105',  'frank.damico@example.org',   TRUE),
    (6,  'Rob Muffuletto',      '555-0106',  'rob.muffuletto@example.org',     FALSE),
    (7,  'Leah Hughes',      '+1 555-0107','leah.hughess@example.org',    TRUE),
    (8,  'Eli Munze', '555-0108',  'Eli.munze@example.org',TRUE),
    (9,  'Peter Parker',    '555-0109',  'peter.parker.org',   TRUE),
    (10, 'Jay Walker',   '555-0110',  'jay.walker@example.org',  TRUE);

 
INSERT INTO Skill (SkillCode, SkillName, SkillDescription) VALUES
 (1, 'First Aid',  'Certified in basic first aid and CPR'),
 (2, 'Spanish',    'Conversational or fluent Spanish'),
 (3, 'Driving',    'Valid license; can transport supplies'),
 (4, 'Cooking',    'Food handling and meal preparation'),
 (5, 'Gardening',  'Planting, weeding, and general grounds work');

 INSERT INTO VolunteerSkill (VolunteerID, SkillCode) VALUES
 (1,1),(1,2),(2,3),(3,4),(4,5),(4,3),(5,2),(6,4),(7,1),(9,5),(9,4),(10,3);

INSERT INTO VolunteerShift (VolunteerID, ShiftID) VALUES
 (1,1),(2,1),(3,1),                 -- shift 1
 (1,2),(4,2),(5,2),(8,2),           -- shift 2 (3 active + 1 to be cancelled)
 (2,3),(7,3),                       -- shift 3
 (9,4),(10,4),                      -- shift 4 (full)
 (9,5),(4,5),                       -- shift 5
 (10,6),(8,6),                      -- shift 6
 (1,9),(2,9),                       -- shift 9 (future, 2 of 3)
 (5,10),(7,10);                     -- shift 10 (future, full)

UPDATE VolunteerShift SET CheckInTime='2026-10-03 08:00:00', CheckOutTime='2026-10-03 11:00:00' WHERE VolunteerID=1 AND ShiftID=1;
UPDATE VolunteerShift SET CheckInTime='2026-10-03 08:05:00', CheckOutTime='2026-10-03 11:00:00' WHERE VolunteerID=2 AND ShiftID=1;
UPDATE VolunteerShift SET CheckInTime='2026-10-03 11:00:00', CheckOutTime='2026-10-03 14:00:00' WHERE VolunteerID=1 AND ShiftID=2;
UPDATE VolunteerShift SET CheckInTime='2026-10-03 11:00:00', CheckOutTime='2026-10-03 14:00:00' WHERE VolunteerID=4 AND ShiftID=2;
UPDATE VolunteerShift SET CheckInTime='2026-10-03 13:00:00', CheckOutTime='2026-10-03 16:00:00' WHERE VolunteerID=2 AND ShiftID=3;
UPDATE VolunteerShift SET CheckInTime='2026-10-03 13:05:00', CheckOutTime='2026-10-03 16:00:00' WHERE VolunteerID=7 AND ShiftID=3;
UPDATE VolunteerShift SET CheckInTime='2026-10-04 09:00:00', CheckOutTime='2026-10-04 12:00:00' WHERE VolunteerID=9 AND ShiftID=4;
UPDATE VolunteerShift SET CheckInTime='2026-10-04 09:10:00', CheckOutTime='2026-10-04 12:00:00' WHERE VolunteerID=10 AND ShiftID=4;
UPDATE VolunteerShift SET CheckInTime='2026-10-04 12:00:00', CheckOutTime='2026-10-04 15:00:00' WHERE VolunteerID=9 AND ShiftID=5;
UPDATE VolunteerShift SET CheckInTime='2026-10-04 12:00:00', CheckOutTime='2026-10-04 14:30:00' WHERE VolunteerID=4 AND ShiftID=5;   -- left early
UPDATE VolunteerShift SET CheckInTime='2026-10-04 15:00:00', CheckOutTime='2026-10-04 17:00:00' WHERE VolunteerID=10 AND ShiftID=6;
UPDATE VolunteerShift SET CheckInTime='2026-10-04 15:00:00', CheckOutTime='2026-10-04 15:00:10' WHERE VolunteerID=8 AND ShiftID=6;

UPDATE VolunteerShift SET CheckInTime='2026-10-03 11:10:00' WHERE VolunteerID=5 AND ShiftID=2;

UPDATE VolunteerShift SET Status='No-Show'   WHERE VolunteerID=3 AND ShiftID=1;
UPDATE VolunteerShift SET Status='Cancelled' WHERE VolunteerID=8 AND ShiftID=2;