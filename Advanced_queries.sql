-- 1. Show the average salary of employees for each year (average salary among those who worked in the reporting period - statistics from the beginning to 2005)

SELECT YEAR(from_date) AS year_sal, AVG(salary) AS avg_sal
FROM employees.salaries
WHERE YEAR(to_date) <= 2005
GROUP BY year_sal
ORDER BY year_sal;

-- 2. Show the average salary of employees for each department. Note: take into account only current departments and current salary
SELECT dept_no, AVG(salary) AS avg_sal
FROM salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no 
WHERE NOW() BETWEEN s.from_date AND s.to_date AND NOW() BETWEEN d_e.from_date AND d_e.to_date
GROUP BY dept_no;

-- 3. Show the average salary of employees in each department for each year. Note:
-- for the average salary of department d001 in the year 1987
-- we need to take
-- average of all salaries in the year 1987
-- employees who were in department d001 in the year 1987

SELECT dept_no, year(s.from_date) AS year_sal, AVG(salary) as average_salary 
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (d_e.from_date >= s.from_date AND d_e.to_date < s.to_date)
GROUP BY dept_no, year_sal
ORDER BY dept_no, year_sal;

-- 4. Show for each year the largest department (by number of employees) in that year and its average salary
WITH Cte1
AS (
SELECT dept_no, year(s.from_date) AS year_, AVG(salary) as average_salary, COUNT(d_e.emp_no) AS emp_quant
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (s.from_date >= d_e.from_date AND s.to_date < d_e.to_date)
GROUP BY dept_no, year_
ORDER BY year_ ASC, emp_quant DESC
)
SELECT dept_no, year_, average_salary, MAX(emp_quant) AS max_emp_quant
FROM Cte1
GROUP BY year_;

-- 5. Show details of the longest-serving manager at the moment

SELECT d_m.emp_no, first_name, last_name, birth_date, gender, hire_date, dept_no, d_m.from_date, d_m.to_date, salary, DATEDIFF(d_m.to_date, d_m.from_date) AS serv_period_days
FROM employees.dept_manager AS d_m 
INNER JOIN employees.employees AS e ON d_m.emp_no = e.emp_no AND (NOW() BETWEEN d_m.from_date AND d_m.to_date)
INNER JOIN employees.salaries AS s ON s.emp_no = e.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date)
ORDER BY serv_period_days DESC
LIMIT 1;

-- 6. Show the top-10 current employees of the company with the largest difference between their salary and the current average salary in their department.

SELECT d_e.emp_no, d_e.dept_no, salary, AVG(salary) OVER (PARTITION BY dept_no) AS avg_dept_sal, ABS(AVG(salary) OVER (PARTITION BY dept_no) - salary) AS sal_dif
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date) AND (NOW() BETWEEN d_e.from_date AND d_e.to_date)
ORDER BY sal_dif DESC
LIMIT 10;

-- 7.Due to the crisis, only 500 thousand dollars are allocated for timely payment of salaries per department. 
-- The board has decided that low-paid employees will be paid first. Show a list of all employees who will receive their salary on time 
-- (note that we have to pay salaries for one month, but we store annual amounts in the database).

WITH CTE
AS (SELECT d_e.emp_no, d_e.dept_no, salary, salary/12 AS month_sal, ROW_NUMBER() OVER(PARTITION BY dept_no ORDER BY salary) AS id
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date) AND (NOW() BETWEEN d_e.from_date AND d_e.to_date)
ORDER BY dept_no, month_sal)

SELECT emp_no, dept_no, month_sal, cum_sal 
FROM (SELECT *, SUM(month_sal) OVER (PARTITION BY dept_no ORDER BY id) AS cum_sal
FROM CTE) AS t1
WHERE cum_sal <= 500000;
