Select * From NetflixTitles

-- Remove duplicates
WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY show_id ORDER BY (SELECT NULL)) AS RowNum
    FROM NetflixTitles
)
DELETE FROM CTE WHERE RowNum > 1;

-- Handle missing values
Select * From NetflixTitles
Select * From DisneyPlusTitles

UPDATE NetflixTitles
SET director = 'Unknown'
WHERE director = 'unknown'

UPDATE NetflixTitles
SET cast = 'Unknown'
WHERE cast IS NULL;

UPDATE NetflixTitles
SET country = 'Unknown'
WHERE country IS NULL;

---------------------------------------------
Select LEN(Cast)
From NetflixTitles

SELECT LEN(LTRIM(RTRIM(cast))) AS cast_length
FROM NetflixTitles
ORDER BY cast_length DESC;

Select * From NetflixTitles

SELECT
    country,
    COUNT(CASE WHEN type = 'Movie' THEN 1 END) AS num_movies,
    COUNT(CASE WHEN type = 'TV Show' THEN 1 END) AS num_tv_shows
FROM
    NetflixTitles
WHERE 
    country <> 'Unknown'
GROUP BY
    country
ORDER BY
    num_movies DESC, num_tv_shows DESC;

USE DATA_ANALYSIS
IF OBJECT_ID('tempdb..#DirectorSplits') IS NOT NULL
    DROP TABLE #DirectorSplits;

CREATE TABLE #DirectorSplits (
    show_id VARCHAR(10),
    director1 VARCHAR(208),
    director2 VARCHAR(208)
);

Select * From #DirectorSplits

INSERT INTO #DirectorSplits (show_id, director1, director2)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', director) > 0 THEN SUBSTRING(director, 1, CHARINDEX(',', director) - 1) ELSE director END AS director1,
    CASE WHEN CHARINDEX(',', director, CHARINDEX(',', director) + 1) > 0 THEN SUBSTRING(director, CHARINDEX(',', director) + 1, CHARINDEX(',', director, CHARINDEX(',', director) + 1) - CHARINDEX(',', director) - 1) ELSE NULL END AS director2
    --CASE WHEN CHARINDEX(',', director, CHARINDEX(',', director, CHARINDEX(',', director) + 1) + 1) > 0 THEN SUBSTRING(director, CHARINDEX(',', director, CHARINDEX(',', director, CHARINDEX(',', director) + 1) + 1) + 1, LEN(director) - CHARINDEX(',', director, CHARINDEX(',', director, CHARINDEX(',', director) + 1) + 1)) ELSE NULL END AS director3
FROM NetflixTitles;

Select * From #DirectorSplits

UPDATE nt
SET nt.director1 = ds.director1,
    nt.director2 = ds.director2
FROM NetflixTitles nt
JOIN #DirectorSplits ds ON nt.show_id = ds.show_id;

Select show_id,director,director1,director2
From NetflixTitles

ALTER TABLE NetflixTitles
DROP COLUMN director;

Select * From NetflixTitles

EXEC sp_rename 'NetflixTitles.director1', 'director';
EXEC sp_rename 'NetflixTitles.director2', 'director1';

UPDATE NetflixTitles
SET director1 = 'NA'
WHERE director1 is null

Select COUNT(director1)
from NetflixTitles
Where director1 = 'NA'

Select COUNT(director1)
from NetflixTitles
Where director1 <> 'NA'

----------------------------
IF OBJECT_ID('tempdb..#CategorySplits') IS NOT NULL
    DROP TABLE #CategorySplits;
CREATE TABLE #CategorySplits (
    show_id VARCHAR(10),
    Listed_in_category1 VARCHAR(50),
    Listed_in_category2 VARCHAR(50),
    Listed_in_category3 VARCHAR(50)
);

