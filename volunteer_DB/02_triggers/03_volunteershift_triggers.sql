DELIMITER $$

CREATE TRIGGER volunteershift_before_insert
BEFORE INSERT ON VolunteerShift
FOR EACH ROW 

    DECLARE is_verf BOOLEAN;
    DECLARE cap INT;
    DECLARE startTime DATETIME;
    DECLARE endTime DATETIME;
    DECLARE currentassignments INT DEFAULT 0;
    DECLARE overlapping INT DEFAULT 0;

    IF NEW.Status <> 'Scheduled' THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'New assignments must have status Scheduled';
    END IF;

    SELECT BackgroundCheck INTO is_verf
    FROM Volunteer
    WHERE VolunteerID = NEW.VolunteerID;

     IF (is_verf IS NOT TRUE) THEN
        SIGNAL SQLSTATE '45500'
        SET MESSAGE_TEXT = "Volunteer's background check is false"
    END IF;

    SELECT Capacity,StartDateTime,EndDateTime 
        INTO cap,startTime,endTime
    FROM Shift
    WHERE ShiftID = NEW.ShiftID
    FOR UPDATE;

    SELECT COUNT(*) INTO currentassignments
    FROM VolunteerShift
    WHERE ShiftID = NEW.ShifID
    AND Stauts <> 'Cancelled'
    FOR UPDATE;

    IF currentassignments >= cap THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Shift is at capacity';
    END IF;

    SELECT COUNT(*) INTO overlapping
    FROM Shift s 
    INNER JOIN VolunteerShift vs ON vs.ShifID = s.ShiftID
    WHERE s.VolunteerID = NEW.VolunteerID
        AND vs.status <> 'Cancelled'
        AND s.StartDateTime < endTime
        AND s.EndDateTime > startTime;

    IF (overlapping > 0) THEN 
        SIGNAL SQLSTATE '45500'
        SET MESSAGE_TEXT = "Shift overlaps with another shift."
    END IF;

END $$

CREATE TRIGGER voluntershift_before_update
BEFORE UPDATE ON VolunteerShift 
FOR EACH ROW
    DECLARE is_verf BOOLEAN;
    DECLARE cap INT;
    DECLARE startTime DATETIME;
    DECLARE endTime DATETIME;
    DECLARE eventDate DATE;
    DECLARE currentassignments INT DEFAULT 0;
    DECLARE overlapping INT DEFAULT 0;

    IF (OLD.Approved ATIS NOT NULL) THEN 
        SIGNAL SQLSTATE '45500'
        SET MESSAGE_TEXT = "Can't change volunteershift after hours are approved."
    END IF;

    IF (OLD.VolunterID <> NEW.VolunteerID OR OLD.ShiftID <> NEW.ShiftID)
        SIGNAL SQLSTATE '45500'
        SET MESSAGE_TEXT = "Can't change volunteer/shift fields after insertion."
    END IF;

    IF NEW.Status <> OLD.Status
       AND NOT (   (OLD.Status = 'Scheduled'   AND NEW.Status IN ('In-Progress', 'No-Show', 'Cancelled'))
                OR (OLD.Status = 'In-Progress' AND NEW.Status = 'Completed')
                OR (OLD.Status = 'Cancelled'   AND NEW.Status = 'Scheduled')) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'BR-19: invalid status change';
    END IF;

    SELECT s.StartDateTime, s.EndDateTime, e.EventDate
    INTO startTime, endTime, EventDate
    FROM Shift s
    INNER JOIN Event e ON e.EventID = s.EventID
    WHERE s.ShiftID = NEW.ShiftID;
    
    IF NEW.CheckInTime IS NOT NULL AND NOT (NEW.CheckInTime <=> OLD.CheckInTime)
       AND (NEW.CheckInTime < startTime OR NEW.CheckInTime >= endTime) THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Check-in must be within the shift';
    END IF;

    IF NEW.CheckOutTime IS NOT NULL AND NOT (NEW.CheckOutTime <=> OLD.CheckOutTime)
       AND DATE(NEW.CheckOutTime) <> eventDate THEN
            SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Check-out must be on the event date';
    END IF;

    IF OLD.Status = 'Cancelled' AND NEW.Status = 'Scheduled' THEN
        SELECT BackgroundCheck INTO is_verf
        FROM Volunteer
        WHERE VolunteerID = NEW.VolunteerID;

        IF (is_verf IS NOT TRUE) THEN
            SIGNAL SQLSTATE '45500'
            SET MESSAGE_TEXT = "Volunteer's background check is false"
        END IF;

        SELECT Capacity,StartDateTime,EndDateTime 
            INTO cap,startTime,endTime
        FROM Shift
        WHERE ShiftID = NEW.ShiftID
        FOR UPDATE;

        SELECT COUNT(*) INTO currentassignments
        FROM VolunteerShift
        WHERE ShiftID = NEW.ShifID
        AND Stauts <> 'Cancelled'
        FOR UPDATE;

        IF currentassignments >= cap THEN
            SIGNAL SQLSTATE '45000'
                SET MESSAGE_TEXT = 'Shift is at capacity';
        END IF;

        SELECT COUNT(*) INTO overlapping
        FROM Shift s 
        INNER JOIN VolunteerShift vs ON vs.ShifID = s.ShiftID
        WHERE s.VolunteerID = NEW.VolunteerID
            AND vs.status <> 'Cancelled'
            AND s.StartDateTime < endTime
            AND s.EndDateTime > startTime;

        IF (overlapping > 0) THEN 
            SIGNAL SQLSTATE '45500'
            SET MESSAGE_TEXT = "Shift overlaps with another shift."
        END IF;
    END IF;

END $$


CREATE volunteershift_before_delete
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Deletion from the voluneershift is strictly prohibited.';
END  $$
