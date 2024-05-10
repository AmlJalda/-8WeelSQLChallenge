

CREATE DATABASE _8_Weeks_Challenge

GO

USE _8_Weeks_Challenge
GO

CREATE SCHEMA dannys_diner
GO

CREATE TABLE dannys_diner.customers (
										customer_id VARCHAR(10) PRIMARY KEY,
										joind_date DATE
										)
GO

INSERT INTO dannys_diner.customers(
									customer_id,
									joind_date
									)
			VALUES	
					('A', '2021-01-07'),
					('B', '2021-01-09'),
					('C', '2021-01-11')

GO

SELECT * FROM dannys_diner.customers

GO

sp_help 'dannys_diner.customers'

GO


CREATE TABLE dannys_diner.products (
									product_id INT PRIMARY KEY,
									product_name VARCHAR(25),
									price decimal
									)
GO

INSERT INTO dannys_diner.products

SELECT  '1', 'sushi', '10' UNION ALL
SELECT  '2', 'curry', '15' UNION ALL
SELECT  '3', 'ramen', '12'

GO



CREATE TABLE dannys_diner.sales (
								customer_id varchar(10) FOREIGN KEY REFERENCES dannys_diner.customers(customer_id),
								order_date date,
								product_id INT FOREIGN KEY REFERENCES dannys_diner.products(product_id)
								)
GO

INSERT INTO dannys_diner.sales (
								customer_id,
								order_date,
								product_id
								)
			VALUES 
					('A', '2021-01-01', 1),
					('A', '2021-01-01', 2),
					('A', '2021-01-07', 2),
					('A', '2021-01-10', 3),
					('A', '2021-01-11', 3),
					('A', '2021-01-11', 3),
					('B', '2021-01-01', 2),
					('B', '2021-01-02', 2),
					('B', '2021-01-04', 1),
					('B', '2021-01-11', 1),
					('B', '2021-01-16', 3),
					('B', '2021-02-01', 3),
					('C', '2021-01-01', 3),
					('C', '2021-01-01', 3),
					('C', '2021-01-07', 3)

GO

SELECT * FROM dannys_diner.sales
SELECT * FROM dannys_diner.customers
SELECT * FROM dannys_diner.products


--CASE STUDY QUESTIONS

--QUERY: 1 - What is the total amount each customer spent at the restaurant?

SELECT * FROM dannys_diner.sales
SELECT * FROM dannys_diner.products

SELECT
	s.customer_id Customers,
	SUM(p.price) Total_Spent
FROM
	dannys_diner.sales s
INNER JOIN
	dannys_diner.products p
ON s.product_id = p.product_id
GROUP BY s.customer_id

----------------------------------------------------------------------------------------------------

--QUERY: 2 - How many days has each customer visited the restaurant?

SELECT
	customer_id Customers,
	COUNT(order_date) Visits
FROM dannys_diner.sales
GROUP BY customer_id

--------------------------------------------------------------------------------------------------------

--QUERY: 3 - What was the first item from the menu purchased by each customer?

SELECT *
FROM dannys_diner.sales
ORDER BY  customer_id ASC, order_date ASC

SELECT * FROM dannys_diner.products

WITH RNK_CTE
AS(
SELECT
	s.customer_id,
	p.product_name,
	s.order_date,
	DENSE_RANK() OVER (ORDER BY s.order_date ASC) RNK
FROM dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id
)

SELECT
	customer_id customer,
	product_name product
FROM RNK_CTE WHERE RNK = 1

--------------------------------------------------------------------------------------------------------

--QUERY: 4 - What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
	product_id,
	count(customer_id) purchase_count
FROM
	dannys_diner.sales
GROUP BY product_id

SELECT * FROM dannys_diner.products

SELECT TOP 1
	p.product_name products,
	COUNT(s.product_id) purchase_count
FROM
	dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id
GROUP BY
	p.product_name
ORDER BY
	purchase_count DESC

--------------------------------------------------------------------------------------------------------

--QUERY: 5 - Which item was the most popular for each customer?

SELECT *
FROM dannys_diner.sales
ORDER BY customer_id


SELECT * FROM dannys_diner.products


--DENSE_RANK
WITH popular_item_row
AS (
SELECT
s.customer_id,
p.product_name products,
COUNT(s.product_id) purchase_count,
DENSE_RANK ()
	OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) RNK
FROM dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id
GROUP BY s.customer_id, p.product_name
)
SELECT customer_id,
	   products,
	   purchase_count
FROM popular_item_row
WHERE RNK = 1

--RANK
WITH popular_item_rnk AS (
	SELECT
		s.customer_id,
		p.product_name products,
		COUNT(s.product_id) purchase_count,
		RANK() OVER(PARTITION BY s.customer_id ORDER BY COUNT(s.product_id) DESC) RNK
	FROM dannys_diner.sales s
	INNER JOIN dannys_diner.products p
	ON s.product_id = p.product_id
	GROUP BY s.customer_id, p.product_name
	)
