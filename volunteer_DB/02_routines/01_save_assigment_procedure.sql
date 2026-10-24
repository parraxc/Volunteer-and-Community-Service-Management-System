DELIMITER $$

CREATE DEFINER = 'volunteer_proc'@'localhost' PROCEDURE SaveAssignment (
    IN p_VolunteerID  INT,
    IN p_ShiftID      INT,
    IN p_Status       VARCHAR(12),   
    IN p_CheckInTime  DATETIME,      
    IN p_CheckOutTime DATETIME       
)
SQL SECURITY DEFINER
BEGIN
    DECLARE staffID INT;
    DECLARE staffRole     VARCHAR(20);
    DECLARE volunteerID     INT;
    DECLARE shiftID    INT;
    DECLARE existing INT;
    DECLARE actiontaken   VARCHAR(10);

    DECLARE EXIT HANDLER FOR 1205, 1213
    BEGIN
        ROLLBACK;
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Lock conflict: nothing was saved, retry the whole operation';
    END;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT StaffID, StaffRole INTO staffId, staffRole
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    IF staffID IS NULL OR staffRole <> 'Event Coordinator' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Caller is not a registered Event Coordinator';
    END IF;

    IF p_Status IS NOT NULL
       AND p_Status NOT IN ('Scheduled', 'In-Progress', 'Completed', 'No-Show', 'Cancelled') THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Unknown assignment status';
    END IF;

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;

    SELECT VolunteerID INTO volunteerID
    FROM Volunteer
    WHERE VolunteerID = p_VolunteerID
    FOR UPDATE;

    IF volunteerID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Volunteer not found';
    END IF;

    SELECT ShiftID INTO shiftID
    FROM Shift
    WHERE ShiftID = p_ShiftID
    FOR UPDATE;

    IF shiftID IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Shift not found';
    END IF;

    SELECT VolunteerID INTO existing
    FROM VolunteerShift
    WHERE VolunteerID = p_VolunteerID AND ShiftID = p_ShiftID
    FOR UPDATE;

    
    IF existing IS NULL THEN 
        IF (p_Status IS NOT NULL AND p_Status <> 'Scheduled')
           OR p_CheckInTime IS NOT NULL OR p_CheckOutTime IS NOT NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'A new assignment must be Scheduled with no attendance times';
        END IF;

        INSERT INTO VolunteerShift (VolunteerID, ShiftID)
        VALUES (p_VolunteerID, p_ShiftID);

        SET actiontaken = 'ASSIGNED';
    ELSE
        IF p_Status IS NULL AND p_CheckInTime IS NULL AND p_CheckOutTime IS NULL THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assignment already exists (pass status Scheduled to reactivate a cancelled one)';
        END IF;

        UPDATE VolunteerShift
        SET Status       = COALESCE(p_Status, Status),
            CheckInTime  = COALESCE(p_CheckInTime, CheckInTime),
            CheckOutTime = COALESCE(p_CheckOutTime, CheckOutTime)
        WHERE VolunteerID = p_VolunteerID AND ShiftID = p_ShiftID;

        SET actiontaken = 'UPDATED';
    END IF;

    COMMIT;

    SELECT actiontaken AS Result, VolunteerID, ShiftID, Status, CheckInTime, CheckOutTime
    FROM VolunteerShift
    WHERE VolunteerID = p_VolunteerID AND ShiftID = p_ShiftID;
END $$

DELIMITER ;