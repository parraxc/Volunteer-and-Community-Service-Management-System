DELIMITER $$

CREATE DEFINER = 'volunteer_proc'@'localhost' PROCEDURE ApproveHours (IN p_volunteerID INT, IN p_shiftID INT)
SQL SECURITY DEFINER
BEGIN
    DECLARE v_staff_id INT;
    DECLARE v_staff_role VARCHAR(20);
    DECLARE volunteerLocked   INT;
    DECLARE v_event_id INT;
    DECLARE v_coord_id INT;
    DECLARE volunteerStatus      VARCHAR(12);
    DECLARE checkIn    DATETIME;
    DECLARE checkOut   DATETIME;
    DECLARE v_approved_at DATETIME(6);
    DECLARE totalHours       DECIMAL(8,2);

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    SELECT StaffID, StaffRole INTO v_staff_id, v_staff_role
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    IF v_staff_id IS NULL OR v_staff_role <> 'Event Coordinator' THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Caller is not a registered Event Coordinator';
    END IF;

    SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
    START TRANSACTION;

    SELECT VolunteerID INTO volunteerLocked
    FROM Volunteer
    WHERE VolunteerID = p_VolunteerID
    FOR UPDATE;

    SELECT EventID INTO v_event_id
    FROM Shift
    WHERE ShiftID = p_shiftID
    FOR UPDATE;

    SELECT CoordinatorID INTO v_coord_id
    FROM Event
    WHERE EventID = v_event_id
    FOR UPDATE;

    SELECT Status, CheckInTime, CheckOutTime, ApprovedAt
      INTO volunteerStatus, checkIn, checkOut, v_approved_at
    FROM VolunteerShift
    WHERE VolunteerID = p_VolunteerID AND ShiftID = p_shiftID
    FOR UPDATE;

    IF volunteerStatus IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assignment not found';
    END IF;

     IF v_coord_id IS NULL OR v_coord_id <> v_staff_id THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only the event''s assigned Event Coordinator can approve these hours';
    END IF;

     IF volunteerStatus <> 'Completed' OR checkIn IS NULL OR checkOut IS NULL THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Only a Completed assignment can be approved';
    END IF;

    IF v_approved_at IS NOT NULL
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
    SET HoursApproved = TRUE,
        ApprovedBy = v_staff_id,
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
