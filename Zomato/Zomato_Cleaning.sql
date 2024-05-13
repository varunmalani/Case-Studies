-- https://www.kaggle.com/datasets/sanjanchaudhari/zomato-data

CREATE TABLE zomato (
	a INTEGER NOT NULL, 
	name VARCHAR(255) NOT NULL, 
	online_order VARCHAR(255) NOT NULL, 
	book_table VARCHAR(255) NOT NULL, 
	rating DECIMAL(4,2) NOT NULL, 
	votes INTEGER NOT NULL, 
	location VARCHAR(255) NOT NULL, 
	rest_type VARCHAR(255), 
	dish_liked VARCHAR(255), 
	cuisines VARCHAR(255), 
	approx_cost DECIMAL(8,2) NOT NULL, 
	type VARCHAR(255)
);

SET GLOBAL local_infile=1;

LOAD DATA LOCAL INFILE 'file_path'
INTO TABLE zomato
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

SELECT * FROM zomato;

-- Fetching only the column names from the table zomato
SELECT COLUMN_NAME FROM information_schema.columns
WHERE TABLE_NAME = 'zomato'


-- Cleaning the data

-- We do not required column a, hence we can drop the column
ALTER TABLE zomato DROP COLUMN a;

-- Replace the BLANK with suitable values
SELECT GROUP_CONCAT(
	CONCAT('SUM(CASE WHEN `', COLUMN_NAME, '`='''' THEN 1 ELSE 0 END) AS `', COLUMN_NAME, '`')
) INTO @ZomatoTblSummary
FROM information_schema.columns
WHERE TABLE_NAME = 'zomato';

SELECT @ZomatoTblSummary;

SET @ZomatoTblSummary = CONCAT('select ', @ZomatoTblSummary,' from zomato');

PREPARE smt FROM  @ZomatoTblSummary;
EXECUTE  smt ;
DEALLOCATE  PREPARE smt;


SELECT * FROM zomato;