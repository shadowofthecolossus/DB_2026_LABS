-- lab 3 dml

-- 1. create database and tables
CREATE DATABASE advanced_lab;
-- \c advanced_lab

CREATE TABLE employees (
    emp_id     SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name  VARCHAR(50) NOT NULL,
    department VARCHAR(50) DEFAULT 'General', -- default is needed for task 10
    salary     INTEGER DEFAULT 30000,         -- default for task 3
    hire_date  DATE,
    status     VARCHAR(20) DEFAULT 'Active'
);

CREATE TABLE departments (
    dept_id    SERIAL PRIMARY KEY,
    dept_name  VARCHAR(50) NOT NULL,
    budget     INTEGER,
    manager_id INTEGER
);

CREATE TABLE projects (
    project_id   SERIAL PRIMARY KEY,
    project_name VARCHAR(100) NOT NULL,
    dept_id      INTEGER,
    start_date   DATE,
    end_date     DATE,
    budget       INTEGER
);

-- 2. insert only some columns
INSERT INTO employees (emp_id, first_name, last_name, department)
VALUES (1, 'Ivan', 'Petrov', 'IT'),
       (2, 'Aigerim', 'Sarsen', 'Sales');
-- i set the ids by hand so i move the sequence forward, otherwise duplicate key error later
SELECT setval(pg_get_serial_sequence('employees', 'emp_id'),
              (SELECT MAX(emp_id) FROM employees));

-- 3. salary and status use default values
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Dana', 'Nurlan', 'IT', DEFAULT, '2021-05-10', DEFAULT);

-- 4. 3 departments in one insert
INSERT INTO departments (dept_name, budget, manager_id)
VALUES ('IT', 200000, 1),
       ('Sales', 150000, 2),
       ('HR', 80000, NULL);

-- 5. hire_date = today, salary = 50000 * 1.1
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Timur', 'Bek', 'IT', 50000 * 1.1, CURRENT_DATE);

-- 6. temp table, then copy everyone from IT into it
CREATE TEMPORARY TABLE temp_employees (LIKE employees INCLUDING DEFAULTS);

INSERT INTO temp_employees
SELECT * FROM employees
WHERE department = 'IT';

-- added more data so there is something to test
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Aliya', 'Kim',     'Sales', 90000, '2018-03-01', 'Active'),
       ('Marat', 'Omarov',  'Sales', 65000, '2019-07-15', 'Active'),
       ('Sergey', 'Ivanov', 'HR',    45000, '2022-01-20', 'Active'),
       ('Olga', 'Smirnova', 'IT',    70000, '2017-11-11', 'Active');

INSERT INTO projects (project_name, dept_id, start_date, end_date, budget)
VALUES ('Website Redesign', 1, '2022-01-01', '2022-12-31', 60000),
       ('CRM Migration',    2, '2023-03-01', '2024-03-01', 90000),
       ('Recruiting Portal',3, '2023-06-01', '2024-01-01', 30000);

-- 7. everyone gets +10%, round is needed because salary is integer
UPDATE employees
SET salary = ROUND(salary * 1.10);

-- 8. status Senior if salary > 60000 and hired before 2020
UPDATE employees
SET status = 'Senior'
WHERE salary > 60000
  AND hire_date < '2020-01-01';

-- 9. department by salary using case
-- if salary is NULL it goes to else (Junior)
UPDATE employees
SET department = CASE
                     WHEN salary > 80000 THEN 'Management'
                     WHEN salary BETWEEN 50000 AND 80000 THEN 'Senior'
                     ELSE 'Junior'
                 END;

-- after task 9 all departments changed, so adding new rows for task 10
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Nazar', 'Abenov', 'Sales', 40000, '2021-02-02', 'Inactive'),
       ('Lena', 'Popova', 'IT',    55000, '2020-06-06', 'Inactive');

-- 10. set department to default (General) for inactive ones
UPDATE employees
SET department = DEFAULT
WHERE status = 'Inactive';

-- 11. department budget = average salary * 1.2
-- exists is here so budget doesnt become NULL for departments with no employees
UPDATE departments d
SET budget = ROUND((SELECT AVG(e.salary)
                    FROM employees e
                    WHERE e.department = d.dept_name) * 1.20)
WHERE EXISTS (SELECT 1 FROM employees e WHERE e.department = d.dept_name);

-- putting normal departments back so the next tasks work
UPDATE employees SET department = 'Sales' WHERE first_name IN ('Aliya', 'Marat');
UPDATE employees SET department = 'IT'    WHERE first_name IN ('Ivan', 'Dana', 'Timur', 'Olga');

