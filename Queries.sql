-- Q1 Find the average price of “iPhone Xs” on Shiokee from 1 August 2021 to 31 August 2021. 
 
SELECT AVG(Price) AS 'Average Price of iPhone X (August 2021)'
FROM PriceHistory, ProductListings
WHERE ProductListings.PName = 'iPhone X'
AND StartDate >= '2021-08-01'
AND EndDate <= '2021-08-31'
AND ProductListings.SPID = PriceHistory.SPID;

-- Q2 Find products that received at least 100 ratings of “5” in August 2021, and order them by their average ratings.
 
--Scenario 1: Feedback is given for each ProductsInOrders, regardless of Oquantity ordered.

SELECT Pname, AVG(CAST(rating AS FLOAT)) AS AverageRating, SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) AS Numof5Ratings
FROM  Feedback, ProductsInOrders
WHERE Feedback.OPID = ProductsInOrders.OPID
AND Feedback.DateTime >= '2021-08-01'
AND Feedback.DateTime <= '2021-08-31'
GROUP BY Pname
Having SUM(CASE WHEN rating = 5 THEN 1 ELSE 0 END) >= 100
ORDER BY AVG(CAST(rating AS FLOAT)) DESC;

-- Scenario 2: Feedback is given for each Oquantity ordered in ProductsInOrders

SELECT Pname,
CAST(SUM(Rating * OQuantity)AS FLOAT)/CAST(SUM(OQuantity) AS FLOAT) AS AverageRating,
SUM(CASE WHEN rating = 5 THEN OQuantity ELSE 0 END) AS Numof5Ratings
FROM  Feedback, ProductsInOrders
WHERE Feedback.OPID = ProductsInOrders.OPID
AND Feedback.DateTime >= '2021-08-01'
AND Feedback.DateTime <= '2021-08-31'
GROUP BY Pname
Having SUM(CASE WHEN rating = 5 THEN OQuantity ELSE 0 END) >= 100
ORDER BY AverageRating DESC;

--Q3 For all products purchased in June 2021 that have been delivered, find the average time from the ordering date to the delivery date.
 
--Scenario 1: Without considering OQuantity
 
SELECT CAST(SUM(DATEDIFF(day, Orders.DateTime, ProductsInOrders.DeliveryDate)) AS FLOAT)/CAST(COUNT(Orders.OID) AS FLOAT) AS 'Average Time(Days)'
FROM Orders, ProductsInOrders
WHERE Orders.OID = ProductsInOrders.OID
AND status = 'Delivered'
AND Orders.DateTime >= '2021-06-01'
AND Orders.DateTime <= '2021-06-30';

--Scenario 2: Considering OQuantity
 
SELECT CAST(SUM(OQuantity *DATEDIFF(day, Orders.DateTime, ProductsInOrders.DeliveryDate)) AS FLOAT)/CAST(SUM(OQuantity) AS FLOAT) AS 'Average Time(Days)'
FROM Orders, ProductsInOrders
WHERE Orders.OID = ProductsInOrders.OID
AND status = 'Delivered'
AND Orders.DateTime >= '2021-06-01'
AND Orders.DateTime <= '2021-06-30';

-- Q4 Let us define the “latency” of an employee by the average that he/she takes to process a complaint. Find the employee with the smallest latency. 

-- Step 2: Find the employee with the least latency
SELECT Employees.name AS EmployeeName,
AVG(DATEDIFF(day, FilledDateTime, HandledDateTime)) AS AverageLatency
FROM Complaints,Employees
WHERE Employees.EID = Complaints.EID
GROUP BY Employees.Name
HAVING AVG(DATEDIFF(day, FilledDateTime, HandledDateTime)) =
(
   -- Step 1: Find the least latency
   SELECT TOP 1 AVG(DATEDIFF(day, FilledDateTime, HandledDateTime))
   FROM Complaints,Employees
   WHERE Employees.EID = Complaints.EID
   GROUP BY Employees.Name
   ORDER BY AVG(DATEDIFF(day, FilledDateTime, HandledDateTime)) ASC
)


-- Q5 Produce a list that contains (i) all products made by Samsung, and (ii) for each of them, the number of shops on Shiokee that sell the product.
 
SELECT ProductListings.Pname, COUNT(ProductListings.Sname) AS NumShopSelling
FROM ProductListings, Products
WHERE ProductListings.Pname = Products.Pname
AND Maker = 'SAMSUNG'
GROUP BY ProductListings.Pname
ORDER BY NumShopSelling DESC

-- Q6 Find shops that made the most revenue in August 2021.
 
