-- Section 14: MySQL's NULL-safe comparison.
-- guide-sections: 14
SELECT NULL <=> NULL AS both_null, 1 <=> NULL AS one_null;