INSERT INTO #CategorySplits (show_id, Listed_in_category1, Listed_in_category2, Listed_in_category3)
SELECT 
    show_id,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 3) AS Listed_in_category1,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 2) AS Listed_in_category2,
    PARSENAME(REPLACE(Listed_In, ', ', '.'), 1) AS Listed_in_category3
FROM NetflixTitles;

Select * From #CategorySplits

Update #CategorySplits
Set Listed_in_category1 = Listed_in_category2 
Where Listed_in_category1 is NUll

Update #CategorySplits
Set Listed_in_category2 = Listed_in_category3
Where Listed_in_category2 is NUll

Update #CategorySplits
Set Listed_in_category2 = 'NA'
Where Listed_in_category2 = Listed_in_category1

Update #CategorySplits
Set Listed_in_category3 = 'NA'
Where Listed_in_category3 = Listed_in_category2

Update #CategorySplits
Set Listed_in_category2 = Listed_in_category3
Where Listed_in_category2 = 'NA' and Listed_in_category3 <> 'NA'

Update #CategorySplits
Set Listed_in_category3 = 'NA'
Where Listed_in_category3 = Listed_in_category2

--------------------------------------------------
Select * From NetflixTitles

ALTER TABLE NetflixTitles
ADD Listed_in_category1 VARCHAR(50),
    Listed_in_category2 VARCHAR(50),
    Listed_in_category3 VARCHAR(50);


UPDATE nt
SET nt.Listed_in_category1 = cs.Listed_in_category1,
    nt.Listed_in_category2 = cs.Listed_in_category2,
    nt.Listed_in_category3 = cs.Listed_in_category3
FROM NetflixTitles nt
JOIN #CategorySplits cs ON nt.show_id = cs.show_id;

Select * From NetflixTitles

ALTER TABLE NetflixTitles
DROP COLUMN listed_in;

---------------------------------------------------------------------
-- Drop the existing #CastSplits table if it exists
IF OBJECT_ID('tempdb..#CastSplits') IS NOT NULL
    DROP TABLE #CastSplits;

-- Recreate the #CastSplits table with the appropriate column lengths
CREATE TABLE #CastSplits (
    show_id VARCHAR(10),
    cast1 VARCHAR(208),
    cast2 VARCHAR(208),
    cast3 VARCHAR(1000)--,
    --cast4 VARCHAR(1000)
);

-- Insert split cast members into the temporary table
INSERT INTO #CastSplits (show_id, cast1, cast2, cast3)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', cast) > 0 THEN 
             LEFT(cast, CHARINDEX(',', cast) - 1) 
         ELSE cast 
    END AS cast1,
    CASE WHEN CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) > 0 THEN 
             SUBSTRING(cast, CHARINDEX(',', cast) + 1, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) - CHARINDEX(',', cast) - 1) 
         ELSE NULL 
    END AS cast2,
    CASE WHEN CHARINDEX(',', cast, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) + 1) > 0 THEN 
             SUBSTRING(cast, CHARINDEX(',', cast, CHARINDEX(',', cast, CHARINDEX(',', cast) + 1) + 1) + 1, LEN(cast) - CHARINDEX(',', REVERSE(cast))) 
         ELSE NULL 
    END AS cast3
FROM NetflixTitles;

-- View the data in the temporary table
SELECT * FROM #CastSplits
order by show_id asc

ALTER TABLE NetflixTitles
Drop Column cast1,
    cast2 

ALTER TABLE NetflixTitles
ADD cast1 VARCHAR(208),
    cast2 VARCHAR(208);
    --cast3 VARCHAR(1000);

Select * From NetflixTitles

UPDATE nt
SET nt.cast1 = cs.cast1,
    nt.cast2 = cs.cast2
FROM NetflixTitles nt
JOIN #CastSplits cs ON nt.show_id = cs.show_id;

Update NetflixTitles
set cast2 = 'Unknown'
where cast1 = 'Unknown'

Update NetflixTitles
set cast2 = 'NA'

