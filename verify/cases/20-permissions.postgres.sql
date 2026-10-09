-- Section 20: roles and grants (PostgreSQL). Roles are server-wide, so the
-- case cleans up after itself.
-- guide-sections: 20
CREATE TABLE orders (id INT PRIMARY KEY);
CREATE TABLE customers (id INT PRIMARY KEY);
DROP ROLE IF EXISTS analyst;

CREATE ROLE analyst LOGIN PASSWORD 'change_this_password';
GRANT SELECT ON ALL TABLES IN SCHEMA public TO analyst;
REVOKE SELECT ON orders FROM analyst;

SELECT table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'analyst'
ORDER BY table_name;

DROP OWNED BY analyst;
DROP ROLE analyst;
