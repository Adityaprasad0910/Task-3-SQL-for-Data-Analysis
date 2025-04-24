-- Employee Database Schema
CREATE TABLE employees (
    employee_id INT PRIMARY KEY,
    employee_name VARCHAR(50) NOT NULL,
    department VARCHAR(50),
    salary DECIMAL(10, 2),
    hire_date DATE,
    manager_id INT
);

-- Insert sample data
INSERT INTO employees (employee_id, employee_name, department, salary, hire_date, manager_id)
VALUES
    (1, 'John Doe', 'IT', 60000.00, '2022-01-15', NULL),
    (2, 'Jane Smith', 'HR', 55000.00, '2022-02-20', 1),
    (3, 'Bob Johnson', 'Finance', 70000.00, '2022-03-10', 1),
    (4, 'Alice Williams', 'IT', 65000.00, '2022-04-05', 2),
    (5, 'Charlie Brown', 'HR', 50000.00, '2022-05-12', 2);

-- ==========================================
-- 1. Basic SELECT with WHERE and ORDER BY
-- ==========================================

-- Find all IT employees ordered by salary (highest to lowest)
SELECT employee_id, employee_name, salary
FROM employees
WHERE department = 'IT'
ORDER BY salary DESC;

-- Find employees hired in the first quarter of 2022
SELECT employee_id, employee_name, department, hire_date
FROM employees
WHERE hire_date BETWEEN '2022-01-01' AND '2022-03-31'
ORDER BY hire_date;

-- Find employees with salaries in a specific range
SELECT employee_id, employee_name, department, salary
FROM employees
WHERE salary BETWEEN 55000 AND 65000
ORDER BY salary;

-- ==========================================
-- 2. GROUP BY with Aggregation
-- ==========================================

-- Get average salary by department
SELECT department, 
       COUNT(*) as employee_count,
       AVG(salary) as avg_salary
FROM employees
GROUP BY department
ORDER BY avg_salary DESC;

-- Find number of employees by manager
SELECT manager_id, COUNT(*) as direct_reports
FROM employees
WHERE manager_id IS NOT NULL
GROUP BY manager_id
ORDER BY direct_reports DESC;

-- Count employees hired by month
SELECT EXTRACT(MONTH FROM hire_date) as month,
       TO_CHAR(hire_date, 'Month') as month_name,
       COUNT(*) as hires
FROM employees
GROUP BY EXTRACT(MONTH FROM hire_date), TO_CHAR(hire_date, 'Month')
ORDER BY month;

-- ==========================================
-- 3. JOINS
-- ==========================================

-- INNER JOIN: Match employees with their managers
SELECT e.employee_id, e.employee_name, e.department, e.salary,
       m.employee_id as manager_id, m.employee_name as manager_name
FROM employees e
INNER JOIN employees m ON e.manager_id = m.employee_id;

-- LEFT JOIN: Show all employees and their managers (if they have one)
SELECT e.employee_id, e.employee_name, e.department,
       m.employee_name as manager_name
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- RIGHT JOIN: Show all potential managers with their direct reports
SELECT e.employee_name as employee_name,
       m.employee_id as manager_id, 
       m.employee_name as manager_name
FROM employees e
RIGHT JOIN employees m ON e.manager_id = m.employee_id;

-- SELF JOIN: Find employees in the same department
SELECT e1.employee_name, e1.department, e2.employee_name as colleague
FROM employees e1
JOIN employees e2 ON e1.department = e2.department AND e1.employee_id != e2.employee_id
ORDER BY e1.department, e1.employee_name, e2.employee_name;

-- ==========================================
-- 4. Subqueries
-- ==========================================

-- Find employees who earn more than the average salary
SELECT employee_name, department, salary
FROM employees
WHERE salary > (SELECT AVG(salary) FROM employees);

-- Find employees who work in departments with average salary > 55000
SELECT employee_name, department, salary
FROM employees
WHERE department IN (
  SELECT department 
  FROM employees 
  GROUP BY department 
  HAVING AVG(salary) > 55000
);

-- Find the highest paid employee in each department
SELECT e.department, e.employee_name, e.salary
FROM employees e
WHERE e.salary = (
    SELECT MAX(salary)
    FROM employees
    WHERE department = e.department
);

-- Find employees hired after the company's first hire
SELECT employee_name, hire_date
FROM employees
WHERE hire_date > (
    SELECT MIN(hire_date)
    FROM employees
);

-- Find employees who earn more than their managers
SELECT e.employee_name, e.salary, m.employee_name as manager_name, m.salary as manager_salary
FROM employees e
JOIN employees m ON e.manager_id = m.employee_id
WHERE e.salary > m.salary;

-- ==========================================
-- 5. Aggregate Functions
-- ==========================================

