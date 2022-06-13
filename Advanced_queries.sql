-- SQL степ-проект
-- Запросы
-- 1.Покажите среднюю зарплату сотрудников за каждый год (средняя заработная плата среди тех, кто работал в отчетный период - статистика с начала до 2005 года).

SELECT YEAR(from_date) AS year_sal, AVG(salary) AS avg_sal
FROM employees.salaries
WHERE YEAR(to_date) <= 2005
GROUP BY year_sal
ORDER BY year_sal;

-- 2.Покажите среднюю зарплату сотрудников по каждому отделу. Примечание: принять в расчет только текущие отделы и текущую заработную плату.
SELECT dept_no, AVG(salary) AS avg_sal
FROM salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no 
WHERE NOW() BETWEEN s.from_date AND s.to_date AND NOW() BETWEEN d_e.from_date AND d_e.to_date
GROUP BY dept_no;

-- 3.Покажите среднюю зарплату сотрудников по каждому отделу за каждый год. Примечание: 
-- для средней зарплаты отдела d001 в году 1987 
-- нам нужно взять 
-- среднее значение всех зарплат в году 1987 
-- сотрудников,которые были в отделе d001 в году 1987.

SELECT dept_no, year(s.from_date) AS year_sal, AVG(salary) as average_salary 
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (d_e.from_date >= s.from_date AND d_e.to_date < s.to_date)
GROUP BY dept_no, year_sal
ORDER BY dept_no, year_sal;

-- 4.Покажите для каждого года самый крупный отдел (по количеству сотрудников) в этом году и его среднюю зарплату.
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

-- 5.Покажите подробную информацию о менеджере, который дольше всех исполняет свои обязанности на данный момент.

SELECT d_m.emp_no, first_name, last_name, birth_date, gender, hire_date, dept_no, d_m.from_date, d_m.to_date, salary, DATEDIFF(d_m.to_date, d_m.from_date) AS serv_period_days
FROM employees.dept_manager AS d_m 
INNER JOIN employees.employees AS e ON d_m.emp_no = e.emp_no AND (NOW() BETWEEN d_m.from_date AND d_m.to_date)
INNER JOIN employees.salaries AS s ON s.emp_no = e.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date)
ORDER BY serv_period_days DESC
LIMIT 1;

-- 6.Покажите топ-10 нынешних сотрудников компании с наибольшей разницей между их зарплатой и текущей средней зарплатой в их отделе.

SELECT d_e.emp_no, d_e.dept_no, salary, AVG(salary) OVER (PARTITION BY dept_no) AS avg_dept_sal, ABS(AVG(salary) OVER (PARTITION BY dept_no) - salary) AS sal_dif
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date) AND (NOW() BETWEEN d_e.from_date AND d_e.to_date)
ORDER BY sal_dif DESC
LIMIT 10;

-- 7.Из-за кризиса на одно подразделение на своевременную выплату зарплаты выделяется всего 500 тысяч долларов. Правление решило, что низкооплачиваемые сотрудники будут первыми получать зарплату. Показать список всех сотрудников, которые будут вовремя получать зарплату (обратите внимание, что мы должны платить зарплату за один месяц, но в базе данных мы храним годовые суммы).

WITH CTE
AS (SELECT d_e.emp_no, d_e.dept_no, salary, salary/12 AS month_sal, ROW_NUMBER() OVER(PARTITION BY dept_no ORDER BY salary) AS id
FROM employees.salaries AS s 
INNER JOIN dept_emp AS d_e ON d_e.emp_no = s.emp_no AND (NOW() BETWEEN s.from_date AND s.to_date) AND (NOW() BETWEEN d_e.from_date AND d_e.to_date)
ORDER BY dept_no, month_sal)

SELECT emp_no, dept_no, month_sal, cum_sal 
FROM (SELECT *, SUM(month_sal) OVER (PARTITION BY dept_no ORDER BY id) AS cum_sal
FROM CTE) AS t1
WHERE cum_sal <= 500000;
