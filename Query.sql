--Get employee details with department, shift, and current salary.
CREATE VIEW vw_HR_Dashboard AS
SELECT 
    e.BusinessEntityID,
    d.Name AS Department,
    s.Name AS Shift,
    eph.Rate AS Salary,
    edh.StartDate
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
    ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.Shift s 
    ON edh.ShiftID = s.ShiftID
JOIN HumanResources.EmployeePayHistory eph 
    ON e.BusinessEntityID = eph.BusinessEntityID
WHERE edh.EndDate IS NULL;
select * from vw_HR_Dashboard

--🔹 2. Current Active Employees

--Find employees who are currently active in a department (EndDate IS NULL). 
SELECT 
    e.BusinessEntityID,
    d.Name AS Department
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh 
    ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
    ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL;

--🔹 3. Highest Paid Employee per Department

--Return the highest salary employee in each department
WITH SalaryCTE AS (SELECT d.Name AS Department,e.BusinessEntityID,eph.Rate,
RANK() OVER (PARTITION BY d.Name ORDER BY eph.Rate DESC) AS rnk FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID JOIN HumanResources.EmployeePayHistory eph 
ON e.BusinessEntityID = eph.BusinessEntityID WHERE edh.EndDate IS NULL
)
SELECT * FROM SalaryCTE WHERE rnk = 1;

--🔹 4. Department-wise Average Salary

--Calculate average salary for each department.
SELECT d.Name AS Department,AVG(eph.Rate) AS AvgSalary FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.EmployeeDepartmentHistory edh ON eph.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL GROUP BY d.Name;

--🔹 5. Salary Rank within Department

--Rank employees based on salary within each department using RANK().
SELECT  d.Name AS Department,e.BusinessEntityID, eph.Rate,
RANK() OVER (PARTITION BY d.Name ORDER BY eph.Rate DESC) AS RankInDept
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh 
ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
 ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.EmployeePayHistory eph 
ON e.BusinessEntityID = eph.BusinessEntityID
WHERE edh.EndDate IS NULL;

--🔹 6. Top 3 Highest Paid Employees Overall

--Use TOP or ROW_NUMBER() to fetch top earners.

SELECT TOP 3 BusinessEntityID, Rate AS Salary
FROM HumanResources.EmployeePayHistory ORDER BY Rate DESC;

--🔹 7. Salary Growth per Employee
--Compare current salary vs previous salary using LAG().
SELECT BusinessEntityID, Rate, LAG(Rate) OVER (PARTITION BY BusinessEntityID ORDER BY RateChangeDate) AS PrevSalary, Rate - LAG(Rate) OVER (PARTITION BY BusinessEntityID ORDER BY RateChangeDate) AS SalaryGrowth
FROM HumanResources.EmployeePayHistory;

--🔹 8. Employees with Multiple Department Changes
--Find employees who worked in more than 1 department.
SELECT BusinessEntityID, COUNT(DISTINCT DepartmentID) AS DeptCount FROM HumanResources.EmployeeDepartmentHistory
GROUP BY BusinessEntityID HAVING COUNT(DISTINCT DepartmentID) > 1;

--🔹 9. Longest Serving Employee
--Calculate employee with maximum tenure using HireDate.
SELECT TOP 1  BusinessEntityID, DATEDIFF(YEAR, HireDate, GETDATE()) AS YearsWorked
FROM HumanResources.Employee ORDER BY YearsWorked DESC;

--🔹 10. Department with Highest Total Salary Expense
--Sum salaries grouped by department.
SELECT TOP 1 d.Name AS Department,SUM(eph.Rate) AS TotalSalary
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.EmployeeDepartmentHistory edh ON eph.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL GROUP BY d.Name ORDER BY TotalSalary DESC;

--🔹 11. Shift-wise Employee Count
--Count employees working in each shift.
SELECT s.Name AS Shift,COUNT(*) AS EmployeeCount
FROM HumanResources.EmployeeDepartmentHistory edh
JOIN HumanResources.Shift s ON edh.ShiftID = s.ShiftID
WHERE edh.EndDate IS NULL GROUP BY s.Name;