-- Calculate total salary budget by department
SELECT department, 
       COUNT(*) as employee_count,
       SUM(salary) as total_salary_budget,
       MIN(salary) as min_salary,
       MAX(salary) as max_salary,
       ROUND(AVG(salary), 2) as avg_salary,
       MAX(salary) - MIN(salary) as salary_range
FROM employees
GROUP BY department;

-- Calculate salary stats for employees hired in each month
SELECT EXTRACT(MONTH FROM hire_date) as hire_month,
       COUNT(*) as hires,
       SUM(salary) as total_salary,
       ROUND(AVG(salary), 2) as avg_salary
FROM employees
GROUP BY EXTRACT(MONTH FROM hire_date)
ORDER BY hire_month;

-- Calculate salary distribution as percentage of total payroll
SELECT employee_id, employee_name, salary,
       ROUND((salary / (SELECT SUM(salary) FROM employees)) * 100, 2) as percentage_of_total
FROM employees
ORDER BY percentage_of_total DESC;

-- ==========================================
-- 6. Creating Views
-- ==========================================

-- Create a view for management hierarchy
CREATE OR REPLACE VIEW employee_hierarchy AS
SELECT e.employee_id, e.employee_name, e.department,
       e.salary, e.hire_date,
       m.employee_id as manager_id,
       m.employee_name as manager_name,
       m.department as manager_department
FROM employees e
LEFT JOIN employees m ON e.manager_id = m.employee_id;

-- Query the view
SELECT * FROM employee_hierarchy;

-- Create a department summary view
CREATE OR REPLACE VIEW department_summary AS
SELECT department,
       COUNT(*) as employee_count,
       SUM(salary) as total_salary,
       ROUND(AVG(salary), 2) as avg_salary,
       MIN(salary) as min_salary,
       MAX(salary) as max_salary,
       MAX(salary) - MIN(salary) as salary_range
FROM employees
GROUP BY department;

-- Query the view
SELECT * FROM department_summary;

-- Create a view for salary ranges
CREATE OR REPLACE VIEW salary_ranges AS
SELECT 
    'Below 55K' as salary_range,
    COUNT(*) as employee_count
FROM employees WHERE salary < 55000
UNION
SELECT 
    '55K-65K' as salary_range,
    COUNT(*) as employee_count
FROM employees WHERE salary BETWEEN 55000 AND 65000
UNION
SELECT 
    'Above 65K' as salary_range,
    COUNT(*) as employee_count
FROM employees WHERE salary > 65000
ORDER BY salary_range;

-- Query the view
SELECT * FROM salary_ranges;

-- ==========================================
-- 7. Optimizing with Indexes
-- ==========================================

-- Create index on frequently searched columns
CREATE INDEX idx_department ON employees(department);
CREATE INDEX idx_hire_date ON employees(hire_date);
CREATE INDEX idx_manager_id ON employees(manager_id);

-- Create a composite index for queries that filter on department and sort by salary
CREATE INDEX idx_dept_salary ON employees(department, salary);

-- Index for range queries on salary
CREATE INDEX idx_salary ON employees(salary);

-- ==========================================
-- 8. Bonus: Common Table Expressions (CTEs)
-- ==========================================

-- Calculate department statistics using a CTE
WITH dept_stats AS (
    SELECT department,
           COUNT(*) as emp_count,
           AVG(salary) as avg_salary
    FROM employees
    GROUP BY department
)
SELECT e.employee_name, e.department, e.salary,
       ds.avg_salary as dept_avg_salary,
       e.salary - ds.avg_salary as diff_from_avg
FROM employees e
JOIN dept_stats ds ON e.department = ds.department
ORDER BY department, salary DESC;

-- Find the highest paid employee in each department using a CTE
WITH ranked_employees AS (
    SELECT employee_name, department, salary,
           RANK() OVER (PARTITION BY department ORDER BY salary DESC) as salary_rank
    FROM employees
)
SELECT employee_name, department, salary
FROM ranked_employees
WHERE salary_rank = 1;

-- ==========================================
-- 9. Window Functions
-- ==========================================

-- Add rank, salary percentile and running total by department
SELECT employee_name, department, salary,
       RANK() OVER (PARTITION BY department ORDER BY salary DESC) as dept_salary_rank,
       ROUND(PERCENT_RANK() OVER (PARTITION BY department ORDER BY salary) * 100, 2) as percentile,
       SUM(salary) OVER (PARTITION BY department ORDER BY salary) as running_dept_total
FROM employees;

-- Calculate the difference between each employee's salary and the next highest in their department
SELECT employee_name, department, salary,
       LEAD(salary, 1, 0) OVER (PARTITION BY department ORDER BY salary DESC) as next_lower_salary,
       salary - LEAD(salary, 1, 0) OVER (PARTITION BY department ORDER BY salary DESC) as salary_gap
FROM employees;