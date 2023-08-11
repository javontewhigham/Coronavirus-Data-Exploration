-- Selects data we are starting with

Select Location, date, total_cases, new_cases, total_deaths, population
From CoronavirusDataExploration..CovidDeaths
Where continent is not null 
order by 1,2


-- Total cases vs total deaths
-- Shows likelihood of dying if contracted in your country

Select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CoronavirusDataExploration..CovidDeaths
Where location like '%states%' and continent is not null 
order by 1,2


-- Total cases vs population
-- Shows what percentage of population is infected

Select Location, date, Population, total_cases, (total_cases/population)*100 as PercentPopulationInfected
From CoronavirusDataExploration..CovidDeaths
order by 1,2


-- Countries with the highest infection rate compared to population

Select Location, Population, MAX(total_cases) as HighestInfectionCount, Max((total_cases/population))*100 as PercentPopulationInfected
From CoronavirusDataExploration..CovidDeaths
group by Location, Population
order by PercentPopulationInfected desc


-- Countries with the highest death count per population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CoronavirusDataExploration..CovidDeaths
Where continent is not null 
group by Location
order by TotalDeathCount desc


-- BREAKING DATA DOWN BY CONTINENT:

-- Shows contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From CoronavirusDataExploration..CovidDeaths
Where continent is not null 
group by continent
order by TotalDeathCount desc


-- Shows percentage of death among population in each continent

Select SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CoronavirusDataExploration..CovidDeaths
where continent is not null 
order by 1,2


-- Total population vs vaccinations
-- Shows percentage of population that has recieved at least one vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(cast(vac.new_vaccinations as int)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CoronavirusDataExploration..CovidDeaths dea
Join CoronavirusDataExploration..CovidVaccinations vac On dea.location = vac.location and dea.date = vac.date
Where dea.continent is not null 
order by 2,3

-- Using CTE to perform calculation on 'Partition by' in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as (
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CoronavirusDataExploration..CovidDeaths dea
Join CoronavirusDataExploration..CovidVaccinations vac On dea.location = vac.location and dea.date = vac.date
where dea.continent is not null 
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac

-- Using temp table to perform calculation on 'Partition by' in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From CoronavirusDataExploration..CovidDeaths dea
Join CoronavirusDataExploration..CovidVaccinations vac On dea.location = vac.location and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated