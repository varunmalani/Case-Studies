-- Creating a database
CREATE DATABASE DATA_SCIENCE;

USE DATA_SCIENCE;

-- CREATING A TABLE
CREATE TABLE salaries (
	work_year INTEGER NOT NULL, 
	experience_level VARCHAR(255) NOT NULL, 
	employment_type VARCHAR(255) NOT NULL, 
	job_title VARCHAR(255) NOT NULL, 
	salary INTEGER NOT NULL, 
	salary_currency VARCHAR(255) NOT NULL, 
	salary_in_usd INTEGER NOT NULL, 
	employee_residence VARCHAR(255) NOT NULL, 
	remote_ratio INTEGER NOT NULL, 
	company_location VARCHAR(255) NOT NULL, 
	company_size VARCHAR(255) NOT NULL
);

-- INSERTING THE DATA INTO THE TABLE
LOAD DATA LOCAL INFILE 'file_path.csv'
INTO TABLE salaries
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM salaries;

-- You're a Compensation Analyst employed by a Multinational Corporation. Your Assigment is to pin-point Countries which give work fully remotely, for the title managers, paying salaries exceeding $90,000 USD
SELECT DISTINCT company_location FROM salaries
WHERE salary_in_usd > 90000 AND job_title LIKE '%Manager%' AND remote_ratio = 100;

-- As a remote work Advocate Working for a Progressive HR Tech startup who place their freshers client in large tech firms. You're tasked with identifying Top 5 Countries having the greatest count of large (company size) number of freshers. Picture yourself as a data scientist working for a workforce management
SELECT company_location, COUNT(company_location) AS TotalFreshers FROM salaries 
WHERE experience_level = 'EN' AND company_size = 'L'
GROUP BY 1
ORDER BY 2 DESC LIMIT 5;

-- Picture yourself as a Data Scientist working for a Workforce Management Platform. Your objective is to calculate the percentage of employees, who enjoy fully remote roles, with salaries > $ 100,000, shedding light on the attractiveness of high-paying positions
SELECT (SELECT COUNT(*) FROM salaries WHERE remote_ratio = 100 AND salary_in_usd > 100000) / (SELECT COUNT(*) FROM salaries WHERE salary_in_usd > 100000) * 100 AS HighPayingPositions

-- Imagine you're a data analyst working for a global Rrecruitment Agency. Your task is to identify the locations where entry-level average salaries exceed the avereage salary for that job title in market for entry-level, helping your agency guide candidates towards lucrative oppourtunities

-- The below code is using subqueries
SELECT s1.company_location, s1.job_title, a1.job_title
FROM salaries s1
INNER JOIN (	SELECT job_title, AVG(salary_in_usd) AS AvgSalary FROM salaries
			WHERE experience_level = 'EN'
			GROUP BY job_title
			ORDER BY job_title) a1
ON s1.job_title = a1.job_title
WHERE s1.experience_level = 'EN' AND s1.salary_in_usd >= a1.AvgSalary

-- The code below is using CTE
WITH avg_salary_JobTitle AS(
SELECT job_title, AVG(salary_in_usd) AS AvgSalary FROM salaries
WHERE experience_level = 'EN'
GROUP BY job_title
ORDER BY job_title
)
SELECT s1.company_location, s1.job_title, a1.job_title
FROM salaries s1
INNER JOIN avg_salary_JobTitle a1
ON s1.job_title = a1.job_title
WHERE s1.experience_level = 'EN' AND s1.salary_in_usd >= a1.AvgSalary

-- You have been hired by a big HR Consultancy to look at how much people get paid in different countries. Your job is to find out for each job title which country pays the maximum average salay. This helps you place your candidates in those countries
SELECT company_location, job_title FROM 
	(SELECT *, DENSE_RANK() OVER (PARTITION BY job_title ORDER BY AvgSalary DESC) AS RankSalary
	FROM 
		(SELECT company_location, job_title, AVG(salary_in_usd) AS AvgSalary
		FROM salaries
		GROUP BY company_location, job_title
		ORDER BY 1,2 DESC) Tb1
		) Tb2
WHERE RankSalary = 1;

-- As a data-driven business consultant you've been hired by a mulinational corporation to analyze salary trends across different company locations. Your goal is to pin-point locations where the average salary has consistently increased over the past few years. (Countries where data is avilable for 3 years only [present year and past 2 years] providing insights into locations experiencing sustained salary growth)

