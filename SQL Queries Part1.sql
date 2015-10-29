/************************************************************************************************
Title:			SQL Queries
Created by: Santosh Mungle  <santoshmungle@gmail.com>
License:		CC BY 3.0

Usage:
These queries meant to give you an understanding of sql queries for analyzing data in database.
In this part, there are following 3 tables in the database:
 1) Table: trades
    columns: trade_id (pk), client_id, trade_datetime, facevalue, revenue
 2) Table: salesreps
    columns: salesrep_id (pk), first_name, last_name
 3) Table: clients
    columns: client_id (pk), name, assigned_salesrep_id, signup_datetime,   churn_datetime 
************************************************************************************************/


Query 1. How many trades were there in the month of September 2015?
Solution: 
SELECT COUNT(*) FROM trades 
WHERE MONTH(trade_datetime) = 9 and YEAR(trade_datetime) = 2015


Query 2. A client is signed up if he has a signup date and churned if there is a churn date. 
         What % of signed up accounts have churned?
Solution: 
SELECT (SELECT COUNT(*) FROM clients WHERE churn_datetime IS NOT NULL and signup_datetime IS NOT NULL ) * 100 / 
(SELECT COUNT(*) FROM clients as Sign_up WHERE signup_datetime IS NOT NULL) AS percentage 
    
    
Query 3. Produce a table which measures each sales representative’s performance for Q3 2015, 
         by number of clients signed up, number of clients churned, total facevalue of trades and total revenue generated.
Solution:
/* Trades is my database where I have tables including clients, trades, salesreps, comments, net_promoter_scores*/
USE Trades 
GO

WITH SalesRepData_CTE 
AS 
(
   SELECT salesrep_id, first_name, last_name, trade_datetime, signup_datetime, churn_datetime, facevalue, 
   revenue
   FROM clients, trades, salesreps
   WHERE clients.client_id = trades.client_id AND
   clients.assigned_salesrep_id = salesreps.salesrep_id AND
   trades.trade_datetime BETWEEN '2015-07-01 00:00:00.000' AND '2015-09-30 23:59:59.000'
),

AA_CTE 
AS
(
SELECT AA.salesrep_id, SUM(AA.NumClientSign) AS NumClientSign, 
SUM(AA.facevalue) AS TotalFaceValue, SUM(AA.revenue) AS TotalRevenue          
FROM 
(SELECT salesrep_id, first_name, last_name, COUNT(salesrep_id) AS NumClientSign, facevalue, revenue 
FROM SalesRepData_CTE GROUP BY salesrep_id, first_name, last_name, signup_datetime, facevalue, revenue
HAVING signup_datetime IS NOT NULL) AA
GROUP BY AA.salesrep_id 
),

BB_CTE
AS
(
SELECT BB.salesrep_id, SUM(BB.NumClientChurn) AS NumClientChurn        
FROM 
(SELECT salesrep_id, COUNT(salesrep_id) AS NumClientChurn FROM SalesRepData_CTE 
GROUP BY salesrep_id, churn_datetime
HAVING churn_datetime IS NOT NULL) BB
GROUP BY BB.salesrep_id   
)

SELECT AA_CTE.salesrep_id, AA_CTE.NumClientSign, BB_CTE.NumClientChurn, 
AA_CTE.TotalFaceValue, AA_CTE.TotalRevenue
FROM AA_CTE, BB_CTE
WHERE AA_CTE.salesrep_id=BB_CTE.salesrep_id  

         
Query 4. In 2015, due to government incentives, a significant proportion of trades were from clients with the word ‘Green’ or the word ‘Purple’ in their names. 
What fraction of total facevalue for the year can be attributed to these companies? 
Solution:
SELECT (SELECT SUM(AA.facevalue) FROM (SELECT clients.client_id, clients.name, trades.facevalue FROM clients
INNER JOIN trades
ON clients.client_id=trades.client_id AND
(clients.name LIKE '%Green%' OR clients.name LIKE '%Purple%')) AA) * 100 / 
(SELECT SUM(facevalue) FROM trades) AS FractionOfFaceval
