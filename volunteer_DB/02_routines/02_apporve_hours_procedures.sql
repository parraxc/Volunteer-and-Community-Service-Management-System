DELIMITER $$

CREATE PROCEDURE ApproveHours (IN p_volunteerID INT, IN p_shiftID INT) 
SQL SECURITY DEFINER 
BEGIN 
    DECLARE staffID    INT;
    DECLARE staffRole   VARCHAR(20);
    DECLARE volunteerLocked   INT;
    DECLARE eventID    INT;
    DECLARE coordID    INT;
    DECLARE volunteerStatus      VARCHAR(12);
    DECLARE checkIn    DATETIME;
    DECLARE checkOut   DATETIME;
    DECLARE approvedAt DATETIME(6);
    DECLARE totalHours       DECIMAL(8,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION 
    BEGIN 
        ROLLBACK;
        RESIGNAL;
    END;
    
    SELECT StaffID, StaffRole INTO staffID, staffRole
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    IF staffID IS NULL OR staffRole <> 'Event Coordinator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Caller is not a registered Event Coordinator';
    END IF;


    START TRANSACTION;

    SELECT VolunteerID INTO volunteerLocked
    FROM Volunteer
    WHERE VolunteerID = p_VolunteerID
    FOR UPDATE;

    SELECT EventID INTO eventID
    FROM Shift
    WHERE ShiftID = p_shiftID
    FOR UPDATE;

    SELECT CoordinatorID INTO coordID
    FROM Event
    WHERE EventID = event_id
    FOR UPDATE;

    SELECT Status, CheckInTime, CheckOutTime, ApprovedAt
      INTO volunteerStatus, checkIn, checkOut, approvedAt
    FROM VolunteerShift
    WHERE VolunteerID = p_VolunteerID AND ShiftID = p_shiftID
    FOR UPDATE;

    IF volunteerStatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assignment not found';
    END IF;

     IF coord_id <> staffID THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only the event''s assigned Event Coordinator can approve these hours';
    END IF;

     IF volunteerStatus <> 'Completed' OR checkIn IS NULL OR checkOut IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only a Completed assignment can be approved';
    END IF;

    IF approvedAt IS NOT NULL
       OR EXISTS (SELECT 1 FROM VolunteerHours
                  WHERE VolunteerID = p_VolunteerID AND ShiftID = p_ShiftID) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Hours for this assignment are already approved';
    END IF;

    SET totalHours = ROUND(TIMESTAMPDIFF(SECOND, checkIN, checkOut) / 3600.0, 2);

    IF totalHours <= 0 THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Attendance is too short to record approved hours';
    END IF;

    UPDATE VolunteerShift
    SET ApprovedBy = staffID,
        ApprovedAt = UTC_TIMESTAMP(6)
    WHERE VolunteerID = p_VolunteerID AND ShiftID = p_ShiftID;

    INSERT INTO VolunteerHours (VolunteerID, ShiftID, HoursWorked)
    VALUES (p_VolunteerID, p_ShiftID, totalHours);

    COMMIT;

     SELECT p_VolunteerID AS VolunteerID,
            p_ShiftID     AS ShiftID,
            totalHours       AS HoursApproved;

END $$

DELIMITER ;
