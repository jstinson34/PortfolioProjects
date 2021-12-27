--Portfolio Project: Nashville Housing, Data Cleaning
/*

Cleaning Data in SQL Queries

*/

Select SaleDateConverted, CONVERT(Date, SaleDate)
From PortfolioProject.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(date, SaleDate) 

-- After only the Select & Update statements, SaleDate did not convert to the date only as expected.
-- ALTER TABLE used to add the column SaleDateConverted the NashvilleHousing table. 
-- ALTER TABLE must be run before Update to create a column for Update to reference

ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date; 

-- NashvilleHousing tabled Updated to fill the SaleDateConverted with the converted date from SaleDate

Update NashvilleHousing
SET SaleDateConverted = CONVERT(date, SaleDate)


-----------------------
-- Populate Property Address Data

-- Find all Property Addresses that are null and replace with addresses if available. 
-- Parcel IDs correlate to Property Address but Property address is not always included (is null)
---- Join Table on itself to find all properties with the same ParcelID but different UniqueIDs (UniqueIDs differ because owner may differ).
---- Use WHERE clause to grab only the properties where there are NULL properties among the duplicates
---- If Propertyaddress is NULL, input Property address from duplicate ParcelID

--Select NH1.ParcelID, NH1.PropertyAddress, NH2.ParcelID, NH2.PropertyAddress, ISNULL(NH1.PropertyAddress, NH2.PropertyAddress)
--From PortfolioProject.dbo.NashvilleHousing as NH1
--INNER JOIN PortfolioProject.dbo.NashvilleHousing as NH2
--	ON NH1.ParcelID = NH2.ParcelID
--	AND NH1.[UniqueID ]<>NH2.[UniqueID ]
--Where NH1.PropertyAddress is null

-- Update Records in the table. Do NOT forget to add WHERE clause, or else all records will change!!
Update a
SET PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From PortfolioProject.dbo.NashvilleHousing as a
JOIN PortfolioProject.dbo.NashvilleHousing as b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

-----------
-- Breaking out Addresses  into Indivdual Columns
Select PropertyAddress
From PortfolioProject.dbo.NashvilleHousing
--Where PropertyAddress IS NULL
--Order by ParcelID

-- CHARINDEX = FIND location of comma, then subtract one to get just before the comma so it is not included
-- SUBSTRING ( string to extract from, start of string, length of string)
----SELECT 
----SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as Address
----, SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress)) as City 
----From PortfolioProject.dbo.NashvilleHousing

-- Separate out Property Address

ALTER TABLE NashvilleHousing
ADD PropertySplitAddress nvarchar(255); 

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)

ALTER TABLE NashvilleHousing
ADD PropertySplitCity nvarchar(255); 

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))

-- Separate Owner Address
select OwnerAddress
From PortfolioProject.dbo.NashvilleHousing

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)
, PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD OwnerSplitAddress nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerSplitCity nvarchar(255)

ALTER TABLE NashvilleHousing
ADD OwnerSplitState nvarchar(255) 

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'),3)

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'),2)

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.'),1)


----------
--Change Y and N to Yes and No "Sold as Vacant" field

-- Count the # of different outputs in SoldAsVacant to determine if all should be Y/N or Yes/No
Select DISTINCT (SoldasVacant), COUNT(SoldAsVacant)
From PortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by SoldAsVacant

-- Determine if this statement will work to change the Y/N to Yes/No
Select SoldAsVacant
, CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END
From PortfolioProject.dbo.NashvilleHousing

-- Update Table to change the y/n to yes/no
Update NashvilleHousing
SET SoldAsVacant = 
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	WHEN SoldAsVacant = 'N' THEN 'No'
	ELSE SoldAsVacant
	END

	
-------------------------
--Remove Duplicates (not standard practice to DELETE duplicates)
WITH RowNumCTE as (
Select *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID, 
	PropertyAddress,
	SalePrice,
	SaleDate,
	LegalReference
	ORDER BY UniqueID) as row_num
From PortfolioProject.dbo.NashvilleHousing ) 
--Order by ParcelID
DELETE
From RowNumCTE
Where row_num > 1


-----------------
-- Delete Unused Columns

select *
From PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate