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

-- You're working as a market analyst for a mobile app development company. Your task is to identify the most promising categories(TOP 5) for launching new free apps based on their average ratings.
SELECT Category, ROUND(AVG(rating), 2) AS AvgRating FROM playstore
GROUP BY Category
ORDER BY 2 DESC
LIMIT 5;


--  As a business strategist for a mobile app company, your objective is to pinpoint the three categories that generate the most revenue from paid apps. This calculation is based on the product of the app price and its number of installations.
SELECT Category, ROUND(SUM(Installs * Price), 2) AS TotalRevenue FROM playstore
WHERE Type = 'Paid'
GROUP BY 1
ORDER BY 2 DESC
LIMIT 3;


-- As a data analyst for a gaming company, you're tasked with calculating the percentage of games within each category. This information will help the company understand the distribution of gaming apps across different categories
SELECT *, ROUND((AvgCnt / (SELECT COUNT(*) FROM playstore)), 2) * 100 AS AvgMraketShare FROM
    (SELECT Category, COUNT(*) AS AvgCnt FROM playstore
    GROUP BY Category) Tb1
ORDER BY 2 DESC;


-- As a data analyst at a mobile app-focused market research firm, you'll recommend whether the company should develop paid or free apps for each category based on the  ratings of that category.
SELECT Category, Type, AvgRating FROM
    (SELECT Category, Type, ROUND(AVG(Rating) , 2) AS AvgRating,
    DENSE_RANK() OVER (PARTITION BY Category ORDER BY  ROUND(AVG(Rating) , 2) DESC) AS RatRank
    FROM playstore
    GROUP BY Category, Type) Tb1
WHERE RatRank = 1;


-- Suppose you're a database administrator, your databases have been hacked  and hackers are changing price of certain apps on the database , its taking long for IT team to neutralize the hack , however you as a responsible manager  don't want your data to be changed, create some measures where the changes in price can be recorded as you cant stop hackers from making changes

-- Creating a duplicate table which stores all the values of playstore
CREATE TABLE playstore_backup AS
SELECT * FROM playstore;

SELECT * FROM playstore_backup;

-- If we want to get to know if any event has happened then we will be using triggers
-- First creating a table which stores the data where we can keep a track as to which app price was updated and at what time
CREATE TABLE app_price_change(
    App VARCHAR(255),
    OldPrice DECIMAL(4,2),
    NewPrice DECIMAL(4,2),
    UpdatedTime DATETIME
);

DELIMITER //
CREATE TRIGGER app_price_change_trigger
-- This is basically if there is an update in the price of the backup table then a row is inserted into app_price_change table
AFTER UPDATE ON playstore_backup 
FOR EACH ROW
BEGIN
    INSERT INTO app_price_change(App, OldPrice, NewPrice, UpdatedTime)
    VALUES(OLD.App, OLD.OldPrice, NEW.NewPrice, CURRENT_TIMESTAMP);
END //
DELIMITER ;

DROP TRIGGER app_price_change_trigger

-- your IT team have neutralize the threat,  however hacker have made some changes in the prices, but becasue of your measure you have noted the changes , now you want correct data to be inserted into the database.


-- As a data person you are assigned the task to investigate the correlation between two numeric factors: app ratings and the quantity of reviews.


-- Your boss noticed  that some rows in genres columns have multiple generes in them, which was creating issue when developing the  recommendor system from the data he/she asssigned you the task to clean the genres column and make two genres out of it, rows that have only one genre will have other column as blank.


-- Your senior manager wants to know which apps are  not performing as par in their particular category, however he is not interested in handling too many files or list for every  category and he/she assigned  you with a task of creating a dynamic tool where he/she  can input a category of apps he/she  interested in and your tool then provides real-time feedback by displaying apps within that category that have ratings lower than the average rating for that specific category.


-- What is duration time and fetch time.
-- Duration Time :- Duration time is how long  it takes system to completely understand the instructions given  from start to end  in proper order  and way.
-- Fetch Time :- Once the instructions are completed , fetch ttime is like the time it takes for  the system to hand back the results, it depend on how quickly  ths system Can find  and bring back what you asked for.            
-- if query is simple  and have  to show large valume of data, fetch time will be large, If query is complex duration time will be large.
-- Duration Time: Imagine you type in your search query, such as "fiction books," and hit enter. The duration time is the period it takes for the system to process your request from the moment you hit enter until it comprehensively understands what you're asking for and how to execute it. This includes parsing your query,  analyzing keywords, and preparing to fetch the relevant data.
-- Fetch Time: Once the system has fully understood your request, it begins fetching the results. Fetch time refers to the time it takes for the system to retrieve and present the search results back to you.
-- For instance, if your query is straightforward but requires fetching a large volume of data (like all fiction books in the library), the fetch time may be prolonged as the system sifts through extensive records to compile the results. Conversely, if your query is complex involving multiple criteria or parameters, the duration time might be longer as the system processes the intricacies of your request before initiating the fetch process.



