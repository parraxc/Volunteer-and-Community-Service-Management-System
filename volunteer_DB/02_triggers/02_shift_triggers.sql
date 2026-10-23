DELIMITER $$

CREATE TRIGGER Shift_before_insert
BEFORE INSERT ON Shift
FOR EACH ROW 
BEGIN 
    DECLARE event_date DATE;

    SELECT EventDate INTO event_date
    FROM Event
    WHERE EventID = NEW.EventID;

    IF DATE(NEW.StartDateTime) <> event_date  
    OR DATE(NEW.EndDateTime) <> event_date THEN
        SIGNAL SQLSTATE '45500'
        SET MESSAGE_TEXT = "Insert shift's date,
        does not match event's date ";
    END IF;
END $$

CREATE TRIGGER Shift_before_update
BEFORE UPDATE ON Shift
FOR EACH ROW 
BEGIN 
    DECLARE event_date DATE;
    DECLARE has_assigments INT DEFAULT(0);

    SELECT EventDate INTO event_date
    FROM Event
    WHERE EventID = NEW.EventID;

    SELECT COUNT(*) INTO has_assigments
    FROM VolunteerShift
    WHERE ShiftID = OLD.ShiftID;

    IF ((NEW.StartDateTime <> OLD.StartDateTime) 
        OR (NEW.EndDateTime <> OLD.EndDateTime)
        OR (NEW.EventID <> OLD.EventID))
    AND (DATE(NEW.StartDateTime) <> event_date  
        OR DATE(NEW.EndDateTime <> event_date)) THEN
            SIGNAL SQLSTATE '45500'
            SET MESSAGE_TEXT = "Shift must start and end on its event date";
    END IF;

    IF (has_assigments > 0) 
       AND (NOT (NEW.StartDateTime <=> OLD.StartDateTime)
         OR NOT (NEW.EndDateTime   <=> OLD.EndDateTime)
         OR NOT (NEW.Capacity      <=> OLD.Capacity)
         OR NOT (NEW.EventID       <=> OLD.EventID)) THEN 
            SIGNAL SQLSTATE '45500'
            SET MESSAGE_TEXT = "Shift times, capacity, 
            and event cannot change once volunteers are assigned"
    END IF;

END $$

DELIMITER ;

