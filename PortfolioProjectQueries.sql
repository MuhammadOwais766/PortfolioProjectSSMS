SELECT * FROM PortfolioProject..CovidDeaths ORDER BY 3,4

-- SELECT DATA TO BE USED


SELECT location, date, total_cases, new_cases, total_deaths, population FROM PortfolioProject..CovidDeaths ORDER BY 1,2

-- TOTAL CASES VS. TOTAL DEATHS - To see the likely hood of dying from covid in Pakistan


SELECT location, date, total_cases, total_deaths, (CONVERT(float, total_deaths) / NULLIF(CONVERT(float, total_cases), 0)) * 100
AS DeathPercentage FROM PortfolioProject..CovidDeaths WHERE location LIKE '%Pak%' ORDER BY 1,2

-- TOTAL CASES VS. POPULATION - To see what %age of population in Pakistan has contracted COVID


SELECT location, date, population, total_cases, (total_cases/population) * 100 AS InfectedPercentage FROM PortfolioProject..CovidDeaths
WHERE location LIKE '%Pak%' ORDER BY 1,2

-- Which country has the highest Infected rate.


SELECT location, date, population, MAX(total_cases) HighestInfectedCount, MAX((total_cases/population)) * 100 AS InfectedPercentage FROM PortfolioProject..CovidDeaths
GROUP BY location, date, population ORDER BY InfectedPercentage DESC

-- Which countries have the highest death rate due to COVID.


SELECT location, MAX(CAST (total_deaths AS INT)) HighestDeathCount FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL
GROUP BY location ORDER BY HighestDeathCount DESC

--CHECKING DEATHS BY CONTINENT


SELECT location, MAX(CAST (total_deaths AS INT)) HighestDeathCount FROM PortfolioProject..CovidDeaths WHERE continent IS NULL
GROUP BY location ORDER BY HighestDeathCount DESC

--DISPLAYING CONTINENTS WITH THE HIGHEST DEATH COUNT.


SELECT continent, MAX(CAST (total_deaths AS INT)) HighestDeathCount FROM PortfolioProject..CovidDeaths WHERE continent IS NOT NULL
GROUP BY continent ORDER BY HighestDeathCount DESC

--GLOBAL NUMBERS


SELECT  date, SUM(new_cases) AS Total_Cases, SUM(CAST (new_deaths AS INT)) AS Total_Deaths,
SUM(CAST (new_deaths AS INT))/SUM(new_cases) * 100 AS Global_Death_Percentage FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL GROUP BY date ORDER BY 1,2

--TOTAL DEATHS, CASES AND PERCENTAGE OF PEOPLE DEAD FROM COVID


SELECT SUM(new_cases) AS Total_Cases, SUM(CAST (new_deaths AS INT)) AS Total_Deaths,
SUM(CAST (new_deaths AS INT))/SUM(new_cases) * 100 AS Global_Death_Percentage FROM PortfolioProject..CovidDeaths
WHERE continent IS NOT NULL ORDER BY 1,2


--TOTAL POPULATION VS. VACCINATIONS
--PARTITION BY Location (To ensure the SUM does not carry over to a new country) AND ORDER BY location + date (To ensure that the new_vaccinations are incrementing as
--the value increases, instead of completely rounding off the total of the vaccination number)

SELECT death.continent,death.location, death.date, death.population, vac.new_vaccinations,
--Finding out the total number of vaccinated people==>
SUM(CAST (vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Incrementing_Vaccinations
--Finding out how many people in each country are vaccinated compared to the entire population ==>
--(MAX(Incrementing_Vaccinations) / population) * 100 AS Population_Vaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date WHERE death.continent IS NOT NULL ORDER BY 2,3

--USING CTE

WITH PopuVsVacc (continent, location, date, population, new_vaccinations, Incrementing_Vaccinations) AS
(
SELECT death.continent,death.location, death.date, death.population, vac.new_vaccinations,
--Finding out the total number of vaccinated people==>
SUM(CAST (vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Incrementing_Vaccinations
--Finding out how many people in each country are vaccinated compared to the entire population ==>
--(MAX(Incrementing_Vaccinations) / population) * 100 AS Population_Vaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date WHERE death.continent IS NOT NULL 
--ORDER BY 2,3
)
SELECT *, (Incrementing_Vaccinations / population) * 100 AS Population_Vaccinated FROM PopuVsVacc


--USING TEMP TABLES

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar (255), location nvarchar (255), date datetime, population numeric, New_Vaccinations numeric, Incrementing_Vaccinations numeric)


INSERT INTO #PercentPopulationVaccinated
SELECT death.continent,death.location, death.date, death.population, vac.new_vaccinations,
--Finding out the total number of vaccinated people==>
SUM(CAST (vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Incrementing_Vaccinations
--Finding out how many people in each country are vaccinated compared to the entire population ==>
--(MAX(Incrementing_Vaccinations) / population) * 100 AS Population_Vaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date WHERE death.continent IS NOT NULL 
--ORDER BY 2,3

SELECT *, (Incrementing_Vaccinations / population) * 100 AS Population_Vaccinated FROM #PercentPopulationVaccinated


--CREATING VIEW TO STORE DATA FOR VISUALIZATION

CREATE VIEW PercentPopulationVaccinated AS
SELECT death.continent,death.location, death.date, death.population, vac.new_vaccinations,
--Finding out the total number of vaccinated people==>
SUM(CAST (vac.new_vaccinations AS INT)) OVER (PARTITION BY death.location ORDER BY death.location, death.date) AS Incrementing_Vaccinations
--Finding out how many people in each country are vaccinated compared to the entire population ==>
--(MAX(Incrementing_Vaccinations) / population) * 100 AS Population_Vaccinated
FROM PortfolioProject..CovidDeaths death
JOIN PortfolioProject..CovidVaccinations vac ON death.location = vac.location AND death.date = vac.date WHERE death.continent IS NOT NULL 
--ORDER BY 2,3