SELECT customer_id,
	   products,
	   purchase_count
FROM popular_item_rnk
WHERE RNK = 1

--------------------------------------------------------------------------------------------------------

--QUERY: 6 - Which item was purchased first by the customer after they became a member?

SELECT * FROM dannys_diner.customers
SELECT * FROM dannys_diner.sales

SELECT * FROM dannys_diner.products

--A joind on 2021-01-07 and we want to see orders on or after this date

--USING CTE

WITH my_cte
AS (
SELECT
	s.customer_id,
	c.joind_date,
	s.order_date,
	p.product_name,
	RANK()
		OVER(PARTITION BY c.joind_date ORDER BY s.order_date) RNK
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
LEFT JOIN dannys_diner.products p
ON s.product_id = p.product_id
WHERE c.joind_date <= s.order_date
)
SELECT 
	customer_id,
	joind_date,
	order_date,
	product_name
FROM my_cte
WHERE RNK = 1

--USING SUB QUERY

SELECT * FROM (
SELECT s.customer_id, c.joind_date, s.order_date, p.product_name,
RANK() OVER(PARTITION BY c.joind_date ORDER BY s.order_date) RNK
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
LEFT JOIN dannys_diner.products p
ON s.product_id = p.product_id
WHERE c.joind_date <= s.order_date
) A --Alias for this SUB-QUERY
WHERE A.RNK = 1

--------------------------------------------------------------------------------------------------------

--QUERY: 7 - Which item was purchased just before the customer became a member?

WITH my_cte AS (
SELECT
	s.customer_id,
	c.joind_date,
	s.order_date,
	p.product_name,
	RANK()
		OVER(PARTITION BY c.joind_date ORDER BY s.order_date) RNK
FROM dannys_diner.sales s
LEFT JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
LEFT JOIN dannys_diner.products p
ON s.product_id = p.product_id
WHERE c.joind_date >= s.order_date
)
SELECT 
	customer_id,
	joind_date,
	order_date,
	product_name
FROM my_cte
WHERE RNK = 1

--------------------------------------------------------------------------------------------------------

--QUERY: 8 - What is the total items and amount spent by each member before they became a member?

SELECT * FROM dannys_diner.sales

WITH my_cte
AS (
SELECT
	c.customer_id,
	c.joind_date,
	s.order_date,
	s.product_id,
	COUNT(s.product_id) product_count,
	p.price
FROM dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id
INNER JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
WHERE c.joind_date > s.order_date
GROUP BY
	c.customer_id,
	c.joind_date,
	s.order_date,
	p.price,
	s.product_id
)
SELECT
	customer_id,
	joind_date,
	MAX(order_date) order_date,
	SUM(product_count) total_products,
	SUM(price) price,
	SUM(product_count * price) total_amount
FROM my_cte
GROUP BY
	customer_id,
	joind_date
ORDER BY customer_id

--------------------------------------------------------------------------------------------------------

--QUERY: 9 - If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

--If each $1 = 10 points and sushi * 2.

SELECT
	s.customer_id,
	s.product_id,
	p.product_name,
	p.price,
	CASE
		WHEN p.product_name = 'sushi' THEN 20 ELSE 10
	END AS points,
	CASE
		WHEN p.product_name = 'sushi'
			THEN p.price * 20
		ELSE p.price * 10
	END AS total_points 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id


SELECT
	s.customer_id,
	SUM(CASE
			WHEN p.product_name = 'sushi'
				THEN p.price * 20
			ELSE p.price * 10
		END ) AS total_points 
FROM dannys_diner.sales s
INNER JOIN dannys_diner.products p
ON s.product_id = p.product_id
GROUP BY
	s.customer_id

--------------------------------------------------------------------------------------------------------
/*
--QUERY: 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items,
not just sushi - how many points do customer A and B have at the end of January?
*/
WITH my_cte
AS (
SELECT
	s.customer_id,
	s.product_id,
	(s.product_id * 2) points,
	s.order_date,
	c.joind_date,
	DATEADD(DAY, 7, c.joind_date) first_week
FROM dannys_diner.sales s
INNER JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
)
SELECT
	customer_id,
	SUM(points) total_points
FROM my_cte
WHERE 
	(order_date BETWEEN joind_date AND first_week)
AND 
	customer_id IN ('A', 'B')
GROUP BY 
	customer_id


SELECT
	s.customer_id,
	s.product_id,
	(s.product_id * 2) points,
	c.joind_date, 7 Days , DATEADD(DAY, 7, c.joind_date) first_week,
	s.order_date
FROM dannys_diner.sales s
INNER JOIN dannys_diner.customers c
ON s.customer_id = c.customer_id
WHERE
	s.customer_id IN ('A', 'B') AND s.order_date BETWEEN c.joind_date
		AND DATEADD(DAY, 7, c.joind_date)