-- Brute Force Approach
SELECT Sal2024.company_location, sal3 AS 2022YR, sal2 AS 2023YR, sal1 AS 2024YR
FROM 
  -- Salary in 2024 (or the current year)
  (SELECT company_location, AVG(salary_in_usd) AS Sal1 
   FROM salaries 
   WHERE work_year = (SELECT MAX(work_year) FROM salaries) 
   GROUP BY company_location) AS Sal2024
INNER JOIN 
  -- Salary in 2023
  (SELECT company_location, AVG(salary_in_usd) AS Sal2 
   FROM salaries 
   WHERE work_year = (SELECT MAX(work_year) FROM salaries) - 1 
   GROUP BY company_location) AS Sal2023
ON Sal2024.company_location = Sal2023.company_location
INNER JOIN 
  -- Salary in 2022
  (SELECT company_location, AVG(salary_in_usd) AS Sal3 
   FROM salaries 
   WHERE work_year = (SELECT MAX(work_year) FROM salaries) - 2 
   GROUP BY company_location) AS Sal2022
ON Sal2023.company_location = Sal2022.company_location
WHERE Sal1 >= Sal2 AND Sal2 >= Sal3 
ORDER BY 1;

-- Optimized Approach
WITH AvgSalaries AS (
    SELECT company_location, work_year, AVG(salary_in_usd) avg_salary FROM salaries
    WHERE work_year >= (YEAR(CURRENT_DATE()) - 2)
    GROUP BY 1,2
)
SELECT 
  company_location,
  MAX(CASE WHEN work_year = (SELECT MAX(work_year) FROM salaries) THEN avg_salary END) AS 2024YR,
  MAX(CASE WHEN work_year = (SELECT MAX(work_year) - 1 FROM salaries) THEN avg_salary END) AS 2023YR,
  MAX(CASE WHEN work_year = (SELECT MAX(work_year) - 2 FROM salaries) THEN avg_salary END) AS 2022YR
FROM AvgSalaries
GROUP BY company_location
HAVING 2024YR >= 2023YR AND 2023YR >= 2022YR
ORDER BY 1;

-- Picture yourself as a workforce strategist employed by a global HR startup. Your mission is to determine the percentage of only fully remote work for each experience level in 2021 and compare it with the corresponding figures for 2024. Highlighting any significant increases or decreases in remote work adoption over the years
SELECT Tb1.experience_level, Per2021, Per2024,
IF(Per2024 > Per2021, "Increase", "Decrease") AS IncDec
FROM 
    (SELECT experience_level, (COUNT(*) / (SELECT COUNT(*) FROM salaries WHERE remote_ratio = 100 AND work_year = 2021)) * 100 AS Per2021 FROM salaries 
    WHERE remote_ratio = 100 AND work_year = 2021
    GROUP BY 1) Tb1 
INNER JOIN
    (SELECT experience_level, (COUNT(*) / (SELECT COUNT(*) FROM salaries WHERE remote_ratio = 100 AND work_year = 2024)) * 100 AS Per2024 FROM salaries 
    WHERE remote_ratio = 100 AND work_year = 2024
    GROUP BY 1) Tb2
ON Tb1.experience_level = Tb2.experience_level;

-- As a compensation specialist at a fortune 500 company, you're tasked with analyzing salary trends over time. Your objectie is to calculate the average salary increase percentage for each experience level and job title between the years 2023 and 2024, helping the company to stay competetive in the talent market
SELECT Tb1.experience_level, Tb1.job_title, AvgSalary2023, AvgSalary2024, ROUND(((AvgSalary2024 - AvgSalary2023) / AvgSalary2023) * 100, 2) AS YOY FROM
  (SELECT experience_level, job_title, AVG(salary_in_usd) AS AvgSalary2023
  FROM salaries
  WHERE work_year = 2023
  GROUP BY 1,2) Tb1
INNER JOIN
  (SELECT experience_level, job_title, AVG(salary_in_usd) AS AvgSalary2024
  FROM salaries
  WHERE work_year = 2024
  GROUP BY 1,2) Tb2
ON Tb1.experience_level = Tb2.experience_level AND Tb1.job_title = Tb2.job_title
ORDER BY 5 DESC;