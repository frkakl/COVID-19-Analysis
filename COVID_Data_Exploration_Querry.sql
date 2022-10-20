--Select Data that we are gonna use
SELECT *
FROM PortfolioProject..Covid_Deaths
ORDER BY 2

SELECT *
FROM PortfolioProject..Covid_Vaccinations
ORDER BY 3,4


--Focusing at Total Cases and Total Deaths 
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM PortfolioProject..Covid_Deaths
ORDER BY 1,2


-- Set divide by zero warnings off
SET ANSI_WARNINGS OFF


-- Change data type because we use it for math operations
ALTER TABLE PortfolioProject..Covid_Deaths
ALTER COLUMN total_cases FLOAT NULL;

ALTER TABLE PortfolioProject..Covid_Deaths
ALTER COLUMN total_deaths FLOAT NULL;

ALTER TABLE PortfolioProject..Covid_Deaths
ALTER COLUMN new_cases FLOAT NULL;

ALTER TABLE PortfolioProject..Covid_Deaths
ALTER COLUMN new_deaths FLOAT NULL;

ALTER TABLE PortfolioProject..Covid_Deaths
ALTER COLUMN population FLOAT NULL;


-- Focusing at Total Cases and Population
SELECT location, date, total_cases, total_deaths, (total_deaths /total_cases)*100 AS Death_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE location = 'Turkey'
ORDER BY 1,2


-- Focusing at Countries with Infection Rate
SELECT location, date, population, total_cases, (total_cases/ population)*100 AS Infection_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE location = 'Turkey'
ORDER BY 1,2


-- Focusing at Countries with Highest Infection Rate 
SELECT location, population, MAX(total_cases) AS Highest_Infection, MAX((total_cases/ population))*100 AS Highest_Infection_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 4 DESC


-- Focusing at Countries with Highest Death Rate
SELECT location, population, MAX(total_deaths) AS Total_Death, MAX((total_deaths/ population))*100 AS Highest_Death_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY 3 DESC


--Global Deaths and Cases
SELECT SUM(new_cases) AS Total_cases , SUM(CAST(new_deaths AS FLOAT)) AS Total_Death, SUM(CAST(new_deaths AS FLOAT))/SUM(new_cases)*100 AS Death_Per_Case_Percentage_in_World
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
--GROUP BY date
ORDER BY 1


-- JOIN TWO TABLE
SELECT D.location, D.date, D.population, V.new_vaccinations
, SUM(CAST(V.new_vaccinations AS FLOAT)) OVER (PARTITION BY V.location ORDER BY D.location, D.date) AS Total_Vaccinated_People
--, (Total_Vaccinated_People/population)*100 -- ERROR let's go to CTE's
FROM PortfolioProject..Covid_Deaths D
JOIN PortfolioProject..Covid_Vaccinations V
	ON D.location = V.location AND D.date= V.date
WHERE D.continent IS NOT NULL 
ORDER BY 1,2 


-- CTE
With Population_and_Vaccination (Location, Date, Population, New_Vaccinations, Total_Vaccinated_People)
as
(
SELECT D.location, D.date, D.population, V.new_vaccinations
, SUM(CAST(V.new_vaccinations AS FLOAT)) OVER (PARTITION BY V.location ORDER BY D.location, D.date) AS Total_Vaccinated_People
--, (Total_Vaccinated_People/population)*100 -- ERROR let's go to CTE's
FROM PortfolioProject..Covid_Deaths D
JOIN PortfolioProject..Covid_Vaccinations V
	ON D.location = V.location AND D.date= V.date
WHERE D.continent IS NOT NULL 
)
Select *, (Total_Vaccinated_People/Population)*100 AS Vaccinated_Percentage
From Population_and_Vaccination
ORDER BY 1,2


--Temp Table 
DROP Table if exists #Vaccinated_Percentage
Create Table #Vaccinated_Percentage
(
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations float,
Total_Vaccinated_People float
)

Insert into #Vaccinated_Percentage
SELECT D.location, D.date, D.population, V.new_vaccinations
, SUM(CAST(V.new_vaccinations AS FLOAT)) OVER (PARTITION BY V.location ORDER BY D.location, D.date) AS Total_Vaccinated_People
--, (Total_Vaccinated_People/population)*100 -- ERROR let's go to CTE's
FROM PortfolioProject..Covid_Deaths D
JOIN PortfolioProject..Covid_Vaccinations V
	ON D.location = V.location AND D.date= V.date
WHERE D.continent IS NOT NULL 

Select *, (Total_Vaccinated_People/Population)*100 AS Vaccinated_Percentage
From #Vaccinated_Percentage
ORDER BY 1,2


-- Creating Views for Power BI
-- 1) Vaccinated Percentage 
Create View Vaccinated_Percentage as
With Vaccinated_Percentage (Location, Date, Population, New_Vaccinations, Total_Vaccinated_People) AS(
SELECT D.location, D.date, D.population, V.new_vaccinations
, SUM(CAST(V.new_vaccinations AS FLOAT)) OVER (PARTITION BY V.location ORDER BY D.location, D.date) AS Total_Vaccinated_People
--, (Total_Vaccinated_People/population)*100 -- ERROR let's go to CTE's
FROM PortfolioProject..Covid_Deaths D
JOIN PortfolioProject..Covid_Vaccinations V
	ON D.location = V.location AND D.date= V.date
WHERE D.continent IS NOT NULL 
)
SELECT *, (Total_Vaccinated_People/Population)*100 AS Vaccinated_Percentage
FROM Vaccinated_Percentage

SELECT *
FROM Vaccinated_Percentage


-- 2) Case and Death by Date Percentage
CREATE VIEW Case_and_Death_Date_Percentage AS
WITH Case_and_Death_Date_Percentage (Date, Total_Cases, Total_Deaths, Death_Percentage) as (
SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as Death_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent is not null 
GROUP BY date
)
SELECT *
FROM Case_and_Death_Date_Percentage


-- 3) Infection Percentage
CREATE VIEW Infection_Percentage AS
WITH Infection_Percentage (Location, Date, Population, Total_Cases, Infection_Percentage) AS (
SELECT location, date, population, total_cases, (total_cases/ population)*100 AS Infection_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
)
SELECT *
FROM Infection_Percentage


-- 4) Highest Infection Percentage
CREATE VIEW Highest_Infection_Percentage AS
WITH Highest_Infection_Percentage (Location, Population, Highest_Infection, Highest_Infection_Percentage) AS (
SELECT location, population, MAX(total_cases) AS Highest_Infection, MAX((total_cases/ population))*100 AS Highest_Infection_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
)
SELECT *
FROM Highest_Infection_Percentage


-- 5) Highest Death Percentage
CREATE VIEW Highest_Death_Percentage AS
WITH Highest_Death_Percentage (Location, Population, Total_Death, Highest_Death_Percentage) AS (
SELECT location, population, MAX(total_deaths) AS Total_Death, MAX((total_deaths/ population))*100 AS Highest_Death_Percentage
FROM PortfolioProject..Covid_Deaths
WHERE continent IS NOT NULL
GROUP BY location, population
)
SELECT *
FROM Highest_Death_Percentage