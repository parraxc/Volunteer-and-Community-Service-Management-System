CREATE USER 'mgr_test'@'localhost'    IDENTIFIED BY 'A';
CREATE USER 'coord_test1'@'localhost' IDENTIFIED BY 'B';
CREATE USER 'coord_test2'@'localhost' IDENTIFIED BY 'C';
CREATE USER 'staff_test'@'localhost'  IDENTIFIED BY 'D';

GRANT 'manager_role'     TO 'mgr_test'@'localhost';
GRANT 'coordinator_role' TO 'coord_test1'@'localhost', 'coord_test2'@'localhost';
GRANT 'staff_role'       TO 'staff_test'@'localhost';

SET DEFAULT ROLE 'manager_role'     TO 'mgr_test'@'localhost';
SET DEFAULT ROLE 'coordinator_role' TO 'coord_test1'@'localhost', 'coord_test2'@'localhost';
SET DEFAULT ROLE 'staff_role'       TO 'staff_test'@'localhost';