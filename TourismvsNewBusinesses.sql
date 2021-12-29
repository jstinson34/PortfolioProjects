
/*  PERCENT CHANGE YEAR OVER YEAR PER COUNTRY

1. Get previous year data from arrivals & new business registration. 
2. Use previous year data to get tourism arrivals and new business percent change year over year
3. Combine tables to compare percent change year over year per country

*/

-- 1. & 2.
WITH PrevYearArrivals as
(Select Entity as Country, Code, Year, TourismArrivals, 
LAG(TourismArrivals) OVER (Partition by Code ORDER BY Code) as ArrivalsPrevYear
From PortfolioProject.dbo.Arrivals
Where Year BETWEEN 2006 AND 2018
	AND Code is not null),
ChangeArrivals as (
Select Country, Code, Year,
((TourismArrivals - ArrivalsPrevYear)/TourismArrivals)*100  as PercentChangeArrivalsPrevYr
From PrevYearArrivals),

PrevYearNewBusiness as
(Select Entity as Country, Code, Year, NewBusinessDensity, 
LAG(NewBusinessDensity) OVER (Partition by Code ORDER BY Code) as NewBusinessPrevYear
From PortfolioProject.dbo.NewBusinessDensity
Where Year BETWEEN 2006 AND 2018
	AND Code is not null),
ChangeNewBusiness as (
Select Country, Code, Year
,((NewBusinessDensity - NewBusinessPrevYear)/NewBusinessDensity)*100  as PercentChangeNewBusinessPrevYr
From PrevYearNewBusiness)

-- 2. 
Select ca.Country, ca.Code, ca.Year, PercentChangeArrivalsPrevYr, PercentChangeNewBusinessPrevYr
From ChangeNewBusiness as cn
JOIN ChangeArrivals as ca
	ON cn.Code = ca.Code
	AND	cn.Year = ca.year
Order by Country, Year asc


/* MAX TOURISM ARRIVALS & MAX NEW BUSINESS PER COUNTRY
1. Maximum arrivals per country per year
*/
 
--1. 
Select entity as Country, Code, Year,
MAX(TourismArrivals) as MaxTourismArrivals
From PortfolioProject.dbo.Arrivals
WHERE entity not like '%world%'
	AND Code is not null
GROUP BY Code, entity, Year
ORDER BY MaxTourismArrivals DESC

--2. 
Select entity as Country, Code, Year,
MAX(NewBusinessDensity) as MaxNewBusiness
From PortfolioProject.dbo.NewBusinessDensity
WHERE entity not like '%world%'
	AND Code is not null
GROUP BY Code, entity, Year
ORDER BY MaxNewBusiness DESC


/* AVG TOURISM ARRIVALS VS. NEW BUSINESS BY INCOME LEVEL 

1. Determine MIN/MAX year common in each dataset to ensure matching timelines ==> 2006 - 2018 
2. Join tables and on income level for year range 2006 - 2018
3. Average tourism arrivals & businesss income level for 2006 - 2018
4. Rank tourism arrivals and New Business density 

*/

-- 1.
Select Entity as NewBusinessEntity, MIN(year), MAX(year) as maxyear
From PortfolioProject.dbo.newbusinessdensity
Where Code is null
	AND Entity like '%income%'
Group by Entity
Order by Entity;

Select Entity, MIN(year), MAX(year) as maxyear
From PortfolioProject.dbo.Arrivals
Where Code is null
	AND Entity like '%income%'
Group by Entity
Order by Entity;

-- 2. 
WITH IncomevsNewBusiness as (
Select a.Entity as TourismIncomeRegion, TourismArrivals ,a.Year as TYear, N.Entity as NewBusinessIncomeRegion, NewBusinessDensity, N. Year
From PortfolioProject.dbo.Arrivals as A
JOIN PortfolioProject.dbo.NewBusinessDensity as N
	ON A.Entity = N.Entity
	AND A.Year = N.Year
Where a.Code is null
	AND A.Entity like '%income'
	AND a.Year BETWEEN 2006 and 2018
	AND N.Year BETWEEN 2006 and 2018
),
-- 3. 
AvgTourismVsNewBusiness as (
Select TourismIncomeRegion, NewBusinessIncomeRegion
, AVG(TourismArrivals) as AvgTourismArrivalsbyIncome
, AVG(NewBusinessDensity) as AvgNewBusinessDensity
From IncomevsNewBusiness
Group by TourismIncomeRegion, NewBusinessIncomeRegion
--Order by AvgNewBusinessDensity DESC;
)

--select *
--from IncomevsNewBusiness
-- 4.
Select TourismIncomeRegion as IncomeRegion, AvgTourismArrivalsbyIncome, AvgNewBusinessDensity
, RANK() OVER (ORDER BY Avgtourismarrivalsbyincome DESC) as Rank_Tourism
, RANK() OVER (ORDER BY AvgNewbusinessdensity DESC) as Rank_NewBusiness
From AvgTourismVsNewBusiness
Order by Rank_NewBusiness