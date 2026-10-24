DELIMITER $$

CREATE TRIGGER prevent_volunteerhours_update
BEFORE UPDATE ON VolunteerHours
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Directly updating volunteerhours is strictly prohibited.';
END  $$

CREATE TRIGGER prevent_volunteerhours_delete
BEFORE DELETE ON VolunteerHours
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Deletion from the volunteerhours is strictly prohibited.';
END  $$


DELIMITER ;
