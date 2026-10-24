DELIMITER $$

CREATE TRIGGER Event_before_insert
BEFORE INSERT ON Event
FOR EACH ROW 
BEGIN
    DECLARE is_coord INT DEFAULT(0);

    SELECT COUNT(*) INTO is_coord
    FROM StaffMember
    WHERE StaffID = NEW.CoordinatorID
        AND StaffRole = 'Event Coordinator';

    IF (is_coord = 0) THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = "Assigned staff member is not a event coordinator";
    END IF;

END $$

CREATE TRIGGER Event_before_update
BEFORE UPDATE ON Event
FOR EACH ROW
BEGIN
    DECLARE is_coord INT DEFAULT 0;
    DECLARE has_shift INT DEFAULT 0;

    SELECT COUNT(*) INTO is_coord
    FROM StaffMember
    WHERE StaffID = NEW.CoordinatorID
      AND StaffRole = 'Event Coordinator';

    SELECT COUNT(*) INTO has_shift
    FROM Shift
    WHERE EventID = OLD.EventID;

    IF (is_coord = 0) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Assigned staff member is not an Event Coordinator';
    END IF;

    IF NOT (NEW.EventDate <=> OLD.EventDate) AND has_shift > 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Event date cannot be changed once the event has shifts';
    END IF;
END $$

DELIMITER ;

    
    