-- Section 20: users, grants and roles (MySQL). Users are server-wide, so the
-- case cleans up before and after itself. The guide's "shop" database is
-- "verify" here.
-- guide-sections: 20
DROP USER IF EXISTS 'analyst'@'localhost', 'app'@'%';
DROP ROLE IF EXISTS read_only;
CREATE TABLE orders (id INT PRIMARY KEY);
DELIMITER //
CREATE PROCEDURE apply_discount() BEGIN END //
DELIMITER ;

CREATE USER 'analyst'@'localhost' IDENTIFIED BY 'change_this_password';
CREATE USER 'app'@'%' IDENTIFIED BY 'change_this_password';

GRANT SELECT ON verify.* TO 'analyst'@'localhost';
GRANT SELECT, INSERT, UPDATE ON verify.orders TO 'app'@'%';
GRANT EXECUTE ON PROCEDURE verify.apply_discount TO 'app'@'%';

REVOKE UPDATE ON verify.orders FROM 'app'@'%';

SHOW GRANTS FOR 'analyst'@'localhost';
SHOW GRANTS FOR 'app'@'%';

CREATE ROLE read_only;
GRANT SELECT ON verify.* TO read_only;
GRANT read_only TO 'analyst'@'localhost';
SET DEFAULT ROLE read_only TO 'analyst'@'localhost';
SHOW GRANTS FOR 'analyst'@'localhost';

DROP USER 'analyst'@'localhost', 'app'@'%';
DROP ROLE read_only;
