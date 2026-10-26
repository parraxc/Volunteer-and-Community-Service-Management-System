-- FR-19 / BR-33: do not invalidate an event's coordinator by editing the staff role.
DELIMITER $$
CREATE TRIGGER staffmember_before_update
BEFORE UPDATE ON StaffMember
FOR EACH ROW
BEGIN
    IF OLD.StaffRole = 'Event Coordinator'
       AND NEW.StaffRole <> 'Event Coordinator'
       AND EXISTS (SELECT 1 FROM Event e WHERE e.CoordinatorID = OLD.StaffID) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Cannot change role while staff member coordinates an event';
    END IF;
END $$
DELIMITER ;