SELECT *
FROM #CastSplits
WHERE cast2 IS NULL AND cast3 IS NOT NULL;

Update #CastSplits
set cast3 = 'NULL'
WHERE cast2 = cast3

ALTER TABLE #CastSplits
Drop Column cast1,
    cast2 

ALTER TABLE #CastSplits
ADD cast4 VARCHAR(1000); -- Adjust the length as needed

Select * From #CastSplits
order by show_id

UPDATE #CastSplits
SET 
    cast4 = CASE WHEN CHARINDEX(',', cast3) > 0 THEN 
                 SUBSTRING(cast3, CHARINDEX(',', cast3) + 1, LEN(cast3) - CHARINDEX(',', cast3))
               ELSE NULL 
           END,
    cast3 = CASE WHEN CHARINDEX(',', cast3) > 0 THEN 
                 LEFT(cast3, CHARINDEX(',', cast3) - 1)
               ELSE cast3 
           END;

ALTER TABLE NetflixTitles
ADD cast3 VARCHAR(208)

Select * From NetflixTitles

UPDATE nt
SET nt.cast3 = cs.cast3
FROM NetflixTitles nt
JOIN #CastSplits cs ON nt.show_id = cs.show_id;


Update NetflixTitles
set cast2 = 'Unknown' 
WHERE cast1 = 'Unknown'

Update NetflixTitles
set cast3 = 'Unknown' 
WHERE cast2 = 'Unknown'

Select * From NetflixTitles

Update NetflixTitles
set cast2 = 'NA'
where cast1 <> 'Unknown' and cast2 is NULL

Select * from NetflixTitles
where cast1 <> 'Unknown' and cast2 is NULL

Select * From NetflixTitles
where cast1 = 'Unknown' 

Update NetflixTitles
set cast3 = 'Unknown'
where cast1 = 'Unknown' and cast2 = 'Unknown'

Select * from NetflixTitles
where cast2 = 'NA'

Update NetflixTitles
set cast3 = 'NA'
where cast2 = 'NA'

Select * from NetflixTitles
where cast3 IS NULL and cast2 <> 'Unknown' and cast2 <> 'NA' 

Update NetflixTitles
set cast3 = 'NA'
where cast3 IS NULL and cast2 <> 'Unknown' and cast2 <> 'NA'

Alter table NetflixTitles
drop column cast

Select * From NetflixTitles
where duration IS NULL

update NetflixTitles
set date_added = 'Unknown'
where date_added IS NULL

UPDATE NetflixTitles
SET date_added = 
    CASE 
        WHEN release_year = 2013 THEN '2013-01-01' -- Assuming January 1st of the year
        WHEN release_year = 2018 THEN '2018-01-01'
        WHEN release_year = 2003 THEN '2003-01-01'
        WHEN release_year = 2008 THEN '2008-01-01'
		WHEN release_year = 2010 THEN '2010-01-01'
		WHEN release_year = 2012 THEN '2012-01-01'
		WHEN release_year = 2016 THEN '2016-01-01'
		WHEN release_year = 2015 THEN '2015-01-01'
	END
WHERE date_added IS NULL;

UPDATE NetflixTitles
SET rating = 'Unknown'
where rating IS NULL

UPDATE NetflixTitles
SET duration = rating
where duration IS NULL

UPDATE NetflixTitles
SET rating = 'Unknown'
where duration = rating


SELECT rating, COUNT(*) AS rating_count
FROM NetflixTitles
GROUP BY rating;
--------------------------------------------------------
SELECT country, COUNT(*) AS rating_count
FROM NetflixTitles
GROUP BY country;

-- Drop the existing #CountrySplits table if it exists
IF OBJECT_ID('tempdb..#CountrySplits') IS NOT NULL
    DROP TABLE #CountrySplits;