-- Step 2: Find the shops with maximum revenue
SELECT Sname, SUM(OPrice * OQuantity) AS Revenue
FROM ProductsInOrders, Orders
WHERE ProductsInOrders.OID = Orders.OID
AND Orders.DateTime >= '2021-08-01'
AND Orders.DateTime <= '2021-08-31'
GROUP BY Sname
HAVING SUM(OPrice * OQuantity) =
(
   -- Step 1: Find the maximum revenue
   SELECT TOP 1 SUM(OPrice * OQuantity)
   FROM ProductsInOrders, Orders
   WHERE ProductsInOrders.OID = Orders.OID
   AND Orders.DateTime >= '2021-08-01'
   AND Orders.DateTime <= '2021-08-31'
   GROUP BY SName
   ORDER BY SUM(OPrice * OQuantity) DESC
)

-- Q7 For users that made the most amount of complaints, find the most expensive products he/she has ever purchased. 
 
-- Step 4: Find the name of such product for each user
SELECT Y.UID, Pname, MaxPrice
FROM
(
  -- Step 3: Find the price of the most expensive items bought by these users
  SELECT X.UID, MAX(Oprice) as MaxPrice
  FROM
  (
      -- Step 2: Find the users with the highest number of complaint
      SELECT Users.UID
      FROM Users,Complaints
      WHERE Users.UID = Complaints.UID
      GROUP By Users.UID
      HAVING COUNT(complaints.uid) =
      (
          -- Step 1: Find the highest number of complaints
          SELECT TOP 1 COUNT(Complaints.UID)
          FROM Users,Complaints
          WHERE Users.UID = Complaints.UID
          GROUP By Complaints.UID
          ORDER By Count(CID) DESC
      )
  )X, Orders, ProductsInOrders
  WHERE Orders.UID = X.UID
  AND Orders.OID = ProductsInOrders.OID
  GROUP BY X.UID
)Y, Orders, ProductsInOrders
WHERE Orders.UID = Y.UID
AND Orders.OID = ProductsInOrders.OID
AND OPrice = MaxPrice

-- Q8 Find products that have never been purchased by some users, but are the top 5 most purchased products by other users in August 2021. (e.g. Suppose some users: uid = 521 & 581)
 
-- Step 2:Finding top 5 most purchased products by other users
Select TOP 5 Pname, SUM(OQuantity) as 'Quantity Sold'
FROM Orders, ProductsInOrders
Where Orders.OID = ProductsInOrders.OID
AND PName NOT IN
(
   -- Step 1:Finding all products purchased by UID 521 & UID 581
   SELECT Pname
   FROM Orders, ProductsInOrders
   WHERE Orders.OID = ProductsInOrders.OID
   AND Orders.UID = 521
   UNION
   SELECT Pname
   FROM Orders, ProductsInOrders
   WHERE Orders.OID = ProductsInOrders.OID
   AND Orders.UID = 581
)
AND Orders.DateTime >= '2021-08-01'
AND Orders.DateTime <= '2021-08-31'
GROUP BY Pname
ORDER BY SUM(OQuantity) DESC

-- Q9 Find products that are increasingly being purchased over at least 3 months. 
 
Query Input
-- Step 2: Find product that increasingly being purchased over at least 3 months
SELECT DISTINCT Pname
FROM
(
   -- Step 1: Find difference between no. product sold this month compared to one   month ago, two month ago, and three month ago
   SELECT Products.Pname, SUM(OQuantity) as NumSold,
   YEAR(Orders.DateTime)*100 + MONTH(Orders.DateTime) AS YearMonth,
   SUM(OQuantity) - Lag(SUM(OQuantity),1,NULL) OVER (PARTITION BY Products.Pname ORDER BY Products.Pname, YEAR(Orders.DateTime)*100 + MONTH(Orders.DateTime)) AS Diff1,
   SUM(OQuantity) - Lag(SUM(OQuantity),2,NULL) OVER (PARTITION BY Products.Pname ORDER BY Products.Pname, YEAR(Orders.DateTime)*100 + MONTH(Orders.DateTime)) AS Diff2,
   SUM(OQuantity) - Lag(SUM(OQuantity),3,NULL) OVER (PARTITION BY Products.Pname ORDER BY Products.Pname, YEAR(Orders.DateTime)*100 + MONTH(Orders.DateTime)) AS Diff3
   FROM ProductsInOrders, Products, Orders
   WHERE ProductsInOrders.Pname = Products.Pname
   AND Orders.OID = ProductsInOrders.OID
   GROUP By Products.Pname, YEAR(Orders.DateTime)*100 + MONTH(Orders.DateTime)
) AS X
WHERE Diff1 >0
AND Diff2 > 0
AND Diff3 > 0
AND Diff2 > Diff1
AND Diff3 > Diff2
AND Diff3 > Diff1