--🔹 12. Employees Without Department
--Find employees who are not assigned to any department.
SELECT e.BusinessEntityID FROM HumanResources.Employee e
LEFT JOIN HumanResources.EmployeeDepartmentHistory edh 
ON e.BusinessEntityID = edh.BusinessEntityID
WHERE edh.BusinessEntityID IS NULL;

--🔹 13. Salary Difference from Department Average
--Compare each employee’s salary with department average.
WITH DeptAvg AS (SELECT d.Name AS Department,AVG(eph.Rate) AS AvgSalary
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.EmployeeDepartmentHistory edh 
ON eph.BusinessEntityID = edh.BusinessEntityID 
JOIN HumanResources.Department d 
ON edh.DepartmentID = d.DepartmentID
WHERE edh.EndDate IS NULL GROUP BY d.Name)SELECT  d.Name AS Department, e.BusinessEntityID,eph.Rate,da.AvgSalary,eph.Rate - da.AvgSalary AS Difference
FROM HumanResources.Employee e
JOIN HumanResources.EmployeeDepartmentHistory edh 
ON e.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
 ON edh.DepartmentID = d.DepartmentID
JOIN HumanResources.EmployeePayHistory eph 
ON e.BusinessEntityID = eph.BusinessEntityID
JOIN DeptAvg da ON d.Name = da.Department
WHERE edh.EndDate IS NULL;

--🔹 14. Monthly Hiring Trend
--Analyze hiring pattern using YEAR() and MONTH().
SELECT YEAR(HireDate) AS Year,MONTH(HireDate) AS Month,COUNT(*) AS TotalHires
FROM HumanResources.Employee
GROUP BY YEAR(HireDate), MONTH(HireDate)
ORDER BY Year, Month;

--🔹 15. Employees Working in Night Shift with High Salary
--Apply multiple filters (shift + salary condition).
SELECT e.BusinessEntityID,eph.Rate,s.Name AS Shift
FROM HumanResources.Employee e JOIN HumanResources.EmployeeDepartmentHistory edh 
ON e.BusinessEntityID = edh.BusinessEntityID JOIN HumanResources.Shift s 
ON edh.ShiftID = s.ShiftID JOIN HumanResources.EmployeePayHistory eph 
ON e.BusinessEntityID = eph.BusinessEntityID
WHERE s.Name = 'Night' AND eph.Rate > 50;

--🔹 16. Most Frequent Department Transfer
--Find department where most transfers happened.
SELECT TOP 1 DepartmentID,COUNT(*) AS TransferCount
FROM HumanResources.EmployeeDepartmentHistory
GROUP BY DepartmentID ORDER BY TransferCount DESC;



--🔹 17. Employees with Same Salary in Same Department
--Detect duplicates using GROUP BY HAVING.
SELECT d.Name,eph.Rate,COUNT(*) AS CountEmployees
FROM HumanResources.EmployeePayHistory eph
JOIN HumanResources.EmployeeDepartmentHistory edh 
ON eph.BusinessEntityID = edh.BusinessEntityID
JOIN HumanResources.Department d 
ON edh.DepartmentID = d.DepartmentID
GROUP BY d.Name, eph.Rate
HAVING COUNT(*) > 1;

--🔹 18. Latest Salary Record for Each Employee
--Use ROW_NUMBER() to get most recent salary.
WITH LatestSalary AS ( SELECT  BusinessEntityID,Rate,
ROW_NUMBER() OVER (PARTITION BY BusinessEntityID ORDER BY RateChangeDate DESC) AS rn
FROM HumanResources.EmployeePayHistory)
SELECT * FROM LatestSalary WHERE rn = 1;

--🔹 19. Department-wise Salary Distribution Bands
--Create salary groups:
--Low (< 50K)
--Medium (50K–100K)
--High (> 100K)

SELECT BusinessEntityID,Rate,CASE WHEN Rate < 50 THEN 'Low'
WHEN Rate BETWEEN 50 AND 100 THEN 'Medium'ELSE 'High'END AS SalaryBand
FROM HumanResources.EmployeePayHistory;