-- Recreate the #CountrySplits table with the appropriate column lengths
CREATE TABLE #CountrySplits (
    show_id VARCHAR(10),
    country1 VARCHAR(100),
    country2 VARCHAR(100),
    country3 VARCHAR(100),
    country4 VARCHAR(100) -- Add more columns as needed
);

select * from #CountrySplits

-- Insert split country values into the temporary table
INSERT INTO #CountrySplits (show_id, country1, country2, country3, country4)
SELECT 
    show_id,
    CASE WHEN CHARINDEX(',', country) > 0 THEN 
             LEFT(country, CHARINDEX(',', country) - 1) 
         ELSE country 
    END AS country1,
    CASE WHEN CHARINDEX(',', country, CHARINDEX(',', country) + 1) > 0 THEN 
             SUBSTRING(country, CHARINDEX(',', country) + 1, CHARINDEX(',', country, CHARINDEX(',', country) + 1) - CHARINDEX(',', country) - 1) 
         ELSE NULL 
    END AS country2,
    CASE WHEN CHARINDEX(',', country, CHARINDEX(',', country, CHARINDEX(',', country) + 1) + 1) > 0 THEN 
             SUBSTRING(country, CHARINDEX(',', country, CHARINDEX(',', country, CHARINDEX(',', country) + 1) + 1) + 1, LEN(country) - CHARINDEX(',', REVERSE(country))) 
         ELSE NULL 
    END AS country3,
    NULL AS country4 -- Initialize country4 column to NULL
FROM NetflixTitles;

-- View the data in the temporary table
SELECT * FROM #CountrySplits
ORDER BY show_id;


SELECT * FROM #CountrySplits
where country2 is null and country3 is not null
ORDER BY show_id;

update #CountrySplits
set country2 = country3
where country2 is null and country3 is not null

Alter table #CountrySplits
drop column country3

Update #CountrySplits
set country2 = 'NA'
where country2 is null

SELECT country2, COUNT(*) AS rating_count
FROM #CountrySplits
GROUP BY country2;

SELECT * FROM #CountrySplits
where country2 not in ('NA', 'Unknown')

SELECT country1, COUNT(*) AS rating_count
FROM #CountrySplits
GROUP BY country1;

select *
FROM #CountrySplits
where country1 = 'NA' and country2 = 'France'
GROUP BY country1;

update #CountrySplits
set country1 = 'NA'
where country1 = ' ' 

Alter table #CountrySplits
drop column country2

select * From #CountrySplits
Where country1 = 'NA'

Update #CountrySplits
set country1 = 'Unknown'
where show_id = 's194'

ALTER TABLE NetflixTitles
ADD country1 VARCHAR(208)

Select * From NetflixTitles

UPDATE nt
SET nt.country1 = cs.country1
FROM NetflixTitles nt
JOIN #CountrySplits cs ON nt.show_id = cs.show_id;

Alter table NetflixTitles
drop column country

EXEC sp_rename 'NetflixTitles.country1', 'country';
----------------------------------------------------
Select * From NetflixTitles
where type = 'Movie'

ALTER TABLE NetflixTitles
ADD [duration_in_min] VARCHAR(10) NULL;

ALTER TABLE NetflixTitles
ADD [Total_Seasons] VARCHAR(10) NULL;

update NetflixTitles
set Total_Seasons = duration
where  type <> 'Movie'

Select * From NetflixTitles
where Total_Seasons is null

Alter table NetflixTitles
drop column duration

Select LEN(duration_in_min), duration_in_min
from NetflixTitles
where duration_in_min <> 'NA'

SELECT LEN(REPLACE(duration_in_min, ' min', '')) AS duration_length, REPLACE(duration_in_min, ' min', '') AS duration
FROM NetflixTitles
WHERE duration_in_min <> 'NA';

UPDATE NetflixTitles
SET duration_in_min = REPLACE(duration_in_min, ' min', '')
WHERE duration_in_min <> 'NA';

---------------------------------------------------------------
CREATE TABLE [dbo].[NetflixTitles_Movies](
	[show_id] [varchar](10) NOT NULL,
	[type] [varchar](10) NOT NULL,
	[title] [varchar](104) NOT NULL,
	[date_added] [date] NULL,
	[release_year] [int] NOT NULL,
	[rating] [varchar](8) NULL,
	[director] [varchar](100) NULL,
	[director1] [varchar](100) NULL,
	[Listed_in_category1] [varchar](50) NULL,
	[Listed_in_category2] [varchar](50) NULL,
	[Listed_in_category3] [varchar](50) NULL,
	[cast1] [varchar](208) NULL,
	[cast2] [varchar](208) NULL,
	[cast3] [varchar](208) NULL,
	[country] [varchar](208) NULL,
	[duration_in_min] [int] NULL,
	)

Select * From NetflixTitles
where duration_in_min <> 'NA'

INSERT INTO NetflixTitles_Movies (show_id, type, title, date_added, release_year, rating, director, director1, Listed_in_category1, Listed_in_category2, Listed_in_category3, cast1, cast2, cast3, country, duration_in_min)
SELECT 
    show_id,
    type,
    title,
    date_added,
    release_year,
    rating,
    director,
    director1,
    Listed_in_category1,
    Listed_in_category2,
    Listed_in_category3,
    cast1,
    cast2,
    cast3,
    country,
    CAST(duration_in_min AS int) -- Convert duration_in_min to int
FROM NetflixTitles
WHERE duration_in_min <> 'NA' and Type= 'Movies';

Select LEN(Total_Seasons), Total_Seasons
From NetflixTitles
where Total_Seasons <> 'NA'

SELECT LEFT(Total_Seasons, 1) AS first_letter, Total_Seasons
FROM NetflixTitles
WHERE Total_Seasons <> 'NA';

UPDATE NetflixTitles
SET Total_Seasons = LEFT(Total_Seasons, 1)
WHERE Total_Seasons <> 'NA';

Select * From NetflixTitles
------------------------------------------------------------------
CREATE TABLE [dbo].[NetflixTitles_TV_Shows](
	[show_id] [varchar](10) NOT NULL,
	[type] [varchar](10) NOT NULL,
	[title] [varchar](104) NOT NULL,
	[date_added] [date] NULL,
	[release_year] [int] NOT NULL,
	[rating] [varchar](8) NULL,
	[director] [varchar](100) NULL,
	[director1] [varchar](100) NULL,
	[Listed_in_category1] [varchar](50) NULL,
	[Listed_in_category2] [varchar](50) NULL,
	[Listed_in_category3] [varchar](50) NULL,
	[cast1] [varchar](208) NULL,
	[cast2] [varchar](208) NULL,
	[cast3] [varchar](208) NULL,
	[country] [varchar](208) NULL,
	[Total_Seasons] [int] NULL,
	)

Select * From NetflixTitles
where Total_Seasons <> 'NA'

INSERT INTO NetflixTitles_TV_Shows (show_id, type, title, date_added, release_year, rating, director, director1, Listed_in_category1, Listed_in_category2, Listed_in_category3, cast1, cast2, cast3, country, Total_Seasons)
SELECT 
    show_id,
    type,
    title,
    date_added,
    release_year,
    rating,
    director,
    director1,
    Listed_in_category1,
    Listed_in_category2,
    Listed_in_category3,
    cast1,
    cast2,
    cast3,
    country,
    CAST(Total_Seasons AS int) -- Convert Total_Seasons to int
FROM NetflixTitles
WHERE Total_Seasons <> 'NA' and Type <> 'Movies';

Select * From NetflixTitles_TV_Shows
Select * From NetflixTitles_Movies
-----------------------------------------------
/* Data Analysis */

--1. Trends_Over_Time: 
SELECT 
    release_year,
    COUNT(*) AS num_shows
FROM 
    NetflixTitles_TV_Shows
GROUP BY 
    release_year
ORDER BY 
    release_year desc;

