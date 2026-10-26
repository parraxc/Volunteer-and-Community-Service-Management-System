DELIMITER $$

CREATE TRIGGER prevent_auditlog_delete
BEFORE DELETE ON AuditLog
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Deletion from the audit log is strictly prohibited.';
END  $$

CREATE TRIGGER prevent_auditlog_update
BEFORE UPDATE ON AuditLog
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000'
    SET MESSAGE_TEXT = 'Updating the audit log is strictly prohibited.';
END  $$

CREATE TRIGGER event_after_insert_audit
AFTER INSERT ON Event
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, NewValues)
    VALUES (
        'Event',
        'INSERT',
        CONCAT('EventID=', NEW.EventID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT(
            'EventName',  NEW.EventName,
            'EventDate', NEW.EventDate,
            'CoordinatorID', NEW.CoordinatorID
        )
    );
END $$

CREATE TRIGGER event_after_update_audit
AFTER UPDATE ON Event
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, OldValues, NewValues)
    VALUES (
        'Event',
        'UPDATE',
        CONCAT('EventID=', NEW.EventID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT('EventName', OLD.EventName, 'EventDate', OLD.EventDate, 'CoordinatorID', OLD.CoordinatorID),
        JSON_OBJECT('EventName', NEW.EventName, 'EventDate', NEW.EventDate, 'CoordinatorID', NEW.CoordinatorID)
    );
END $$


CREATE TRIGGER volunteer_after_insert_audit
AFTER INSERT ON Volunteer
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, NewValues)
    VALUES (
        'Volunteer',
        'INSERT',
        CONCAT('VolunteerID=', NEW.VolunteerID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT(
            'VolunteerName',  NEW.VolunteerName,
            'VolunteerPhoneNumber', NEW.VolunteerPhoneNumber,
            'VolunteerEmail', NEW.VolunteerEmail,
            'BackgroundCheck', NEW.BackgroundCheck
        )
    );
END $$

CREATE TRIGGER volunteer_after_update_audit
AFTER UPDATE ON Volunteer
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, OldValues, NewValues)
    VALUES (
        'Volunteer',
        'UPDATE',
        CONCAT('VolunteerID=', NEW.VolunteerID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT('VolunteerName', OLD.VolunteerName, 'VolunteerPhoneNumber', OLD.VolunteerPhoneNumber, 'VolunteerEmail', OLD.VolunteerEmail, 'BackgroundCheck', OLD.BackgroundCheck),
        JSON_OBJECT('VolunteerName', NEW.VolunteerName, 'VolunteerPhoneNumber', NEW.VolunteerPhoneNumber, 'VolunteerEmail', NEW.VolunteerEmail, 'BackgroundCheck', NEW.BackgroundCheck)
    );
END $$

CREATE TRIGGER volunteersSift_after_insert_audit
AFTER INSERT ON VolunteerShift
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, NewValues)
    VALUES (
        'VolunteerShift',
        'INSERT',
        CONCAT('VolunteerID=', NEW.VolunteerID, ';ShiftID=', NEW.ShiftID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT(
            'Status',  NEW.Status,
            'CheckInTime',  NEW.CheckInTime,
            'CheckOutTime', NEW.CheckOutTime,
            'ApprovedBy', NEW.ApprovedBy,
            'ApprovedAt', NEW.ApprovedAt
        )
    );
END $$

CREATE TRIGGER volunteerShift_after_update_audit
AFTER UPDATE ON VolunteerShift
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, OldValues, NewValues)
    VALUES (
        'VolunteerShift',
        'UPDATE',
        CONCAT('VolunteerID=', NEW.VolunteerID, ';ShiftID=', NEW.ShiftID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT('Status', OLD.Status, 'CheckInTime', OLD.CheckInTime, 'CheckOutTime', OLD.CheckOutTime,'ApprovedBy', OLD.ApprovedBy, 'ApprovedAt', OLD.ApprovedAt),
        JSON_OBJECT('Status', NEW.Status, 'CheckInTime', NEW.CheckInTime, 'CheckOutTime', NEW.CheckOutTime,'ApprovedBy', NEW.ApprovedBy,'ApprovedAt', NEW.ApprovedAt)
    );
END $$

CREATE TRIGGER volunteerHours_after_insert_audit
AFTER INSERT ON VolunteerHours
FOR EACH ROW
BEGIN
    DECLARE v_staff_id INT DEFAULT NULL;

    SELECT StaffID INTO v_staff_id
    FROM StaffMember
    WHERE DbUsername COLLATE utf8mb4_bin = SUBSTRING_INDEX(USER(), '@', 1);

    INSERT INTO AuditLog (TableName, Operation, RecordId, ChangedBy, ChangedByStaffID, ChangedAt, NewValues)
    VALUES (
        'VolunteerHours',
        'INSERT',
        CONCAT('VolunteerID=', NEW.VolunteerID, ';ShiftID=', NEW.ShiftID),
        USER(),
        v_staff_id,
        UTC_TIMESTAMP(6),
        JSON_OBJECT(
            'HoursWorked',  NEW.HoursWorked
        )
    );
END $$

DELIMITER ;
