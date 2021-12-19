SELECT *
FROM PorfolioProject..covid_deaths$
WHERE continent is not null
order by 3,4

--SELECT *
--FROM PorfolioProject..covid_vacc$
--order by 3,4 

-- Select data we are going to use

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PorfolioProject..covid_deaths$
ORDER BY 1,2

-- Evaluating Total Cases vs. Total Deaths 
-- Current likelihood of dying if you contract covid in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PorfolioProject..covid_deaths$
WHERE location like '%states%'
ORDER BY 1,2

-- Total Cases vs Population (United States)
-- Shows what percentage of population contracted Covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as CovidPercentage
FROM PorfolioProject..covid_deaths$
WHERE location like '%states%'
ORDER BY 1,2

-- Evaluate Countries with Highest Infection Rate compared to population
SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases)/population)*100 as PercentPopulationInfected
FROM PorfolioProject..covid_deaths$
--WHERE location like '%states%'
Group by Location, population
ORDER BY PercentPopulationInfected DESC

--Showing countries with highest death count per population
SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PorfolioProject..covid_deaths$
--WHERE location like '%states%'
WHERE continent is not null
Group by Location
ORDER BY TotalDeathCount DESC

-- Per Continent
SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PorfolioProject..covid_deaths$
--WHERE location like '%states%'
WHERE continent is not null
Group by continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS
SELECT date, SUM(new_cases) as totalcases, SUM(cast(new_deaths as int)) as totaldeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
FROM PorfolioProject..covid_deaths$
--WHERE location like '%states%'
Where continent is not null
Group by date
ORDER BY 1,2


-- Looking at total population vs. vaccinations

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date)
From PorfolioProject..covid_deaths$ as dea
JOIN PorfolioProject..covid_vacc$ as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
Order by 2,3

--USE CTE
WITH PopsVsVacc (continent, location, date, population, New_Vaccinations, RollingPpLVaccinated)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
From PorfolioProject..covid_deaths$ as dea
JOIN PorfolioProject..covid_vacc$ as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
--Order by 2,3
)
Select *, (RollingPpLVaccinated/population)*100 as percentage
From PopsVsVacc


-- TEMP TABLE

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar (255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPplVaccinated numeric,
)

Insert into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
From PorfolioProject..covid_deaths$ as dea
JOIN PorfolioProject..covid_vacc$ as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPpLVaccinated/population)*100 as percentage
From #PercentPopulationVaccinated

--Creating View to Store data for later visualizations
Create View PercentPopulationVaccinated1 as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPplVaccinated
From PorfolioProject..covid_deaths$ as dea
JOIN PorfolioProject..covid_vacc$ as vac
	ON dea.location = vac.location 
	AND dea.date = vac.date
Where dea.continent is not null
--Order by 2,3