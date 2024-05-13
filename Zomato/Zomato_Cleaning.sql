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

-- Newly opened restaurants where customers have not left any reviews
SELECT * FROM zomato
WHERE rating = 0.0 AND dish_liked = 'NA' AND votes = 0;

UPDATE zomato
SET dish_liked = 'No dishes tried'
WHERE rating = 0.0 AND dish_liked = 'NA' AND votes = 0;

UPDATE zomato
SET dish_liked = 'No dishes liked yet :('
WHERE dish_liked = 'NA';

-- Over here we see that there are dishes liked, votes > 0 but there is no rating given, hence we will return the avg rating based on the location and rest_type
SELECT * FROM zomato
WHERE rating <> 0.0 AND (dish_liked <> 'No dishes tried' OR dish_liked <> 'NA') AND votes <> 0;

SELECT location, rest_type, ROUND(AVG(rating),2) AS AvgRating FROM zomato
WHERE rating <> 0.0 AND (dish_liked <> 'No dishes tried' OR dish_liked <> 'NA') AND votes <> 0
GROUP BY 1,2
ORDER BY 1 DESC,2;

UPDATE zomato
JOIN	(
	SELECT location, rest_type, ROUND(AVG(rating),2) AS AvgRating FROM zomato
	WHERE rating <> 0.0 AND (dish_liked <> 'No dishes tried' OR dish_liked <> 'NA') AND votes <> 0
	GROUP BY location, rest_type
	) AS a 
ON zomato.location = a.location AND zomato.rest_type = a.rest_type
SET zomato.rating = a.AvgRating
WHERE zomato.votes <> 0 AND zomato.dish_liked <> 'NA'

-- If votes are 0 then the rating should be 0
SELECT * FROM zomato where votes = 0 and rating <> 0;

UPDATE zomato
SET rating = 0.0
WHERE votes = 0;

-- Replacing NA values in Type with the 1st value in the rest_type column
SELECT type, rest_type, SUBSTRING_INDEX(rest_type, ',', 1) FROM zomato
WHERE type = 'NA';

UPDATE zomato
SET type = SUBSTRING_INDEX(rest_type, ',', 1)
WHERE type = 'NA'

SELECT DISTINCT type FROM zomato ORDER BY 1;

-- Replacing the relevant Types 
-- Cafes -> Cafe
-- Fine Dining, Casual Dining -> Dine-out
-- Sweet Shop, Desserts -> Dessert Parlor

UPDATE zomato
SET type = 'Cafe'
WHERE type = 'Cafes';

UPDATE zomato
SET type = 'Dine-out'
WHERE type IN ('Fine Dining', 'Casual Dining');

UPDATE zomato
SET type = 'Dessert Parlor'
WHERE type IN ('Sweet Shop', 'Desserts');

-- Cleaned Zomato table
SELECT * FROM zomato;