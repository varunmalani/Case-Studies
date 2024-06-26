CREATE TABLE playstore (
	App VARCHAR(255) NOT NULL, 
	Category VARCHAR(255) NOT NULL, 
	Rating DECIMAL(4,2) NOT NULL, 
	Reviews INTEGER NOT NULL, 
	Size VARCHAR(255) NOT NULL, 
	Installs INTEGER NOT NULL, 
	Type VARCHAR(255) NOT NULL, 
	Price DECIMAL(4,2) NOT NULL, 
	Content_Rating VARCHAR(255) NOT NULL, 
	Genres VARCHAR(255) NOT NULL, 
	Last_Updated DATE NOT NULL, 
	Current_Ver VARCHAR(255) NOT NULL, 
	Android_Ver VARCHAR(255) NOT NULL
);

-- mysql -uroot -p --local-infile -> Run in terminal and then load the data

LOAD DATA LOCAL INFILE 'file_path'
INTO TABLE playstore
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

-- You're working as a market analyst for a mobile app development company. Your task is to identify the most promising categories (TOP 5) for launching new free apps based on their average ratings.
SELECT Category, ROUND(AVG(rating), 2) AS AvgRating FROM playstore
GROUP BY Category
ORDER BY 2 DESC
LIMIT 5;


--  As a business strategist for a mobile app company, your objective is to pin-point the 3 categories that generate the most revenue from paid apps. This calculation is based on the product of the app price and its number of installations.
SELECT Category, ROUND(SUM(Installs * Price), 2) AS TotalRevenue FROM playstore
WHERE Type = 'Paid'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;


-- As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category. This information will help the company understand the distribution of gaming apps across different categories.
SELECT *, ROUND((AvgCnt / (SELECT COUNT(*) FROM playstore)), 2) * 100 AS AvgMraketShare FROM
    (SELECT Category, COUNT(*) AS AvgCnt FROM playstore
    GROUP BY Category) Tb1
ORDER BY 2 DESC;


-- As a data analyst at a mobile app-focused market research firm, you'll recommend whether the company should develop paid or free apps for each category based on the ratings of that category.
SELECT Category, Type, AvgRating FROM
    (SELECT Category, Type, ROUND(AVG(Rating) , 2) AS AvgRating,
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY  ROUND(AVG(Rating) , 2) DESC) AS RatRank
    FROM playstore
    GROUP BY Category, Type) Tb1
WHERE RatRank = 1;


-- Suppose you're a database administrator, your databases have been hacked and hackers are changing the price of certain apps on the database, its taking long for IT team to neutralize the hack, however you as a responsible manager don't want your data to be changed. Create some measures where the changes in price can be recorded as you cant stop hackers from making changes.

-- Creating a duplicate table which stores all the values of playstore
CREATE TABLE playstore_backup AS
SELECT * FROM playstore;

SELECT * FROM playstore_backup;

-- If we want to get to know if any event has happened then we will be using triggers
-- First creating a table which stores the data where we can keep a track as to which app price was updated and at what time
DROP TABLE IF EXISTS app_price_change;

CREATE TABLE app_price_change(
    App VARCHAR(255),
    OldPrice DECIMAL(4,2),
    NewPrice DECIMAL(4,2),
    UpdatedTime DATETIME
);

DELIMITER //
CREATE TRIGGER app_price_change_trigger
-- This is basically if there is an update in the price of the backup table then a row is inserted into app_price_change table
DELIMITER //
CREATE TRIGGER app_price_change_trigger
AFTER UPDATE ON playstore_backup
FOR EACH ROW
BEGIN
    IF OLD.Price <> NEW.Price THEN
        INSERT INTO app_price_change(App, OldPrice, NewPrice, UpdatedTime)
        VALUES(OLD.App, OLD.Price, NEW.Price, CURRENT_TIMESTAMP);
    END IF;
END //
DELIMITER ;

UPDATE playstore_backup
SET Price = 2.5
WHERE App = 'Photo Editor & Candy Camera & Grid & ScrapBook'

UPDATE playstore_backup
SET Price = 3.2
WHERE App = 'Photo Editor & Candy Camera & Grid & ScrapBook'

SELECT * FROM playstore_backup
WHERE App = 'Photo Editor & Candy Camera & Grid & ScrapBook'

-- Now viewing the the changed price table
SELECT * FROM app_price_change;

-- Your IT team have neutralized the threat, however hackers have made some changes in the prices, but becasue of your measure you have noted the changes, now you want correct data to be inserted into the database.

-- Drop the trigger as we do not need the trigger any more because the threat has been neutralized
DROP TRIGGER app_price_change_trigger;

UPDATE playstore_backup pb
INNER JOIN app_price_change apc ON pb.App = apc.App 
SET pb.Price = (SELECT OldPrice FROM app_price_change ORDER BY UpdatedTime LIMIT 1);

SELECT * FROM playstore_backup
WHERE App = 'Photo Editor & Candy Camera & Grid & ScrapBook'

-- Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when developing the recommendor system from the data, he asssigned you the task to clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank.

-- Here the total ; values is 1
SELECT MAX(LENGTH(Genres) - LENGTH(REPLACE(Genres, ';', ''))) AS max_semicolon_count FROM playstore;

SELECT *,
CASE 
	WHEN Genres LIKE '%;%' THEN SUBSTRING(Genres, 1, (LOCATE(';', Genres)) - 1)
	ELSE Genres
END AS Genres_1,
CASE 
	WHEN Genres LIKE '%;%' THEN SUBSTRING(Genres, (LOCATE(';', Genres)) + 1)
	ELSE ''
END AS Genres_2
from playstore;

-- Your senior manager wants to know which apps are not performing as par in their particular category, however he is not interested in handling too many files or list for every category and he assigned, your task is of creating a dynamic tool where he can input a category of apps he is interested in and your tool that provides real-time feedback by displaying apps within that category that have ratings lower than the average rating for that specific category.
DELIMITER //
CREATE PROCEDURE CatRatLow (IN Cat VARCHAR(255))
BEGIN
SELECT p.*, Tb1.AvgCatRating FROM playstore p
INNER JOIN
(SELECT Category, ROUND(AVG(Rating), 2) AvgCatRating FROM playstore
WHERE Category = Cat
GROUP BY Category) AS Tb1
ON p.Category = Tb1.Category
WHERE p.Rating < Tb1.AvgCatRating;
END //
DELIMITER ;

CALL CatRatLow('FINANCE');