-- 12. change salary and status in Sales in one update
UPDATE employees
SET salary = ROUND(salary * 1.15),
    status = 'Promoted'
WHERE department = 'Sales';

-- 13. delete Terminated (added a couple of rows first for testing)
INSERT INTO employees (first_name, last_name, department, salary, hire_date, status)
VALUES ('Old', 'Timer',  'HR', 50000, '2015-01-01', 'Terminated'),
       ('New', 'Intern', NULL, 35000, '2024-02-01', 'Active');

DELETE FROM employees
WHERE status = 'Terminated';

-- 14. delete with several conditions at once
DELETE FROM employees
WHERE salary < 40000
  AND hire_date > '2023-01-01'
  AND department IS NULL;

-- 15. delete departments that have no employees
-- the task compares dept_id with the department string, thats not possible (different types)
-- so i compare dept_name instead
DELETE FROM departments
WHERE dept_name NOT IN (SELECT DISTINCT department
                        FROM employees
                        WHERE department IS NOT NULL);

-- 16. delete old projects and show what was deleted
DELETE FROM projects
WHERE end_date < '2023-01-01'
RETURNING *;

-- 17. employee with NULL salary and department
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Null', 'Person', NULL, NULL, CURRENT_DATE);

-- 18. NULL department -> Unassigned (need IS NULL here, = NULL doesnt work)
UPDATE employees
SET department = 'Unassigned'
WHERE department IS NULL;

-- 19. delete where salary or department is NULL
DELETE FROM employees
WHERE salary IS NULL
   OR department IS NULL;

-- 20. new employee, returns id and full name
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Zhanna', 'Aitkali', 'HR', 48000, CURRENT_DATE)
RETURNING emp_id, first_name || ' ' || last_name AS full_name;

-- 21. IT salary +5000, show old and new salary
-- returning cant give the old value directly, so i took it from a subquery
UPDATE employees e
SET salary = e.salary + 5000
FROM (SELECT emp_id, salary AS old_salary
      FROM employees
      WHERE department = 'IT') AS old
WHERE e.emp_id = old.emp_id
RETURNING e.emp_id, old.old_salary, e.salary AS new_salary;

-- 22. delete everyone hired before 2020 and return all columns
DELETE FROM employees
WHERE hire_date < '2020-01-01'
RETURNING *;

-- 23. insert only if this employee doesnt exist yet
-- Zhanna is already there from task 20, so 0 rows will be inserted
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
SELECT 'Zhanna', 'Aitkali', 'HR', 48000, CURRENT_DATE
WHERE NOT EXISTS (SELECT 1
                  FROM employees
                  WHERE first_name = 'Zhanna'
                    AND last_name = 'Aitkali');

-- 24. if department budget > 100000 then +10%, otherwise +5%
UPDATE employees e
SET salary = ROUND(e.salary * CASE
                                  WHEN (SELECT d.budget
                                        FROM departments d
                                        WHERE d.dept_name = e.department) > 100000
                                  THEN 1.10
                                  ELSE 1.05
                              END)
WHERE e.salary IS NOT NULL;

-- 25. 5 employees in one insert, then one update +10%
INSERT INTO employees (first_name, last_name, department, salary, hire_date)
VALUES ('Bulk1', 'Test', 'IT', 40000, CURRENT_DATE),
       ('Bulk2', 'Test', 'IT', 41000, CURRENT_DATE),
       ('Bulk3', 'Test', 'IT', 42000, CURRENT_DATE),
       ('Bulk4', 'Test', 'IT', 43000, CURRENT_DATE),
       ('Bulk5', 'Test', 'IT', 44000, CURRENT_DATE);

UPDATE employees
SET salary = ROUND(salary * 1.10)
WHERE last_name = 'Test'
  AND first_name LIKE 'Bulk%';

-- 26. archive: copy Inactive to the new table, then delete them from employees
CREATE TABLE employee_archive (LIKE employees INCLUDING DEFAULTS);

BEGIN;
    INSERT INTO employee_archive
    SELECT * FROM employees
    WHERE status = 'Inactive';

    DELETE FROM employees
    WHERE status = 'Inactive';
COMMIT;

-- 27. add 30 days to end_date for projects with budget > 50000
-- but only if the department has more than 3 employees
UPDATE projects p
SET end_date = p.end_date + 30 -- you can just add a number of days to a date
WHERE p.budget > 50000
  AND (SELECT COUNT(*)
       FROM employees e
       JOIN departments d ON d.dept_name = e.department
       WHERE d.dept_id = p.dept_id) > 3;