--2. Popular Categories
SELECT genre, COUNT(*) AS num_shows
FROM (
    SELECT Listed_in_category1 AS genre FROM NetflixTitles_TV_Shows
    UNION ALL
    SELECT Listed_in_category2 AS genre FROM NetflixTitles_TV_Shows
    UNION ALL
    SELECT Listed_in_category3 AS genre FROM NetflixTitles_TV_Shows
) AS combined_genres
WHERE genre IS NOT NULL and genre <> 'NA'
GROUP BY genre
ORDER BY num_shows DESC;

--3. Regional_Preferences

SELECT 
    country,
    COUNT(*) AS num_shows
FROM 
    NetflixTitles_TV_Shows
GROUP BY 
    country
ORDER BY 
    num_shows DESC;

--4. Seasons_Analysis

SELECT 
    Total_Seasons,
    COUNT(*) AS num_shows
FROM 
    NetflixTitles_TV_Shows
GROUP BY 
    Total_Seasons
ORDER BY 
    Total_Seasons;

--5. Date Added Trends
SELECT 
    YEAR(date_added) AS year_added,
    MONTH(date_added) AS month_added,
    COUNT(*) AS num_shows
FROM 
    NetflixTitles_TV_Shows
GROUP BY 
    YEAR(date_added), MONTH(date_added)
ORDER BY 
    year_added, month_added;

--6. Rating Distribution
SELECT 
    rating,
    COUNT(*) AS num_shows
FROM 
    NetflixTitles_TV_Shows
GROUP BY 
    rating
ORDER BY 
    num_shows DESC;

--7. Cast Analysis
SELECT 
    cast_member,
    COUNT(*) AS num_shows
FROM (
    SELECT CAST(cast1 AS VARCHAR(MAX)) AS cast_member FROM NetflixTitles_TV_Shows WHERE cast1 IS NOT NULL
    UNION ALL
    SELECT CAST(cast2 AS VARCHAR(MAX)) AS cast_member FROM NetflixTitles_TV_Shows WHERE cast2 IS NOT NULL
    UNION ALL
    SELECT CAST(cast3 AS VARCHAR(MAX)) AS cast_member FROM NetflixTitles_TV_Shows WHERE cast3 IS NOT NULL
) AS combined_cast
WHERE
	cast_member not in ('NA','Unknown')
GROUP BY 
    cast_member
ORDER BY 
    num_shows DESC;

-------------------------------------------------------------------
--1. Release Year Distribution

SELECT 
    release_year,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    release_year
ORDER BY 
    release_year desc;

--2. Popular Genre

SELECT 
    Listed_in_category1 AS genre,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    Listed_in_category1
ORDER BY 
    num_movies DESC;

--3. Top Director and movies

SELECT 
    director,
    COUNT(*) AS num_movies
FROM (
    SELECT director FROM DisneyPlusTitles_Movies WHERE director IS NOT NULL AND director <> 'Unknown'
    UNION ALL
    SELECT director1 FROM DisneyPlusTitles_Movies WHERE director1 IS NOT NULL AND director1 <> 'Unknown'
) AS combined_directors
WHERE
	director <> 'NA'
GROUP BY 
    director
ORDER BY 
    num_movies DESC;

--4. Regional Preference

SELECT 
    country,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    country
ORDER BY 
    num_movies DESC;

--5. Duration Analysis
SELECT 
    duration_in_min,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    duration_in_min
ORDER BY 
    duration_in_min desc;

SELECT 
    duration_in_min,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    duration_in_min
ORDER BY 
    num_movies desc;

--6. Date Added Trend
SELECT 
    YEAR(date_added) AS year_added,
    MONTH(date_added) AS month_added,
    COUNT(*) AS num_movies
FROM 
    NetflixTitles_Movies
GROUP BY 
    YEAR(date_added), MONTH(date_added)
ORDER BY 
    year_added, month_added;