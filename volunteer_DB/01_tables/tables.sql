DROP DATABASE IF EXISTS volunteer_db;
CREATE DATABASE volunteer_db;
USE volunteer_db;

-- ===== volunteer_DB/01_tables/tables.sql =====

CREATE TABLE StaffMember (
    StaffID INT AUTO_INCREMENT PRIMARY KEY,
    StaffName VARCHAR(100) NOT NULL,
    StaffRole VARCHAR(20) NOT NULL,
    DbUsername VARCHAR(32) NOT NULL UNIQUE,
    CONSTRAINT chk_staff_role
        CHECK (StaffRole IN ('Manager', 'Event Coordinator', 'Staff Member'))

);

CREATE TABLE Event (
    EventID INT AUTO_INCREMENT PRIMARY KEY,
    EventName VARCHAR(150) NOT NULL,
    EventDate DATE NOT NULL, 
    CoordinatorID INT,
    FOREIGN KEY (CoordinatorID) REFERENCES StaffMember (StaffID)
);

CREATE TABLE Shift(
    ShiftID INT AUTO_INCREMENT PRIMARY KEY,
    EventID INT NOT NULL,
    ShiftRole VARCHAR(100) NOT NULL,
    Capacity INT NOT NULL,
    StartDateTime DATETIME NOT NULL,
    EndDateTime DATETIME NOT NULL,
    FOREIGN KEY (EventID) REFERENCES Event(EventID),
    CONSTRAINT chk_shift_capacity 
        CHECK (Capacity > 0),
    CONSTRAINT chk_shift_times
        CHECK (EndDateTime > StartDateTime)
);

CREATE TABLE Volunteer(
    VolunteerID INT AUTO_INCREMENT PRIMARY KEY,
    VolunteerName VARCHAR(100) NOT NULL,
    VolunteerPhoneNumber VARCHAR(20) NOT NULL,
    VolunteerEmail VARCHAR(100) NOT NULL,
    BackgroundCheck BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE TABLE VolunteerShift(
    VolunteerID INT NOT NULL,
    ShiftID INT NOT NULL,
    Status VARCHAR(40) NOT NULL DEFAULT 'Scheduled',
    CheckInTime DATETIME NULL,
    CheckOutTime DATETIME NULL,
    HoursApproved BOOLEAN DEFAULT FALSE,
    ApprovedBy INT NULL,
    ApprovedAt DATETIME NULL,
    PRIMARY KEY (VolunteerID, ShiftID),
    FOREIGN KEY (VolunteerID) REFERENCES Volunteer(VolunteerID),
    FOREIGN KEY (ShiftID) REFERENCES Shift(ShiftID),
    FOREIGN KEY (ApprovedBy) REFERENCES StaffMember(StaffID),

    CONSTRAINT chk_vshift_status CHECK  
        (Status IN ('Scheduled', 'In-Progress', 'Completed', 'No-Show', 'Cancelled')),
    
    CONSTRAINT chk_vshift_status_time CHECK (
        (Status IN ('Scheduled','No-Show','Cancelled') AND CheckInTime IS NULL AND CheckOutTime IS NULL)
        OR (Status = 'In-Progress' AND CheckInTime IS NOT NULL AND CheckOutTime IS NULL)
        OR (Status = 'Completed' AND CheckInTime IS NOT NULL AND CheckOutTime IS NOT NULL)
    ),

    CONSTRAINT chk_vshift_checkout CHECK (CheckOutTime > CheckInTime),

    CONSTRAINT chk_vshift_approval CHECK
    ((ApprovedBy IS NULL AND ApprovedAt IS NULL)
        OR (ApprovedBy IS NOT NULL AND ApprovedAt IS NOT NULL AND Status = 'Completed')) 
); 

CREATE TABLE VolunteerHours(
    VolunteerID INT NOT NULL,
    ShiftID INT NOT NULL,
    HoursWorked DECIMAL(5,2) NOT NULL,

    PRIMARY KEY (VolunteerID, ShiftID),
    FOREIGN KEY (VolunteerID) REFERENCES Volunteer(VolunteerID),
    FOREIGN KEY (ShiftID) REFERENCES Shift(ShiftID),
    CONSTRAINT chk_vhours CHECK (HoursWorked > 0)

);

CREATE TABLE Skill(
    SkillCode INT AUTO_INCREMENT PRIMARY KEY,
    SkillName VARCHAR(50) NOT NULL UNIQUE, 
    SkillDescription VARCHAR(100) NOT NULL
);

CREATE TABLE VolunteerSkill(
    VolunteerID INT NOT NULL, 
    SkillCode INT NOT NULL,
    PRIMARY KEY(VolunteerID, SkillCode),
    FOREIGN KEY (VolunteerID) REFERENCES Volunteer(VolunteerID),
    FOREIGN KEY (SkillCode) REFERENCES Skill(SkillCode)
);

CREATE TABLE AuditLog (
    AuditID          BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    TableName        VARCHAR(64)  NOT NULL,
    Operation        ENUM('INSERT', 'UPDATE') NOT NULL,
    RecordId         VARCHAR(100) NOT NULL,
    ChangedBy        VARCHAR(288) NOT NULL,
    ChangedByStaffID INT          NULL,
    ChangedAt        DATETIME(6)  NOT NULL,
    OldValues        JSON         NULL,
    NewValues        JSON         NOT NULL,
    FOREIGN KEY (ChangedByStaffID) REFERENCES StaffMember (StaffID),
    INDEX idx_audit_record (TableName, RecordId, ChangedAt),
    INDEX idx_audit_staff  (ChangedByStaffID, ChangedAt)
);