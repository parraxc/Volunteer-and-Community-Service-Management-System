DELIMITER $$

CREATE prevent_auditlog_delete
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Deletion from the audit log is strictly prohibited.';
END  $$

CREATE prevent_auditlog_update
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Directly updating the audit log is strictly prohibited.';
END  $$

CREATE TRIGGER event_after_insert_audit
AFTER INSERT ON Event
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, NewValues, ChangedBy)
    VALUES (
        'Event',
        'INSERT',
        NEW.EventID,
        JSON_OBJECT(
            'EventName',  NEW.EventName,
            'EventDate', NEW.EventDate,
            'CoordinatorID', NEW.CoordinatorID
        ),
        USER(),
    );
END $$

CREATE TRIGGER event_after_update_audit
AFTER UPDATE ON Event
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, OldValues, NewValues, ChangedBy)
    VALUES (
        'Event',
        'UPDATE',
        NEW.EventID,
        JSON_OBJECT('EventName', OLD.EventName, 'EventDate', OLD.EventDate, 'CoordinatorID', OLD.CoordinatorID),
        JSON_OBJECT('EventName', NEW.EventName, 'EventDate', NEW.EventDate, 'CoordinatorID', NEW.CoordinatorID),
        USER(),
    );
END $$


CREATE TRIGGER volunteer_after_insert_audit
AFTER INSERT ON Volunteer
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, NewValues, ChangedBy)
    VALUES (
        'Volunteer',
        'INSERT',
        NEW.VolunteerID,
        JSON_OBJECT(
            'VolunteerName',  NEW.VolunteerName,
            'VolunteerPhoneNumber', NEW.VolunteerPhoneNumber,
            'VolunteerEmail', NEW.VolunteerEmail
            'BackgroundCheck', NEW.BackgroundCheck
        ),
        USER(),
    );
END $$

CREATE TRIGGER volunteer_after_update_audit
AFTER UPDATE ON Volunteer
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, OldValues, NewValues, ChangedBy)
    VALUES (
        'Event',
        'UPDATE',
        NEW.EventID
        JSON_OBJECT('VolunteerName', OLD.VolunteerName, 'VolunteerPhoneNumber', OLD.VolunteerPhoneNumber, 'VolunteerEmail', OLD.VolunteerEmail, 'BackgroundCheck', OLD.BackgroundCheck),
        JSON_OBJECT('VolunteerName', NEW.VolunteerName, 'VolunteerPhoneNumber', NEW.VolunteerPhoneNumber, 'VolunteerEmail', NEW.VolunteerEmail, 'BackgroundCheck', NEW.BackgroundCheck),
        USER(),
    );
END $$

CREATE TRIGGER volunteersSift_after_insert_audit
AFTER INSERT ON VolunteerShift
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, NewValues, ChangedBy)
    VALUES (
        'VolunteerShift',
        'INSERT',
        CONCAT_WS('-', NEW.VolunteerID, NEW.ShiftID),
        JSON_OBJECT(
            'Status',  NEW.Status,
            'CheckInTime',  NEW.CheckInTime,
            'CheckOutTime', NEW.CheckOutTime,
            'ApprovedBy', NEW.ApprovedBy,
            'ApprovedAt', NEW.ApprovedAt
        ),
        USER(),
    );
END $$

CREATE TRIGGER volunteerShift_after_update_audit
AFTER UPDATE ON VolunteerShift
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, OldValues, NewValues, ChangedBy)
    VALUES (
        'VolunteerShift',
        'UPDATE',
        CONCAT_WS('-', NEW.VolunteerID, NEW.ShiftID),
        JSON_OBJECT('Status', OLD.Status, 'CheckInTime', OLD.CheckInTime, 'CheckOutTime', OLD.CheckOutTime,
        ,'ApprovedBy', OLD.ApprovedBy, 'ApprovedAt', OLD.ApprovedAt),
        JSON_OBJECT('Status', NEW.Status, 'CheckInTime', NEW.CheckInTime, 'CheckOutTime', NEW.CheckOutTime,
        'ApprovedBy', NEW.ApprovedBy,'ApprovedAt', NEW.ApprovedAt),
        USER(),
    );
END $$

CREATE TRIGGER volunteerHours_after_insert_audit
AFTER INSERT ON VolunteerHours
FOR EACH ROW
BEGIN
    INSERT INTO audit_log (TableName, Action, RecordID, NewValues, ChangedBy)
    VALUES (
        'VolunteerHours',
        'INSERT',
        CONCAT_WS('-', NEW.VolunteerID, NEW.ShiftID),
        JSON_OBJECT(
            'HoursWorked',  NEW.HoursWorked,
        ),
        USER(),
    );
END $$

DELIMITER ; 