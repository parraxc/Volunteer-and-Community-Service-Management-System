DELIMITER $$

CREATE prevent_volunteerhours_delete
BEFORE UPDATE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Directly updating volunteerhours is strictly prohibited.';
END  $$

CREATE prevent_volunteerhours_delete
BEFORE DELETE ON audit_log
FOR EACH ROW
BEGIN
    SIGNAL SQLSTATE '45000' 
    SET MESSAGE_TEXT = 'Deletion from the volunteerhours is strictly prohibited.';
END  $$


DELIMITER ;
